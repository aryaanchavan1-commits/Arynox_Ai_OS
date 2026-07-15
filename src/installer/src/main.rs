use anyhow::{bail, Context, Result};
use serde::{Deserialize, Serialize};
use std::path::Path;
use std::process::Command;
use std::sync::Arc;
use tokio::sync::Mutex;
use tracing::{error, info, warn};
use zbus::{dbus_interface, ConnectionBuilder};

fn simple_id() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let ts = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_nanos();
    format!("{:x}", ts)
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct DiskInfo {
    path: String,
    model: String,
    size: u64,
    is_ssd: bool,
    is_nvme: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PartitionInfo {
    path: String,
    size: u64,
    fs_type: String,
    mount_point: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct InstallProgress {
    stage: String,
    percentage: u8,
    message: String,
    is_error: bool,
    error_message: Option<String>,
    completed: bool,
}

struct InstallerBackend {
    progress: Arc<Mutex<InstallProgress>>,
}

impl InstallerBackend {
    fn new() -> Self {
        Self {
            progress: Arc::new(Mutex::new(InstallProgress {
                stage: "idle".to_string(),
                percentage: 0,
                message: "Waiting".to_string(),
                is_error: false,
                error_message: None,
                completed: false,
            })),
        }
    }

    fn run_cmd(args: &[&str]) -> Result<String> {
        let output = Command::new(args[0]).args(&args[1..]).output()
            .context("Failed to execute command")?;
        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        if !output.status.success() {
            bail!("Command {:?} failed: {}", args, stderr.trim());
        }
        Ok(stdout)
    }

    fn detect_disks() -> Result<Vec<DiskInfo>> {
        if !cfg!(target_os = "linux") {
            return Ok(vec![
                DiskInfo { path: "/dev/sda".into(), model: "Virtual Disk".into(), size: 107374182400, is_ssd: true, is_nvme: false },
            ]);
        }
        let output = Self::run_cmd(&["lsblk", "-o", "NAME,MODEL,SIZE,TYPE,ROTA", "-J", "-b"])?;
        let parsed: serde_json::Value = serde_json::from_str(&output)?;
        let mut disks = Vec::new();
        if let Some(blockdevices) = parsed["blockdevices"].as_array() {
            for device in blockdevices {
                if device["type"] == "disk" {
                    let name = device["name"].as_str().unwrap_or("unknown");
                    let model = device["model"].as_str().unwrap_or("Unknown").trim().to_string();
                    let size = device["size"].as_str().unwrap_or("0").parse().unwrap_or(0);
                    let is_ssd = device["rota"].as_str() == Some("0");
                    disks.push(DiskInfo {
                        path: format!("/dev/{}", name),
                        model,
                        size,
                        is_ssd,
                        is_nvme: name.contains("nvme"),
                    });
                }
            }
        }
        Ok(disks)
    }

    fn detect_partitions() -> Result<Vec<PartitionInfo>> {
        if !cfg!(target_os = "linux") {
            return Ok(vec![
                PartitionInfo { path: "/dev/sda1".into(), size: 1073741824, fs_type: "vfat".into(), mount_point: Some("/boot".into()) },
                PartitionInfo { path: "/dev/sda2".into(), size: 10737418240, fs_type: "btrfs".into(), mount_point: None },
            ]);
        }
        let output = Self::run_cmd(&["lsblk", "-o", "NAME,SIZE,FSTYPE,MOUNTPOINT,TYPE", "-J", "-b"])?;
        let parsed: serde_json::Value = serde_json::from_str(&output)?;
        let mut parts = Vec::new();
        if let Some(blockdevices) = parsed["blockdevices"].as_array() {
            for device in blockdevices {
                if let Some(children) = device["children"].as_array() {
                    for child in children {
                        if child["type"] == "part" {
                            let name = child["name"].as_str().unwrap_or("");
                            parts.push(PartitionInfo {
                                path: format!("/dev/{}", name),
                                size: child["size"].as_str().unwrap_or("0").parse().unwrap_or(0),
                                fs_type: child["fstype"].as_str().unwrap_or("").to_string(),
                                mount_point: child["mountpoint"].as_str().map(|s| s.to_string()),
                            });
                        }
                    }
                }
            }
        }
        Ok(parts)
    }

    fn install_base_system(squashfs_path: &str, target: &str) -> Result<()> {
        std::fs::create_dir_all(target)?;
        let output = Command::new("unsquashfs")
            .args(["-f", "-d", target, "-i", squashfs_path])
            .output()
            .context("Failed to extract squashfs image")?;
        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            bail!("unsquashfs failed: {}", stderr.trim());
        }
        info!("Base system installed from {}", squashfs_path);
        Ok(())
    }

    fn install_bootloader(esp_mount: &str) -> Result<()> {
        if Path::new("/sys/firmware/efi").exists() {
            Self::run_cmd(&["bootctl", "--esp-path", esp_mount, "install"])?;
        }
        Ok(())
    }
}

#[dbus_interface(name = "org.arynox.Installer")]
impl InstallerBackend {
    async fn list_disks(&self) -> String {
        match Self::detect_disks() {
            Ok(disks) => serde_json::to_string(&disks).unwrap_or_else(|e| format!(r#"{{"error":"{}"}}"#, e)),
            Err(e) => format!(r#"{{"error":"{}"}}"#, e),
        }
    }

    async fn list_partitions(&self) -> String {
        match Self::detect_partitions() {
            Ok(parts) => serde_json::to_string(&parts).unwrap_or_else(|e| format!(r#"{{"error":"{}"}}"#, e)),
            Err(e) => format!(r#"{{"error":"{}"}}"#, e),
        }
    }

    async fn install_system(&self, squashfs_path: String, target: String, esp_mount: String) -> String {
        if let Err(e) = Self::install_base_system(&squashfs_path, &target) {
            return format!(r#"{{"error":"Base install failed: {}"}}"#, e);
        }
        if let Err(e) = Self::install_bootloader(&esp_mount) {
            return format!(r#"{{"error":"Bootloader install failed: {}"}}"#, e);
        }
        serde_json::json!({"status": "success", "message": "Arynox OS installed successfully"}).to_string()
    }

    async fn get_install_progress(&self) -> String {
        let progress = self.progress.lock().await;
        serde_json::to_string(&*progress).unwrap_or_default()
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt().with_env_filter("info").init();
    info!("Starting Arynox OS Installer Backend");

    let backend = InstallerBackend::new();
    let _conn = ConnectionBuilder::session()?
        .name("org.arynox.Installer")?
        .serve_at("/org/arynox/Installer", backend)?
        .build()
        .await?;

    info!("Installer D-Bus service running on org.arynox.Installer");

    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
    }
}
