use std::sync::{Mutex, PoisonError};
use std::time::Duration;

use amane::{
    Animation, Bluetooth, Brightness, Button, Center, Color, Full, Layer, LayerWindow, Link, Media,
    Monitor, Network, Notifications, Padding, Parent, Pointer, Rectangle, Row, Service, SpaceBetween,
    Stack, Start, Vertical, Weight, Widget, Workspace, Workspaces, Zone, children,
};

use crate::logic::notifications::{NotificationCenter, Page, Tick};
use crate::logic::stats::{BatteryState, Detail, Stats, Volume, brightness_scrolled, volume_scrolled};
use crate::logic::theme::Theme;
use crate::logic::tray::{self, Tray};
use crate::looks::hyprland::panel;
use crate::looks::hyprland::ui::{self, GAP, ISLAND, TEXT, frame, label};
use crate::looks::tabs::controls::{glyph, with_alpha};

// the room inside an island, either side of its contents
const INSET: f32 = 12.0;

const GLYPH: f32 = 15.0;

// a workspace is a dot; the one this monitor shows grows into a block
const DOT: f32 = 8.0;

const BLOCK: f32 = 26.0;

const GROW: Duration = Duration::from_millis(180);

const MEDIA_TEXT: f32 = 320.0;

const BELL: &str = "\u{EA35}";

const BELL_OFF: &str = "\u{ECE9}";

const BLUETOOTH: &str = "\u{EA37}";

const BLUETOOTH_OFF: &str = "\u{ECEB}";

const BLUETOOTH_CONNECTED: &str = "\u{ECEA}";

const WIFI: &str = "\u{EB52}";

const WIFI_OFF: &str = "\u{ECFA}";

const ETHERNET: &str = "\u{ECCC}";

const NETWORK: &str = "\u{F09F}";

const VOLUME: &str = "\u{EB51}";

const VOLUME_OFF: &str = "\u{F1C3}";

const HEADPHONES: &str = "\u{EABD}";

const SUN: &str = "\u{EB30}";

const CHARGING: &str = "\u{EA33}";

// battery, battery-1 to battery-4: empty to full
const BATTERY: [&str; 5] = ["\u{EA34}", "\u{EA2F}", "\u{EA30}", "\u{EA31}", "\u{EA32}"];

const MUSIC: &str = "\u{EAFC}";

const PREVIOUS: &str = "\u{ED4C}";

const PLAY: &str = "\u{ED46}";

const PAUSE: &str = "\u{ED45}";

const NEXT: &str = "\u{ED4B}";

// what only the bar's own input changes: the hovered workspace and the battery's time left
#[derive(Default)]
pub struct BarState {
    hovered: Option<(String, i64)>,
    battery_alt: bool,
}

impl Service for BarState {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

static WIDTHS: Mutex<Vec<((String, i64), Animation)>> = Mutex::new(Vec::new());

// the marker's width on its way to the target, per monitor, so focus changes grow and shrink
fn grown(monitor: &str, id: i64, target: f32) -> f32 {
    let mut widths = WIDTHS.lock().unwrap_or_else(PoisonError::into_inner);

    let index = match widths.iter().position(|((name, key), _)| name == monitor && *key == id) {
        Some(index) => index,
        None => {
            widths.push(((monitor.to_string(), id), Animation::new(target).duration(GROW)));
            widths.len() - 1
        }
    };

    widths[index].1.to(target);
    widths[index].1.value()
}

fn island(content: Row, base: &[Color; 16]) -> Rectangle {
    let width = (ui::width_of(&content) + INSET * 2.0).ceil();

    frame(Rectangle::new().width(width).height(ISLAND), base)
        .padding(Padding {
            left: INSET,
            right: INSET,
            ..Padding::default()
        })
        .align_child(Start, Center)
        .child(content.height(Parent))
}

fn marker(workspace: &Workspace, monitor: &str, hovered: bool, base: &[Color; 16]) -> Rectangle {
    let accent = base[0x0E];
    let here = workspace.active() && workspace.output() == Some(monitor);

    let (target, color) = if here && workspace.focused() {
        (BLOCK, accent)
    } else if here {
        (BLOCK, base[5])
    } else if workspace.active() {
        // the workspace the other monitor shows
        (DOT, with_alpha(accent, 0.5))
    } else if hovered {
        (DOT, base[5])
    } else {
        (DOT, base[3])
    };

    let width = grown(monitor, workspace.id(), target);
    let id = workspace.id();
    let monitor = monitor.to_string();

    Rectangle::new()
        .width(width + DOT)
        .height(Parent)
        .align_child(Center, Center)
        .cursor(Pointer)
        .on_click(move |_| Workspaces::focus(id))
        .on_hover(move |inside| {
            let mut state = BarState::write();

            if inside {
                state.hovered = Some((monitor.clone(), id));
            } else if state.hovered == Some((monitor.clone(), id)) {
                state.hovered = None;
            }
        })
        .child(Rectangle::new().width(width).height(DOT).fill(color))
}

// only workspaces with windows, and the empty one a monitor may be showing
fn workspaces(monitor: &str, base: &[Color; 16]) -> Rectangle {
    let workspaces = Workspaces::read();
    let state = BarState::read();

    let mut list: Vec<&Workspace> = workspaces
        .list()
        .iter()
        .filter(|workspace| workspace.windows() > 0 || workspace.active())
        .collect();
    list.sort_by_key(|workspace| (workspace.index() == 0, workspace.index(), workspace.name().map(String::from)));

    let markers: Vec<Box<dyn Widget>> = list
        .into_iter()
        .map(|workspace| {
            let hovered = state.hovered.as_ref() == Some(&(monitor.to_string(), workspace.id()));
            Box::new(marker(workspace, monitor, hovered, base)) as Box<dyn Widget>
        })
        .collect();

    island(Row::new(markers), base)
}

// the song and its controls; nothing at all while no player is up
fn media(base: &[Color; 16]) -> Option<Rectangle> {
    let media = Media::read();
    media.active()?;

    let song = if media.artist().is_empty() {
        media.title().to_string()
    } else {
        format!("{} – {}", media.title(), media.artist())
    };

    let text = label(song, TEXT, base[5]);
    let width = ui::width_of(&text).min(MEDIA_TEXT).ceil();

    let button = |code: &str, color: Color, action: fn()| {
        Rectangle::new()
            .width(22.0)
            .height(Parent)
            .align_child(Center, Center)
            .cursor(Pointer)
            .on_click(move |_| action())
            .child(glyph(code, GLYPH, color))
    };

    let play = if media.playing() { PAUSE } else { PLAY };

    let row = Row::new(children![
        glyph(MUSIC, GLYPH, base[0x0E]),
        Rectangle::new()
            .width(width)
            .height(Parent)
            .align_child(Start, Center)
            .cursor(Pointer)
            .on_click(|_| panel::open(Page::Home, true))
            .child(text.elide()),
        Row::new(children![
            button(PREVIOUS, base[5], Media::previous),
            button(play, base[0x0E], Media::play_pause),
            button(NEXT, base[5], Media::next),
        ])
        .height(Parent),
    ])
    .gap(8.0)
    .align(Center);

    Some(island(row, base))
}

// the right island's unit: an icon, then its value when it has one
fn module(code: &str, value: Option<String>, color: Color, base: &[Color; 16]) -> Rectangle {
    let mut parts: Vec<Box<dyn Widget>> = vec![Box::new(glyph(code, GLYPH, color))];

    if let Some(value) = value {
        parts.push(Box::new(label(value, TEXT, base[5])));
    }

    let row = Row::new(parts).gap(6.0).align(Center);

    Rectangle::new()
        .width(ui::width_of(&row).ceil())
        .height(Parent)
        .align_child(Start, Center)
        .cursor(Pointer)
        .child(row)
}

fn opens(module: Rectangle, page: Page) -> Rectangle {
    module.on_click(move |button| {
        if button == Button::Left {
            panel::open(page, false);
        }
    })
}

// shows the module's details under the pointer while it hovers
fn detailed(module: Rectangle, detail: Detail, monitor: &str) -> Rectangle {
    let monitor = monitor.to_string();

    module.on_hover(move |inside| tray::module_hovered(detail, inside, &monitor))
}

fn bluetooth(base: &[Color; 16]) -> Option<Rectangle> {
    let bluetooth = Bluetooth::read();

    if !bluetooth.available() {
        return None;
    }

    let connected = bluetooth.devices().iter().find(|device| device.connected());

    let (code, color) = match (bluetooth.powered(), connected) {
        (false, _) => (BLUETOOTH_OFF, base[3]),
        (true, Some(_)) => (BLUETOOTH_CONNECTED, base[0x0E]),
        (true, None) => (BLUETOOTH, base[0x0E]),
    };

    let name = connected.map(|device| device.name().chars().take(16).collect());

    Some(opens(module(code, name, color, base), Page::Bluetooth))
}

fn battery(battery: &BatteryState, alt: bool, base: &[Color; 16]) -> Rectangle {
    // the states sway's bar uses: warning at 30, critical at 20
    let critical = battery.capacity <= 20;
    let warning = !critical && battery.capacity <= 30;
    let charging = matches!(battery.status, "charging" | "plugged");

    let code = if charging {
        CHARGING
    } else {
        BATTERY[(usize::from(battery.capacity) * BATTERY.len() / 101).min(BATTERY.len() - 1)]
    };

    let color = if critical {
        base[8]
    } else if warning {
        base[9]
    } else {
        base[0x0E]
    };

    let value = if alt { battery.time.clone() } else { format!("{}%", battery.capacity) };

    module(code, Some(value), color, base).on_click(|button| {
        if button == Button::Left {
            let mut state = BarState::write();
            state.battery_alt = !state.battery_alt;
        }
    })
}

fn status(monitor: &str, base: &[Color; 16]) -> Rectangle {
    let accent = base[0x0E];
    let stats = Stats::read();
    let volume = Volume::read();
    let network = Network::read();
    let brightness = Brightness::read();
    let state = BarState::read();
    let dnd = NotificationCenter::read().dnd;
    let unread = Notifications::read().list().len();

    // the clock changes once a minute
    let _tick = Tick::read();

    let mut right: Vec<Box<dyn Widget>> = Vec::new();

    if Tray::read().items.iter().any(|item| item.status != "Passive") {
        right.push(Box::new(super::tray::icons(monitor)));
    }

    let bell = if dnd { BELL_OFF } else { BELL };
    let count = (unread > 0).then(|| unread.to_string());
    right.push(Box::new(opens(module(bell, count, accent, base), Page::Notifications)));

    if let Some(bluetooth) = bluetooth(base) {
        right.push(Box::new(bluetooth));
    }

    let (code, color, down) = match network.link() {
        Link::Offline => (WIFI_OFF, base[3], "off"),
        Link::Wifi => (WIFI, accent, stats.down.as_str()),
        Link::Wired => (ETHERNET, accent, stats.down.as_str()),
        Link::Other => (NETWORK, accent, stats.down.as_str()),
    };
    // as wide as "999.9Mb/s" in the monospaced font, so the island doesn't twitch with the rate
    right.push(Box::new(detailed(
        opens(module(code, Some(format!("{down:>9}")), color, base), Page::Network),
        Detail::Network,
        monitor,
    )));

    let (code, color, level) = if volume.muted {
        (VOLUME_OFF, base[8], String::from("muted"))
    } else if volume.bluetooth {
        (HEADPHONES, accent, format!("{}%", volume.percent))
    } else {
        (VOLUME, accent, format!("{}%", volume.percent))
    };
    right.push(Box::new(
        module(code, Some(level), color, base)
            .on_click(|button| match button {
                Button::Left => panel::open(Page::Audio, false),
                Button::Middle => amane::spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle"),
                // the sway bar's right click, kept as configured
                Button::Right => amane::spawn("pulseaudio"),
            })
            .on_scroll(volume_scrolled),
    ));

    if brightness.present() {
        right.push(Box::new(
            module(SUN, Some(format!("{}%", brightness.percent())), accent, base).on_scroll(brightness_scrolled),
        ));
    }

    if let Some(battery_state) = &stats.battery {
        right.push(Box::new(detailed(
            battery(battery_state, state.battery_alt, base),
            Detail::Battery,
            monitor,
        )));
    }

    right.push(Box::new(Rectangle::new().width(1.0).height(14.0).fill(base[2])));

    let clock = label(chrono::Local::now().format("%a %b %-d  %H:%M").to_string(), TEXT, accent).weight(Weight::Bold);

    right.push(Box::new(opens(
        Rectangle::new()
            .width(ui::width_of(&clock).ceil())
            .height(Parent)
            .align_child(Start, Center)
            .cursor(Pointer)
            .child(clock),
        Page::Home,
    )));

    island(Row::new(right).gap(14.0).align(Center), base)
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    let base = Theme::read().base;

    let mut layers: Vec<Box<dyn Widget>> = vec![Box::new(
        Row::new(children![workspaces(&monitor.name, &base), status(&monitor.name, &base)])
            .width(Parent)
            .height(Parent)
            .justify(SpaceBetween),
    )];

    // the middle of the screen, however wide the other two islands are
    if let Some(media) = media(&base) {
        layers.push(Box::new(
            Rectangle::new()
                .width(Parent)
                .height(Parent)
                .align_child(Center, Start)
                .child(media),
        ));
    }

    // the window is clear, so the islands float; it reserves the gap above them too
    LayerWindow::new()
        .width(Full)
        .height(GAP + ISLAND)
        .anchor_vertical(Vertical::Top)
        .layer(Layer::Top)
        .space(Zone::Reserve)
        .namespace("amane-bar")
        .child(
            Rectangle::new()
                .width(Parent)
                .height(Parent)
                .padding(Padding {
                    top: GAP,
                    left: GAP,
                    right: GAP,
                    ..Padding::default()
                })
                .on_move(|point| tray::track_pointer(point.x))
                .child(Stack::new(layers).width(Parent).height(Parent)),
        )
}
