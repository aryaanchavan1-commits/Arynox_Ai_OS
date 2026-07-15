use anyhow::{Context, Result};
use std::process::Command;
use std::time::{Duration, Instant};
use systemstat::{Platform, System};
use tokio::time;

const BOOT_TIMEOUT_SECS: u64 = 30;
const BOOT_TARGET_SECS: u64 = 10;

#[derive(Debug, serde::Serialize)]
struct BootMetrics {
    boot_time_secs: f64,
    target_met: bool,
    services_healthy: Vec<String>,
    hardware_ok: bool,
    gpu_accelerated: bool,
}

fn check_services() -> Vec<String> {
    let mut healthy = Vec::new();
    let services = [
        "systemd",
        "network-manager",
        "bluetooth",
        "pipewire",
    ];
    for svc in &services {
        let status = Command::new("systemctl")
            .args(["is-active", svc])
            .output();
        if let Ok(out) = status {
            if out.stdout.starts_with(b"active") {
                healthy.push(svc.to_string());
            }
        }
    }
    healthy
}

fn check_hardware() -> bool {
    System::new().cpu_load().is_ok()
}

fn check_gpu() -> bool {
    std::fs::read_dir("/dev/dri").is_ok()
}

fn write_metrics(metrics: &BootMetrics) -> Result<()> {
    let json = serde_json::to_string_pretty(metrics)?;
    std::fs::create_dir_all("/run/arynox")?;
    std::fs::write("/run/arynox/boot-metrics.json", &json)?;
    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();

    let start = Instant::now();
    time::sleep(Duration::from_secs(2)).await;

    let services = check_services();
    let hardware_ok = check_hardware();
    let gpu_ok = check_gpu();
    let elapsed = start.elapsed().as_secs_f64();

    let metrics = BootMetrics {
        boot_time_secs: elapsed,
        target_met: elapsed <= BOOT_TARGET_SECS as f64,
        services_healthy: services,
        hardware_ok,
        gpu_accelerated: gpu_ok,
    };

    write_metrics(&metrics)?;

    tracing::info!("Boot completed in {:.2}s (target: {}s)", elapsed, BOOT_TARGET_SECS);

    if elapsed > BOOT_TIMEOUT_SECS as f64 {
        tracing::warn!("Boot exceeded timeout");
    }

    Ok(())
}
