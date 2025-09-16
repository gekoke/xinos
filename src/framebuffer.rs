use lazy_static::lazy_static;
use limine::{framebuffer::Framebuffer, request::FramebufferRequest};

#[used]
#[link_section = ".requests"]
static FRAMEBUFFER_REQUEST: FramebufferRequest = FramebufferRequest::new();

lazy_static! {
    static ref FRAME_BUFFER: Framebuffer<'static> = FRAMEBUFFER_REQUEST
        .get_response()
        .expect("framebuffers to be set up")
        .framebuffers()
        .next()
        .expect("at least one framebuffer to exist");
}

pub fn draw_stuff() -> () {
    for i in 0..100_u64 {
        // Calculate the pixel offset using the framebuffer information we obtained above.
        // We skip `i` scanlines (pitch is provided in bytes) and add `i * 4` to skip `i` pixels forward.
        let pixel_offset = i * FRAME_BUFFER.pitch() + i * 4;

        unsafe {
            // Write 0xFFFFFFFF to the provided pixel offset to fill it white.
            *(FRAME_BUFFER.addr().add(pixel_offset as usize) as *mut u32) = 0xFFFFFFFF;
        }
    }
}
