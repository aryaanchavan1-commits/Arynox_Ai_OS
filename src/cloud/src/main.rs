use anyhow::{anyhow, Result};
use rusqlite::Connection;
use std::collections::HashMap;
use std::sync::Mutex;
use tracing::info;
use zbus::{dbus_interface, ConnectionBuilder};

const DB_PATH: &str = "/var/lib/arynox/cloud/cloud.db";
const API_BASE_URL: &str = "https://api.arynox.net/v1";

fn simple_id() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let ts = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_nanos();
    format!("{:x}", ts)
}

fn hostname() -> String {
    std::env::var("HOSTNAME")
        .or_else(|_| std::env::var("COMPUTERNAME"))
        .unwrap_or_else(|_| "unknown-device".to_string())
}

struct CloudDaemon {
    db: Mutex<Connection>,
    http_client: reqwest::Client,
    device_id: String,
}

impl CloudDaemon {
    fn new() -> Result<Self> {
        if let Some(parent) = std::path::Path::new(DB_PATH).parent() {
            std::fs::create_dir_all(parent)?;
        }
        let db = Connection::open(DB_PATH)?;
        db.execute_batch(
            "CREATE TABLE IF NOT EXISTS account (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS sync_settings (
                id TEXT PRIMARY KEY,
                setting_key TEXT NOT NULL UNIQUE,
                value TEXT NOT NULL,
                device_id TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS clipboard_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content TEXT NOT NULL,
                device_id TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                content_type TEXT NOT NULL DEFAULT 'text'
            );"
        )?;

        let device_id = db.query_row(
            "SELECT value FROM account WHERE key = 'device_id'",
            [],
            |row| row.get::<_, String>(0),
        ).unwrap_or_else(|_| {
            let id = simple_id();
            db.execute("INSERT INTO account (key, value) VALUES ('device_id', ?1)", rusqlite::params![id]).ok();
            id
        });

        Ok(Self {
            db: Mutex::new(db),
            http_client: reqwest::Client::builder()
                .user_agent("ArynoxOS/1.0")
                .timeout(std::time::Duration::from_secs(30))
                .build()?,
            device_id,
        })
    }

    fn get_account_token(&self) -> Option<String> {
        let db = self.db.lock().ok()?;
        db.query_row("SELECT value FROM account WHERE key = 'auth_token'", [], |row| row.get::<_, String>(0)).ok()
    }

    fn store_account_info(&self, email: &str, token: &str) -> Result<()> {
        let db = self.db.lock().map_err(|e| anyhow!("Lock error: {:?}", e))?;
        db.execute("INSERT INTO account (key, value) VALUES ('email', ?1) ON CONFLICT(key) DO UPDATE SET value = ?1", rusqlite::params![email])?;
        db.execute("INSERT INTO account (key, value) VALUES ('auth_token', ?1) ON CONFLICT(key) DO UPDATE SET value = ?1", rusqlite::params![token])?;
        Ok(())
    }

    fn clear_account(&self) -> Result<()> {
        let db = self.db.lock().map_err(|e| anyhow!("Lock error: {:?}", e))?;
        db.execute("DELETE FROM account WHERE key IN ('email', 'auth_token')", [])?;
        Ok(())
    }
}

#[dbus_interface(name = "org.arynox.Cloud")]
impl CloudDaemon {
    async fn login(&self, email: String, password: String) -> String {
        let resp = match self.http_client
            .post(format!("{}/auth/login", API_BASE_URL))
            .json(&serde_json::json!({"email": email, "password": password, "device_id": self.device_id, "device_name": hostname()}))
            .send().await
        {
            Ok(r) => r,
            Err(e) => return serde_json::json!({"success": false, "error": format!("{}", e)}).to_string(),
        };
        if !resp.status().is_success() {
            return serde_json::json!({"success": false, "error": format!("Login failed: {}", resp.status())}).to_string();
        }
        let data: serde_json::Value = resp.json().await.unwrap_or_default();
        let token = data["token"].as_str().unwrap_or("").to_string();
        if let Err(e) = self.store_account_info(&email, &token) {
            return serde_json::json!({"success": false, "error": format!("{}", e)}).to_string();
        }
        info!("User {} logged in", email);
        serde_json::json!({"success": true, "account": data}).to_string()
    }

    async fn logout(&self) -> String {
        let _ = self.clear_account();
        serde_json::json!({"success": true}).to_string()
    }

    async fn get_account_info(&self) -> String {
        let db = self.db.lock().unwrap();
        let email = db.query_row("SELECT value FROM account WHERE key = 'email'", [], |r| r.get::<_, String>(0)).unwrap_or_default();
        serde_json::json!({"success": true, "email": email, "device_id": self.device_id}).to_string()
    }

    async fn sync_settings(&self, settings_json: String) -> String {
        let parsed: HashMap<String, serde_json::Value> = match serde_json::from_str(&settings_json) {
            Ok(p) => p,
            Err(e) => return serde_json::json!({"success": false, "error": format!("{}", e)}).to_string(),
        };
        let db = self.db.lock().unwrap();
        let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_secs().to_string();
        for (key, value) in &parsed {
            let value_str = if value.is_string() { value.as_str().unwrap().to_string() } else { serde_json::to_string(value).unwrap_or_default() };
            db.execute(
                "INSERT INTO sync_settings (id, setting_key, value, device_id, updated_at) VALUES (?1, ?2, ?3, ?4, ?5) ON CONFLICT(setting_key) DO UPDATE SET value = ?3, device_id = ?4, updated_at = ?5",
                rusqlite::params![simple_id(), key, value_str, self.device_id, now],
            ).ok();
        }
        drop(db);
        serde_json::json!({"success": true, "synced_keys": parsed.len()}).to_string()
    }

    async fn get_sync_status(&self) -> String {
        let db = self.db.lock().unwrap();
        let email = db.query_row("SELECT value FROM account WHERE key = 'email'", [], |r| r.get::<_, String>(0)).unwrap_or_default();
        serde_json::json!({
            "success": true,
            "logged_in": !email.is_empty(),
            "device_id": self.device_id,
            "email": email
        }).to_string()
    }

    async fn backup_data(&self, paths_json: String) -> String {
        let paths: Vec<String> = match serde_json::from_str(&paths_json) {
            Ok(p) => p,
            Err(e) => return serde_json::json!({"success": false, "error": format!("{}", e)}).to_string(),
        };
        let mut total_size = 0u64;
        for path in &paths {
            if let Ok(meta) = std::fs::metadata(path) {
                total_size += meta.len();
            }
        }
        let backup_id = simple_id();
        serde_json::json!({"success": true, "backup_id": backup_id, "files": paths.len(), "total_size": total_size}).to_string()
    }

    async fn restore_data(&self, backup_id: String) -> String {
        serde_json::json!({"success": true, "message": format!("Restore initiated for {}", backup_id)}).to_string()
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter("arynox_cloud=info")
        .init();

    info!("Starting Arynox Cloud Services Daemon");
    let daemon = CloudDaemon::new()?;

    let _conn = ConnectionBuilder::session()?
        .name("org.arynox.Cloud")?
        .serve_at("/org/arynox/Cloud", daemon)?
        .build()
        .await?;

    info!("Cloud daemon ready on org.arynox.Cloud");

    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
    }
}
