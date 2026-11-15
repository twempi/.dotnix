use std::thread;
use std::time::Duration;

use amane::{Monitor, Service, Workspaces};

// sway's binding mode, hidden while it is "default"
pub struct SwayMode {
    pub name: String,
}

impl Service for SwayMode {
    fn new() -> Self {
        Self {
            name: String::new(),
        }
    }

    fn listen() {
        loop {
            // -r keeps each event on one line
            for line in amane::lines(r#"swaymsg -r -m -t subscribe '["mode"]'"#) {
                let event: serde_json::Value = serde_json::from_str(&line).unwrap_or_default();

                let mode = event["change"].as_str().unwrap_or("default");

                Self::write().name = if mode == "default" {
                    String::new()
                } else {
                    mode.to_string()
                };
            }

            // not running under sway, or sway is going away
            thread::sleep(Duration::from_secs(5));
        }
    }
}

// the monitor a popup opens on: where the focused workspace is
pub fn focused_output() -> String {
    Workspaces::read()
        .list()
        .iter()
        .find(|workspace| workspace.focused())
        .and_then(|workspace| workspace.output())
        .unwrap_or_default()
        .to_string()
}

// an empty monitor name means the focused one wasn't known, so every monitor shows it
pub fn shown_on(wanted: &str, monitor: &Monitor) -> bool {
    wanted.is_empty() || wanted == monitor.name
}

// swaynotificationcenter and rofi both run commands through sway, so launched
// programs don't live in the shell's service and survive a shell restart
pub fn run(command: &str) {
    if std::env::var_os("SWAYSOCK").is_none() {
        amane::spawn(command);
        return;
    }

    amane::spawn(&format!("swaymsg {}", quote(&format!("exec {command}"))));
}

pub fn quote(value: &str) -> String {
    format!("'{}'", value.replace('\'', r"'\''"))
}

// the one monitor notification popups show on, whichever monitor has focus
#[derive(Default)]
pub struct MainOutput {
    pub name: String,
}

impl Service for MainOutput {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        loop {
            refresh_main_output();

            // sway announces every monitor added, removed or moved
            for _ in amane::lines(r#"swaymsg -r -m -t subscribe '["output"]'"#) {
                refresh_main_output();
            }

            // not running under sway, or sway is going away
            thread::sleep(Duration::from_secs(5));
        }
    }
}

fn refresh_main_output() {
    let outputs = serde_json::from_str(&amane::output("swaymsg -r -t get_outputs")).unwrap_or_default();
    let name = main_output(&outputs);

    if MainOutput::read().name != name {
        MainOutput::write().name = name;
    }
}

// the leftmost, then topmost, enabled monitor: DP-1 on desktop, the laptop panel on g14
fn main_output(outputs: &serde_json::Value) -> String {
    outputs
        .as_array()
        .into_iter()
        .flatten()
        .filter(|output| output["active"] == true)
        .min_by_key(|output| (output["rect"]["x"].as_i64(), output["rect"]["y"].as_i64()))
        .and_then(|output| output["name"].as_str())
        .unwrap_or_default()
        .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn quotes_for_sh() {
        assert_eq!(quote("a b"), "'a b'");
        assert_eq!(quote("it's"), r"'it'\''s'");
    }

    #[test]
    fn picks_the_top_left_monitor() {
        let outputs = serde_json::json!([
            {"name": "HDMI-A-1", "active": true, "rect": {"x": 2560, "y": 0}},
            {"name": "eDP-1", "active": false, "rect": {"x": 0, "y": 0}},
            {"name": "DP-1", "active": true, "rect": {"x": 0, "y": 0}}
        ]);

        assert_eq!(main_output(&outputs), "DP-1");
        assert_eq!(main_output(&serde_json::json!([])), "");
    }
}
