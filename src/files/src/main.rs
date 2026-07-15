use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::path::Path;
use tracing::{error, info};
use walkdir::WalkDir;
use zbus::{dbus_interface, ConnectionBuilder};

#[derive(Debug, Serialize, Deserialize)]
struct FileInfo {
    path: String,
    name: String,
    is_dir: bool,
    size: u64,
    modified: String,
}

struct FileManager;

fn get_file_info(path: &Path) -> Result<FileInfo> {
    let metadata = path.metadata()?;
    let name = path.file_name().map(|n| n.to_string_lossy().to_string()).unwrap_or_default();
    let modified = metadata.modified()
        .map(|t| {
            let duration = t.duration_since(std::time::UNIX_EPOCH).unwrap_or_default();
            duration.as_secs().to_string()
        })
        .unwrap_or_default();
    Ok(FileInfo {
        path: path.to_string_lossy().to_string(),
        name,
        is_dir: path.is_dir(),
        size: metadata.len(),
        modified,
    })
}

#[dbus_interface]
impl FileManager {
    fn list_directory(&self, path: &str, show_hidden: bool) -> Vec<String> {
        let p = Path::new(path);
        if !p.is_dir() {
            return vec![];
        }
        let mut entries = vec![];
        let read_dir = match std::fs::read_dir(p) {
            Ok(d) => d,
            Err(e) => { error!("read_dir {}: {}", path, e); return vec![]; }
        };
        for entry in read_dir.flatten() {
            let ep = entry.path();
            if !show_hidden {
                if let Some(name) = ep.file_name() {
                    if name.to_string_lossy().starts_with('.') {
                        continue;
                    }
                }
            }
            if let Ok(info) = get_file_info(&ep) {
                if let Ok(json) = serde_json::to_string(&info) {
                    entries.push(json);
                }
            }
        }
        entries.sort();
        entries
    }

    fn get_info(&self, path: &str) -> String {
        match get_file_info(Path::new(path)) {
            Ok(info) => serde_json::to_string(&info).unwrap_or_default(),
            Err(e) => format!("error: {}", e),
        }
    }

    fn delete(&self, path: &str) -> String {
        let p = Path::new(path);
        if !p.exists() {
            return format!("error: path does not exist: {}", path);
        }
        let result = if p.is_dir() { std::fs::remove_dir_all(p) } else { std::fs::remove_file(p) };
        match result {
            Ok(_) => format!("ok: deleted {}", path),
            Err(e) => format!("error: {}", e),
        }
    }

    fn rename(&self, source: &str, destination: &str) -> String {
        match std::fs::rename(source, destination) {
            Ok(_) => format!("ok: renamed {} -> {}", source, destination),
            Err(e) => format!("error: {}", e),
        }
    }

    fn copy(&self, source: &str, destination: &str) -> String {
        let src = Path::new(source);
        let dst = Path::new(destination);
        let result = if src.is_dir() {
            if let Err(e) = std::fs::create_dir_all(dst) {
                return format!("error: {}", e);
            }
            for entry in std::fs::read_dir(src).unwrap().flatten() {
                let target = dst.join(entry.file_name());
                if let Err(e) = entry.path().is_dir().then(|| std::fs::create_dir_all(&target)).unwrap_or(Ok(())) {
                    return format!("error: {}", e);
                }
                if entry.path().is_file() {
                    if let Err(e) = std::fs::copy(entry.path(), target) {
                        return format!("error: {}", e);
                    }
                }
            }
            Ok(())
        } else {
            std::fs::copy(src, dst).map(|_| ())
        };
        match result {
            Ok(_) => format!("ok: copied {} -> {}", source, destination),
            Err(e) => format!("error: {}", e),
        }
    }

    fn search(&self, path: &str, query: &str, max_results: u32) -> Vec<String> {
        let q = query.to_lowercase();
        let mut results = vec![];
        for entry in WalkDir::new(path).follow_links(false).into_iter().filter_map(|e| e.ok()) {
            if results.len() >= max_results as usize {
                break;
            }
            if entry.file_type().is_dir() { continue; }
            if entry.file_name().to_string_lossy().to_lowercase().contains(&q) {
                if let Ok(info) = get_file_info(entry.path()) {
                    if let Ok(json) = serde_json::to_string(&info) {
                        results.push(json);
                    }
                }
            }
        }
        results
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt().init();

    info!("File Manager daemon starting");

    let _conn = ConnectionBuilder::system()?
        .name("org.arynox.FileManager")?
        .serve_at("/org/arynox/FileManager", FileManager)?
        .build()
        .await?;

    info!("File Manager ready on D-Bus org.arynox.FileManager");
    tokio::signal::ctrl_c().await?;
    info!("File Manager daemon shutting down");
    Ok(())
}
