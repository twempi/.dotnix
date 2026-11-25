use std::sync::atomic::{AtomicBool, Ordering};
use std::{env, fs};

use amane::{
    Align, Bluetooth, Center, Color, Column, Image, LayerWindow, Media, Monitor, Network, Padding,
    Parent, Pointer, Rectangle, Row, Service, SpaceBetween, Stack, Weight, Widget, children,
};

use crate::logic::compositor;
use crate::logic::notifications::{self, NotificationCenter, Page, Tick};
use crate::logic::panel::bluetooth::start_agent;
use crate::logic::panel::calendar::{CalendarState, toggle_events};
use crate::logic::panel::usage::{self as usage_logic, UsageState};
use crate::logic::panel::{Cover, dismiss, playback, select, uptime_hours};
use crate::logic::stats::format_time;
use crate::logic::theme::{Theme, home};
use crate::looks::hyprland::ui::{self, BELOW, GAP, Placement, settle};
use crate::looks::tabs::controls::{
    CONTROL_SM, FONT_BODY, FONT_CAPTION, FONT_TITLE, SPACE_MD, SPACE_SM, SPACE_XS, Ui, Variant, glyph,
    disabled, hoverable, icon_button, label, look, sized_card,
};
use crate::looks::tabs::{audio, bluetooth, calendar, network, usage};

// the size sway's panel gives the tabs, which they are laid out for
const CONTENT: f32 = 497.0;

const BODY: f32 = 448.0;

const PADDING: f32 = 12.0;

const TABS: f32 = 36.0;

const HEADER: f32 = 32.0;

const WIDTH: f32 = CONTENT + PADDING * 2.0;

const BODY_Y: f32 = PADDING + TABS + SPACE_MD + HEADER + SPACE_MD;

const HEIGHT: f32 = BODY_Y + BODY + PADDING;

const PROFILE_HEIGHT: f32 = 104.0;

const AVATAR: f32 = 72.0;

const COVER: f32 = 150.0;

const TOGGLES_HEIGHT: f32 = 76.0;

const GLYPH_CLOSE: &str = "\u{EB55}";

const GLYPH_POWER: &str = "\u{EB0D}";

const GLYPH_USER: &str = "\u{EB4D}";

const GLYPH_MUSIC: &str = "\u{EAFC}";

const GLYPH_PREVIOUS: &str = "\u{ED4C}";

const GLYPH_PLAY: &str = "\u{ED46}";

const GLYPH_PAUSE: &str = "\u{ED45}";

const GLYPH_NEXT: &str = "\u{ED4B}";

const GLYPH_WIFI: &str = "\u{EB52}";

const GLYPH_WIFI_OFF: &str = "\u{ECFA}";

const GLYPH_BLUETOOTH: &str = "\u{EA37}";

const GLYPH_BLUETOOTH_OFF: &str = "\u{ECEB}";

const GLYPH_BELL: &str = "\u{EA35}";

const GLYPH_BELL_OFF: &str = "\u{ECE9}";

const TAB_LIST: [(Page, &str); 7] = [
    (Page::Home, "\u{EAC1}"),
    (Page::Audio, "\u{EB51}"),
    (Page::Network, GLYPH_WIFI),
    (Page::Bluetooth, GLYPH_BLUETOOTH),
    (Page::Calendar, "\u{EA52}"),
    (Page::Usage, usage::GLYPH_USAGE),
    (Page::Notifications, GLYPH_BELL),
];

// which island the panel drops from: the media island's song, or the right island
static FROM_MEDIA: AtomicBool = AtomicBool::new(false);

pub fn open(page: Page, from_media: bool) {
    FROM_MEDIA.store(from_media, Ordering::Relaxed);
    notifications::toggle_from_bar(page);
}

// a strip of tabs across the top; the open one is underlined in the accent
fn tabs(ui: &Ui, page: Page) -> Row {
    let cells: Vec<Box<dyn Widget>> = TAB_LIST
        .iter()
        .map(|&(target, code)| {
            let key = format!("tab:{code}");
            let active = target == page;
            let hovered = ui.hovered(&key);

            let (fill, color) = if active {
                (Color::TRANSPARENT, ui.c.primary)
            } else if hovered {
                (ui.c.hover, ui.c.on_surface)
            } else {
                (Color::TRANSPARENT, ui.c.variant)
            };

            let line = if active { (2.0, ui.c.primary) } else { (1.0, ui.c.outline) };

            Box::new(hoverable(
                Rectangle::new()
                    .width(Parent)
                    .height(TABS)
                    .fill(fill)
                    .cursor(Pointer)
                    .on_click(move |_| select(target))
                    .child(Column::new(children![
                        Rectangle::new()
                            .width(Parent)
                            .height(TABS - 2.0)
                            .align_child(Center, Center)
                            .child(glyph(code, 18.0, color)),
                        Rectangle::new().width(Parent).height(2.0).align_child(Center, Align::End).child(
                            Rectangle::new().width(Parent).height(line.0).fill(line.1),
                        ),
                    ])),
                key,
            )) as Box<dyn Widget>
        })
        .collect();

    Row::new(cells).width(CONTENT).height(TABS)
}

fn header_action(ui: &Ui, code: &str, variant: Variant) -> Rectangle {
    icon_button(ui, format!("action:{code}"), code, (CONTROL_SM, 14.0, 0.0), variant)
}

fn header(ui: &Ui, page: Page, events_shown: bool, usage_loading: bool) -> Row {
    let title = match page {
        Page::Home => "HOME",
        Page::Audio => "AUDIO",
        Page::Network => "NETWORK",
        Page::Bluetooth => "BLUETOOTH",
        Page::Calendar => "CALENDAR",
        Page::Usage => "USAGE",
        Page::Notifications => "NOTIFICATIONS",
    };

    let mut actions: Vec<Box<dyn Widget>> = Vec::new();

    if page == Page::Home {
        actions.push(Box::new(header_action(ui, GLYPH_POWER, Variant::Outline).on_click(|_| {
            notifications::close();
            compositor::run("amane-power");
        })));
    }

    if page == Page::Calendar {
        let (code, variant) = if events_shown {
            (calendar::EVENTS_ON, Variant::TabActive)
        } else {
            (calendar::EVENTS_OFF, Variant::Outline)
        };

        actions.push(Box::new(header_action(ui, code, variant).on_click(|_| toggle_events())));
    }

    if page == Page::Usage {
        let refresh = header_action(ui, usage::GLYPH_REFRESH, Variant::Outline);

        actions.push(Box::new(if usage_loading {
            disabled(refresh)
        } else {
            refresh.on_click(|_| usage_logic::refresh())
        }));
    }

    actions.push(Box::new(
        header_action(ui, GLYPH_CLOSE, Variant::Outline).on_click(|_| notifications::close()),
    ));

    Row::new(children![
        label(title, FONT_TITLE, ui.c.on_surface).weight(Weight::Bold),
        Row::new(actions).gap(SPACE_SM),
    ])
    .width(CONTENT)
    .height(HEADER)
    .justify(SpaceBetween)
    .align(Center)
}

fn profile(ui: &Ui) -> Rectangle {
    let c = &ui.c;
    let user = env::var("USER").unwrap_or_default();
    let host = fs::read_to_string("/proc/sys/kernel/hostname").unwrap_or_default();
    let face = home().join(".face");
    let now = chrono::Local::now();

    let avatar = Rectangle::new().width(AVATAR).height(AVATAR).clip().border(1.0, c.primary);

    let avatar = if face.is_file() {
        avatar.fill(Image::cover(face).thumbnail(144, 144))
    } else {
        avatar
            .fill(c.surface)
            .align_child(Center, Center)
            .child(glyph(GLYPH_USER, 40.0, c.on_surface))
    };

    sized_card(ui, Parent, PROFILE_HEIGHT).child(
        Row::new(children![
            Row::new(children![
                avatar,
                Column::new(children![
                    label(user.clone(), FONT_TITLE, c.on_surface).weight(Weight::Bold),
                    label(format!("{user}@{}", host.trim()), FONT_CAPTION, c.variant),
                    label(format!("up {}", format_time(uptime_hours())), FONT_CAPTION, c.variant),
                ])
                .gap(SPACE_XS),
            ])
            .gap(14.0)
            .align(Center),
            Column::new(children![
                label(now.format("%H:%M").to_string(), 28.0, c.primary).weight(Weight::Bold),
                label(now.format("%A, %B %-d").to_string(), FONT_CAPTION, c.on_surface),
            ])
            .gap(SPACE_XS)
            .align(Align::End),
        ])
        .width(Parent)
        .height(Parent)
        .justify(SpaceBetween)
        .align(Center),
    )
}

// what the media island's song opens: the cover, the song and its controls
fn media_card(ui: &Ui) -> Rectangle {
    let c = &ui.c;
    let media = Media::read();
    let cover = Cover::read();

    let card = sized_card(ui, Parent, Parent);

    if media.active().is_none() {
        return card.align_child(Center, Center).child(
            Column::new(children![
                glyph(GLYPH_MUSIC, 28.0, c.variant),
                label("Nothing Playing", FONT_BODY, c.variant),
            ])
            .gap(SPACE_SM)
            .align(Center),
        );
    }

    let art = Rectangle::new().width(COVER).height(COVER).clip().border(1.0, c.outline);

    let art = match &cover.path {
        Some(path) => art.fill(Image::cover(path).thumbnail(300, 300)),
        None => art
            .fill(c.surface)
            .align_child(Center, Center)
            .child(glyph(GLYPH_MUSIC, 48.0, c.variant)),
    };

    let status = playback(media.playing(), media.position().as_secs(), media.length().as_secs());
    let play = if media.playing() { GLYPH_PAUSE } else { GLYPH_PLAY };
    let size = (CONTROL_SM, 16.0, 0.0);

    let controls = Row::new(children![
        icon_button(ui, "media:previous", GLYPH_PREVIOUS, size, Variant::Outline).on_click(|_| Media::previous()),
        icon_button(ui, "media:play", play, size, Variant::Primary).on_click(|_| Media::play_pause()),
        icon_button(ui, "media:next", GLYPH_NEXT, size, Variant::Outline).on_click(|_| Media::next()),
    ])
    .gap(SPACE_SM);

    card.cursor(Pointer).on_click(|_| Media::play_pause()).align_child(Align::Start, Center).child(
        Row::new(children![
            art,
            Column::new(children![
                label(media.title(), FONT_TITLE, c.on_surface).weight(Weight::Bold).elide(),
                label(media.artist(), FONT_BODY, c.variant).elide(),
                label(status, FONT_CAPTION, c.secondary).elide(),
                Rectangle::new().width(1.0).height(SPACE_SM),
                controls,
            ])
            .gap(SPACE_XS),
        ])
        .height(COVER)
        .gap(SPACE_MD + 4.0)
        .align(Center),
    )
}

fn tile(ui: &Ui, key: &str, code: &str, text: &str, on: bool) -> Rectangle {
    let key = format!("tile:{key}");
    let shown = if on { Variant::TabActive } else { Variant::Outline };
    let look = look(&ui.c, shown, ui.hovered(&key));

    let tile = Rectangle::new()
        .width(Parent)
        .height(Parent)
        .fill(look.fill)
        .cursor(Pointer)
        .align_child(Center, Center)
        .child(
            Column::new(children![
                glyph(code, FONT_TITLE + 2.0, look.content),
                label(text, FONT_CAPTION, look.content),
            ])
            .gap(SPACE_XS)
            .align(Center),
        );

    let tile = match look.border {
        Some(border) => tile.border(1.0, border),
        None => tile,
    };

    hoverable(tile, key)
}

fn toggles(ui: &Ui, dnd: bool) -> Row {
    let (wifi, ssid) = {
        let network = Network::read();

        (network.wifi_enabled(), network.ssid().to_string())
    };
    let bluetooth = Bluetooth::read().powered();

    let wifi_label = if ssid.is_empty() { "Wi-Fi" } else { &ssid };
    let wifi_glyph = if wifi { GLYPH_WIFI } else { GLYPH_WIFI_OFF };
    let bluetooth_glyph = if bluetooth { GLYPH_BLUETOOTH } else { GLYPH_BLUETOOTH_OFF };
    let bell = if dnd { GLYPH_BELL_OFF } else { GLYPH_BELL };

    Row::new(children![
        tile(ui, "wifi", wifi_glyph, wifi_label, wifi).on_click(move |_| Network::set_wifi(!wifi)),
        tile(ui, "bluetooth", bluetooth_glyph, "Bluetooth", bluetooth)
            .on_click(move |_| Bluetooth::set_powered(!bluetooth)),
        tile(ui, "dnd", bell, "Do Not Disturb", dnd).on_click(|_| notifications::toggle_dnd()),
    ])
    .width(Parent)
    .height(TOGGLES_HEIGHT)
    .gap(SPACE_MD)
}

fn home_page(ui: &Ui, dnd: bool) -> Column {
    Column::new(children![profile(ui), media_card(ui), toggles(ui, dnd)])
        .width(Parent)
        .height(Parent)
        .gap(SPACE_MD)
}

fn content(page: Page, dnd: bool) -> Stack {
    // the uptime and the clock change once a minute
    let _tick = Tick::read();
    let theme = Theme::read();
    let ui = Ui::with(ui::roles(&theme.base), true);
    let calendar = CalendarState::read();
    let events_shown = calendar.events;
    let usage_state = UsageState::read();

    let body: Box<dyn Widget> = match page {
        Page::Home => Box::new(home_page(&ui, dnd)),
        Page::Audio => Box::new(audio::view(&ui, CONTENT, BODY)),
        Page::Network => Box::new(network::view(&ui, CONTENT, BODY)),
        Page::Bluetooth => Box::new(bluetooth::view(&ui, CONTENT, BODY)),
        Page::Calendar => Box::new(calendar::view(&ui, &calendar, CONTENT, BODY)),
        Page::Usage => Box::new(usage::view(&ui, &usage_state, CONTENT, BODY)),
        Page::Notifications => Box::new(super::notifications::page(&ui, CONTENT, dnd, &theme.base)),
    };

    let body = Column::new(vec![body]).width(CONTENT).height(BODY);

    let frame = ui::swallow_clicks(
        ui::frame(Rectangle::new().width(WIDTH).height(HEIGHT), &theme.base)
            .padding(PADDING)
            .child(
                Column::new(children![tabs(&ui, page), header(&ui, page, events_shown, usage_state.loading), body])
                    .width(CONTENT)
                    .height(Parent)
                    .gap(SPACE_MD),
            ),
    );

    let mut layers: Vec<Box<dyn Widget>> = vec![Box::new(frame)];

    if page == Page::Audio {
        layers.extend(audio::menu_layer(&ui, WIDTH, HEIGHT, PADDING, BODY_Y));
    }

    Stack::new(layers).width(WIDTH).height(HEIGHT)
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    start_agent();

    let center = NotificationCenter::read();
    let visible = center.open && compositor::shown_on(&center.monitor, monitor);

    // a keybind opens it under the right island, like the bar's other modules
    if !center.open {
        FROM_MEDIA.store(false, Ordering::Relaxed);
    }

    let from_media = FROM_MEDIA.load(Ordering::Relaxed);
    let settled = ui::appear(&format!("panel:{}", monitor.name), visible);

    // the home page reads services that change every second; a hidden panel must not redraw for them
    let panel = if visible {
        settle(
            Rectangle::new().width(WIDTH).height(HEIGHT).child(content(center.page, center.dnd)),
            settled,
        )
    } else {
        Rectangle::new().width(0.0).height(0.0)
    };

    ui::overlay(
        "amane-notification-center",
        visible,
        Placement {
            horizontal: if from_media { Align::Center } else { Align::End },
            vertical: Align::Start,
            padding: Padding {
                top: BELOW,
                right: if from_media { 0.0 } else { GAP },
                ..Padding::default()
            },
        },
        dismiss,
        notifications::center_key,
        panel,
    )
}
