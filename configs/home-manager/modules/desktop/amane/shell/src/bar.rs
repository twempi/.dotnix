use std::time::Duration;

use amane::{
    Brightness, Button, Center, Color, Column, Full, Layer, LayerWindow, Link, Monitor, Network,
    Padding, Parent, Rectangle, Row, Scroll, Service, SpaceBetween, Start, Text, Vertical, Weight,
    Widget, Workspace, Workspaces, Zone, children,
};

use crate::notifications::{self, Page};
use crate::stats::{BatteryState, Clock, Detail, Stats, SwayMode, Volume};
use crate::theme::Theme;
use crate::tray::{self, Tray};
use crate::ui::{self, BAR_FONT, BAR_HEIGHT, BAR_TEXT};

// the reference bar's 2px bottom line and the space between its modules
const LINE: f32 = 2.0;
const GAP: f32 = 20.0;

// its darker purples are the text color at part opacity over the background
const LINE_ALPHA: u8 = 153;
const BOX_ALPHA: u8 = 84;
// fainter, so it doesn't merge with the focused box when their numbers are adjacent
const OTHER_MONITOR_ALPHA: u8 = 42;

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
    // Iosevka names its 900 weight Heavy, so amane's lookup of Black fell back to Regular
    ui::text(content, BAR_TEXT, BAR_FONT)
        .color(color)
        .weight(Weight::Bold)
}

fn tint(color: Color, alpha: u8) -> Color {
    Color::rgba(color.red(), color.green(), color.blue(), alpha)
}

// a status module: plain text like "CPU 7%"
fn module(content: String, color: Color) -> Rectangle {
    let text = label(content, color);

    // whole pixels, so the tray left of these modules draws its icons unblurred
    Rectangle::new()
        .width(ui::width_of(&text).ceil())
        .height(Parent)
        .align_child(Start, Center)
        .child(text)
}

// shows the module's details under the pointer while it hovers
fn detailed(module: Rectangle, detail: Detail, monitor: &str) -> Rectangle {
    let monitor = monitor.to_string();

    module.on_hover(move |inside| tray::module_hovered(detail, inside, &monitor))
}

fn workspace_button(workspace: &Workspace, monitor: &str, hovered: bool, base: &[Color; 16]) -> Rectangle {
    let accent = base[0x0E];

    // a tinted box marks the workspace each monitor shows; the focused one's digit is dark
    let (fill, color) = if workspace.focused() {
        (tint(accent, BOX_ALPHA), base[0])
    } else if workspace.urgent() {
        (Color::TRANSPARENT, base[8])
    } else if workspace.active() {
        (tint(accent, OTHER_MONITOR_ALPHA), accent)
    } else if hovered {
        (Color::TRANSPARENT, base[5])
    } else {
        (Color::TRANSPARENT, accent)
    };

    // "format": "{index}"; a workspace with only a name shows its name
    let name = if workspace.index() > 0 {
        workspace.index().to_string()
    } else {
        workspace.name().unwrap_or_default().to_string()
    };

    let text = label(name, color);
    // 7px either side puts single digits 21px apart, as in the reference
    let width = (ui::width_of(&text) + 14.0).round();

    let id = workspace.id();
    let monitor = monitor.to_string();

    Rectangle::new()
        .width(width)
        .height(Parent)
        .fill(fill)
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

    // i3status's names for the states
    let name = match battery.status {
        "charging" | "plugged" => "CHR",
        "full" => "FULL",
        _ => "BAT",
    };

    let value = if alt {
        // format-alt: the time left
        battery.time.clone()
    } else if critical && name == "BAT" {
        format!("{}%!!", battery.capacity)
    } else {
        format!("{}%", battery.capacity)
    };

    let color = if critical {
        base[8]
    } else if warning {
        base[9]
    } else {
        base[0x0E]
    };

    module(format!("{name} {value}"), color).on_click(|button| {
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

pub fn view(monitor: &Monitor) -> LayerWindow {
    let theme = Theme::read();
    let base = theme.base;
    let accent = base[0x0E];

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

    let buttons: Vec<Box<dyn Widget>> = list
        .into_iter()
        .map(|workspace| {
            let hovered = state.hovered.as_ref() == Some(&(monitor.name.clone(), workspace.id()));
            Box::new(workspace_button(workspace, &monitor.name, hovered, &base)) as Box<dyn Widget>
        })
        .collect();

    let mut left: Vec<Box<dyn Widget>> = vec![Box::new(Row::new(buttons))];

    if !mode.name.is_empty() {
        // "max-length": 50
        let name: String = mode.name.chars().take(50).collect();
        let content = label(name, base[0]);
        let width = (ui::width_of(&content) + 14.0).round();

        left.push(Box::new(
            Rectangle::new()
                .width(width)
                .height(Parent)
                .fill(accent)
                .align_child(Center, Center)
                .child(content),
        ));
    }

    // the reference's order, with this bar's extra modules beside their kin
    let mut right: Vec<Box<dyn Widget>> = Vec::new();

    if Tray::read().items.iter().any(|item| item.status != "Passive") {
        right.push(Box::new(tray::icons(&monitor.name)));
    }

    let name = monitor.name.as_str();

    right.push(Box::new(detailed(module(format!("CPU {}%", stats.cpu), accent), Detail::Cpu, name)));
    right.push(Box::new(detailed(module(format!("MEM {}", stats.memory), accent), Detail::Memory, name)));
    right.push(Box::new(detailed(module(format!("DISK {}", stats.disk_free), accent), Detail::Disk, name)));

    let down: &str = match network.link() {
        Link::Offline => "off",
        _ => &stats.down,
    };
    right.push(Box::new(
        detailed(module(format!("NET {down}"), accent), Detail::Network, name).on_click(|button| {
            if button == Button::Left {
                notifications::toggle_from_bar(Page::Network);
            }
        }),
    ));

    if brightness.present() {
        right.push(Box::new(
            module(format!("BRI {}%", brightness.percent()), accent).on_scroll(brightness_scrolled),
        ));
    }

    let sink = if volume.bluetooth { "BT" } else { "VOL" };
    let (level, volume_color) = if volume.muted {
        (String::from("muted"), base[8])
    } else {
        (format!("{}%", volume.percent), accent)
    };

    right.push(Box::new(
        module(format!("{sink} {level}"), volume_color)
            .on_click(|button| match button {
                Button::Left => notifications::toggle_from_bar(Page::Audio),
                // mute moved here from the left click
                Button::Middle => amane::spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle"),
                // waybar's on-click-right, kept as configured
                Button::Right => amane::spawn("pulseaudio"),
            })
            .on_scroll(volume_scrolled),
    ));

    if let Some(state_of_battery) = &stats.battery {
        right.push(Box::new(detailed(
            battery(state_of_battery, state.battery_alt, &base),
            Detail::Battery,
            name,
        )));
    }

    right.push(Box::new(
        module(clock.text.clone(), accent).on_click(|button| {
            if button == Button::Left {
                notifications::toggle_from_bar(Page::Home);
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
                .on_move(|point| tray::track_pointer(point.x))
                .child(Column::new(children![
                    Rectangle::new()
                        .width(Parent)
                        .height(Parent)
                        // the workspaces start at the edge; the clock stops short of it
                        .padding(Padding {
                            right: 8.0,
                            ..Padding::default()
                        })
                        .child(
                            Row::new(children![
                                Row::new(left).gap(GAP),
                                // centers the tray's icons; the text modules fill the height
                                Row::new(right).gap(GAP).align(Center),
                            ])
                            .width(Parent)
                            .height(Parent)
                            .justify(SpaceBetween),
                        ),
                    Rectangle::new()
                        .width(Parent)
                        .height(LINE)
                        .fill(tint(accent, LINE_ALPHA)),
                ])),
        )
}
