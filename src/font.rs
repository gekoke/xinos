static KAKWA_BDF: &str = include_str!("./fonts/kakwa.bdf");

fn parse_character_section(str: &str) -> [u8; 12] {
    let mut bitmap: [u8; 12] = [0; 12];

    let bitmap_rows = str
        .lines()
        .skip_while(|line| { *line != "BITMAP" })
        .skip(1)
        .take_while(|line| { *line != "ENDCHAR"})
        .map(|byte_hex_str| { u8::from_str_radix(byte_hex_str, 16).expect("each line to be a 2 char hex number")})
        .take(12);

    for (i, bitmap_row) in bitmap_rows.enumerate() {
        bitmap[i] = bitmap_row
    }
    bitmap
}

pub fn get_ascii_table() -> [[u8; 12]; 128] {
    let mut ascii_table: [[u8; 12]; 128] = [[0; 12]; 128];

    let bitmaps = KAKWA_BDF
        .split("STARTCHAR ")
        .skip(1) // header
        .map(parse_character_section)
        .take(128);

    for (i, bitmap) in bitmaps.enumerate() {
        ascii_table[i] = bitmap;
    }
    ascii_table
}
