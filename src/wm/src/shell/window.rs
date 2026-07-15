use smithay::{
    utils::{Logical, Point, Rectangle, Size},
    wayland::shell::xdg::ToplevelSurface,
    reexports::wayland_server::protocol::wl_surface::WlSurface,
};
use std::collections::HashMap;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WindowState {
    Floating,
    Tiling,
    Maximized,
    Fullscreen,
    Minimized,
    SnappedLeft,
    SnappedRight,
    SnappedTopLeft,
    SnappedTopRight,
    SnappedBottomLeft,
    SnappedBottomRight,
}

#[derive(Debug, Clone)]
pub struct Window {
    pub id: u64,
    pub surface: Option<WlSurface>,
    pub toplevel: Option<ToplevelSurface>,
    pub title: String,
    pub app_id: String,
    pub state: WindowState,
    pub geometry: Rectangle<i32, Logical>,
    pub floating_geometry: Rectangle<i32, Logical>,
    pub workspace: usize,
    pub minimized: bool,
    pub mapped: bool,
    pub focus_order: usize,
}

impl Window {
    pub fn new(id: u64, workspace: usize) -> Self {
        Window {
            id,
            surface: None,
            toplevel: None,
            title: String::new(),
            app_id: String::new(),
            state: WindowState::Floating,
            geometry: Rectangle::from_loc_and_size(
                Point::from((100, 100)),
                Size::from((1024, 768)),
            ),
            floating_geometry: Rectangle::from_loc_and_size(
                Point::from((100, 100)),
                Size::from((1024, 768)),
            ),
            workspace,
            minimized: false,
            mapped: false,
            focus_order: 0,
        }
    }

    pub fn toggle_state(&mut self, new_state: WindowState) {
        if self.state == new_state {
            // Toggle back to floating
            self.state = WindowState::Floating;
            self.geometry = self.floating_geometry;
        } else {
            self.state = new_state;
        }
    }
}

pub struct WindowManager {
    pub windows: HashMap<u64, Window>,
    pub active_window: Option<u64>,
    pub next_id: u64,
    pub focus_counter: usize,
}

impl WindowManager {
    pub fn new() -> Self {
        WindowManager {
            windows: HashMap::new(),
            active_window: None,
            next_id: 1,
            focus_counter: 0,
        }
    }

    pub fn create_window(&mut self, workspace: usize) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        let mut window = Window::new(id, workspace);
        window.focus_order = self.focus_counter;
        self.focus_counter += 1;
        self.windows.insert(id, window);
        id
    }

    pub fn remove_window(&mut self, id: u64) {
        self.windows.remove(&id);
        if self.active_window == Some(id) {
            self.active_window = None;
        }
    }

    pub fn focus_window(&mut self, id: u64) {
        if let Some(window) = self.windows.get_mut(&id) {
            window.focus_order = self.focus_counter;
            self.focus_counter += 1;
            self.active_window = Some(id);
        }
    }

    pub fn get_windows_on_workspace(&self, workspace: usize) -> Vec<&Window> {
        self.windows
            .values()
            .filter(|w| w.workspace == workspace && w.mapped)
            .collect()
    }

    pub fn snap_window(&mut self, id: u64, output_size: Size<i32, Logical>, snap: WindowState) {
        if let Some(window) = self.windows.get_mut(&id) {
            if window.state == WindowState::Floating || window.state.to_string().contains("Snap") {
                window.floating_geometry = window.geometry;
            }

            let (width, height) = (output_size.w, output_size.h);

            window.geometry = match snap {
                WindowState::SnappedLeft => Rectangle::from_loc_and_size(
                    Point::from((0, 0)),
                    Size::from((width / 2 - 4, height)),
                ),
                WindowState::SnappedRight => Rectangle::from_loc_and_size(
                    Point::from((width / 2 + 4, 0)),
                    Size::from((width / 2 - 4, height)),
                ),
                WindowState::SnappedTopLeft => Rectangle::from_loc_and_size(
                    Point::from((0, 0)),
                    Size::from((width / 2 - 4, height / 2 - 4)),
                ),
                WindowState::SnappedTopRight => Rectangle::from_loc_and_size(
                    Point::from((width / 2 + 4, 0)),
                    Size::from((width / 2 - 4, height / 2 - 4)),
                ),
                WindowState::SnappedBottomLeft => Rectangle::from_loc_and_size(
                    Point::from((0, height / 2 + 4)),
                    Size::from((width / 2 - 4, height / 2 - 4)),
                ),
                WindowState::SnappedBottomRight => Rectangle::from_loc_and_size(
                    Point::from((width / 2 + 4, height / 2 + 4)),
                    Size::from((width / 2 - 4, height / 2 - 4)),
                ),
                _ => window.geometry,
            };

            window.state = snap;
        }
    }

    pub fn maximize_window(&mut self, id: u64) {
        if let Some(window) = self.windows.get_mut(&id) {
            window.toggle_state(WindowState::Maximized);
        }
    }

    pub fn minimize_window(&mut self, id: u64) {
        if let Some(window) = self.windows.get_mut(&id) {
            window.minimized = !window.minimized;
        }
    }

    pub fn close_window(&mut self, id: u64) {
        // Send close request to XDG toplevel
        if let Some(window) = self.windows.get(&id) {
            if let Some(toplevel) = &window.toplevel {
                toplevel.send_close();
            }
        }
    }
}
