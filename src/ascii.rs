pub struct AsciiCode(u8);

impl From<AsciiCode> for u8 {
    fn from(val: AsciiCode) -> Self {
        val.0
    }
}

impl From<AsciiCode> for usize {
    fn from(val: AsciiCode) -> Self {
        val.0.into()
    }
}
