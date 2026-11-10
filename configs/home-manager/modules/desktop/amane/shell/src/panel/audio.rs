use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Mutex;
use std::thread;
use std::time::{Duration, Instant};

use amane::{
    Apps, Center, Column, End, Image, Padding, Parent, Pointer, Rectangle, Row, Service, Weight, Widget,
    children,
};
use serde_json::Value;

use super::controls::{
    CONTROL, CONTROL_SM, FONT_BODY, FONT_CAPTION, FONT_TITLE, RADIUS_LG, RADIUS_MD, SPACE_MD, SPACE_SM,
    SPACE_XS, Ui, Variant, elide_middle, glyph, hoverable, icon_button, label, scroll_view, sized_card,
    slider,
};
use crate::icons::Icons;
use crate::ui::{self, height_of, width_of};

const GLYPH_VOLUME: &str = "\u{EB51}";
const GLYPH_VOLUME_MUTE: &str = "\u{F1C3}";
const GLYPH_MIC: &str = "\u{EAF0}";
const GLYPH_MIC_MUTE: &str = "\u{ED16}";
const GLYPH_MORE: &str = "\u{EA94}";
const GLYPH_HEADPHONES: &str = "\u{EABD}";
const GLYPH_CHECK: &str = "\u{EA5E}";

const TICK: Duration = Duration::from_millis(33);
const HOLD: Duration = Duration::from_millis(250);
const DEVICE_CARD: f32 = 104.0;
const ROW: f32 = 54.0;
const ICON: f32 = 28.0;
const SLIDER_COMPACT: f32 = 20.0;
const VALUE_WIDTH: f32 = 60.0;
const MENU_PADDING: f32 = 6.0;
const MENU_ITEM: f32 = 32.0;
const MENU_SEPARATOR: f32 = 10.0;
const MENU_SLOT: f32 = 16.0;
const MENU_SIDES: f32 = 16.0;
const MENU_OVERHANG: f32 = 8.0;
const DEFAULT_DEVICE: &str = "Default device";

static VISIBLE: AtomicBool = AtomicBool::new(false);
static DIRTY: AtomicBool = AtomicBool::new(false);
static PENDING: Mutex<Option<HashMap<Target, f32>>> = Mutex::new(None);
static HOLD_UNTIL: Mutex<Option<Instant>> = Mutex::new(None);

#[derive(Default, Clone, PartialEq)]
struct Device {
    name: String,
    description: String,
    volume: f32,
    muted: bool,
}

#[derive(Default, Clone, PartialEq)]
struct Stream {
    index: u32,
    name: String,
    subtitle: String,
    icon: Option<PathBuf>,
    sink: u32,
    volume: f32,
    muted: bool,
}

#[derive(Default, Clone, PartialEq)]
struct AudioData {
    sinks: Vec<(Device, u32)>,
    sources: Vec<Device>,
    streams: Vec<Stream>,
    default_sink: String,
    default_source: String,
}

impl AudioData {
    fn default_sink_device(&self) -> Option<&Device> {
        self.sinks.iter().map(|(device, _)| device).find(|device| device.name == self.default_sink)
    }

    fn default_source_device(&self) -> Option<&Device> {
        self.sources.iter().find(|device| device.name == self.default_source)
    }

    fn default_sink_index(&self) -> u32 {
        self.sinks
            .iter()
            .find(|(device, _)| device.name == self.default_sink)
            .map_or(0, |(_, index)| *index)
    }
}

#[derive(Clone, PartialEq, Eq, Hash)]
enum Target {
    Sink(String),
    Source(String),
    Stream(u32),
}

#[derive(Clone)]
enum MenuAction {
    DefaultSink(String),
    DefaultSource(String),
    Route(u32, String),
    RouteDefault(u32),
}

#[derive(Clone)]
struct MenuItem {
    text: String,
    selected: bool,
    action: Option<MenuAction>,
}

#[derive(Clone)]
struct Menu {
    id: String,
    items: Vec<MenuItem>,
    center_x: f32,
    y: f32,
    min_width: f32,
    max_width: f32,
}

#[derive(Default)]
pub struct AudioTab {
    data: AudioData,
    menu: Option<Menu>,
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
            Target::Sink(name) => format!("pactl set-sink-volume {} {percent}%", ui::quote(&name)),
            Target::Source(name) => format!("pactl set-source-volume {} {percent}%", ui::quote(&name)),
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
fn available(entry: &Value, default: &str) -> bool {
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

fn subtitle(media: &str, name: &str) -> String {
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

fn refresh() {
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
fn set_volume(target: Target, volume: f32) {
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

fn toggle_mute(target: &Target) {
    let command = match target {
        Target::Sink(name) => format!("pactl set-sink-mute {} toggle", ui::quote(name)),
        Target::Source(name) => format!("pactl set-source-mute {} toggle", ui::quote(name)),
        Target::Stream(index) => format!("pactl set-sink-input-mute {index} toggle"),
    };

    amane::spawn(&command);
}

fn run_menu_action(action: &MenuAction) {
    let command = match action {
        MenuAction::DefaultSink(name) => format!("pactl set-default-sink {}", ui::quote(name)),
        MenuAction::DefaultSource(name) => format!("pactl set-default-source {}", ui::quote(name)),
        MenuAction::Route(index, sink) => format!("pactl move-sink-input {index} {}", ui::quote(sink)),
        MenuAction::RouteDefault(index) => format!("pactl move-sink-input {index} @DEFAULT_SINK@"),
    };

    amane::spawn(&command);
}

fn toggle_menu(menu: Menu) {
    let mut tab = AudioTab::write();

    tab.menu = if tab.menu.as_ref().is_some_and(|open| open.id == menu.id) {
        None
    } else {
        Some(menu)
    };
}

fn device_card(ui: &Ui, data: &AudioData, input: bool, width: f32, center_x: f32) -> Rectangle {
    let c = &ui.c;
    let inner = width - SPACE_MD * 2.0;
    let (title, device) = if input {
        ("Input", data.default_source_device())
    } else {
        ("Output", data.default_sink_device())
    };

    let name = device.map(|device| device.name.clone()).unwrap_or_default();
    let description = device.map_or("No device", |device| device.description.as_str());
    let volume = device.map_or(0.0, |device| device.volume);
    let muted = device.is_some_and(|device| device.muted);
    let target = if input { Target::Source(name.clone()) } else { Target::Sink(name.clone()) };

    let value_width = width_of(&label("888%", FONT_BODY, c.on_surface).weight(Weight::Bold));
    let slider_width = inner - SPACE_SM - value_width - SPACE_SM - CONTROL_SM;

    let items: Vec<MenuItem> = if input {
        data.sources
            .iter()
            .map(|device| MenuItem {
                text: device.description.clone(),
                selected: device.name == data.default_source,
                action: Some(MenuAction::DefaultSource(device.name.clone())),
            })
            .collect()
    } else {
        data.sinks
            .iter()
            .map(|(device, _)| MenuItem {
                text: device.description.clone(),
                selected: device.name == data.default_sink,
                action: Some(MenuAction::DefaultSink(device.name.clone())),
            })
            .collect()
    };

    let min_width = 280.0f32.min(width);
    let menu = Menu {
        id: title.to_string(),
        items,
        center_x,
        y: SPACE_MD + 1.0 + CONTROL + SPACE_XS,
        min_width,
        max_width: 420.0,
    };

    let (muted_glyph, normal_glyph) = if input {
        (GLYPH_MIC_MUTE, GLYPH_MIC)
    } else {
        (GLYPH_VOLUME_MUTE, GLYPH_VOLUME)
    };

    let mute_target = target.clone();

    let body = Column::new(children![
        Row::new(children![
            Column::new(children![
                label(title, FONT_TITLE, c.on_surface).weight(Weight::Bold),
                label(elide_middle(description, FONT_CAPTION, inner - CONTROL_SM - SPACE_SM), FONT_CAPTION, c.variant),
            ])
            .width(Parent),
            icon_button(ui, format!("audio:menu:{title}"), GLYPH_MORE, (CONTROL_SM, 13.0, RADIUS_MD), Variant::Ghost)
                .on_click(move |_| toggle_menu(menu.clone())),
        ])
        .width(Parent)
        .height(CONTROL)
        .gap(SPACE_SM)
        .align(Center),
        Row::new(children![
            slider(ui, format!("audio:volume:{title}"), (slider_width, CONTROL), volume, move |value| {
                set_volume(target.clone(), value);
            }),
            Rectangle::new().width(value_width).height(CONTROL).align_child(End, Center).child(
                label(format!("{}%", (volume * 100.0).round() as i32), FONT_BODY, c.on_surface).weight(Weight::Bold),
            ),
            icon_button(
                ui,
                format!("audio:mute:{title}"),
                if muted { muted_glyph } else { normal_glyph },
                (CONTROL_SM, FONT_BODY, RADIUS_MD),
                if muted { Variant::Destructive } else { Variant::Default },
            )
            .on_click(move |_| toggle_mute(&mute_target)),
        ])
        .width(Parent)
        .height(CONTROL)
        .gap(SPACE_SM)
        .align(Center),
    ])
    .width(Parent)
    .gap(SPACE_XS);

    sized_card(ui, width, DEVICE_CARD).child(body)
}

fn app_icon(ui: &Ui, stream: &Stream) -> Rectangle {
    let frame = Rectangle::new().width(ICON).height(ICON).radius(RADIUS_MD).clip();

    match &stream.icon {
        Some(path) => frame.fill(Image::contain(path).thumbnail(56, 56)),
        None => frame.fill(ui.c.surface),
    }
}

fn program_row(ui: &Ui, data: &AudioData, stream: &Stream, width: f32, menu_y: f32) -> Rectangle {
    let c = &ui.c;
    let index = stream.index;
    let target = Target::Stream(index);
    let mute_target = target.clone();

    let name = label(stream.name.clone(), FONT_BODY, c.on_surface).weight(Weight::Bold);

    let mut title: Vec<Box<dyn Widget>> = vec![Box::new(name)];

    if !stream.subtitle.is_empty() {
        title.push(Box::new(
            Rectangle::new()
                .width(Parent)
                .height(18.0)
                .align_child(amane::Start, Center)
                .child(label(stream.subtitle.clone(), FONT_CAPTION, c.variant).elide()),
        ));
    }

    let inner = width - SPACE_MD * 2.0 - ICON - SPACE_SM - SPACE_MD - CONTROL_SM * 2.0 - SPACE_XS;

    let pinned = stream.sink != data.default_sink_index();
    let mut items = vec![
        MenuItem {
            text: DEFAULT_DEVICE.to_string(),
            selected: !pinned,
            action: Some(MenuAction::RouteDefault(index)),
        },
        MenuItem {
            text: String::new(),
            selected: false,
            action: None,
        },
    ];

    items.extend(data.sinks.iter().map(|(device, sink)| MenuItem {
        text: device.description.clone(),
        selected: pinned && *sink == stream.sink,
        action: Some(MenuAction::Route(index, device.name.clone())),
    }));

    let menu = Menu {
        id: format!("route:{index}"),
        items,
        center_x: width - CONTROL_SM - SPACE_XS - CONTROL_SM / 2.0 - SPACE_MD + SPACE_MD,
        y: menu_y,
        min_width: 240.0,
        max_width: 420.0,
    };

    let routing = icon_button(
        ui,
        format!("audio:route:{index}"),
        GLYPH_HEADPHONES,
        (CONTROL_SM, FONT_BODY, RADIUS_MD),
        if pinned { Variant::Outline } else { Variant::Ghost },
    )
    .on_click(move |_| toggle_menu(menu.clone()));

    let mute = icon_button(
        ui,
        format!("audio:stream-mute:{index}"),
        if stream.muted { GLYPH_VOLUME_MUTE } else { GLYPH_VOLUME },
        (CONTROL_SM, FONT_BODY, RADIUS_MD),
        if stream.muted { Variant::Destructive } else { Variant::Default },
    )
    .on_click(move |_| toggle_mute(&mute_target));

    let content = Row::new(children![
        Row::new(children![
            app_icon(ui, stream),
            Column::new(children![
                Row::new(children![
                    Row::new(title).width(Parent).height(18.0).gap(SPACE_XS).align(Center),
                    Rectangle::new().width(VALUE_WIDTH).height(18.0).align_child(End, Center).child(
                        label(format!("{}%", (stream.volume * 100.0).round() as i32), FONT_BODY, c.on_surface)
                            .weight(Weight::Bold),
                    ),
                ])
                .width(Parent)
                .height(18.0)
                .gap(SPACE_SM)
                .align(Center),
                slider(ui, format!("audio:stream:{index}"), (inner, SLIDER_COMPACT), stream.volume, move |value| {
                    set_volume(target.clone(), value);
                }),
            ])
            .width(Parent),
        ])
        .width(Parent)
        .height(CONTROL_SM + SPACE_XS + 2.0)
        .gap(SPACE_SM)
        .align(Center),
        Row::new(children![routing, mute]).gap(SPACE_XS).align(Center),
    ])
    .width(Parent)
    .height(CONTROL_SM + SPACE_XS + 2.0)
    .gap(SPACE_MD)
    .align(Center);

    Rectangle::new()
        .width(width)
        .height(ROW)
        .radius(RADIUS_MD)
        .fill(c.surface)
        .padding(Padding {
            left: SPACE_MD,
            right: SPACE_MD,
            top: SPACE_SM,
            bottom: SPACE_SM,
        })
        .child(content)
}

fn empty_card(ui: &Ui, width: f32) -> Rectangle {
    let body = Column::new(children![
        label("No Application Audio", FONT_BODY, ui.c.on_surface).weight(Weight::Bold),
        label("No application playback streams are currently available.", FONT_CAPTION, ui.c.variant),
    ])
    .width(Parent)
    .gap(SPACE_XS);

    Rectangle::new()
        .width(width)
        .height(height_of(&body) + SPACE_MD * 2.0)
        .radius(RADIUS_MD)
        .fill(ui.c.surface)
        .padding(SPACE_MD)
        .child(body)
}

pub fn view(ui: &Ui, width: f32, height: f32) -> Column {
    let tab = AudioTab::read();
    let data = &tab.data;
    let card_width = (width - SPACE_MD) / 2.0;

    let cards = Row::new(children![
        device_card(ui, data, false, card_width, card_width / 2.0),
        device_card(ui, data, true, card_width, card_width + SPACE_MD + card_width / 2.0),
    ])
    .width(width)
    .height(DEVICE_CARD)
    .gap(SPACE_MD);

    let apps_height = height - DEVICE_CARD - SPACE_MD;
    let title = label("Application Volumes", FONT_TITLE, ui.c.on_surface).weight(Weight::Bold);
    let title_height = height_of(&title);
    let list_height = apps_height - SPACE_MD * 2.0 - title_height - SPACE_SM;
    let list_top = DEVICE_CARD + SPACE_MD + SPACE_MD + title_height + SPACE_SM;
    let offset = ui.scroll_offset("audio-programs");

    let list = scroll_view(ui, "audio-programs", (width - SPACE_MD * 2.0, list_height), |list_width| {
        if data.streams.is_empty() {
            return Column::new(children![empty_card(ui, list_width)]).width(list_width);
        }

        let rows: Vec<Box<dyn Widget>> = data
            .streams
            .iter()
            .enumerate()
            .map(|(position, stream)| {
                let menu_y = list_top + position as f32 * (ROW + SPACE_SM) + SPACE_SM + CONTROL_SM + SPACE_XS - offset;

                Box::new(program_row(ui, data, stream, list_width, menu_y)) as Box<dyn Widget>
            })
            .collect();

        Column::new(rows).width(list_width).gap(SPACE_SM)
    });

    let apps = sized_card(ui, width, apps_height).child(
        Column::new(children![title, list]).width(Parent).height(Parent).gap(SPACE_SM),
    );

    Column::new(children![cards, apps]).width(width).height(height).gap(SPACE_MD)
}

fn menu_item(ui: &Ui, item: &MenuItem, index: usize, width: f32) -> Box<dyn Widget> {
    let c = &ui.c;

    let Some(action) = item.action.clone() else {
        return Box::new(
            Rectangle::new().width(Parent).height(MENU_SEPARATOR).align_child(Center, Center).child(
                Rectangle::new().width(Parent).height(1.0).fill(c.outline),
            ),
        );
    };

    let key = format!("menu:{index}");
    let hovered = ui.hovered(&key);
    let color = if hovered { c.on_hover } else { c.on_surface };
    let text_width = width - MENU_SIDES - MENU_SLOT;

    let slot = Rectangle::new().width(MENU_SLOT).height(MENU_ITEM).align_child(amane::Start, Center);
    let slot = if item.selected { slot.child(glyph(GLYPH_CHECK, FONT_CAPTION - 1.0, color)) } else { slot };

    let row = Rectangle::new()
        .width(Parent)
        .height(MENU_ITEM)
        .fill(if hovered { c.hover } else { amane::Color::TRANSPARENT })
        .cursor(Pointer)
        .padding(Padding {
            left: MENU_SIDES / 2.0,
            right: MENU_SIDES / 2.0,
            ..Padding::default()
        })
        .on_click(move |_| {
            run_menu_action(&action);
            close_menu();
            DIRTY.store(true, Ordering::Relaxed);
        })
        .child(
            Row::new(children![
                slot,
                label(elide_middle(&item.text, FONT_CAPTION, text_width), FONT_CAPTION, color),
            ])
            .height(MENU_ITEM)
            .align(Center),
        );

    Box::new(hoverable(row, key))
}

// on top of the panel, free to hang over its edge as Noctalia's popup does
pub fn menu_layer(ui: &Ui, panel_width: f32, panel_height: f32, body_x: f32, body_y: f32) -> Vec<Box<dyn Widget>> {
    let Some(menu) = AudioTab::read().menu.clone() else {
        return Vec::new();
    };

    let text_width = menu
        .items
        .iter()
        .map(|item| width_of(&label(item.text.clone(), FONT_CAPTION, ui.c.on_surface)))
        .fold(0.0, f32::max);

    let width = (text_width + MENU_SLOT + MENU_SIDES + MENU_PADDING * 2.0)
        .clamp(menu.min_width, menu.max_width);

    let height = menu
        .items
        .iter()
        .map(|item| if item.action.is_some() { MENU_ITEM } else { MENU_SEPARATOR })
        .sum::<f32>()
        + MENU_PADDING * 2.0;

    let x = (body_x + menu.center_x - width / 2.0)
        .min(panel_width + MENU_OVERHANG - width)
        .max(-MENU_OVERHANG);
    let y = (body_y + menu.y).min(panel_height + MENU_OVERHANG - height);

    let items: Vec<Box<dyn Widget>> = menu
        .items
        .iter()
        .enumerate()
        .map(|(index, item)| menu_item(ui, item, index, width))
        .collect();

    vec![
        Box::new(Rectangle::new().width(panel_width).height(panel_height).on_click(|_| {
            close_menu();
        })),
        Box::new(
            Rectangle::new()
                .width(width)
                .height(height)
                .radius(RADIUS_LG)
                .fill(ui.c.surface)
                .border(1.0, ui.c.outline)
                .padding(MENU_PADDING)
                .translate(x, y)
                .on_click(|_| {})
                .child(Column::new(items).width(Parent)),
        ),
    ]
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
