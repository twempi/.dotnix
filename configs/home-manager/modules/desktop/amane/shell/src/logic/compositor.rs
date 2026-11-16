use std::env;
use std::io::{BufRead, BufReader};
use std::os::unix::net::UnixStream;
use std::path::PathBuf;
use std::thread;
use std::time::Duration;

use amane::{Monitor, Service, Workspaces};

// amane checks hyprland before sway too, so a SWAYSOCK left over in the session doesn't count
pub fn hyprland() -> bool {
    env::var_os("HYPRLAND_INSTANCE_SIGNATURE").is_some()
}

// hyprland's event socket, a line per event like "monitoradded>>DP-1"; nothing if it isn't up
fn hyprland_events() -> impl Iterator<Item = String> {
    let path = env::var_os("XDG_RUNTIME_DIR")
        .zip(env::var_os("HYPRLAND_INSTANCE_SIGNATURE"))
        .map(|(runtime, instance)| PathBuf::from(runtime).join("hypr").join(instance).join(".socket2.sock"));

    path.and_then(|path| UnixStream::connect(path).ok())
        .into_iter()
        .flat_map(|stream| BufReader::new(stream).lines().map_while(Result::ok))
}

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
        // shortcut: hyprland's submaps aren't shown, add them once the config has one
        if hyprland() {
            return;
        }

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
// programs don't live in the shell's service and survive a shell restart;
// hyprland's keybinds give each program its own unit through uwsm instead
pub fn run(command: &str) {
    if hyprland() {
        amane::spawn(&format!("uwsm app -- sh -c {}", quote(command)));
    } else if env::var_os("SWAYSOCK").is_some() {
        amane::spawn(&format!("swaymsg {}", quote(&format!("exec {command}"))));
    } else {
        amane::spawn(command);
    }
}

// the terminal each session opens: foot on sway, kitty on hyprland
pub fn terminal() -> &'static str {
    if hyprland() { "kitty" } else { "foot" }
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

            if hyprland() {
                // monitors added or removed, or rearranged by a config reload
                for event in hyprland_events() {
                    if event.starts_with("monitor") || event.starts_with("configreloaded") {
                        refresh_main_output();
                    }
                }
            } else {
                // sway announces every monitor added, removed or moved
                for _ in amane::lines(r#"swaymsg -r -m -t subscribe '["output"]'"#) {
                    refresh_main_output();
                }
            }

            // the compositor isn't up yet, or is going away
            thread::sleep(Duration::from_secs(5));
        }
    }
}

fn refresh_main_output() {
    let command = if hyprland() { "hyprctl -j monitors" } else { "swaymsg -r -t get_outputs" };
    let outputs = serde_json::from_str(&amane::output(command)).unwrap_or_default();
    let name = main_output(&outputs);

    if MainOutput::read().name != name {
        MainOutput::write().name = name;
    }
}

// the leftmost, then topmost, enabled monitor: DP-1 on desktop, the laptop panel on g14;
// sway marks enabled outputs active and nests their position in rect, hyprctl marks disabled ones
fn main_output(outputs: &serde_json::Value) -> String {
    outputs
        .as_array()
        .into_iter()
        .flatten()
        .filter(|output| output["active"] == true || output["disabled"] == false)
        .min_by_key(|output| {
            let position = if output["rect"].is_object() { &output["rect"] } else { output };

            (position["x"].as_i64(), position["y"].as_i64())
        })
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

        // hyprctl -j monitors, trimmed
        let monitors = serde_json::json!([
            {"name": "HDMI-A-1", "x": 2560, "y": 0, "disabled": false},
            {"name": "eDP-1", "x": 0, "y": 0, "disabled": true},
            {"name": "DP-1", "x": 0, "y": 0, "disabled": false}
        ]);

        assert_eq!(main_output(&monitors), "DP-1");
    }
}
