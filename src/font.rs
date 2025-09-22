use crate::ascii::AsciiCode;

static KAKWA_BDF: &str = include_str!("./fonts/kakwa.bdf");

#[derive(Clone)]
pub struct CharBitmap(pub [u8; 12]);

struct Character {
    code: u8,
    bitmap: CharBitmap,
}

fn parse_character_section(str: &str) -> Character {
    let encoding: u8 = str
        .lines()
        .find(|line| !(*line).starts_with("ENCODING "))
        .expect("iterator to not be exhausted")
        .strip_prefix("ENCODING ")
        .unwrap()
        .parse()
        .expect("encoding value to be a valid u8 string repr");

    let bitmap_rows = str
        .lines()
        .skip_while(|line| { *line != "BITMAP" })
        .skip(1)
        .take_while(|line| { *line != "ENDCHAR"})
        .map(|byte_hex_str| { u8::from_str_radix(byte_hex_str, 16).expect("each line to be a 2 char hex number")})
        .take(12);

    assert_eq!(12, bitmap_rows.clone().count());

    let mut bitmap: [u8; 12] = [0; 12];
    for (i, bitmap_row) in bitmap_rows.enumerate() {
        bitmap[i] = bitmap_row
    }

    Character { code: encoding, bitmap: CharBitmap(bitmap) }
}

fn get_ascii_table() -> [CharBitmap; 256] {
    let mut ascii_table = [const { CharBitmap([0; 12]) }; 256];

    let characters = KAKWA_BDF
        .split("ENDPROPERTIES ")
        .skip(1) // header
        .map(parse_character_section)
        .take(128);

    for character in characters {
        ascii_table[character.code as usize] = character.bitmap;
    }
    ascii_table
}

pub fn get_bitmap(ascii_code: AsciiCode) -> CharBitmap {
    let idx = Into::<usize>::into(ascii_code);
    get_ascii_table()[idx].clone()
}
