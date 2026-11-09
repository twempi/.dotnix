use std::path::PathBuf;
use std::{env, fs};

use amane::{Color, Service};

// the stylix base16 palette, written by Home Manager as `base00=#rrggbb` lines
pub struct Theme {
    pub base: [Color; 16],
}

impl Service for Theme {
    fn new() -> Self {
        load()
    }

    // theme-switch activates another Home Manager generation, which relinks the file
    fn listen() {
        let path = path();

        for _ in amane::watch_file(&path.to_string_lossy()) {
            *Self::write() = load();
        }
    }
}

pub fn config_home() -> PathBuf {
    env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| home().join(".config"))
}

pub fn home() -> PathBuf {
    env::var_os("HOME").map(PathBuf::from).unwrap_or_default()
}

fn path() -> PathBuf {
    config_home().join("amane-shell/colors")
}

fn load() -> Theme {
    Theme {
        base: parse_palette(&fs::read_to_string(path()).unwrap_or_default()),
    }
}

pub fn parse_palette(text: &str) -> [Color; 16] {
    // grayscale fallback, so a missing file still gives a readable shell
    let mut base = [Color::rgb(128, 128, 128); 16];
    base[0] = Color::rgb(24, 24, 24);
    base[5] = Color::rgb(216, 216, 216);

    for line in text.lines() {
        let Some((key, value)) = line.split_once('=') else {
            continue;
        };

        let Some(index) = key.trim().strip_prefix("base") else {
            continue;
        };

        let (Ok(index), Some(hex)) = (usize::from_str_radix(index, 16), parse_hex(value.trim()))
        else {
            continue;
        };

        if index < 16 {
            base[index] = hex;
        }
    }

    base
}

fn parse_hex(value: &str) -> Option<Color> {
    let hex = value.strip_prefix('#')?;

    if hex.len() != 6 {
        return None;
    }

    let channel = |at: usize| u8::from_str_radix(&hex[at..at + 2], 16).ok();

    Some(Color::rgb(channel(0)?, channel(2)?, channel(4)?))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_hex() {
        assert_eq!(parse_hex("#ff8000"), Some(Color::rgb(255, 128, 0)));
        assert_eq!(parse_hex("ff8000"), None);
        assert_eq!(parse_hex("#ff80"), None);
    }
}
