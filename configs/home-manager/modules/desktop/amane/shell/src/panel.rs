use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use std::path::PathBuf;
use std::time::Duration;
use std::{env, fs, mem, thread};

use amane::{
    Align, Bluetooth, Center, Column, Image, LayerWindow, Media, Monitor, Network, Padding,
    Parent, Pointer, Rectangle, Row, Service, SpaceBetween, Stack, Weight, Widget, children,
};

use crate::notifications::{self, MARGIN, NotificationCenter, Page, Tick};
use crate::stats::format_time;
use crate::theme::{Theme, home};
use crate::tray::runtime_dir;
use crate::ui::{self, BAR_HEIGHT, Placement};

mod audio;
mod bluetooth;
mod calendar;
pub mod controls;
mod network;

use controls::{
    CONTROL_SM, FONT_BODY, FONT_CAPTION, FONT_TITLE, Interaction, RADIUS_LG, RADIUS_MD, RADIUS_XL, SPACE_MD, SPACE_SM,
    SPACE_XS, Ui, Variant, glyph, icon_button, label, look, sized_card,
};

// Noctalia's control center frame: a sidebar of tabs beside a header and the tab's body
const WIDTH: f32 = 595.0;
const HEIGHT: f32 = 520.0;
const PADDING: f32 = 14.0;
const SIDEBAR: f32 = 56.0;
const CONTENT: f32 = 497.0;
const HEADER: f32 = 32.0;
const BODY: f32 = 448.0;
const PROFILE_HEIGHT: f32 = 200.0;
const AVATAR: f32 = 96.0;
const MEDIA_HEIGHT: f32 = 130.0;
const COVER: f32 = MEDIA_HEIGHT - SPACE_MD * 2.0;
const TOGGLES_WIDTH: f32 = 183.0;

const GLYPH_CLOSE: &str = "\u{EB55}";
const GLYPH_POWER: &str = "\u{EB0D}";
const GLYPH_USER: &str = "\u{EB4D}";
const GLYPH_MUSIC: &str = "\u{EAFC}";
const GLYPH_WIFI: &str = "\u{EB52}";
const GLYPH_WIFI_OFF: &str = "\u{ECFA}";
const GLYPH_BLUETOOTH: &str = "\u{EA37}";
const GLYPH_BLUETOOTH_OFF: &str = "\u{ECEB}";
const GLYPH_BELL: &str = "\u{EA35}";
const GLYPH_BELL_OFF: &str = "\u{ECE9}";

const TABS: [(Page, &str); 6] = [
    (Page::Home, "\u{EAC1}"),
    (Page::Audio, "\u{EB51}"),
    (Page::Network, GLYPH_WIFI),
    (Page::Bluetooth, GLYPH_BLUETOOTH),
    (Page::Calendar, "\u{EA52}"),
    (Page::Notifications, GLYPH_BELL),
];

// the current track's cover as a file, because Amane only draws local images
#[derive(Default)]
pub struct Cover {
    url: String,
    path: Option<PathBuf>,
}

impl Service for Cover {
    fn new() -> Self {
        Self::default()
    }

    // not update(), which holds the write lock: a download must not stall the drawing
    fn listen() {
        loop {
            let url = Media::read().art_url().to_string();

            if Cover::read().url != url {
                let path = local_cover(&url);
                let previous = mem::replace(&mut *Cover::write(), Cover { url, path }).path;

                // only our own downloads: a player's file:// cover is not ours to delete
                if let Some(previous) = previous.filter(|file| file.starts_with(runtime_dir())) {
                    let _ = fs::remove_file(previous);
                }
            }

            thread::sleep(Duration::from_secs(1));
        }
    }
}

// shortcut: a percent-encoded file:// path shows the placeholder, decode it if a player needs that
fn local_cover(url: &str) -> Option<PathBuf> {
    let path = if let Some(path) = url.strip_prefix("file://") {
        PathBuf::from(path)
    } else if url.starts_with("https://") {
        download_cover(url)?
    } else {
        return None;
    };

    path.is_file().then_some(path)
}

// Spotify gives https links; the file only counts once curl has finished it
fn download_cover(url: &str) -> Option<PathBuf> {
    let mut hasher = DefaultHasher::new();
    url.hash(&mut hasher);

    let dir = runtime_dir();
    fs::create_dir_all(&dir).ok()?;

    let path = dir.join(format!("cover-{:x}", hasher.finish()));

    // the url comes from whichever player is active, so it is quoted
    amane::output(&format!(
        "curl -sf --max-time 10 --max-filesize 10M -o {file} {url} || rm -f {file}",
        file = ui::quote(&path.to_string_lossy()),
        url = ui::quote(url),
    ));

    Some(path)
}

fn minutes(seconds: u64) -> String {
    format!("{}:{:02}", seconds / 60, seconds % 60)
}

// a live stream has no length, so it shows only its state
fn playback(playing: bool, position: u64, length: u64) -> String {
    let state = if playing { "Playing" } else { "Paused" };

    if length == 0 {
        return state.to_string();
    }

    format!("{state} · {} / {}", minutes(position), minutes(length))
}

fn uptime_hours() -> f64 {
    let seconds: Option<f64> = fs::read_to_string("/proc/uptime")
        .ok()
        .and_then(|text| text.split_whitespace().next()?.parse().ok());

    seconds.unwrap_or(0.0) / 3600.0
}

// each tab hears when it comes on screen and when it goes, for scans and refreshes
pub fn select(page: Page) {
    let previous = mem::replace(&mut NotificationCenter::write().page, page);

    if previous != page {
        left(previous);
        entered(page);
    }
}

pub fn entered(page: Page) {
    Interaction::clear_hover();

    match page {
        Page::Audio => audio::entered(),
        Page::Bluetooth => bluetooth::entered(),
        Page::Network => network::entered(),
        Page::Calendar => calendar::reset(),
        _ => {}
    }
}

pub fn left(page: Page) {
    match page {
        Page::Audio => audio::left(),
        Page::Bluetooth => bluetooth::left(),
        Page::Network => network::left(),
        _ => {}
    }
}

// an open menu is the first thing Esc or an outside click closes
pub fn dismiss() {
    if !audio::close_menu() {
        notifications::close();
    }
}

fn sidebar(ui: &Ui, page: Page) -> Rectangle {
    let buttons: Vec<Box<dyn Widget>> = TABS
        .iter()
        .map(|&(target, code)| {
            let variant = if target == page { Variant::TabActive } else { Variant::Ghost };

            Box::new(
                icon_button(ui, format!("tab:{code}"), code, (CONTROL_SM, 21.0, RADIUS_LG), variant)
                    .on_click(move |_| select(target)),
            ) as Box<dyn Widget>
        })
        .collect();

    sized_card(ui, SIDEBAR, HEIGHT - PADDING * 2.0).child(Column::new(buttons).gap(SPACE_XS))
}

fn header_action(ui: &Ui, code: &str, variant: Variant) -> Rectangle {
    icon_button(ui, format!("action:{code}"), code, (CONTROL_SM, 14.0, RADIUS_MD), variant)
}

fn header(ui: &Ui, page: Page, events_shown: bool) -> Row {
    let title = match page {
        Page::Home => "Home",
        Page::Audio => "Audio",
        Page::Network => "Network",
        Page::Bluetooth => "Bluetooth",
        Page::Calendar => "Calendar",
        Page::Notifications => "Notifications",
    };

    let mut actions: Vec<Box<dyn Widget>> = Vec::new();

    if page == Page::Home {
        actions.push(Box::new(header_action(ui, GLYPH_POWER, Variant::Default).on_click(|_| {
            notifications::close();
            ui::run("amane-power");
        })));
    }

    if page == Page::Calendar {
        let (code, variant) = if events_shown {
            (calendar::EVENTS_ON, Variant::TabActive)
        } else {
            (calendar::EVENTS_OFF, Variant::Default)
        };

        actions.push(Box::new(
            header_action(ui, code, variant).on_click(|_| calendar::toggle_events()),
        ));
    }

    actions.push(Box::new(
        header_action(ui, GLYPH_CLOSE, Variant::Default).on_click(|_| notifications::close()),
    ));

    Row::new(children![
        label(title, FONT_TITLE, ui.c.primary).weight(Weight::Bold),
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

    let avatar = Rectangle::new()
        .width(AVATAR)
        .height(AVATAR)
        .radius(AVATAR / 2.0)
        .clip()
        .border(2.0, c.primary);

    let avatar = if face.is_file() {
        avatar.fill(Image::cover(face).thumbnail(192, 192))
    } else {
        avatar
            .fill(c.surface)
            .align_child(Center, Center)
            .child(glyph(GLYPH_USER, 52.0, c.on_surface))
    };

    sized_card(ui, CONTENT, PROFILE_HEIGHT).child(
        Row::new(children![
            avatar,
            Column::new(children![
                label(user.clone(), FONT_TITLE, c.on_surface).weight(Weight::Bold),
                label(format!("{user}@{}", host.trim()), FONT_BODY, c.variant),
                label(format!("Uptime {}", format_time(uptime_hours())), FONT_BODY, c.variant),
            ])
            .gap(SPACE_XS),
        ])
        .height(Parent)
        .gap(18.0)
        .align(Center),
    )
}

fn media_card(ui: &Ui) -> Rectangle {
    let c = &ui.c;
    let media = Media::read();
    let cover = Cover::read();

    let card = sized_card(ui, Parent, MEDIA_HEIGHT);

    if media.active().is_none() {
        return card.align_child(Center, Center).child(
            Column::new(children![
                label("Nothing Playing", FONT_BODY, c.on_surface),
                label("Idle", FONT_BODY, c.variant),
            ])
            .gap(SPACE_XS),
        );
    }

    let art = Rectangle::new().width(COVER).height(COVER).radius(RADIUS_MD).clip();

    let art = match &cover.path {
        Some(path) => art.fill(Image::cover(path).thumbnail(180, 180)),
        None => art
            .fill(c.surface)
            .align_child(Center, Center)
            .child(glyph(GLYPH_MUSIC, 36.0, c.variant)),
    };

    let status = playback(media.playing(), media.position().as_secs(), media.length().as_secs());

    card.cursor(Pointer).on_click(|_| Media::play_pause()).child(
        Row::new(children![
            art,
            Column::new(children![
                label(media.title(), FONT_BODY, c.on_surface).weight(Weight::Bold).elide(),
                label(media.artist(), FONT_CAPTION, c.variant).elide(),
                label(status, FONT_CAPTION, c.secondary).elide(),
            ])
            .gap(SPACE_XS),
        ])
        .height(Parent)
        .gap(SPACE_MD)
        .align(Center),
    )
}

fn clock_card(ui: &Ui) -> Rectangle {
    let c = &ui.c;
    let now = chrono::Local::now();

    sized_card(ui, Parent, Parent).align_child(Center, Center).child(
        Row::new(children![
            label(now.format("%H:%M").to_string(), 26.0, c.primary).weight(Weight::Bold),
            label(now.format("%A, %m/%d/%Y").to_string(), FONT_CAPTION, c.on_surface),
        ])
        .gap(SPACE_MD)
        .align(Center),
    )
}

fn tile(ui: &Ui, key: &str, code: &str, text: &str, on: bool) -> Rectangle {
    let key = format!("tile:{key}");
    let shown = if on { Variant::TabActive } else { Variant::Default };
    let look = look(&ui.c, shown, ui.hovered(&key));

    let tile = Rectangle::new()
        .width(Parent)
        .height(Parent)
        .radius(RADIUS_LG)
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

    controls::hoverable(tile, key)
}

fn toggles(ui: &Ui, dnd: bool) -> Column {
    let (wifi, ssid) = {
        let network = Network::read();

        (network.wifi_enabled(), network.ssid().to_string())
    };
    let bluetooth = Bluetooth::read().powered();

    let wifi_label = if ssid.is_empty() { "Wi-Fi" } else { &ssid };
    let wifi_glyph = if wifi { GLYPH_WIFI } else { GLYPH_WIFI_OFF };
    let bluetooth_glyph = if bluetooth { GLYPH_BLUETOOTH } else { GLYPH_BLUETOOTH_OFF };
    let bell = if dnd { GLYPH_BELL_OFF } else { GLYPH_BELL };

    Column::new(children![
        tile(ui, "wifi", wifi_glyph, wifi_label, wifi).on_click(move |_| Network::set_wifi(!wifi)),
        tile(ui, "bluetooth", bluetooth_glyph, "Bluetooth", bluetooth).on_click(move |_| Bluetooth::set_powered(!bluetooth)),
        tile(ui, "dnd", bell, "DND", dnd).on_click(|_| notifications::toggle_dnd()),
    ])
    .width(TOGGLES_WIDTH)
    .height(Parent)
    .gap(SPACE_MD)
}

fn home_page(ui: &Ui, dnd: bool) -> Column {
    Column::new(children![
        profile(ui),
        Row::new(children![
            Column::new(children![media_card(ui), clock_card(ui)])
                .width(Parent)
                .height(Parent)
                .gap(SPACE_MD),
            toggles(ui, dnd),
        ])
        .width(Parent)
        .height(Parent)
        .gap(SPACE_MD),
    ])
    .width(Parent)
    .height(Parent)
    .gap(SPACE_MD)
}

fn content(page: Page, dnd: bool) -> Stack {
    // the uptime and the clock card change once a minute
    let _tick = Tick::read();
    let theme = Theme::read();
    let ui = Ui::new(&theme.base);
    let calendar = calendar::CalendarState::read();
    let events_shown = calendar.events;

    let body: Box<dyn Widget> = match page {
        Page::Home => Box::new(home_page(&ui, dnd)),
        Page::Audio => Box::new(audio::view(&ui, CONTENT, BODY)),
        Page::Network => Box::new(network::view(&ui, CONTENT, BODY)),
        Page::Bluetooth => Box::new(bluetooth::view(&ui, CONTENT, BODY)),
        Page::Calendar => Box::new(calendar::view(&ui, &calendar, CONTENT, BODY)),
        Page::Notifications => Box::new(notifications::page(CONTENT, dnd, &theme.base)),
    };

    let body = Column::new(vec![body]).width(CONTENT).height(BODY);

    let frame = ui::swallow_clicks(
        Rectangle::new()
            .width(WIDTH)
            .height(HEIGHT)
            .radius(RADIUS_XL)
            .fill(ui.c.surface)
            // the bar's bottom line
            .border(2.0, ui.c.primary)
            .padding(PADDING)
            .child(
                Row::new(children![
                    sidebar(&ui, page),
                    Column::new(children![header(&ui, page, events_shown), body])
                        .width(CONTENT)
                        .height(Parent)
                        .gap(SPACE_MD),
                ])
                .gap(PADDING),
            ),
    );

    let mut layers: Vec<Box<dyn Widget>> = vec![Box::new(frame)];

    if page == Page::Audio {
        layers.extend(audio::menu_layer(&ui, WIDTH, HEIGHT, PADDING + SIDEBAR + PADDING, PADDING + HEADER + SPACE_MD));
    }

    Stack::new(layers).width(WIDTH).height(HEIGHT)
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    bluetooth::start_agent();

    let center = NotificationCenter::read();
    let visible = center.open && ui::shown_on(&center.monitor, monitor);

    // the home page reads services that change every second; a hidden panel must not redraw for them
    let panel = if visible {
        content(center.page, center.dnd)
    } else {
        Stack::new(Vec::new()).width(0.0).height(0.0)
    };

    ui::overlay(
        "amane-notification-center",
        visible,
        Placement {
            horizontal: Align::End,
            vertical: Align::Start,
            padding: Padding {
                top: BAR_HEIGHT + MARGIN,
                right: MARGIN,
                ..Padding::default()
            },
        },
        dismiss,
        notifications::center_key,
        panel,
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn describes_playback() {
        assert_eq!(playback(true, 61, 286), "Playing · 1:01 / 4:46");
        assert_eq!(playback(false, 0, 0), "Paused");
    }

    #[test]
    fn only_trusts_existing_files_and_https() {
        assert_eq!(local_cover(""), None);
        assert_eq!(local_cover("http://example.com/a.jpg"), None);
        assert_eq!(local_cover("file:///nonexistent/cover.png"), None);
    }
}
