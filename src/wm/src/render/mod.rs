use smithay::{
    backend::renderer::{
        gles::{GlesRenderer, GlesFrame},
        utils::BufferType,
        Frame, Renderer,
    },
    rendering::{
        element::{
            memory::MemoryRenderBuffer,
            surface::WaylandSurfaceRenderElement,
            AsRenderElements,
        },
        Renderer as RenderingRenderer,
    },
    utils::{Physical, Point, Rectangle, Scale, Size, Transform},
};

pub struct GlRenderer {
    pub inner: GlesRenderer,
}

impl GlRenderer {
    pub fn new() -> Result<Self, ()> {
        let renderer = GlesRenderer::new().map_err(|_| ())?;
        Ok(GlRenderer { inner: renderer })
    }
}

impl From<GlesRenderer> for GlRenderer {
    fn from(inner: GlesRenderer) -> Self {
        GlRenderer { inner }
    }
}
