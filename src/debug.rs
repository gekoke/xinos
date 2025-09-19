use owo_colors::OwoColorize;

use crate::serial_println;

pub fn kinfo(text: &str) {
    serial_println!("{} {}", "> ".blue(), text);
}

pub fn kfatal(text: &str) {
    serial_println!("{} {}", "> ".bright_red(), text);
}
