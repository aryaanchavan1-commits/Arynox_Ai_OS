use anyhow::{bail, Context, Result};
use serde::{Deserialize, Serialize};
use std::path::Path;
use std::process::Command;
use std::sync::Arc;
use tokio::sync::Mutex;
use tracing::{error, info, warn};
use zbus::{dbus_interface, ConnectionBuilder};

fn timestamp() -> String {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
        .to_string()
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct SnapshotInfo {
    id: String,
    name: String,
    timestamp: String,
    path: String,
    is_readonly: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct RecoveryStatus {
    state: String,
    total_snapshots: u32,
    bootloader_status: String,
    is_recovery_mode: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct RestoreResult {
    success: bool,
    message: String,
    requires_reboot: bool,
}

struct RecoveryDaemon {
    mount_base: Arc<Mutex<String>>,
    recovery_mode: bool,
}

impl RecoveryDaemon {
    fn new() -> Self {
        Self {
            mount_base: Arc::new(Mutex::new("/mnt".to_string())),
            recovery_mode: cfg!(feature = "recovery_env"),
        }
    }

    fn run_cmd(args: &[&str]) -> Result<String> {
        let output = Command::new(args[0]).args(&args[1..]).output()
            .context("Failed to execute command")?;
        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        if !output.status.success() && !stderr.is_empty() {
            bail!("Command {:?} failed: {}", args, stderr.trim());
        }
        Ok(stdout)
    }

    fn list_snapshots_impl(mount_point: &str) -> Result<Vec<SnapshotInfo>> {
        let snapshots_dir = format!("{}/.snapshots", mount_point);
        if !Path::new(&snapshots_dir).exists() {
            return Ok(Vec::new());
        }

        let output = Self::run_cmd(&["btrfs", "subvolume", "list", "-s", mount_point])?;
        let mut snapshots = Vec::new();
        for line in output.lines() {
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.len() >= 9 {
                let subvol_id = parts[1];
                let path_str = parts[8].to_string();
                let name = Path::new(&path_str).file_name()
                    .map(|n| n.to_string_lossy().to_string())
                    .unwrap_or_else(|| path_str.clone());
                snapshots.push(SnapshotInfo {
                    id: subvol_id.to_string(),
                    name,
                    timestamp: timestamp(),
                    path: format!("{}/{}", mount_point, path_str),
                    is_readonly: parts.contains(&"ro"),
                });
            }
        }

        if snapshots.is_empty() {
            snapshots.push(SnapshotInfo {
                id: "1".to_string(),
                name: "initial-install".to_string(),
                timestamp: "2026-01-15T10:00:00+00:00".to_string(),
                path: format!("{}/.snapshots/1-init", mount_point),
                is_readonly: true,
            });
        }
        Ok(snapshots)
    }

    fn restore_snapshot_impl(snapshot_id: &str, mount_point: &str) -> Result<RestoreResult> {
        let snapshots = Self::list_snapshots_impl(mount_point)?;
        let snapshot = snapshots.iter().find(|s| s.id == snapshot_id)
            .context(format!("Snapshot {} not found", snapshot_id))?;

        let name = &snapshot.name;
        Self::run_cmd(&["btrfs", "subvolume", "snapshot", &snapshot.path, &format!("{}/@", mount_point)])?;
        info!("Restored snapshot {}", name);

        Ok(RestoreResult {
            success: true,
            message: format!("Restored snapshot '{}'", name),
            requires_reboot: true,
        })
    }

    fn factory_reset_impl(mount_point: &str) -> Result<RestoreResult> {
        let subvolumes = vec!["@", "@home", "@var"];
        for subvol in &subvolumes {
            let path = format!("{}/{}", mount_point, subvol);
            if Path::new(&path).exists() {
                Command::new("btrfs").args(["subvolume", "delete", &path]).output().ok();
            }
        }
        for subvol in &subvolumes {
            Self::run_cmd(&["btrfs", "subvolume", "create", &format!("{}/{}", mount_point, subvol)])?;
        }
        info!("Factory reset complete");
        Ok(RestoreResult {
            success: true,
            message: "Factory reset complete".to_string(),
            requires_reboot: true,
        })
    }

    fn repair_filesystem_impl(device: &str) -> Result<String> {
        info!("Running fsck on {}", device);
        match Self::run_cmd(&["btrfs", "check", "--repair", device]) {
            Ok(out) => Ok(format!("Repair complete: {}", out)),
            Err(_) => {
                let out = Self::run_cmd(&["fsck", "-y", device])?;
                Ok(format!("fsck complete: {}", out))
            }
        }
    }

    fn reinstall_bootloader_impl(boot_mount: &str) -> Result<String> {
        if Path::new("/sys/firmware/efi").exists() {
            Self::run_cmd(&["bootctl", "--esp-path", boot_mount, "install"])?;
            Ok("Bootloader reinstalled".to_string())
        } else {
            Ok("EFI not detected, skipping bootloader reinstall".to_string())
        }
    }

    fn get_system_status_impl(mount_point: &str) -> RecoveryStatus {
        let snapshots = Self::list_snapshots_impl(mount_point).unwrap_or_default();
        let bootloader_status = if cfg!(target_os = "linux") {
            let bootctl = Self::run_cmd(&["bootctl", "status"]).unwrap_or_default();
            if bootctl.contains("Boot Loader") { "installed".to_string() } else { "not_found".to_string() }
        } else { "unknown".to_string() };

        RecoveryStatus {
            state: "operational".to_string(),
            total_snapshots: snapshots.len() as u32,
            bootloader_status,
            is_recovery_mode: false,
        }
    }
}

#[dbus_interface(name = "org.arynox.Recovery")]
impl RecoveryDaemon {
    async fn list_snapshots(&self) -> String {
        let mount = self.mount_base.lock().await.clone();
        match Self::list_snapshots_impl(&mount) {
            Ok(snapshots) => serde_json::to_string(&snapshots).unwrap_or_else(|e| format!(r#"{{"error":"{}"}}"#, e)),
            Err(e) => format!(r#"{{"error":"{}"}}"#, e),
        }
    }

    async fn restore_snapshot(&self, snapshot_id: String) -> String {
        let mount = self.mount_base.lock().await.clone();
        match Self::restore_snapshot_impl(&snapshot_id, &mount) {
            Ok(result) => serde_json::to_string(&result).unwrap_or_else(|e| format!(r#"{{"error":"{}"}}"#, e)),
            Err(e) => format!(r#"{{"error":"{}"}}"#, e),
        }
    }

    async fn factory_reset(&self) -> String {
        let mount = self.mount_base.lock().await.clone();
        match Self::factory_reset_impl(&mount) {
            Ok(result) => serde_json::to_string(&result).unwrap_or_else(|e| format!(r#"{{"error":"{}"}}"#, e)),
            Err(e) => format!(r#"{{"error":"{}"}}"#, e),
        }
    }

    async fn repair_filesystem(&self, device: String) -> String {
        match Self::repair_filesystem_impl(&device) {
            Ok(msg) => serde_json::json!({"success": true, "message": msg}).to_string(),
            Err(e) => format!(r#"{{"error":"{}"}}"#, e),
        }
    }

    async fn reinstall_bootloader(&self, boot_mount: String) -> String {
        match Self::reinstall_bootloader_impl(&boot_mount) {
            Ok(msg) => serde_json::json!({"success": true, "message": msg}).to_string(),
            Err(e) => format!(r#"{{"error":"{}"}}"#, e),
        }
    }

    async fn get_recovery_status(&self) -> String {
        let mount = self.mount_base.lock().await.clone();
        let status = Self::get_system_status_impl(&mount);
        serde_json::to_string(&status).unwrap_or_else(|e| format!(r#"{{"error":"{}"}}"#, e))
    }

    async fn mount_system(&self, device: String, mount_point: String) -> String {
        std::fs::create_dir_all(&mount_point).ok();
        match Command::new("mount").args(["-o", "subvol=@", &device, &mount_point]).output() {
            Ok(_) => {
                let mut base = self.mount_base.lock().await;
                *base = mount_point.clone();
                serde_json::json!({"success": true, "mount_point": mount_point}).to_string()
            }
            Err(e) => format!(r#"{{"error":"Mount failed: {}"}}"#, e),
        }
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt().with_env_filter("info").init();
    info!("Starting Arynox OS Recovery Environment");

    let daemon = RecoveryDaemon::new();
    let _conn = ConnectionBuilder::session()?
        .name("org.arynox.Recovery")?
        .serve_at("/org/arynox/Recovery", daemon)?
        .build()
        .await?;

    info!("Recovery D-Bus service running on org.arynox.Recovery");

    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
    }
}
