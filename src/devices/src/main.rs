use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::Path;
use tokio::sync::RwLock;
use tracing::info;
use zbus::{dbus_interface, ConnectionBuilder};

#[derive(Debug, Clone, Serialize, Deserialize)]
struct DeviceInfo {
    id: String,
    name: String,
    device_type: String,
    vendor: String,
    model: String,
    driver: String,
    status: String,
}

fn scan_blocks() -> Vec<DeviceInfo> {
    let mut devices = Vec::new();
    let block_dir = Path::new("/sys/block");
    if !block_dir.exists() { return devices; }
    if let Ok(entries) = std::fs::read_dir(block_dir) {
        for entry in entries.flatten() {
            let name = entry.file_name().to_string_lossy().to_string();
            devices.push(DeviceInfo {
                id: format!("block-{}", name),
                name: name.clone(),
                device_type: "block".into(),
                vendor: "".into(),
                model: name,
                driver: "kernel".into(),
                status: "connected".into(),
            });
        }
    }
    devices
}

fn scan_classes() -> Vec<DeviceInfo> {
    let mut devices = Vec::new();
    let class_dir = Path::new("/sys/class");
    if !class_dir.exists() { return devices; }
    if let Ok(entries) = std::fs::read_dir(class_dir) {
        for entry in entries.flatten() {
            let class = entry.file_name().to_string_lossy().to_string();
            if let Ok(devs) = std::fs::read_dir(entry.path()) {
                for dev in devs.flatten() {
                    let name = dev.file_name().to_string_lossy().to_string();
                    devices.push(DeviceInfo {
                        id: format!("{}-{}", class, name),
                        name,
                        device_type: class.clone(),
                        vendor: "".into(),
                        model: String::new(),
                        driver: "kernel".into(),
                        status: "connected".into(),
                    });
                }
            }
        }
    }
    devices
}

struct DeviceManager {
    devices: RwLock<HashMap<String, DeviceInfo>>,
}

impl DeviceManager {
    fn new() -> Self {
        let mut map = HashMap::new();
        for d in scan_blocks() { map.insert(d.id.clone(), d); }
        for d in scan_classes() { map.entry(d.id.clone()).or_insert(d); }
        if map.is_empty() {
            map.insert("loop0".into(), DeviceInfo {
                id: "loop0".into(), name: "Loopback Device".into(),
                device_type: "loopback".into(), vendor: "System".into(),
                model: "loop0".into(), driver: "kernel".into(), status: "connected".into(),
            });
        }
        Self { devices: RwLock::new(map) }
    }
}

#[dbus_interface(name = "org.arynox.DeviceManager")]
impl DeviceManager {
    async fn list_devices(&self) -> String {
        let devices = self.devices.read().await;
        let list: Vec<&DeviceInfo> = devices.values().collect();
        serde_json::to_string(&list).unwrap_or_default()
    }

    async fn get_device_info(&self, id: String) -> String {
        let devices = self.devices.read().await;
        match devices.get(&id) {
            Some(info) => serde_json::to_string(info).unwrap_or_default(),
            None => serde_json::json!({"error": "Device not found"}).to_string(),
        }
    }

    async fn refresh_devices(&self) -> String {
        let mut map = HashMap::new();
        for d in scan_blocks() { map.insert(d.id.clone(), d); }
        for d in scan_classes() { map.entry(d.id.clone()).or_insert(d); }
        let count = map.len();
        *self.devices.write().await = map;
        serde_json::json!({"success": true, "count": count}).to_string()
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt().init();
    info!("Device Manager started");

    let manager = DeviceManager::new();
    let _conn = ConnectionBuilder::session()?
        .name("org.arynox.DeviceManager")?
        .serve_at("/org/arynox/DeviceManager", manager)?
        .build()
        .await?;

    info!("Device Manager ready on org.arynox.DeviceManager");
    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
    }
}
