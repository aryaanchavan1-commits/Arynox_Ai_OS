use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::net::IpAddr;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::info;
use zbus::{dbus_interface, ConnectionBuilder};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WiFiNetwork {
    pub ssid: String,
    pub bssid: String,
    pub frequency: u32,
    pub signal_strength: i32,
    pub security: String,
    pub saved: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BluetoothDevice {
    pub address: String,
    pub name: String,
    pub paired: bool,
    pub connected: bool,
    pub tethering_enabled: bool,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct EthernetConfig {
    pub interface: String,
    pub mac: String,
    pub ipv4: Option<String>,
    pub ipv6: Option<String>,
    pub gateway: Option<String>,
    pub dns: Vec<String>,
    pub link_up: bool,
    pub speed_mbps: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VPNConnection {
    pub uuid: String,
    pub name: String,
    pub vpn_type: String,
    pub state: String,
    pub autoconnect: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DiscoveredDevice {
    pub ip: IpAddr,
    pub mac: String,
    pub hostname: String,
    pub device_type: String,
    pub os_hint: String,
    pub open_ports: Vec<u16>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FirewallRule {
    pub chain: String,
    pub protocol: String,
    pub src: String,
    pub dst: String,
    pub port: u16,
    pub action: String,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct FirewallStatus {
    pub enabled: bool,
    pub rules: Vec<FirewallRule>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ProxyConfig {
    pub http_proxy: Option<String>,
    pub https_proxy: Option<String>,
    pub ftp_proxy: Option<String>,
    pub no_proxy: Vec<String>,
    pub socks_proxy: Option<String>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct SSHConfig {
    pub enabled: bool,
    pub port: u16,
    pub password_auth: bool,
    pub pubkey_auth: bool,
    pub running: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SMBShare {
    pub name: String,
    pub path: String,
    pub guest_access: bool,
    pub available: bool,
}

#[derive(Default)]
pub struct NetworkState {
    wifi_networks: Vec<WiFiNetwork>,
    saved_networks: Vec<WiFiNetwork>,
    bluetooth_devices: Vec<BluetoothDevice>,
    ethernet: EthernetConfig,
    vpn_connections: Vec<VPNConnection>,
    discovered_devices: Vec<DiscoveredDevice>,
    firewall: FirewallStatus,
    proxy: ProxyConfig,
    ssh: SSHConfig,
    smb_shares: Vec<SMBShare>,
}

fn uuid() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let ts = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_nanos();
    format!("{:016x}-{:04x}-{:04x}-{:04x}-{:012x}",
        (ts >> 48) as u64,
        ((ts >> 32) & 0xFFFF) as u16,
        ((ts >> 16) & 0xFFFF) as u16,
        (ts & 0xFFFF) as u16,
        ts as u64 & 0xFFFFFFFFFFFF)
}

fn ok_response<T: Serialize>(msg: &str, data: &T) -> String {
    let data_val = serde_json::to_value(data).unwrap_or_default();
    serde_json::json!({"success": true, "message": msg, "data": data_val}).to_string()
}

fn ok_simple(msg: &str) -> String {
    serde_json::json!({"success": true, "message": msg}).to_string()
}

fn err_response(code: u32, msg: &str) -> String {
    serde_json::json!({"success": false, "code": code, "message": msg}).to_string()
}

pub struct NetworkManagerDaemon {
    state: Arc<RwLock<NetworkState>>,
}

impl NetworkManagerDaemon {
    pub fn new() -> Self {
        Self { state: Arc::new(RwLock::new(NetworkState::default())) }
    }
}

#[dbus_interface(name = "org.arynox.NetworkManager")]
impl NetworkManagerDaemon {
    async fn scan_wifi(&self) -> String {
        let mut state = self.state.write().await;
        state.wifi_networks = vec![
            WiFiNetwork { ssid: "HomeNet".into(), bssid: "aa:bb:cc:dd:ee:01".into(), frequency: 2437, signal_strength: -45, security: "WPA2".into(), saved: true },
            WiFiNetwork { ssid: "Neighbor5G".into(), bssid: "aa:bb:cc:dd:ee:02".into(), frequency: 5180, signal_strength: -67, security: "WPA3".into(), saved: false },
            WiFiNetwork { ssid: "Office-Guest".into(), bssid: "aa:bb:cc:dd:ee:03".into(), frequency: 2412, signal_strength: -72, security: "Open".into(), saved: false },
        ];
        ok_response("WiFi scan complete", &state.wifi_networks)
    }

    async fn get_wifi_networks(&self) -> String {
        let state = self.state.read().await;
        ok_response("WiFi networks", &state.wifi_networks)
    }

    async fn connect_wifi(&self, ssid: String, password: String) -> String {
        info!("connect_wifi: SSID={}", ssid);
        if ssid.is_empty() { return err_response(400, "SSID cannot be empty"); }
        ok_simple(&format!("Connecting to '{}'", ssid))
    }

    async fn forget_wifi(&self, ssid: String) -> String {
        let mut state = self.state.write().await;
        state.saved_networks.retain(|n| n.ssid != ssid);
        state.wifi_networks.iter_mut().for_each(|n| { if n.ssid == ssid { n.saved = false; } });
        ok_simple(&format!("Forgot '{}'", ssid))
    }

    async fn get_saved_networks(&self) -> String {
        let state = self.state.read().await;
        ok_response("Saved networks", &state.saved_networks)
    }

    async fn scan_bluetooth(&self) -> String {
        let mut state = self.state.write().await;
        state.bluetooth_devices = vec![
            BluetoothDevice { address: "12:34:56:78:90:AB".into(), name: "Pixel Buds".into(), paired: true, connected: false, tethering_enabled: false },
            BluetoothDevice { address: "12:34:56:78:90:CD".into(), name: "Galaxy S24".into(), paired: true, connected: true, tethering_enabled: true },
        ];
        ok_response("Bluetooth scan complete", &state.bluetooth_devices)
    }

    async fn get_bluetooth_devices(&self) -> String {
        let state = self.state.read().await;
        ok_response("Bluetooth devices", &state.bluetooth_devices)
    }

    async fn get_ethernet_status(&self) -> String {
        let state = self.state.read().await;
        ok_response("Ethernet status", &state.ethernet)
    }

    async fn get_vpn_connections(&self) -> String {
        let state = self.state.read().await;
        ok_response("VPN connections", &state.vpn_connections)
    }

    async fn add_vpn(&self, name: String, vpn_type: String) -> String {
        let mut state = self.state.write().await;
        state.vpn_connections.push(VPNConnection {
            uuid: uuid(), name, vpn_type, state: "disconnected".into(), autoconnect: false,
        });
        ok_simple("VPN added")
    }

    async fn remove_vpn(&self, uuid: String) -> String {
        let mut state = self.state.write().await;
        state.vpn_connections.retain(|v| v.uuid != uuid);
        ok_simple("VPN removed")
    }

    async fn get_ssh_config(&self) -> String {
        let state = self.state.read().await;
        ok_response("SSH config", &state.ssh)
    }

    async fn set_ssh_config(&self, enabled: bool, port: u16, password_auth: bool, pubkey_auth: bool) -> String {
        let mut state = self.state.write().await;
        state.ssh = SSHConfig { enabled, port, password_auth, pubkey_auth, running: enabled };
        ok_simple("SSH config updated")
    }

    async fn get_firewall_status(&self) -> String {
        let state = self.state.read().await;
        ok_response("Firewall status", &state.firewall)
    }

    async fn set_firewall_enabled(&self, enabled: bool) -> String {
        let mut state = self.state.write().await;
        state.firewall.enabled = enabled;
        ok_simple(if enabled { "Firewall enabled" } else { "Firewall disabled" })
    }

    async fn add_firewall_rule(&self, chain: String, protocol: String, src: String, dst: String, port: u16, action: String) -> String {
        let mut state = self.state.write().await;
        state.firewall.rules.push(FirewallRule { chain, protocol, src, dst, port, action });
        ok_simple("Firewall rule added")
    }

    async fn get_proxy_config(&self) -> String {
        let state = self.state.read().await;
        ok_response("Proxy config", &state.proxy)
    }

    async fn set_proxy_config(&self, http: String, https: String, ftp: String, no_proxy: Vec<String>, socks: String) -> String {
        let mut state = self.state.write().await;
        state.proxy = ProxyConfig {
            http_proxy: if http.is_empty() { None } else { Some(http) },
            https_proxy: if https.is_empty() { None } else { Some(https) },
            ftp_proxy: if ftp.is_empty() { None } else { Some(ftp) },
            no_proxy,
            socks_proxy: if socks.is_empty() { None } else { Some(socks) },
        };
        ok_simple("Proxy config updated")
    }

    async fn clear_proxy(&self) -> String {
        let mut state = self.state.write().await;
        state.proxy = ProxyConfig { http_proxy: None, https_proxy: None, ftp_proxy: None, no_proxy: vec![], socks_proxy: None };
        ok_simple("Proxy cleared")
    }

    async fn get_smb_shares(&self) -> String {
        let state = self.state.read().await;
        ok_response("SMB shares", &state.smb_shares)
    }

    async fn add_smb_share(&self, name: String, path: String, guest_access: bool) -> String {
        let mut state = self.state.write().await;
        state.smb_shares.push(SMBShare { name, path, guest_access, available: true });
        ok_simple("SMB share added")
    }

    async fn remove_smb_share(&self, name: String) -> String {
        let mut state = self.state.write().await;
        state.smb_shares.retain(|s| s.name != name);
        ok_simple("SMB share removed")
    }

    async fn discover_nearby_devices(&self) -> String {
        let mut state = self.state.write().await;
        state.discovered_devices = vec![
            DiscoveredDevice { ip: "192.168.1.101".parse().unwrap(), mac: "aa:bb:cc:dd:02:01".into(), hostname: "phone-one.local".into(), device_type: "Smartphone".into(), os_hint: "Android 14".into(), open_ports: vec![22, 445] },
            DiscoveredDevice { ip: "192.168.1.102".parse().unwrap(), mac: "aa:bb:cc:dd:02:02".into(), hostname: "tablet.local".into(), device_type: "Tablet".into(), os_hint: "iPadOS 18".into(), open_ports: vec![80, 443] },
        ];
        ok_response("Discovery complete", &state.discovered_devices)
    }

    async fn get_discovered_devices(&self) -> String {
        let state = self.state.read().await;
        ok_response("Discovered devices", &state.discovered_devices)
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt().with_target(false).with_level(true).init();
    info!("Arynox Network Manager daemon starting");

    let daemon = NetworkManagerDaemon::new();

    {
        let mut state = daemon.state.write().await;
        state.ethernet = EthernetConfig {
            interface: "eth0".into(), mac: "00:1a:2b:3c:4d:5e".into(),
            ipv4: Some("192.168.1.42".into()), ipv6: Some("fe80::21a:2bff:fe3c:4d5e".into()),
            gateway: Some("192.168.1.1".into()), dns: vec!["8.8.8.8".into(), "1.1.1.1".into()],
            link_up: true, speed_mbps: 1000,
        };
        state.firewall = FirewallStatus {
            enabled: true,
            rules: vec![FirewallRule { chain: "INPUT".into(), protocol: "tcp".into(), src: "0.0.0.0/0".into(), dst: "0.0.0.0/0".into(), port: 22, action: "ACCEPT".into() }],
        };
        state.vpn_connections = vec![
            VPNConnection { uuid: uuid(), name: "Work VPN".into(), vpn_type: "OpenVPN".into(), state: "disconnected".into(), autoconnect: false },
            VPNConnection { uuid: uuid(), name: "Home WireGuard".into(), vpn_type: "WireGuard".into(), state: "connected".into(), autoconnect: true },
        ];
    }

    let _conn = ConnectionBuilder::session()?
        .name("org.arynox.NetworkManager")?
        .serve_at("/org/arynox/NetworkManager", daemon)?
        .build()
        .await?;

    info!("Arynox Network Manager daemon ready");
    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
    }
}
