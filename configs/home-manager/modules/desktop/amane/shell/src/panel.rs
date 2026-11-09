use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use std::path::PathBuf;
use std::time::Duration;
use std::{env, fs, mem, thread};

use amane::{
    Align, Bluetooth, Center, Color, Column, Image, LayerWindow, Media, Monitor, Network, Padding,
    Parent, Pointer, Rectangle, Row, Service, SpaceBetween, Weight, children,
};

use crate::notifications::{self, MARGIN, NotificationCenter, Page, Tick};
use crate::stats::format_time;
use crate::theme::{Theme, home};
use crate::tray::runtime_dir;
use crate::ui::{self, BAR_HEIGHT, MENU_FONT, MENU_TEXT, Placement};

// a small take on Noctalia's control center: its home tab, with notifications as the other tab
const WIDTH: f32 = 540.0;
const HEIGHT: f32 = 420.0;
const GAP: f32 = 10.0;
const RADIUS: f32 = 12.0;
const SIDEBAR: f32 = 44.0;
const CONTENT: f32 = WIDTH - SIDEBAR - GAP * 3.0;
const PROFILE_HEIGHT: f32 = 130.0;
const AVATAR: f32 = 96.0;
const MEDIA_HEIGHT: f32 = 110.0;
const COVER: f32 = MEDIA_HEIGHT - GAP * 2.0;
const TOGGLES_WIDTH: f32 = 120.0;
const SMALL_TEXT: f32 = MENU_TEXT - 1.0;

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

fn icon_button(glyph: &str, fill: Color, color: Color) -> Rectangle {
    Rectangle::new()
        .width(32.0)
        .height(32.0)
        .radius(8.0)
        .fill(fill)
        .cursor(Pointer)
        .align_child(Center, Center)
        .child(ui::text(glyph, MENU_TEXT + 2.0, MENU_FONT).color(color).tight())
}

fn tab(target: Page, glyph: &str, current: Page, base: &[Color; 16]) -> Rectangle {
    let (fill, color) = if target == current {
        (base[0x0E], base[0])
    } else {
        (Color::TRANSPARENT, base[5])
    };

    icon_button(glyph, fill, color).on_click(move |_| NotificationCenter::write().page = target)
}

fn sidebar(page: Page, base: &[Color; 16]) -> Rectangle {
    Rectangle::new()
        .width(SIDEBAR)
        .height(Parent)
        .radius(RADIUS)
        .fill(base[1])
        .padding(6.0)
        .child(
            Column::new(children![
                tab(Page::Home, "\u{F02DC}", page, base),
                tab(Page::Notifications, "\u{F009A}", page, base),
            ])
            .gap(6.0),
        )
}

fn header(page: Page, base: &[Color; 16]) -> Row {
    let title = match page {
        Page::Home => "Home",
        Page::Notifications => "Notifications",
    };

    Row::new(children![
        ui::text(title, MENU_TEXT + 2.0, MENU_FONT)
            .color(base[0x0E])
            .weight(Weight::Bold),
        Row::new(children![
            icon_button("\u{F0425}", base[0x0E], base[0]).on_click(|_| {
                notifications::close();
                ui::run("amane-power");
            }),
            icon_button("\u{F0156}", base[1], base[5]).on_click(|_| notifications::close()),
        ])
        .gap(6.0),
    ])
    .width(Parent)
    .height(32.0)
    .justify(SpaceBetween)
    .align(Center)
}

fn profile(base: &[Color; 16]) -> Rectangle {
    let user = env::var("USER").unwrap_or_default();
    let host = fs::read_to_string("/proc/sys/kernel/hostname").unwrap_or_default();
    let face = home().join(".face");

    let avatar = Rectangle::new()
        .width(AVATAR)
        .height(AVATAR)
        .radius(AVATAR / 2.0)
        .clip()
        .border(2.0, base[0x0E]);

    let avatar = if face.is_file() {
        avatar.fill(Image::cover(face).thumbnail(192, 192))
    } else {
        avatar
            .fill(base[2])
            .align_child(Center, Center)
            .child(ui::text("\u{F0004}", 52.0, MENU_FONT).color(base[5]).tight())
    };

    Rectangle::new()
        .width(Parent)
        .height(PROFILE_HEIGHT)
        .radius(RADIUS)
        .fill(base[1])
        .padding(16.0)
        .child(
            Row::new(children![
                avatar,
                Column::new(children![
                    ui::text(user.clone(), MENU_TEXT + 3.0, MENU_FONT)
                        .color(base[5])
                        .weight(Weight::Bold),
                    ui::text(format!("{user}@{}", host.trim()), SMALL_TEXT, MENU_FONT).color(base[4]),
                    ui::text(format!("Uptime {}", format_time(uptime_hours())), SMALL_TEXT, MENU_FONT).color(base[4]),
                ])
                .gap(4.0),
            ])
            .height(Parent)
            .gap(18.0)
            .align(Center),
        )
}

fn media_card(base: &[Color; 16]) -> Rectangle {
    let media = Media::read();
    let cover = Cover::read();

    let card = Rectangle::new()
        .width(Parent)
        .height(MEDIA_HEIGHT)
        .radius(RADIUS)
        .fill(base[1]);

    if media.active().is_none() {
        return card
            .align_child(Center, Center)
            .child(ui::text("Nothing playing", MENU_TEXT, MENU_FONT).color(base[3]));
    }

    let art = Rectangle::new().width(COVER).height(COVER).radius(8.0).clip();

    let art = match &cover.path {
        Some(path) => art.fill(Image::cover(path).thumbnail(180, 180)),
        None => art
            .fill(base[2])
            .align_child(Center, Center)
            .child(ui::text("\u{F075A}", 36.0, MENU_FONT).color(base[4]).tight()),
    };

    let status = playback(media.playing(), media.position().as_secs(), media.length().as_secs());

    card.padding(GAP)
        .cursor(Pointer)
        .on_click(|_| Media::play_pause())
        .child(
            Row::new(children![
                art,
                Column::new(children![
                    ui::text(media.title(), MENU_TEXT, MENU_FONT)
                        .color(base[5])
                        .weight(Weight::Bold)
                        .elide(),
                    ui::text(media.artist(), SMALL_TEXT, MENU_FONT).color(base[4]).elide(),
                    ui::text(status, SMALL_TEXT, MENU_FONT).color(base[0x0E]).elide(),
                ])
                .gap(4.0),
            ])
            .height(Parent)
            .gap(12.0)
            .align(Center),
        )
}

fn clock_card(base: &[Color; 16]) -> Rectangle {
    let now = chrono::Local::now();

    Rectangle::new()
        .width(Parent)
        .height(Parent)
        .radius(RADIUS)
        .fill(base[1])
        .align_child(Center, Center)
        .child(
            Row::new(children![
                ui::text(now.format("%H:%M").to_string(), 30.0, MENU_FONT)
                    .color(base[0x0E])
                    .weight(Weight::Bold),
                Column::new(children![
                    ui::text(now.format("%A").to_string(), MENU_TEXT, MENU_FONT).color(base[5]),
                    ui::text(now.format("%Y-%m-%d").to_string(), SMALL_TEXT, MENU_FONT).color(base[4]),
                ])
                .gap(2.0),
            ])
            .gap(16.0)
            .align(Center),
        )
}

fn tile(glyph: &str, label: &str, on: bool, base: &[Color; 16]) -> Rectangle {
    let (fill, color) = if on { (base[0x0E], base[0]) } else { (base[1], base[5]) };

    Rectangle::new()
        .width(Parent)
        .height(Parent)
        .radius(RADIUS)
        .fill(fill)
        .cursor(Pointer)
        .align_child(Center, Center)
        .child(
            Column::new(children![
                ui::text(glyph, MENU_TEXT + 3.0, MENU_FONT).color(color),
                ui::text(label, SMALL_TEXT, MENU_FONT).color(color),
            ])
            .gap(2.0)
            .align(Center),
        )
}

fn toggles(dnd: bool, base: &[Color; 16]) -> Column {
    let wifi = Network::read().wifi_enabled();
    let bluetooth = Bluetooth::read().powered();

    let wifi_glyph = if wifi { "\u{F05A9}" } else { "\u{F05AA}" };
    let bluetooth_glyph = if bluetooth { "\u{F00AF}" } else { "\u{F00B2}" };
    let dnd_glyph = if dnd { "\u{F009B}" } else { "\u{F009A}" };

    Column::new(children![
        tile(wifi_glyph, "Wi-Fi", wifi, base).on_click(move |_| Network::set_wifi(!wifi)),
        tile(bluetooth_glyph, "Bluetooth", bluetooth, base).on_click(move |_| Bluetooth::set_powered(!bluetooth)),
        tile(dnd_glyph, "DND", dnd, base).on_click(|_| notifications::toggle_dnd()),
    ])
    .width(TOGGLES_WIDTH)
    .height(Parent)
    .gap(GAP)
}

fn home_page(dnd: bool, base: &[Color; 16]) -> Column {
    Column::new(children![
        profile(base),
        Row::new(children![
            Column::new(children![media_card(base), clock_card(base)])
                .width(Parent)
                .height(Parent)
                .gap(GAP),
            toggles(dnd, base),
        ])
        .width(Parent)
        .height(Parent)
        .gap(GAP),
    ])
    .width(Parent)
    .height(Parent)
    .gap(GAP)
}

fn content(page: Page, dnd: bool) -> Rectangle {
    // the uptime and the clock card change once a minute
    let _tick = Tick::read();
    let theme = Theme::read();
    let base = &theme.base;

    let body = match page {
        Page::Home => home_page(dnd, base),
        Page::Notifications => notifications::page(CONTENT, dnd, base),
    };

    ui::swallow_clicks(
        Rectangle::new()
            .width(WIDTH)
            .height(HEIGHT)
            .radius(RADIUS)
            .fill(base[0])
            .border(1.0, base[3])
            .padding(GAP)
            .child(
                Row::new(children![
                    sidebar(page, base),
                    Column::new(children![header(page, base), body])
                        .width(CONTENT)
                        .height(Parent)
                        .gap(GAP),
                ])
                .gap(GAP),
            ),
    )
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    let center = NotificationCenter::read();
    let visible = center.open && ui::shown_on(&center.monitor, monitor);

    // the home page reads services that change every second; a hidden panel must not redraw for them
    let panel = if visible {
        content(center.page, center.dnd)
    } else {
        Rectangle::new().width(0.0).height(0.0)
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
        notifications::close,
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
