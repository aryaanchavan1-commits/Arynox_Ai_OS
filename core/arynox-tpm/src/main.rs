use anyhow::{Context, Result};
use std::path::Path;

const TPM_KEY_DIR: &str = "/etc/arynox/tpm";

fn main() -> Result<()> {
    tracing_subscriber::fmt::init();

    let key_dir = Path::new(TPM_KEY_DIR);
    if !key_dir.exists() {
        tracing::info!("No TPM key directory found at {}", TPM_KEY_DIR);
        return Ok(());
    }

    for entry in std::fs::read_dir(key_dir).context("Failed to read TPM key directory")? {
        let entry = entry?;
        let path = entry.path();
        if path.is_file() {
            match std::fs::read_to_string(&path) {
                Ok(contents) => {
                    tracing::info!("TPM key {}: {}", path.display(), contents.trim());
                }
                Err(e) => {
                    tracing::error!("Failed to read {}: {}", path.display(), e);
                }
            }
        }
    }

    Ok(())
}
