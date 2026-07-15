// Utility functions for the compositor

pub fn format_uptime(seconds: f64) -> String {
    let total = seconds as u64;
    let hours = total / 3600;
    let minutes = (total % 3600) / 60;
    let secs = total % 60;
    format!("{:02}:{:02}:{:02}", hours, minutes, secs)
}

pub fn get_config_path() -> std::path::PathBuf {
    std::path::PathBuf::from("/etc/arynox/compositor.toml")
}

pub fn get_session_socket_path() -> std::path::PathBuf {
    std::path::PathBuf::from("/run/user/1000/wayland-1")
}
