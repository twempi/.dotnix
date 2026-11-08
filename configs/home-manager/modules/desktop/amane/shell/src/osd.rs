use std::fs;
use std::thread;
use std::time::{Duration, Instant};

use amane::{
    Center, Full, LayerWindow, Margin, Monitor, Parent, Rectangle, Row, Service, Vertical,
    children,
};

use crate::theme::Theme;
use crate::ui::{self, MENU_FONT, MENU_TEXT};

// Noctalia's OSD hide delay
const SHOWN_FOR: Duration = Duration::from_millis(1400);

// the glyph, the words, and whether the thing turned on
type Message = (&'static str, &'static str, bool);

// Noctalia's OSD for caps lock and the microphone turning on or off
#[derive(Default)]
pub struct Osd {
    caps_lock: bool,
    microphone: bool,
    shown: Option<(Message, Instant)>,
}

impl Service for Osd {
    // caps lock already on when the shell starts gets no popup, a microphone in use does
    fn new() -> Self {
        Self {
            caps_lock: caps_lock(),
            ..Self::default()
        }
    }

    // Noctalia polls the lock keys this often
    fn interval() -> Duration {
        Duration::from_millis(200)
    }

    fn update(&mut self) -> bool {
        let before = self.shown.map(|(message, _)| message);

        let caps_lock = caps_lock();

        if caps_lock != self.caps_lock {
            self.caps_lock = caps_lock;

            let text = if caps_lock { "Caps Lock On" } else { "Caps Lock Off" };
            self.shown = Some((("\u{F0632}", text, caps_lock), Instant::now()));
        }

        let microphone = Microphone::read().active;

        if microphone != self.microphone {
            self.microphone = microphone;

            let message = if microphone {
                ("\u{F036C}", "Microphone Active", true)
            } else {
                ("\u{F036D}", "Microphone Stopped", false)
            };
            self.shown = Some((message, Instant::now()));
        }

        if self.shown.is_some_and(|(_, since)| since.elapsed() >= SHOWN_FOR) {
            self.shown = None;
        }

        self.shown.map(|(message, _)| message) != before
    }
}

// sway keeps every keyboard's caps lock light in step with the lock; Noctalia reads them too
fn caps_lock() -> bool {
    let Ok(leds) = fs::read_dir("/sys/class/leds") else {
        return false;
    };

    leds.flatten()
        .filter(|led| led.file_name().to_string_lossy().ends_with("::capslock"))
        .any(|led| fs::read_to_string(led.path().join("brightness")).is_ok_and(|level| level.trim() != "0"))
}

// whether a program records from a microphone, as Handy does while it listens
#[derive(Default)]
pub struct Microphone {
    active: bool,
}

impl Service for Microphone {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        loop {
            refresh_microphone();

            // a recording starting or stopping changes its source-output and the source
            for line in amane::lines("pactl subscribe") {
                if line.contains("source") {
                    refresh_microphone();
                }
            }

            // pipewire-pulse restarted or isn't up yet
            thread::sleep(Duration::from_secs(2));
        }
    }
}

fn refresh_microphone() {
    let active = recording(&amane::output("pactl list short sources"));

    if Microphone::read().active != active {
        Microphone::write().active = active;
    }
}

// pipewire runs a source only while something records from it; monitors are speakers, not microphones
fn recording(sources: &str) -> bool {
    sources.lines().any(|line| {
        let fields: Vec<&str> = line.split('\t').collect();

        fields.len() > 4 && !fields[1].ends_with(".monitor") && fields[4] == "RUNNING"
    })
}

// shown on every monitor, unlike notifications
pub fn view(_: &Monitor) -> LayerWindow {
    let osd = Osd::read();
    let theme = Theme::read();
    let base = theme.base;

    let (glyph, text, on) = osd.shown.map_or(("", "", false), |(message, _)| message);
    let visible = osd.shown.is_some();

    // what turned off gets a dim glyph, as Noctalia's inactive lock keys do
    let content = Row::new(children![
        ui::text(glyph, MENU_TEXT + 4.0, MENU_FONT).color(if on { base[0x0A] } else { base[3] }),
        ui::text(text, MENU_TEXT, MENU_FONT).color(base[5]),
    ])
    .gap(10.0)
    .align(Center);

    let width = ui::width_of(&content) + 32.0;

    // a full-width strip that never moves, like the tray tooltip (see notifications::close)
    LayerWindow::new()
        .width(Full)
        .height(40.0)
        .anchor_vertical(Vertical::Top)
        .margin(Margin {
            top: 10,
            ..Margin::default()
        })
        .namespace("amane-osd")
        .click_through()
        .visible(visible)
        .child(
            Rectangle::new()
                .width(Parent)
                .height(Parent)
                .align_child(Center, Center)
                .child(
                    Rectangle::new()
                        .width(width)
                        .height(Parent)
                        .fill(base[0])
                        .border(1.0, base[0x0A])
                        .align_child(Center, Center)
                        .child(content),
                ),
        )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn finds_a_recording_microphone() {
        let idle = "67\talsa_output.hdmi-stereo.monitor\tPipeWire\ts32le 2ch 48000Hz\tRUNNING\n\
                    71\talsa_input.usb-webcam.mono-fallback\tPipeWire\ts16le 1ch 48000Hz\tIDLE";

        assert!(!recording(idle));
        assert!(recording(&idle.replace("IDLE", "RUNNING")));
        assert!(!recording(""));
    }
}
