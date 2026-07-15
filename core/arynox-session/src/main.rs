use anyhow::{Context, Result};
use std::process::Command;
use tokio::signal;
use tracing::{error, info};
struct SessionDaemon;

impl SessionDaemon {
    async fn launch_compositor() -> Result<()> {
        let status = Command::new("/usr/lib/arynox/arynox-compositor")
            .spawn()
            .context("Failed to launch compositor")?
            .wait()?;
        if !status.success() {
            error!("Compositor exited with error: {:?}", status);
        }
        Ok(())
    }

    async fn launch_desktop_shell() -> Result<()> {
        let status = Command::new("/usr/lib/arynox/arynox-desktop-shell")
            .spawn()
            .context("Failed to launch desktop shell")?
            .wait()?;
        if !status.success() {
            error!("Desktop shell exited with error: {:?}", status);
        }
        Ok(())
    }

    async fn launch_ai_runtime() -> Result<()> {
        let status = Command::new("/usr/lib/arynox/arynox-ai-runtime")
            .spawn()
            .context("Failed to launch AI runtime")?
            .wait()?;
        if !status.success() {
            error!("AI runtime exited with error: {:?}", status);
        }
        Ok(())
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    info!("Arynox Session Manager starting");

    tokio::spawn(async {
        if let Err(e) = SessionDaemon::launch_compositor().await {
            error!("Compositor error: {}", e);
        }
    });
    tokio::spawn(async {
        if let Err(e) = SessionDaemon::launch_desktop_shell().await {
            error!("Desktop shell error: {}", e);
        }
    });
    tokio::spawn(async {
        if let Err(e) = SessionDaemon::launch_ai_runtime().await {
            error!("AI runtime error: {}", e);
        }
    });

    // Signal systemd readiness
    if let Ok(notify_socket) = std::env::var("NOTIFY_SOCKET") {
        let _ = std::fs::write(&notify_socket, b"READY=1");
    }

    info!("Arynox Session Manager ready");

    signal::ctrl_c().await.ok();
    info!("Shutting down Arynox Session Manager");
    Ok(())
}
