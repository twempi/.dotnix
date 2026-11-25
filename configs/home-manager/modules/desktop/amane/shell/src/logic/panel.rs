use std::collections::hash_map::DefaultHasher;
use std::collections::{HashMap, HashSet};
use std::hash::{Hash, Hasher};
use std::path::PathBuf;
use std::time::Duration;
use std::{fs, mem, thread};

use amane::{Media, Service};

use crate::logic::compositor;
use crate::logic::notifications::{self, NotificationCenter, Page};
use crate::logic::tray::runtime_dir;

pub mod audio;
pub mod bluetooth;
pub mod calendar;
pub mod network;
pub mod usage;

// the current track's cover as a file, because Amane only draws local images
#[derive(Default)]
pub struct Cover {
    url: String,
    pub path: Option<PathBuf>,
}

impl Service for Cover {
    fn new() -> Self {
        Self::default()
    }

    // not update(), which holds the write lock: a download must not stall the drawing
    fn listen() {
        loop {
            let url = Media::read().art_url().to_string();

            if Cover::read().url != url {
                let path = local_cover(&url);
                let previous = mem::replace(&mut *Cover::write(), Cover { url, path }).path;

                // only our own downloads: a player's file:// cover is not ours to delete
                if let Some(previous) = previous.filter(|file| file.starts_with(runtime_dir())) {
                    let _ = fs::remove_file(previous);
                }
            }

            thread::sleep(Duration::from_secs(1));
        }
    }
}

// shortcut: a percent-encoded file:// path shows the placeholder, decode it if a player needs that
fn local_cover(url: &str) -> Option<PathBuf> {
    let path = if let Some(path) = url.strip_prefix("file://") {
        PathBuf::from(path)
    } else if url.starts_with("https://") {
        download_cover(url)?
    } else {
        return None;
    };

    path.is_file().then_some(path)
}

// Spotify gives https links; the file only counts once curl has finished it
fn download_cover(url: &str) -> Option<PathBuf> {
    let mut hasher = DefaultHasher::new();
    url.hash(&mut hasher);

    let dir = runtime_dir();
    fs::create_dir_all(&dir).ok()?;

    let path = dir.join(format!("cover-{:x}", hasher.finish()));

    // the url comes from whichever player is active, so it is quoted
    amane::output(&format!(
        "curl -sf --max-time 10 --max-filesize 10M -o {file} {url} || rm -f {file}",
        file = compositor::quote(&path.to_string_lossy()),
        url = compositor::quote(url),
    ));

    Some(path)
}

fn minutes(seconds: u64) -> String {
    format!("{}:{:02}", seconds / 60, seconds % 60)
}

// a live stream has no length, so it shows only its state
pub fn playback(playing: bool, position: u64, length: u64) -> String {
    let state = if playing { "Playing" } else { "Paused" };

    if length == 0 {
        return state.to_string();
    }

    format!("{state} · {} / {}", minutes(position), minutes(length))
}

pub fn uptime_hours() -> f64 {
    let seconds: Option<f64> = fs::read_to_string("/proc/uptime")
        .ok()
        .and_then(|text| text.split_whitespace().next()?.parse().ok());

    seconds.unwrap_or(0.0) / 3600.0
}

// each tab hears when it comes on screen and when it goes, for scans and refreshes
pub fn select(page: Page) {
    let previous = mem::replace(&mut NotificationCenter::write().page, page);

    if previous != page {
        left(previous);
        entered(page);
    }
}

pub fn entered(page: Page) {
    Interaction::clear_hover();

    match page {
        Page::Audio => audio::entered(),
        Page::Bluetooth => bluetooth::entered(),
        Page::Network => network::entered(),
        Page::Calendar => calendar::reset(),
        Page::Usage => usage::refresh(),
        _ => {}
    }
}

pub fn left(page: Page) {
    match page {
        Page::Audio => audio::left(),
        Page::Bluetooth => bluetooth::left(),
        Page::Network => network::left(),
        _ => {}
    }
}

// an open menu is the first thing Esc or an outside click closes
pub fn dismiss() {
    if !audio::close_menu() {
        notifications::close();
    }
}

// what the pointer is doing in the panel, which only the panel's own views need
#[derive(Default, Clone)]
pub struct Interaction {
    pub hovered: HashSet<String>,
    pub offsets: HashMap<&'static str, f32>,
}

impl Service for Interaction {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

impl Interaction {
    pub fn set_hovered(key: &str, inside: bool) {
        // told about a key it doesn't hold: the layout shifted under the pointer, so Amane named the wrong target
        if !inside && !Self::read().hovered.contains(key) {
            if !Self::read().hovered.is_empty() {
                Self::write().hovered.clear();
            }

            return;
        }

        let mut state = Self::write();

        if inside {
            state.hovered.insert(key.to_string());
        } else {
            state.hovered.remove(key);
        }
    }

    pub fn clear_hover() {
        if !Self::read().hovered.is_empty() {
            Self::write().hovered.clear();
        }
    }

    pub fn scroll_to(id: &'static str, offset: f32, max: f32) {
        let offset = offset.clamp(0.0, max);

        if Self::read().offsets.get(id).copied().unwrap_or(0.0) != offset {
            Self::write().offsets.insert(id, offset);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn describes_playback() {
        assert_eq!(playback(true, 61, 286), "Playing · 1:01 / 4:46");
        assert_eq!(playback(false, 0, 0), "Paused");
    }

    #[test]
    fn only_trusts_existing_files_and_https() {
        assert_eq!(local_cover(""), None);
        assert_eq!(local_cover("http://example.com/a.jpg"), None);
        assert_eq!(local_cover("file:///nonexistent/cover.png"), None);
    }
}
