

#[macro_export]
macro_rules! kinfo {
    ($($arg:tt)*) => {
        $crate::serial_println!(
            "{} {}",
            ::owo_colors::OwoColorize::blue(&"> "),
            format_args!($($arg)*)
        );
    };
}

#[macro_export]
macro_rules! kfatal {
    ($($arg:tt)*) => {
        $crate::serial_println!(
            "{} {}",
            ::owo_colors::OwoColorize::bright_red(&"> "),
            format_args!($($arg)*)
        );
    };
}
