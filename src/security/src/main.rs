use anyhow::{anyhow, Context, Result};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine};
use rusqlite::Connection;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Mutex;
use tracing::{error, info, warn};
use zbus::{dbus_interface, ConnectionBuilder};

const DB_PATH: &str = "/var/lib/arynox/security/security.db";

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Credential {
    id: String,
    service: String,
    username: String,
    password_encrypted: String,
    notes: String,
    created_at: String,
    updated_at: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Permission {
    app_id: String,
    app_name: String,
    permission: String,
    granted: bool,
    granted_at: String,
    expires_at: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct FirewallRule {
    id: String,
    name: String,
    direction: String,
    action: String,
    protocol: Option<String>,
    source: Option<String>,
    destination: Option<String>,
    port: Option<u16>,
    enabled: bool,
    created_at: String,
}

fn timestamp() -> String {
    let dur = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default();
    dur.as_secs().to_string()
}

fn simple_id() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let ts = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_nanos();
    format!("{:x}", ts)
}

fn encrypt(plaintext: &str) -> String {
    BASE64.encode(plaintext.as_bytes())
}

fn decrypt(ciphertext_b64: &str) -> String {
    String::from_utf8(BASE64.decode(ciphertext_b64.trim()).unwrap_or_default()).unwrap_or_default()
}

struct SecurityDaemon {
    db: Mutex<Connection>,
}

impl SecurityDaemon {
    fn new() -> Result<Self> {
        if let Some(parent) = std::path::Path::new(DB_PATH).parent() {
            std::fs::create_dir_all(parent)?;
        }
        let db = Connection::open(DB_PATH)?;
        db.execute_batch(
            "CREATE TABLE IF NOT EXISTS credentials (
                id TEXT PRIMARY KEY,
                service TEXT NOT NULL,
                username TEXT NOT NULL,
                password_encrypted TEXT NOT NULL,
                notes TEXT NOT NULL DEFAULT '',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS permissions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                app_id TEXT NOT NULL,
                app_name TEXT NOT NULL,
                permission TEXT NOT NULL,
                granted INTEGER NOT NULL DEFAULT 0,
                granted_at TEXT NOT NULL,
                expires_at TEXT,
                UNIQUE(app_id, permission)
            );
            CREATE TABLE IF NOT EXISTS firewall_rules (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                direction TEXT NOT NULL,
                action TEXT NOT NULL,
                protocol TEXT,
                source TEXT,
                destination TEXT,
                port INTEGER,
                enabled INTEGER NOT NULL DEFAULT 1,
                created_at TEXT NOT NULL
            );"
        )?;
        Ok(Self { db: Mutex::new(db) })
    }

    fn check_permission_inner(&self, app_id: &str, permission: &str) -> Result<bool> {
        let db = self.db.lock().map_err(|e| anyhow!("Lock error: {:?}", e))?;
        let mut stmt = db.prepare("SELECT granted FROM permissions WHERE app_id = ?1 AND permission = ?2")?;
        match stmt.query_row(rusqlite::params![app_id, permission], |row| row.get::<_, bool>(0)) {
            Ok(granted) => Ok(granted),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(false),
            Err(e) => Err(anyhow!("DB error: {:?}", e)),
        }
    }

    fn request_permission_inner(&self, app_id: &str, app_name: &str, permission: &str) -> Result<bool> {
        let db = self.db.lock().map_err(|e| anyhow!("Lock error: {:?}", e))?;
        let now = timestamp();
        db.execute(
            "INSERT INTO permissions (app_id, app_name, permission, granted, granted_at)
             VALUES (?1, ?2, ?3, 1, ?4)
             ON CONFLICT(app_id, permission) DO UPDATE SET granted = 1, app_name = ?2, granted_at = ?4",
            rusqlite::params![app_id, app_name, permission, now],
        )?;
        Ok(true)
    }

    fn revoke_permission_inner(&self, app_id: &str, permission: &str) -> Result<()> {
        let db = self.db.lock().map_err(|e| anyhow!("Lock error: {:?}", e))?;
        db.execute("UPDATE permissions SET granted = 0 WHERE app_id = ?1 AND permission = ?2", rusqlite::params![app_id, permission])?;
        Ok(())
    }

    fn get_permissions_inner(&self, app_id: &str) -> Result<Vec<Permission>> {
        let db = self.db.lock().map_err(|e| anyhow!("Lock error: {:?}", e))?;
        let mut stmt = db.prepare("SELECT app_id, app_name, permission, granted, granted_at, expires_at FROM permissions WHERE app_id = ?1")?;
        let rows = stmt.query_map(rusqlite::params![app_id], |row| {
            Ok(Permission {
                app_id: row.get(0)?,
                app_name: row.get(1)?,
                permission: row.get(2)?,
                granted: row.get(3)?,
                granted_at: row.get(4)?,
                expires_at: row.get(5)?,
            })
        })?;
        let mut permissions = Vec::new();
        for row in rows {
            permissions.push(row?);
        }
        Ok(permissions)
    }

    fn store_credential_inner(&self, service: &str, username: &str, password: &str, notes: &str) -> Result<String> {
        let id = simple_id();
        let encrypted = encrypt(password);
        let now = timestamp();
        let db = self.db.lock().map_err(|e| anyhow!("Lock error: {:?}", e))?;
        db.execute(
            "INSERT INTO credentials (id, service, username, password_encrypted, notes, created_at, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
            rusqlite::params![id, service, username, encrypted, notes, now, now],
        )?;
        Ok(id)
    }

    fn get_credential_inner(&self, credential_id: &str) -> Result<Credential> {
        let db = self.db.lock().map_err(|e| anyhow!("Lock error: {:?}", e))?;
        let mut stmt = db.prepare("SELECT id, service, username, password_encrypted, notes, created_at, updated_at FROM credentials WHERE id = ?1")?;
        let mut cred = stmt.query_row(rusqlite::params![credential_id], |row| {
            Ok(Credential {
                id: row.get(0)?,
                service: row.get(1)?,
                username: row.get(2)?,
                password_encrypted: row.get(3)?,
                notes: row.get(4)?,
                created_at: row.get(5)?,
                updated_at: row.get(6)?,
            })
        })?;
        cred.password_encrypted = decrypt(&cred.password_encrypted);
        Ok(cred)
    }

    fn delete_credential_inner(&self, credential_id: &str) -> Result<()> {
        let db = self.db.lock().map_err(|e| anyhow!("Lock error: {:?}", e))?;
        db.execute("DELETE FROM credentials WHERE id = ?1", rusqlite::params![credential_id])?;
        Ok(())
    }

    fn get_firewall_rules_inner(&self) -> Result<Vec<FirewallRule>> {
        let db = self.db.lock().map_err(|e| anyhow!("Lock error: {:?}", e))?;
        let mut stmt = db.prepare("SELECT id, name, direction, action, protocol, source, destination, port, enabled, created_at FROM firewall_rules ORDER BY created_at DESC")?;
        let rows = stmt.query_map([], |row| {
            Ok(FirewallRule {
                id: row.get(0)?,
                name: row.get(1)?,
                direction: row.get(2)?,
                action: row.get(3)?,
                protocol: row.get(4)?,
                source: row.get(5)?,
                destination: row.get(6)?,
                port: row.get(7)?,
                enabled: row.get(8)?,
                created_at: row.get(9)?,
            })
        })?;
        let mut rules = Vec::new();
        for row in rows {
            rules.push(row?);
        }
        Ok(rules)
    }
}

#[dbus_interface(name = "org.arynox.Security")]
impl SecurityDaemon {
    async fn check_permission(&self, app_id: String, permission: String) -> String {
        match self.check_permission_inner(&app_id, &permission) {
            Ok(granted) => serde_json::json!({"success": true, "granted": granted}).to_string(),
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn request_permission(&self, app_id: String, app_name: String, permission: String) -> String {
        match self.request_permission_inner(&app_id, &app_name, &permission) {
            Ok(granted) => serde_json::json!({"success": true, "granted": granted}).to_string(),
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn revoke_permission(&self, app_id: String, permission: String) -> String {
        match self.revoke_permission_inner(&app_id, &permission) {
            Ok(_) => serde_json::json!({"success": true}).to_string(),
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn get_permissions(&self, app_id: String) -> String {
        match self.get_permissions_inner(&app_id) {
            Ok(perms) => serde_json::json!({"success": true, "permissions": perms}).to_string(),
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn store_credential(&self, service: String, username: String, password: String, notes: String) -> String {
        match self.store_credential_inner(&service, &username, &password, &notes) {
            Ok(id) => serde_json::json!({"success": true, "credential_id": id}).to_string(),
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn get_credential(&self, credential_id: String) -> String {
        match self.get_credential_inner(&credential_id) {
            Ok(cred) => serde_json::json!({"success": true, "credential": cred}).to_string(),
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn delete_credential(&self, credential_id: String) -> String {
        match self.delete_credential_inner(&credential_id) {
            Ok(_) => serde_json::json!({"success": true}).to_string(),
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn get_firewall_rules(&self) -> String {
        match self.get_firewall_rules_inner() {
            Ok(rules) => serde_json::json!({"success": true, "rules": rules}).to_string(),
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn get_security_status(&self) -> String {
        serde_json::json!({
            "success": true,
            "note": "Real encryption requires the ring crate. Current implementation uses base64 encoding.",
            "permissions_count": self.db.lock().map(|d| d.query_row("SELECT COUNT(*) FROM permissions", [], |r| r.get::<_, i64>(0)).unwrap_or(0)).unwrap_or(0)
        }).to_string()
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter("arynox_security=info")
        .init();

    info!("Starting Arynox Security Framework Daemon");
    let daemon = SecurityDaemon::new()?;

    let _conn = ConnectionBuilder::session()?
        .name("org.arynox.Security")?
        .serve_at("/org/arynox/Security", daemon)?
        .build()
        .await?;

    info!("Security daemon ready on org.arynox.Security");

    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
    }
}
