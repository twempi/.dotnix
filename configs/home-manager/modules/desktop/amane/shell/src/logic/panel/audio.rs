use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Mutex;
use std::sync::atomic::{AtomicBool, Ordering};
use std::thread;
use std::time::{Duration, Instant};

use amane::{Apps, Service};
use serde_json::Value;

use crate::logic::compositor;
use crate::logic::icons::Icons;

const TICK: Duration = Duration::from_millis(33);

const HOLD: Duration = Duration::from_millis(250);

static VISIBLE: AtomicBool = AtomicBool::new(false);

pub static DIRTY: AtomicBool = AtomicBool::new(false);

static PENDING: Mutex<Option<HashMap<Target, f32>>> = Mutex::new(None);

static HOLD_UNTIL: Mutex<Option<Instant>> = Mutex::new(None);

#[derive(Default, Clone, PartialEq)]
pub struct Device {
    pub name: String,
    pub description: String,
    pub volume: f32,
    pub muted: bool,
}

#[derive(Default, Clone, PartialEq)]
pub struct Stream {
    pub index: u32,
    pub name: String,
    pub subtitle: String,
    pub icon: Option<PathBuf>,
    pub sink: u32,
    pub volume: f32,
    pub muted: bool,
}

#[derive(Default, Clone, PartialEq)]
pub struct AudioData {
    pub sinks: Vec<(Device, u32)>,
    pub sources: Vec<Device>,
    pub streams: Vec<Stream>,
    pub default_sink: String,
    pub default_source: String,
}

impl AudioData {
    pub fn default_sink_device(&self) -> Option<&Device> {
        self.sinks.iter().map(|(device, _)| device).find(|device| device.name == self.default_sink)
    }

    pub fn default_source_device(&self) -> Option<&Device> {
        self.sources.iter().find(|device| device.name == self.default_source)
    }

    pub fn default_sink_index(&self) -> u32 {
        self.sinks
            .iter()
            .find(|(device, _)| device.name == self.default_sink)
            .map_or(0, |(_, index)| *index)
    }
}

#[derive(Clone, PartialEq, Eq, Hash)]
pub enum Target {
    Sink(String),
    Source(String),
    Stream(u32),
}

#[derive(Clone)]
pub enum MenuAction {
    DefaultSink(String),
    DefaultSource(String),
    Route(u32, String),
    RouteDefault(u32),
}

#[derive(Clone)]
pub struct MenuItem {
    pub text: String,
    pub selected: bool,
    pub action: Option<MenuAction>,
}

#[derive(Clone)]
pub struct Menu {
    pub id: String,
    pub items: Vec<MenuItem>,
    pub center_x: f32,
    pub y: f32,
    pub min_width: f32,
    pub max_width: f32,
}

#[derive(Default)]
pub struct AudioTab {
    pub data: AudioData,
    pub menu: Option<Menu>,
}

impl Service for AudioTab {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        thread::spawn(|| {
            loop {
                for _ in amane::lines("pactl subscribe") {
                    DIRTY.store(true, Ordering::Relaxed);
                }

                thread::sleep(Duration::from_secs(2));
            }
        });

        loop {
            thread::sleep(TICK);

            flush_pending();

            if !VISIBLE.load(Ordering::Relaxed) || holding() {
                continue;
            }

            if DIRTY.swap(false, Ordering::Relaxed) {
                refresh();
            }
        }
    }
}

fn holding() -> bool {
    let until = HOLD_UNTIL.lock().ok().and_then(|hold| *hold);

    until.is_some_and(|until| Instant::now() < until)
}

fn hold_refresh() {
    if let Ok(mut hold) = HOLD_UNTIL.lock() {
        *hold = Some(Instant::now() + HOLD);
    }
}

fn flush_pending() {
    let volumes = PENDING.lock().ok().and_then(|mut pending| pending.take());

    let Some(volumes) = volumes else {
        return;
    };

    for (target, volume) in volumes {
        let percent = (volume * 100.0).round() as i32;
        let command = match target {
            Target::Sink(name) => format!("pactl set-sink-volume {} {percent}%", compositor::quote(&name)),
            Target::Source(name) => format!("pactl set-source-volume {} {percent}%", compositor::quote(&name)),
            Target::Stream(index) => format!("pactl set-sink-input-volume {index} {percent}%"),
        };

        amane::spawn(&command);
    }
}

fn percent_value(text: &str) -> f32 {
    text.trim_end_matches('%').parse::<f32>().unwrap_or(0.0) / 100.0
}

fn volume_of(entry: &Value) -> f32 {
    entry["volume"]
        .as_object()
        .into_iter()
        .flatten()
        .filter_map(|(_, channel)| channel["value_percent"].as_str())
        .map(percent_value)
        .fold(0.0, f32::max)
}

fn device_from(entry: &Value) -> Device {
    let name = entry["name"].as_str().unwrap_or_default();
    let description = entry["description"].as_str().unwrap_or_default();

    Device {
        name: name.to_string(),
        description: if description.is_empty() { name } else { description }.to_string(),
        volume: volume_of(entry),
        muted: entry["mute"].as_bool().unwrap_or(false),
    }
}

// an unplugged port's device stays listed only while it is the default one
pub fn available(entry: &Value, default: &str) -> bool {
    let active = entry["active_port"].as_str().unwrap_or_default();
    let port_available = entry["ports"]
        .as_array()
        .into_iter()
        .flatten()
        .find(|port| port["name"].as_str() == Some(active))
        .and_then(|port| port["availability"].as_str())
        .is_none_or(|availability| availability != "not available");

    port_available || entry["name"].as_str() == Some(default)
}

fn parse_sinks(json: &str, default: &str) -> Vec<(Device, u32)> {
    let entries: Value = serde_json::from_str(json).unwrap_or_default();
    let mut sinks: Vec<(Device, u32)> = entries
        .as_array()
        .into_iter()
        .flatten()
        .filter(|entry| available(entry, default))
        .map(|entry| (device_from(entry), entry["index"].as_u64().unwrap_or(0) as u32))
        .collect();

    sinks.sort_by(|a, b| a.0.description.cmp(&b.0.description));
    sinks
}

fn parse_sources(json: &str, default: &str) -> Vec<Device> {
    let entries: Value = serde_json::from_str(json).unwrap_or_default();
    let mut sources: Vec<Device> = entries
        .as_array()
        .into_iter()
        .flatten()
        .filter(|entry| entry["monitor_source"].as_str().unwrap_or_default().is_empty())
        .filter(|entry| available(entry, default))
        .map(device_from)
        .collect();

    sources.sort_by(|a, b| a.description.cmp(&b.description));
    sources
}

fn lower(value: &str) -> String {
    value.to_lowercase().replace([' ', '_'], "-")
}

// what might name the program: most specific first
fn name_tokens(properties: &Value) -> Vec<String> {
    let text = |key: &str| properties[key].as_str().unwrap_or_default();
    let name = text("application.name");
    let mut tokens = vec![lower(text("application.process.binary")), lower(text("application.icon_name"))];

    if let (Some(start), Some(end)) = (name.find('['), name.rfind(']'))
        && start < end
    {
        tokens.push(lower(&name[start + 1..end]));
    }

    tokens.push(lower(text("node.name").rsplit('.').next().unwrap_or_default()));
    tokens.push(lower(name));
    tokens.retain(|token| !token.is_empty());
    tokens
}

fn entry_matches(token: &str, name: &str, exec: &str, icon: &str) -> bool {
    let binary = exec.split_whitespace().next().and_then(|path| path.rsplit('/').next()).unwrap_or_default();

    token == lower(name) || token == lower(binary) || token == lower(icon)
}

// shortcut: a condensed form of Noctalia's name resolution, widen it if a program shows a poor name
fn resolve_name(properties: &Value, apps: &Apps, icons: &Icons) -> (String, Option<PathBuf>) {
    let tokens = name_tokens(properties);

    for token in &tokens {
        let found = apps
            .list()
            .iter()
            .find(|app| entry_matches(token, app.name(), app.exec(), app.icon().unwrap_or_default()));

        if let Some(app) = found {
            let icon = app.icon_path().map(PathBuf::from).or_else(|| icons.find(app.icon().unwrap_or_default()));

            return (app.name().to_string(), icon);
        }
    }

    let name = properties["application.name"].as_str().unwrap_or_default();
    let icon = icons.find(properties["application.icon_name"].as_str().unwrap_or_default());
    let name = match (name.find('['), name.rfind(']')) {
        (Some(start), Some(end)) if start < end => prettify(&name[start + 1..end]),
        _ if name.is_empty() => String::from("Application"),
        _ => name.to_string(),
    };

    (name, icon)
}

fn prettify(value: &str) -> String {
    value
        .split(['-', '_', '.', ' '])
        .filter(|word| !word.is_empty())
        .map(|word| {
            let mut chars = word.chars();

            match chars.next() {
                Some(first) => first.to_uppercase().collect::<String>() + chars.as_str(),
                None => String::new(),
            }
        })
        .collect::<Vec<_>>()
        .join(" ")
}

fn is_generic(value: &str) -> bool {
    let normalized = value.to_lowercase().replace([' ', '_', '.'], "-");

    matches!(
        normalized.as_str(),
        "" | "audio-src" | "audio-source" | "audio-sink" | "audio-output" | "audio-input" | "output" | "input" | "stream"
    )
}

pub fn subtitle(media: &str, name: &str) -> String {
    if is_generic(media) || media.eq_ignore_ascii_case(name) {
        String::new()
    } else {
        media.to_string()
    }
}

fn parse_streams(json: &str) -> Vec<Stream> {
    let entries: Value = serde_json::from_str(json).unwrap_or_default();
    let apps = Apps::read();
    let icons = Icons::read();

    entries
        .as_array()
        .into_iter()
        .flatten()
        .map(|entry| {
            let properties = &entry["properties"];
            let (name, icon) = resolve_name(properties, &apps, &icons);

            Stream {
                index: entry["index"].as_u64().unwrap_or(0) as u32,
                subtitle: subtitle(properties["media.name"].as_str().unwrap_or_default(), &name),
                name,
                icon,
                sink: entry["sink"].as_u64().unwrap_or(0) as u32,
                volume: volume_of(entry),
                muted: entry["mute"].as_bool().unwrap_or(false),
            }
        })
        .collect()
}

fn fetch() -> AudioData {
    let default_sink = amane::output("pactl get-default-sink").trim().to_string();
    let default_source = amane::output("pactl get-default-source").trim().to_string();

    AudioData {
        sinks: parse_sinks(&amane::output("pactl -f json list sinks"), &default_sink),
        sources: parse_sources(&amane::output("pactl -f json list sources"), &default_source),
        streams: parse_streams(&amane::output("pactl -f json list sink-inputs")),
        default_sink,
        default_source,
    }
}

pub fn refresh() {
    let data = fetch();

    if AudioTab::read().data != data {
        AudioTab::write().data = data;
    }
}

pub fn entered() {
    VISIBLE.store(true, Ordering::Relaxed);
    DIRTY.store(true, Ordering::Relaxed);
    drop(AudioTab::read());
}

pub fn left() {
    VISIBLE.store(false, Ordering::Relaxed);
    close_menu();
}

pub fn close_menu() -> bool {
    if AudioTab::read().menu.is_none() {
        return false;
    }

    AudioTab::write().menu = None;

    true
}

// shown at once; the command follows on the next tick, so a drag can't queue up a hundred of them
pub fn set_volume(target: Target, volume: f32) {
    {
        let mut tab = AudioTab::write();
        let data = &mut tab.data;

        match &target {
            Target::Sink(name) => {
                if let Some((device, _)) = data.sinks.iter_mut().find(|(device, _)| &device.name == name) {
                    device.volume = volume;
                }
            }
            Target::Source(name) => {
                if let Some(device) = data.sources.iter_mut().find(|device| &device.name == name) {
                    device.volume = volume;
                }
            }
            Target::Stream(index) => {
                if let Some(stream) = data.streams.iter_mut().find(|stream| stream.index == *index) {
                    stream.volume = volume;
                }
            }
        }
    }

    hold_refresh();

    if let Ok(mut pending) = PENDING.lock() {
        pending.get_or_insert_with(HashMap::new).insert(target, volume);
    }
}

pub fn toggle_mute(target: &Target) {
    let command = match target {
        Target::Sink(name) => format!("pactl set-sink-mute {} toggle", compositor::quote(name)),
        Target::Source(name) => format!("pactl set-source-mute {} toggle", compositor::quote(name)),
        Target::Stream(index) => format!("pactl set-sink-input-mute {index} toggle"),
    };

    amane::spawn(&command);
}

pub fn run_menu_action(action: &MenuAction) {
    let command = match action {
        MenuAction::DefaultSink(name) => format!("pactl set-default-sink {}", compositor::quote(name)),
        MenuAction::DefaultSource(name) => format!("pactl set-default-source {}", compositor::quote(name)),
        MenuAction::Route(index, sink) => format!("pactl move-sink-input {index} {}", compositor::quote(sink)),
        MenuAction::RouteDefault(index) => format!("pactl move-sink-input {index} @DEFAULT_SINK@"),
    };

    amane::spawn(&command);
}

pub fn toggle_menu(menu: Menu) {
    let mut tab = AudioTab::write();

    tab.menu = if tab.menu.as_ref().is_some_and(|open| open.id == menu.id) {
        None
    } else {
        Some(menu)
    };
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_the_loudest_channel() {
        let entry = serde_json::json!({"volume": {"left": {"value_percent": "40%"}, "right": {"value_percent": "75%"}}});

        assert_eq!(volume_of(&entry), 0.75);
    }

    #[test]
    fn drops_monitors_and_unplugged_ports() {
        let sources = r#"[
            {"name": "mic", "description": "Mic", "mute": false, "monitor_source": "", "active_port": "a",
             "ports": [{"name": "a", "availability": "available"}], "volume": {"mono": {"value_percent": "50%"}}},
            {"name": "out.monitor", "description": "Monitor", "mute": false, "monitor_source": "out", "active_port": "a",
             "ports": [{"name": "a", "availability": "available"}], "volume": {}},
            {"name": "gone", "description": "Gone", "mute": false, "monitor_source": "", "active_port": "a",
             "ports": [{"name": "a", "availability": "not available"}], "volume": {}}
        ]"#;

        let names: Vec<String> = parse_sources(sources, "").into_iter().map(|device| device.name).collect();

        assert_eq!(names, ["mic"]);
    }

    #[test]
    fn keeps_an_unplugged_default() {
        let sources = r#"[{"name": "gone", "description": "Gone", "mute": false, "monitor_source": "",
            "active_port": "a", "ports": [{"name": "a", "availability": "not available"}], "volume": {}}]"#;

        assert_eq!(parse_sources(sources, "gone").len(), 1);
    }

    #[test]
    fn finds_the_program_behind_a_pipewire_alsa_name() {
        let properties = serde_json::json!({
            "application.name": "PipeWire ALSA [helium]",
            "node.name": "alsa_playback.helium",
        });
        let tokens = name_tokens(&properties);

        assert_eq!(tokens[0], "helium");
        assert!(entry_matches("helium", "Helium", "helium --flag", "helium"));
        assert!(!entry_matches("helium", "Firefox", "firefox", "firefox"));
    }

    #[test]
    fn hides_generic_subtitles() {
        assert_eq!(subtitle("audio stream", "Helium"), "audio stream");
        assert_eq!(subtitle("Audio-Source", "Helium"), "");
        assert_eq!(subtitle("Helium", "helium"), "");
        assert_eq!(subtitle("ALSA Playback", "Helium"), "ALSA Playback");
    }

    #[test]
    fn prettifies_identifiers() {
        assert_eq!(prettify("some_app-name"), "Some App Name");
    }
}
