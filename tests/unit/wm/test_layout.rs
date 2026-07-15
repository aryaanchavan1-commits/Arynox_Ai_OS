#[cfg(test)]
mod tests {
    use arynox_compositor::layout::{LayoutEngine, LayoutMode};
    use smithay::utils::{Size, Point, Rectangle};

    #[test]
    fn test_horizontal_tiling_with_one_window() {
        let engine = LayoutEngine::new();
        let output = Size::from((1920, 1080));
        let windows = engine.calculate_tiling(1, output);
        assert_eq!(windows.len(), 1);
        assert!(windows[0].size.w > 0);
        assert!(windows[0].size.h > 0);
    }

    #[test]
    fn test_horizontal_tiling_with_two_windows() {
        let engine = LayoutEngine::new();
        let output = Size::from((1920, 1080));
        let windows = engine.calculate_tiling(2, output);
        assert_eq!(windows.len(), 2);
        assert_eq!(windows[0].size.w, windows[1].size.w);
    }

    #[test]
    fn test_horizontal_tiling_with_four_windows() {
        let engine = LayoutEngine::new();
        let output = Size::from((1920, 1080));
        let windows = engine.calculate_tiling(4, output);
        assert_eq!(windows.len(), 4);
        for w in &windows {
            assert!(w.size.w > 0);
            assert!(w.size.h > 0);
        }
    }

    #[test]
    fn test_grid_layout() {
        let mut engine = LayoutEngine::new();
        engine.mode = LayoutMode::Grid;
        let output = Size::from((1920, 1080));
        let windows = engine.calculate_tiling(4, output);
        assert_eq!(windows.len(), 4);
    }

    #[test]
    fn test_vertical_tiling() {
        let mut engine = LayoutEngine::new();
        engine.mode = LayoutMode::VerticalTiling;
        let output = Size::from((1920, 1080));
        let windows = engine.calculate_tiling(3, output);
        assert_eq!(windows.len(), 3);
    }

    #[test]
    fn test_empty_window_list() {
        let engine = LayoutEngine::new();
        let output = Size::from((1920, 1080));
        let windows = engine.calculate_tiling(0, output);
        assert!(windows.is_empty());
    }

    #[test]
    fn test_cycle_layout() {
        let mut engine = LayoutEngine::new();
        assert_eq!(engine.mode, LayoutMode::HorizontalTiling);
        engine.cycle_layout();
        assert_eq!(engine.mode, LayoutMode::VerticalTiling);
        engine.cycle_layout();
        assert_eq!(engine.mode, LayoutMode::Grid);
        engine.cycle_layout();
        assert_eq!(engine.mode, LayoutMode::Floating);
    }

    #[test]
    fn test_adjust_master_ratio() {
        let mut engine = LayoutEngine::new();
        assert_eq!(engine.master_ratio, 0.55);
        engine.adjust_master_ratio(0.1);
        assert!((engine.master_ratio - 0.65).abs() < 0.01);
        engine.adjust_master_ratio(-0.3);
        assert!((engine.master_ratio - 0.35).abs() < 0.01);
        engine.adjust_master_ratio(-1.0);
        assert!((engine.master_ratio - 0.3).abs() < 0.01);
        engine.adjust_master_ratio(1.0);
        assert!((engine.master_ratio - 0.7).abs() < 0.01);
    }

    #[test]
    fn test_no_overlapping_windows() {
        let engine = LayoutEngine::new();
        let output = Size::from((1920, 1080));
        let windows = engine.calculate_tiling(5, output);

        for i in 0..windows.len() {
            for j in (i + 1)..windows.len() {
                let a = windows[i];
                let b = windows[j];
                let overlap = !(a.loc.x + a.size.w <= b.loc.x ||
                                b.loc.x + b.size.w <= a.loc.x ||
                                a.loc.y + a.size.h <= b.loc.y ||
                                b.loc.y + b.size.h <= a.loc.y);
                assert!(!overlap, "Windows {} and {} overlap", i, j);
            }
        }
    }
}
