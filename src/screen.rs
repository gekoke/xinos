use limine::framebuffer;

static CELL_SIZE: u64 = 12;

fn columns() -> u64 {
    framebuffer::width() / CELL_SIZE
}

fn lines() -> u64 {
    framebuffer::height() / CELL_SIZE
}

fn is_out_of_bounds(line: u64, column: u64) -> bool {
    line >= lines() || column >= columns()
}
