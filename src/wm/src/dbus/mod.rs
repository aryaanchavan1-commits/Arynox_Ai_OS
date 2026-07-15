use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct CompositorDbus {
    pub connected: bool,
}

impl CompositorDbus {
    pub fn new() -> Self {
        CompositorDbus { connected: false }
    }

    pub fn connect(&mut self) {
        self.connected = true;
    }

    pub fn disconnect(&mut self) {
        self.connected = false;
    }

    pub fn is_connected(&self) -> bool {
        self.connected
    }
}
