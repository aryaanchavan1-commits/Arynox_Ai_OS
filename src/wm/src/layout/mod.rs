use smithay::utils::{Logical, Point, Rectangle, Size};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LayoutMode {
    Floating,
    HorizontalTiling,
    VerticalTiling,
    Grid,
    Maximized,
}

pub struct LayoutEngine {
    pub mode: LayoutMode,
    pub master_ratio: f64,
    pub master_count: usize,
    pub gap: i32,
}

impl LayoutEngine {
    pub fn new() -> Self {
        LayoutEngine {
            mode: LayoutMode::HorizontalTiling,
            master_ratio: 0.55,
            master_count: 1,
            gap: 8,
        }
    }

    pub fn calculate_tiling(
        &self,
        window_count: usize,
        output_size: Size<i32, Logical>,
    ) -> Vec<Rectangle<i32, Logical>> {
        if window_count == 0 {
            return Vec::new();
        }

        let gap = self.gap;
        let (w, h) = (output_size.w - gap, output_size.h - gap);

        match self.mode {
            LayoutMode::HorizontalTiling => self.horizontal_layout(window_count, w, h, gap),
            LayoutMode::VerticalTiling => self.vertical_layout(window_count, w, h, gap),
            LayoutMode::Grid => self.grid_layout(window_count, w, h, gap),
            LayoutMode::Floating | LayoutMode::Maximized => {
                vec![Rectangle::from_loc_and_size(
                    Point::from((gap / 2, gap / 2)),
                    Size::from((w, h)),
                )]
            }
        }
    }

    fn horizontal_layout(
        &self,
        count: usize,
        w: i32,
        h: i32,
        gap: i32,
    ) -> Vec<Rectangle<i32, Logical>> {
        let mut result = Vec::new();

        if count <= self.master_count + 1 {
            // Just split horizontally
            let each = w / count as i32;
            for i in 0..count {
                result.push(Rectangle::from_loc_and_size(
                    Point::from((i as i32 * each + gap / 2, gap / 2)),
                    Size::from((each - gap, h)),
                ));
            }
        } else {
            // Master + stack
            let master_w = (w as f64 * self.master_ratio) as i32;
            let stack_w = w - master_w - gap;
            let stack_count = count - self.master_count;

            // Master windows
            let master_h = (h - (self.master_count as i32 - 1) * gap) / self.master_count as i32;
            for i in 0..self.master_count.min(count) {
                result.push(Rectangle::from_loc_and_size(
                    Point::from((gap / 2, i as i32 * (master_h + gap) + gap / 2)),
                    Size::from((master_w - gap, master_h)),
                ));
            }

            // Stack windows
            let stack_h = (h - (stack_count as i32 - 1) * gap) / stack_count as i32;
            for i in 0..stack_count {
                result.push(Rectangle::from_loc_and_size(
                    Point::from((master_w + gap + gap / 2, i as i32 * (stack_h + gap) + gap / 2)),
                    Size::from((stack_w - gap, stack_h)),
                ));
            }
        }

        result
    }

    fn vertical_layout(
        &self,
        count: usize,
        w: i32,
        h: i32,
        gap: i32,
    ) -> Vec<Rectangle<i32, Logical>> {
        let mut result = Vec::new();

        if count <= self.master_count + 1 {
            let each = h / count as i32;
            for i in 0..count {
                result.push(Rectangle::from_loc_and_size(
                    Point::from((gap / 2, i as i32 * each + gap / 2)),
                    Size::from((w, each - gap)),
                ));
            }
        } else {
            let master_h = (h as f64 * self.master_ratio) as i32;
            let stack_h = h - master_h - gap;
            let stack_count = count - self.master_count;

            let master_w = (w - (self.master_count as i32 - 1) * gap) / self.master_count as i32;
            for i in 0..self.master_count.min(count) {
                result.push(Rectangle::from_loc_and_size(
                    Point::from((i as i32 * (master_w + gap) + gap / 2, gap / 2)),
                    Size::from((master_w, master_h - gap)),
                ));
            }

            let stack_w = (w - (stack_count as i32 - 1) * gap) / stack_count as i32;
            for i in 0..stack_count {
                result.push(Rectangle::from_loc_and_size(
                    Point::from((i as i32 * (stack_w + gap) + gap / 2, master_h + gap + gap / 2)),
                    Size::from((stack_w, stack_h - gap)),
                ));
            }
        }

        result
    }

    fn grid_layout(
        &self,
        count: usize,
        w: i32,
        h: i32,
        gap: i32,
    ) -> Vec<Rectangle<i32, Logical>> {
        let cols = (count as f64).sqrt().ceil() as usize;
        let rows = (count as f64 / cols as f64).ceil() as usize;
        let cell_w = (w - (cols as i32 - 1) * gap) / cols as i32;
        let cell_h = (h - (rows as i32 - 1) * gap) / rows as i32;

        let mut result = Vec::new();
        for i in 0..count {
            let col = i % cols;
            let row = i / cols;
            result.push(Rectangle::from_loc_and_size(
                Point::from((
                    col as i32 * (cell_w + gap) + gap / 2,
                    row as i32 * (cell_h + gap) + gap / 2,
                )),
                Size::from((cell_w, cell_h)),
            ));
        }
        result
    }

    pub fn cycle_layout(&mut self) {
        self.mode = match self.mode {
            LayoutMode::Floating => LayoutMode::HorizontalTiling,
            LayoutMode::HorizontalTiling => LayoutMode::VerticalTiling,
            LayoutMode::VerticalTiling => LayoutMode::Grid,
            LayoutMode::Grid => LayoutMode::Floating,
            LayoutMode::Maximized => LayoutMode::HorizontalTiling,
        };
        tracing::info!("Layout changed to {:?}", self.mode);
    }

    pub fn adjust_master_ratio(&mut self, delta: f64) {
        self.master_ratio = (self.master_ratio + delta).clamp(0.3, 0.7);
    }
}
