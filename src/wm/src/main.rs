use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::sync::Mutex;
use tracing::info;
use zbus::{dbus_interface, ConnectionBuilder};

#[derive(Debug, Clone, Serialize, Deserialize)]
struct WindowInfo {
    id: u64,
    title: String,
    app_id: String,
    workspace: u32,
    x: i32, y: i32, w: u32, h: u32,
    minimized: bool,
    maximized: bool,
    focused: bool,
}

struct CompositorState {
    windows: Vec<WindowInfo>,
    workspaces: Vec<String>,
    active_workspace: u32,
    next_id: u64,
}

impl CompositorState {
    fn new() -> Self {
        Self {
            windows: vec![],
            workspaces: (1..=4).map(|i| format!("Workspace {}", i)).collect(),
            active_workspace: 1,
            next_id: 1,
        }
    }
}

struct Compositor {
    state: Mutex<CompositorState>,
}

#[dbus_interface(name = "org.arynox.Compositor")]
impl Compositor {
    async fn list_windows(&self) -> String {
        let s = self.state.lock().unwrap();
        serde_json::to_string(&s.windows).unwrap_or_default()
    }

    async fn open_window(&self, title: String, app_id: String) -> String {
        let mut s = self.state.lock().unwrap();
        let id = s.next_id;
        s.next_id += 1;
        let ws = s.active_workspace;
        s.windows.push(WindowInfo {
            id, title, app_id,
            workspace: ws,
            x: 100, y: 100, w: 800, h: 600,
            minimized: false, maximized: false, focused: true,
        });
        serde_json::json!({"id": id}).to_string()
    }

    async fn close_window(&self, id: u64) -> String {
        let mut s = self.state.lock().unwrap();
        s.windows.retain(|w| w.id != id);
        "ok".to_string()
    }

    async fn focus_window(&self, id: u64) -> String {
        let mut s = self.state.lock().unwrap();
        for w in s.windows.iter_mut() {
            w.focused = w.id == id;
        }
        "ok".to_string()
    }

    async fn switch_workspace(&self, workspace: u32) -> String {
        let mut s = self.state.lock().unwrap();
        if workspace > 0 && workspace <= s.workspaces.len() as u32 {
            s.active_workspace = workspace;
        }
        "ok".to_string()
    }

    async fn get_workspaces(&self) -> String {
        let s = self.state.lock().unwrap();
        serde_json::json!({
            "workspaces": s.workspaces,
            "active": s.active_workspace,
        }).to_string()
    }

    async fn minimize_window(&self, id: u64) -> String {
        let mut s = self.state.lock().unwrap();
        if let Some(w) = s.windows.iter_mut().find(|w| w.id == id) {
            w.minimized = true;
        }
        "ok".to_string()
    }

    async fn maximize_window(&self, id: u64) -> String {
        let mut s = self.state.lock().unwrap();
        if let Some(w) = s.windows.iter_mut().find(|w| w.id == id) {
            w.maximized = !w.maximized;
        }
        "ok".to_string()
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt().with_env_filter("info").init();
    info!("Arynox Compositor daemon starting");

    let compositor = Compositor { state: Mutex::new(CompositorState::new()) };
    let _conn = ConnectionBuilder::session()?
        .name("org.arynox.Compositor")?
        .serve_at("/org/arynox/Compositor", compositor)?
        .build()
        .await?;

    info!("Compositor ready on org.arynox.Compositor");
    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
    }
}
