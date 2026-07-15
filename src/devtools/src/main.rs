use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::process::Command as SysCommand;
use tokio::sync::RwLock;
use tracing::{error, info, warn};
use zbus::{dbus_interface, ConnectionBuilder};

#[derive(Debug, Serialize, Deserialize, Clone)]
struct DevToolsState {
    dev_mode: bool,
    ssh_running: bool,
    ssh_port: u16,
}

impl Default for DevToolsState {
    fn default() -> Self {
        Self { dev_mode: false, ssh_running: false, ssh_port: 22 }
    }
}

#[derive(Debug, Serialize, Deserialize)]
struct DevToolsResponse {
    success: bool,
    data: serde_json::Value,
    error: Option<String>,
}

struct DevToolsDaemon {
    state: RwLock<DevToolsState>,
}

impl DevToolsDaemon {
    fn new() -> Self {
        Self { state: RwLock::new(DevToolsState::default()) }
    }

    fn run_cmd(program: &str, args: &[&str]) -> Result<String> {
        let output = SysCommand::new(program).args(args).output()
            .with_context(|| format!("failed to execute {} {:?}", program, args))?;
        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        if !output.status.success() {
            anyhow::bail!("{} failed: stderr={}", program, stderr);
        }
        Ok(stdout)
    }

    fn git_command_impl(args: &[String]) -> Result<String> {
        let str_args: Vec<&str> = args.iter().map(|s| s.as_str()).collect();
        Self::run_cmd("git", &str_args)
    }

    fn docker_ps_impl() -> Result<String> {
        Self::run_cmd("sh", &["-c", "docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || podman ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || echo ''"])
    }
}

#[dbus_interface(name = "org.arynox.DevTools")]
impl DevToolsDaemon {
    async fn enable_dev_mode(&self) -> String {
        match Self::run_cmd("sh", &["-c", "touch /etc/arynox/devmode && systemctl enable sshd && systemctl start sshd"]) {
            Ok(_) => {
                self.state.write().await.dev_mode = true;
                serde_json::json!({"success": true, "dev_mode": true}).to_string()
            }
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn disable_dev_mode(&self) -> String {
        match Self::run_cmd("sh", &["-c", "rm -f /etc/arynox/devmode && systemctl stop sshd && systemctl disable sshd"]) {
            Ok(_) => {
                self.state.write().await.dev_mode = false;
                serde_json::json!({"success": true, "dev_mode": false}).to_string()
            }
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn git_command(&self, args: Vec<String>) -> String {
        match Self::git_command_impl(&args) {
            Ok(output) => serde_json::json!({"success": true, "output": output}).to_string(),
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn docker_ps(&self) -> String {
        match Self::docker_ps_impl() {
            Ok(output) => serde_json::json!({"success": true, "output": output}).to_string(),
            Err(e) => serde_json::json!({"success": false, "error": e.to_string()}).to_string(),
        }
    }

    async fn get_system_info(&self) -> String {
        let cpu = Self::run_cmd("sh", &["-c", "cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d: -f2 | xargs"]).unwrap_or_default();
        let mem = Self::run_cmd("sh", &["-c", "free -h | grep Mem | awk '{print $3 \"/\" $2}'"]).unwrap_or_default();
        serde_json::json!({"success": true, "cpu": cpu.trim(), "memory": mem.trim()}).to_string()
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt().with_env_filter("info").init();
    info!("Arynox DevTools daemon starting");

    let daemon = DevToolsDaemon::new();
    let _conn = ConnectionBuilder::session()?
        .name("org.arynox.DevTools")?
        .serve_at("/org/arynox/DevTools", daemon)?
        .build()
        .await?;

    info!("DevTools D-Bus interface registered at org.arynox.DevTools");

    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
    }
}
