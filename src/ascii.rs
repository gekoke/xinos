pub struct AsciiCode(u8);

impl Into<u8> for AsciiCode {
    fn into(self) -> u8 {
        self.0
    }
}

impl Into<usize> for AsciiCode {
    fn into(self) -> usize {
        self.0.into()
    }
}
