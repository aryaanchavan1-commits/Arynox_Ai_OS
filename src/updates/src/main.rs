use anyhow::{Context, Result};
use rusqlite::Connection;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::path::Path;
use std::sync::Mutex;
use tokio::sync::RwLock;
use tracing::{error, info};
use zbus::{dbus_interface, ConnectionBuilder};

const UPDATE_SERVER_URL: &str = "https://updates.arynox.io/v1";
const DB_PATH: &str = "/var/lib/arynox/updates.db";

#[derive(Debug, Serialize, Deserialize, Clone)]
struct UpdatePackage {
    id: String,
    version: String,
    size: u64,
    sha256: String,
    url: String,
    description: String,
    prerelease: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct UpdateStatus {
    state: String,
    current_version: String,
    available_updates: Vec<UpdatePackage>,
    download_progress: f64,
    last_check: String,
    last_update: String,
}

struct UpdateDaemon {
    db: Mutex<Connection>,
    status: RwLock<UpdateStatus>,
    active_download: RwLock<Option<String>>,
}

impl UpdateDaemon {
    fn new() -> Result<Self> {
        let db = Connection::open(DB_PATH)
            .with_context(|| format!("failed to open database at {}", DB_PATH))?;
        db.execute_batch(
            "CREATE TABLE IF NOT EXISTS updates (
                id TEXT PRIMARY KEY,
                version TEXT NOT NULL,
                applied_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );"
        )?;

        Ok(Self {
            db: Mutex::new(db),
            status: RwLock::new(UpdateStatus {
                state: "idle".to_string(),
                current_version: "0.1.0".to_string(),
                available_updates: Vec::new(),
                download_progress: 0.0,
                last_check: String::new(),
                last_update: String::new(),
            }),
            active_download: RwLock::new(None),
        })
    }

    fn timestamp() -> String {
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs()
            .to_string()
    }

    fn current_version() -> String {
        let os_release = Path::new("/etc/os-release");
        if let Ok(content) = std::fs::read_to_string(os_release) {
            for line in content.lines() {
                if let Some(ver) = line.strip_prefix("VERSION_ID=") {
                    return ver.trim_matches('"').to_string();
                }
            }
        }
        "0.1.0".to_string()
    }

    async fn check_for_updates_impl() -> Result<Vec<UpdatePackage>> {
        let client = reqwest::Client::new();
        let resp = client
            .get(format!("{}/check", UPDATE_SERVER_URL))
            .send()
            .await
            .context("failed to contact update server")?;
        if !resp.status().is_success() {
            anyhow::bail!("update server returned status {}", resp.status());
        }
        let updates: Vec<UpdatePackage> = resp.json().await.context("failed to parse update response")?;
        Ok(updates)
    }

    async fn download_update_impl(&self, update_id: &str, update_url: &str) -> Result<String> {
        {
            let mut active = self.active_download.write().await;
            if active.is_some() {
                anyhow::bail!("another download is already in progress");
            }
            *active = Some(update_id.to_string());
        }

        let result = self.perform_download(update_id, update_url).await;

        {
            let mut active = self.active_download.write().await;
            *active = None;
        }
        result
    }

    async fn perform_download(&self, update_id: &str, update_url: &str) -> Result<String> {
        let client = reqwest::Client::new();
        let resp = client.get(update_url).send().await.context("failed to start update download")?;
        let bytes = resp.bytes().await.context("failed to read update data")?;
        let mut hasher = Sha256::new();
        hasher.update(&bytes);

        let dest_path = format!("/var/cache/arynox/updates/{}.update", update_id);
        if let Some(parent) = Path::new(&dest_path).parent() {
            std::fs::create_dir_all(parent)?;
        }

        std::fs::write(&dest_path, &bytes)?;
        let total_size = bytes.len() as u64;

        let _hash = format!("{:x}", hasher.finalize());
        info!("Downloaded update {} ({} bytes) to {}", update_id, total_size, dest_path);

        let mut status = self.status.write().await;
        status.download_progress = 100.0;
        Ok(dest_path)
    }

    fn apply_update_impl(update_path: &str) -> Result<()> {
        let extract_dir = "/tmp/arynox-update";
        std::fs::create_dir_all(extract_dir)?;

        let file = std::fs::File::open(update_path)?;
        let mut decoder = flate2::read::GzDecoder::new(file);
        let mut archive = tar::Archive::new(&mut decoder);
        archive.unpack(extract_dir)?;

        let system_root = "/";
        Self::run_cmd("sh", &["-c", &format!("cp -a {}/. {}", extract_dir, system_root)])?;
        info!("Update applied from {}", update_path);
        Ok(())
    }

    fn run_cmd(program: &str, args: &[&str]) -> Result<String> {
        let output = std::process::Command::new(program)
            .args(args)
            .output()
            .with_context(|| format!("failed to execute {} {:?}", program, args))?;
        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr).to_string();
            anyhow::bail!("{} failed: stderr={}", program, stderr);
        }
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    }
}

#[dbus_interface(name = "org.arynox.Updates")]
impl UpdateDaemon {
    async fn check_for_updates(&self) -> String {
        match Self::check_for_updates_impl().await {
            Ok(updates) => {
                let mut status = self.status.write().await;
                status.available_updates = updates.clone();
                status.last_check = Self::timestamp();
                status.state = if updates.is_empty() { "up_to_date".to_string() } else { "updates_available".to_string() };
                serde_json::json!({"success": true, "updates": updates, "count": updates.len()}).to_string()
            }
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn get_available_updates(&self) -> String {
        let status = self.status.read().await;
        serde_json::json!({
            "success": true,
            "updates": status.available_updates,
            "current_version": Self::current_version(),
            "last_check": status.last_check,
        }).to_string()
    }

    async fn download_update(&self, update_id: String) -> String {
        let updates = self.status.read().await.available_updates.clone();
        let update = updates.iter().find(|u| u.id == update_id);
        match update {
            Some(pkg) => match self.download_update_impl(&pkg.id, &pkg.url).await {
                Ok(path) => serde_json::json!({"success": true, "path": path, "id": pkg.id}).to_string(),
                Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
            },
            None => serde_json::json!({"success": false, "error": "Update not found"}).to_string(),
        }
    }

    async fn apply_update(&self, update_id: String) -> String {
        let update_path = format!("/var/cache/arynox/updates/{}.update", update_id);
        if !Path::new(&update_path).exists() {
            return serde_json::json!({"success": false, "error": "Update file not found"}).to_string();
        }
        match Self::apply_update_impl(&update_path) {
            Ok(_) => {
                let mut status = self.status.write().await;
                status.state = "update_applied".to_string();
                status.last_update = Self::timestamp();
                status.current_version = update_id.clone();
                serde_json::json!({"success": true, "version": update_id, "message": "Update applied, reboot required"}).to_string()
            }
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn cancel_update(&self) -> String {
        let mut active = self.active_download.write().await;
        *active = None;
        let mut status = self.status.write().await;
        status.state = "cancelled".to_string();
        status.download_progress = 0.0;
        serde_json::json!({"success": true}).to_string()
    }

    async fn get_update_status(&self) -> String {
        let status = self.status.read().await;
        serde_json::json!({"success": true, "status": &*status}).to_string()
    }

    async fn get_current_version(&self) -> String {
        serde_json::json!({"success": true, "version": Self::current_version()}).to_string()
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt().with_env_filter("info").init();
    info!("Arynox OTA Update daemon starting");

    let daemon = UpdateDaemon::new().context("failed to initialize update daemon")?;
    let _conn = ConnectionBuilder::session()?
        .name("org.arynox.Updates")?
        .serve_at("/org/arynox/Updates", daemon)?
        .build()
        .await?;

    info!("Updates D-Bus interface registered at org.arynox.Updates");

    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
    }
}
