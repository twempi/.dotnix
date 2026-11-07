use std::time::Duration;

use amane::{
    Brightness, Button, Center, Color, Column, Full, Layer, LayerWindow, Link, Monitor, Network,
    Padding, Parent, Rectangle, Row, Scroll, Service, SpaceBetween, Start, Text, Vertical, Weight,
    Widget, Workspace, Workspaces, Zone, children,
};

use crate::notifications;
use crate::stats::{BatteryState, Clock, Stats, SwayMode, Volume};
use crate::theme::Theme;
use crate::tray::{self, Tray};
use crate::ui::{self, BAR_FONT, BAR_HEIGHT, BAR_TEXT};

// css pt to px: waybar's 2pt borders, 3pt paddings and margins
const BORDER: f32 = 3.0;
const GAP: f32 = 4.0;

const BATTERY_ICONS: [&str; 10] = [
    "\u{F008E}", "\u{F007A}", "\u{F007B}", "\u{F007D}", "\u{F007E}",
    "\u{F007F}", "\u{F0080}", "\u{F0081}", "\u{F0082}", "\u{F0079}",
];
const WIFI_ICONS: [&str; 5] = ["\u{F092B}", "\u{F091F}", "\u{F0922}", "\u{F0925}", "\u{F0928}"];

// what only the bar's own input changes: the hovered workspace and battery's format-alt
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

fn label(content: impl Into<String>, color: Color) -> Text {
    ui::text(content, BAR_TEXT, BAR_FONT)
        .color(color)
        .weight(Weight::from(900))
}

/*
 * a waybar module: "[icon]" in the module color, the value in the text color,
 * 3pt right padding and a 2pt bottom border
 */
fn module(icon: &str, icon_color: Color, value: String, border: Color, text: Color) -> Rectangle {
    let content = Row::new(children![label(format!("[{icon}]"), icon_color), label(format!(" {value}"), text)]);

    let width = ui::width_of(&content) + GAP;

    Rectangle::new().width(width).height(Parent).child(Column::new(children![
        Rectangle::new()
            .width(width)
            .height(Parent)
            .align_child(Start, Center)
            .child(content),
        Rectangle::new().width(width).height(BORDER).fill(border),
    ]))
}

fn workspace_button(workspace: &Workspace, monitor: &str, hovered: bool, base: &[Color; 16]) -> Rectangle {
    // sway.css precedence: focused, urgent, visible, hover, then the persistent color
    let color = if workspace.focused() {
        base[0x0A]
    } else if workspace.urgent() {
        base[8]
    } else if workspace.active() {
        base[0x0B]
    } else if hovered {
        base[0x0A]
    } else {
        base[7]
    };

    // "format": "{index}"; a workspace with only a name shows its name
    let name = if workspace.index() > 0 {
        workspace.index().to_string()
    } else {
        workspace.name().unwrap_or_default().to_string()
    };

    let text = label(name, color);
    let width = (ui::width_of(&text) + 6.6).max(16.0) + BORDER * 2.0;

    let id = workspace.id();
    let monitor = monitor.to_string();

    Rectangle::new()
        .width(width)
        .height(Parent)
        .border(BORDER, color)
        .align_child(Center, Center)
        .on_click(move |_| Workspaces::focus(id))
        .on_hover(move |inside| {
            let mut state = BarState::write();

            if inside {
                state.hovered = Some((monitor.clone(), id));
            } else if state.hovered == Some((monitor.clone(), id)) {
                state.hovered = None;
            }
        })
        .child(text)
}

fn battery(battery: &BatteryState, alt: bool, base: &[Color; 16]) -> Rectangle {
    // states: good 99, warning 30, critical 20
    let critical = battery.capacity <= 20;
    let warning = !critical && battery.capacity <= 30;

    let icon = BATTERY_ICONS[(battery.capacity / 10).min(9) as usize];
    let capacity = format!("{}%", battery.capacity);

    let (glyph, color, value) = if alt {
        // format-alt: "[󱧥] {time}"
        ("\u{F19E5}", base[0x0B], battery.time.clone())
    } else {
        match battery.status {
            "charging" if critical => ("\u{F089C}", base[8], capacity),
            "charging" if warning => ("\u{F089D}", base[9], capacity),
            "charging" | "plugged" => ("\u{F0085}", base[0x0B], capacity),
            "full" => (icon, base[0x0B], capacity),
            _ if critical => (icon, base[8], format!("{capacity}!!")),
            _ if warning => (icon, base[9], capacity),
            _ => (icon, base[0x0B], capacity),
        }
    };

    let border = if critical {
        base[8]
    } else if warning {
        base[9]
    } else {
        base[0x0B]
    };

    module(glyph, color, value, border, base[5]).on_click(|button| {
        if button == Button::Left {
            let mut state = BarState::write();
            state.battery_alt = !state.battery_alt;
        }
    })
}

fn volume_scrolled(scroll: Scroll) {
    // scroll-step 1, max-volume 130
    let step = if scroll.y < 0.0 { "1%+" } else { "1%-" };

    amane::spawn(&format!("wpctl set-volume -l 1.3 @DEFAULT_AUDIO_SINK@ {step}"));
}

fn brightness_scrolled(scroll: Scroll) {
    let current = i32::from(Brightness::read().percent());
    let step = if scroll.y < 0.0 { 1 } else { -1 };

    Brightness::set((current + step).clamp(1, 100) as u8);
}

fn tray_module(monitor: &str, base: &[Color; 16]) -> Option<Rectangle> {
    let visible = Tray::read().items.iter().any(|item| item.status != "Passive");

    if !visible {
        return None;
    }

    let icons = tray::icons(monitor);
    let width = ui::width_of(&icons) + 16.0;

    // #tray: tray-bg background, 6pt side padding, tray-border bottom border
    Some(
        Rectangle::new()
            .width(width)
            .height(Parent)
            .fill(base[1])
            .child(Column::new(children![
                Rectangle::new()
                    .width(width)
                    .height(Parent)
                    .padding(Padding {
                        left: 8.0,
                        right: 8.0,
                        ..Padding::default()
                    })
                    .align_child(Start, Center)
                    .child(icons),
                Rectangle::new().width(width).height(BORDER).fill(base[2]),
            ])),
    )
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    let theme = Theme::read();
    let base = theme.base;
    let text = base[5];

    let stats = Stats::read();
    let clock = Clock::read();
    let volume = Volume::read();
    let mode = SwayMode::read();
    let workspaces = Workspaces::read();
    let network = Network::read();
    let brightness = Brightness::read();
    let state = BarState::read();

    // modules-left: sway/workspaces with all-outputs, then sway/mode
    let mut list: Vec<&Workspace> = workspaces.list().iter().collect();
    list.sort_by_key(|workspace| (workspace.index() == 0, workspace.index(), workspace.name().map(String::from)));

    let mut left: Vec<Box<dyn Widget>> = list
        .into_iter()
        .map(|workspace| {
            let hovered = state.hovered.as_ref() == Some(&(monitor.name.clone(), workspace.id()));
            Box::new(workspace_button(workspace, &monitor.name, hovered, &base)) as Box<dyn Widget>
        })
        .collect();

    if !mode.name.is_empty() {
        // "format": " {}", "max-length": 50
        let name: String = format!("\u{F205} {}", mode.name).chars().take(50).collect();
        let content = label(name, base[0]);
        let width = ui::width_of(&content) + 12.0 + BORDER * 2.0;

        left.push(Box::new(
            Rectangle::new()
                .width(width)
                .height(Parent)
                .fill(base[0x0D])
                .border(BORDER, base[0x0C])
                .align_child(Center, Center)
                .child(content),
        ));
    }

    // modules-right, in waybar's order
    let mut right: Vec<Box<dyn Widget>> = Vec::new();

    if let Some(tray) = tray_module(&monitor.name, &base) {
        right.push(Box::new(tray));
    }

    let network_icon = match network.link() {
        Link::Wifi => WIFI_ICONS[(network.strength() / 20).min(4) as usize],
        Link::Wired => "\u{F0200}",
        _ => "\u{F1616}",
    };
    right.push(Box::new(module(network_icon, base[0x0E], stats.down.clone(), base[0x0E], text)));

    right.push(Box::new(module("\u{F233}", base[8], stats.disk_free.clone(), base[8], text)));
    right.push(Box::new(module("\u{E266}", base[9], format!("{}%", stats.cpu), base[9], text)));

    if brightness.present() {
        right.push(Box::new(
            module("\u{F078F}", base[0x0A], format!("{}%", brightness.percent()), base[0x0A], text)
                .on_scroll(brightness_scrolled),
        ));
    }

    right.push(Box::new(module("\u{EFC5}", base[0x0C], stats.memory.clone(), base[0x0C], text)));

    let (volume_icon, volume_color) = match (volume.bluetooth, volume.muted) {
        (false, false) => ("\u{F028}", base[0x0D]),
        (false, true) => ("\u{EEE8}", base[8]),
        (true, false) => ("\u{F00B0}", base[0x0D]),
        (true, true) => ("\u{F00B2}", base[8]),
    };
    let volume_border = if volume.muted { base[8] } else { base[0x0D] };

    right.push(Box::new(
        module(volume_icon, volume_color, format!("{}%", volume.percent), volume_border, text)
            .on_click(|button| match button {
                Button::Left => amane::spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle"),
                // waybar's on-click-right, kept as configured
                Button::Right => amane::spawn("pulseaudio"),
                Button::Middle => {}
            })
            .on_scroll(volume_scrolled),
    ));

    if let Some(state_of_battery) = &stats.battery {
        right.push(Box::new(battery(state_of_battery, state.battery_alt, &base)));
    }

    right.push(Box::new(
        module("\u{F073}", base[0x0A], clock.text.clone(), base[0x0A], text).on_click(|button| {
            if button == Button::Left {
                notifications::toggle_from_bar();
            }
        }),
    ));

    LayerWindow::new()
        .width(Full)
        .height(BAR_HEIGHT)
        .anchor_vertical(Vertical::Top)
        .layer(Layer::Top)
        .space(Zone::Reserve)
        .namespace("amane-bar")
        .child(
            Rectangle::new()
                .width(Parent)
                .height(Parent)
                .fill(base[0])
                .padding(GAP)
                .on_move(|point| tray::track_pointer(point.x))
                .child(
                    Row::new(children![Row::new(left).gap(GAP), Row::new(right).gap(GAP)])
                        .width(Parent)
                        .height(Parent)
                        .justify(SpaceBetween),
                ),
        )
}
