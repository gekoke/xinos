use lazy_static::lazy_static;
use limine::{framebuffer::Framebuffer, request::FramebufferRequest};
use rgb::Rgba;

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

/// `false`, if the write was out of bounds - `true` otherwise
pub fn draw(pixel: Rgba<u8>, y: u64, x: u64) -> bool {
    if y > FRAME_BUFFER.height() - 1 {
        return false;
    }

    if x > FRAME_BUFFER.width() - 1 {
        return false;
    }

    let line = y * FRAME_BUFFER.pitch();
    let px = x * 4;
    let pixel_offset = line + px;

    unsafe {
        let pixel_addr = FRAME_BUFFER.addr().add(pixel_offset as usize) as *mut Rgba<u8>;
        *pixel_addr = pixel
    }
    true
}

pub fn width() -> u64 {
   FRAME_BUFFER.width() 
}

pub fn height() -> u64 {
   FRAME_BUFFER.height() 
}
