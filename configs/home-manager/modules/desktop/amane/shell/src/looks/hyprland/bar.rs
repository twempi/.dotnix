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
use crate::looks::tabs::controls::glyph;

// the room inside an island, either side of its contents
const INSET: f32 = 12.0;

const GLYPH: f32 = 15.0;

// room beside a workspace's number; the one this monitor shows grows into a wider block
const ROOM: f32 = 12.0;

const WIDE: f32 = 26.0;

const BLOCK: f32 = 20.0;

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


// what only the bar's own input changes: the hovered workspace
#[derive(Default)]
pub struct BarState {
    hovered: Option<(String, i64)>,
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

// the list holds only this monitor's workspaces, so active is the one it shows
fn marker(workspace: &Workspace, monitor: &str, hovered: bool, base: &[Color; 16]) -> Rectangle {
    let shown = workspace.active();

    let (fill, color) = if shown && workspace.focused() {
        (base[0x0E], base[0])
    } else if shown {
        (base[2], base[5])
    } else if workspace.urgent() {
        (Color::TRANSPARENT, base[8])
    } else if hovered {
        (Color::TRANSPARENT, base[5])
    } else {
        (Color::TRANSPARENT, base[4])
    };

    // a workspace with only a name shows its name
    let name = if workspace.index() > 0 {
        workspace.index().to_string()
    } else {
        workspace.name().unwrap_or_default().to_string()
    };

    let text = label(name, TEXT - 1.0, color).weight(Weight::Bold);
    let room = if shown { WIDE } else { ROOM };
    let width = grown(monitor, workspace.id(), (ui::width_of(&text) + room).round());
    let id = workspace.id();
    let monitor = monitor.to_string();

    Rectangle::new()
        .width(width)
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
        .child(
            Rectangle::new()
                .width(width)
                .height(BLOCK)
                .fill(fill)
                .align_child(Center, Center)
                .child(text),
        )
}

// this monitor's workspaces with windows, and the empty one it may be showing
fn workspaces(monitor: &str, base: &[Color; 16]) -> Rectangle {
    let workspaces = Workspaces::read();
    let state = BarState::read();

    let mut list: Vec<&Workspace> = workspaces
        .list()
        .iter()
        .filter(|workspace| workspace.output() == Some(monitor) && (workspace.windows() > 0 || workspace.active()))
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

// the song alone, its controls are in the panel it opens; nothing at all while no player is up
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

    let row = Row::new(children![
        glyph(MUSIC, GLYPH, base[0x0E]),
        Rectangle::new()
            .width(width)
            .height(Parent)
            .align_child(Start, Center)
            .cursor(Pointer)
            .on_click(|_| panel::open(Page::Home, true))
            .child(text.elide()),
    ])
    .gap(8.0)
    .align(Center);

    Some(island(row, base))
}

// the right island's unit, an icon alone; the panel and the hover details have the values
fn module(code: &str, color: Color) -> Rectangle {
    Rectangle::new()
        .width(GLYPH)
        .height(Parent)
        .align_child(Center, Center)
        .cursor(Pointer)
        .child(glyph(code, GLYPH, color))
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

    Some(opens(module(code, color), Page::Bluetooth))
}

fn battery(battery: &BatteryState, base: &[Color; 16]) -> Rectangle {
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

    module(code, color)
}

fn status(monitor: &str, base: &[Color; 16]) -> Rectangle {
    let accent = base[0x0E];
    let stats = Stats::read();
    let volume = Volume::read();
    let network = Network::read();
    let brightness = Brightness::read();
    let dnd = NotificationCenter::read().dnd;
    let unread = Notifications::read().list().len();

    // the clock changes once a minute
    let _tick = Tick::read();

    let mut right: Vec<Box<dyn Widget>> = Vec::new();

    if Tray::read().items.iter().any(|item| item.status != "Passive") {
        right.push(Box::new(super::tray::icons(monitor)));
    }

    if let Some(bluetooth) = bluetooth(base) {
        right.push(Box::new(bluetooth));
    }

    let (code, color) = match network.link() {
        Link::Offline => (WIFI_OFF, base[3]),
        Link::Wifi => (WIFI, accent),
        Link::Wired => (ETHERNET, accent),
        Link::Other => (NETWORK, accent),
    };
    right.push(Box::new(detailed(
        opens(module(code, color), Page::Network),
        Detail::Network,
        monitor,
    )));

    let (code, color) = if volume.muted {
        (VOLUME_OFF, base[8])
    } else if volume.bluetooth {
        (HEADPHONES, accent)
    } else {
        (VOLUME, accent)
    };
    right.push(Box::new(
        module(code, color)
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
            module(SUN, accent).on_scroll(brightness_scrolled),
        ));
    }

    if let Some(battery_state) = &stats.battery {
        right.push(Box::new(detailed(
            battery(battery_state, base),
            Detail::Battery,
            monitor,
        )));
    }

    // only while there are notifications, last before the clock
    if unread > 0 {
        let bell = if dnd { BELL_OFF } else { BELL };
        right.push(Box::new(opens(module(bell, accent), Page::Notifications)));
    }

    right.push(Box::new(Rectangle::new().width(1.0).height(14.0).fill(base[2])));

    let clock = label(chrono::Local::now().format("%H:%M").to_string(), TEXT, accent).weight(Weight::Bold);

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
