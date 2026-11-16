use std::sync::{Mutex, PoisonError};
use std::time::{Duration, Instant};

use amane::{Color, Rectangle, Text, request_frame};

pub use crate::looks::ui::*;
use crate::looks::tabs::controls::Roles;

// the same families as sway's look: Iosevka for the islands, JetBrains Mono for menus
pub const BAR_FONT: &str = "IosevkaTerm Nerd Font Propo";

pub const MENU_FONT: &str = "JetBrainsMono Nerd Font";

pub const TEXT: f32 = 14.0;

// the islands float this far from the screen's edges, and popups this far under them
pub const GAP: f32 = 8.0;

pub const ISLAND: f32 = 30.0;

pub const BELOW: f32 = GAP + ISLAND + GAP;

// sharp minimal: opaque fills, thin borders, no rounded corners anywhere
pub const BORDER: f32 = 1.0;

const SETTLE: Duration = Duration::from_millis(160);

pub fn label(content: impl Into<String>, size: f32, color: Color) -> Text {
    text(content, size, BAR_FONT).color(color)
}

// the panel's colors: sway's look tints with the accent, this one stays opaque
pub fn roles(base: &[Color; 16]) -> Roles {
    Roles {
        primary: base[0x0E],
        on_primary: base[0x00],
        secondary: base[0x0D],
        hover: base[0x02],
        on_hover: base[0x0E],
        surface: base[0x00],
        container: base[0x01],
        on_surface: base[0x05],
        variant: base[0x04],
        outline: base[0x02],
        error: base[0x08],
        on_error: base[0x00],
        calendars: [base[0x0E], base[0x0D], base[0x0B], base[0x09], base[0x0C], base[0x08], base[0x0A], base[0x0F]],
    }
}

// a floating box: the islands, popups and menus all share it
pub fn frame(rectangle: Rectangle, base: &[Color; 16]) -> Rectangle {
    rectangle.fill(base[0]).border(BORDER, base[0x0E])
}

// when each thing on screen first appeared, keyed by what it is and on which monitor
static SINCE: Mutex<Vec<(String, Instant)>> = Mutex::new(Vec::new());

/*
 * 0 when something has just come on screen, 1 once it has settled; the window keeps
 * drawing frames until then. Only the drawing moves, the layer surface never changes size
 */
pub fn appear(key: &str, shown: bool) -> f32 {
    let mut since = SINCE.lock().unwrap_or_else(PoisonError::into_inner);
    let found = since.iter().position(|(name, _)| name == key);

    if !shown {
        if let Some(index) = found {
            since.swap_remove(index);
        }

        return 1.0;
    }

    let started = match found {
        Some(index) => since[index].1,
        None => {
            since.push((key.to_string(), Instant::now()));
            Instant::now()
        }
    };

    let progress = (started.elapsed().as_secs_f32() / SETTLE.as_secs_f32()).min(1.0);

    if progress < 1.0 {
        request_frame();
    }

    1.0 - (1.0 - progress).powi(3)
}

// what left the screen without appear(key, false), like a popup that timed out
pub fn forget(stale: impl Fn(&str) -> bool) {
    SINCE.lock().unwrap_or_else(PoisonError::into_inner).retain(|(name, _)| !stale(name));
}

// slides a popup down into place while it fades in
pub fn settle(rectangle: Rectangle, progress: f32) -> Rectangle {
    rectangle.translate(0.0, (progress - 1.0) * GAP).opacity(progress)
}
