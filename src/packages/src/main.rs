use anyhow::{Context, Result};
use rusqlite::Connection;
use serde::{Deserialize, Serialize};
use std::sync::Mutex;
use tracing::{error, info};
use zbus::{dbus_interface, ConnectionBuilder};

const DB_PATH: &str = "/var/lib/arynox/packages.db";

#[derive(Debug, Serialize, Deserialize)]
struct PackageInfo {
    name: String,
    version: String,
    description: String,
    installed: bool,
    size: u64,
}

struct PackageManager {
    db: Mutex<Connection>,
}

impl PackageManager {
    fn new() -> Result<Self> {
        if let Some(parent) = std::path::Path::new(DB_PATH).parent() {
            std::fs::create_dir_all(parent)?;
        }
        let db = Connection::open(DB_PATH)
            .with_context(|| format!("failed to open database at {}", DB_PATH))?;
        db.execute_batch(
            "CREATE TABLE IF NOT EXISTS packages (
                name TEXT PRIMARY KEY,
                version TEXT NOT NULL,
                description TEXT NOT NULL DEFAULT '',
                installed INTEGER NOT NULL DEFAULT 0,
                size INTEGER NOT NULL DEFAULT 0
            );"
        )?;
        Ok(Self { db: Mutex::new(db) })
    }

    fn run_cmd(program: &str, args: &[&str]) -> Result<String> {
        let output = std::process::Command::new(program)
            .args(args)
            .output()
            .with_context(|| format!("failed to execute {} {:?}", program, args))?;
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    }
}

#[dbus_interface(name = "org.arynox.PackageManager")]
impl PackageManager {
    async fn list_installed(&self) -> String {
        let db = self.db.lock().unwrap();
        let mut stmt = match db.prepare("SELECT name, version, description, size FROM packages WHERE installed = 1") {
            Ok(s) => s,
            Err(e) => return serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        };
        let packages: Vec<PackageInfo> = stmt.query_map([], |row| {
            Ok(PackageInfo {
                name: row.get(0)?,
                version: row.get(1)?,
                description: row.get(2)?,
                installed: true,
                size: row.get(3)?,
            })
        }).unwrap().filter_map(|r| r.ok()).collect();
        serde_json::json!({"success": true, "packages": packages, "count": packages.len()}).to_string()
    }

    async fn search(&self, query: String) -> String {
        let output = Self::run_cmd("apt-cache", &["search", &query]).unwrap_or_default();
        let packages: Vec<&str> = output.lines().collect();
        serde_json::json!({"success": true, "results": packages, "count": packages.len()}).to_string()
    }

    async fn install(&self, package_name: String) -> String {
        match Self::run_cmd("apt-get", &["install", "-y", &package_name]) {
            Ok(out) => {
                let db = self.db.lock().unwrap();
                db.execute(
                    "INSERT INTO packages (name, version, description, installed, size) VALUES (?1, '', '', 1, 0) ON CONFLICT(name) DO UPDATE SET installed = 1",
                    rusqlite::params![package_name],
                ).ok();
                serde_json::json!({"success": true, "output": out}).to_string()
            }
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn remove(&self, package_name: String) -> String {
        match Self::run_cmd("apt-get", &["remove", "-y", &package_name]) {
            Ok(out) => {
                let db = self.db.lock().unwrap();
                db.execute("UPDATE packages SET installed = 0 WHERE name = ?1", rusqlite::params![package_name]).ok();
                serde_json::json!({"success": true, "output": out}).to_string()
            }
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn update(&self) -> String {
        match Self::run_cmd("apt-get", &["update"]) {
            Ok(out) => serde_json::json!({"success": true, "output": out}).to_string(),
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn upgrade(&self) -> String {
        match Self::run_cmd("apt-get", &["upgrade", "-y"]) {
            Ok(out) => serde_json::json!({"success": true, "output": out}).to_string(),
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn get_info(&self, package_name: String) -> String {
        let output = Self::run_cmd("apt-cache", &["show", &package_name]).unwrap_or_default();
        serde_json::json!({"success": true, "info": output}).to_string()
    }

    async fn get_package_count(&self) -> String {
        let db = self.db.lock().unwrap();
        let count: i64 = db.query_row("SELECT COUNT(*) FROM packages WHERE installed = 1", [], |r| r.get(0)).unwrap_or(0);
        serde_json::json!({"success": true, "count": count}).to_string()
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt().with_env_filter("info").init();
    info!("Package Manager daemon starting");

    let daemon = PackageManager::new()?;
    let _conn = ConnectionBuilder::system()?
        .name("org.arynox.PackageManager")?
        .serve_at("/org/arynox/PackageManager", daemon)?
        .build()
        .await?;

    info!("Package Manager ready on org.arynox.PackageManager");
    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
    }
}
