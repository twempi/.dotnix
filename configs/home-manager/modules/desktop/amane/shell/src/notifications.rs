use std::thread;
use std::time::{Duration, SystemTime};

use amane::{
    Align, Button, Center, Color, Column, Horizontal, Image, Key, LayerWindow, Margin, Monitor,
    Notification, Notifications, Parent, Pointer, Rectangle, Row, ScrollArea, Service,
    SpaceBetween, Urgency, Vertical, Weight, Widget, children,
};

use crate::icons::Icons;
use crate::panel;
use crate::theme::Theme;
use crate::tray::strip_markup;
use crate::ui::{self, BAR_HEIGHT, MENU_FONT, MENU_TEXT};

// swaync's notification-window-width and notification-icon-size
const POPUP_WIDTH: f32 = 380.0;
const ICON: f32 = 50.0;
pub const MARGIN: f32 = 10.0;

// the panel's tabs, see panel.rs
#[derive(Default, Clone, Copy, PartialEq)]
pub enum Page {
    #[default]
    Home,
    Audio,
    Network,
    Bluetooth,
    Calendar,
    Notifications,
}

// the state of the panel that holds the notification center
#[derive(Default)]
pub struct NotificationCenter {
    pub open: bool,
    pub page: Page,
    pub monitor: String,
    pub dnd: bool,
    // popups from before the center last closed stay gone, as in swaync
    popups_after: Option<SystemTime>,
}

impl Service for NotificationCenter {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

// redraws popups when one times out, and the center once a minute for its timestamps
#[derive(Default)]
pub struct Tick {
    popups: Vec<u32>,
    minute: u64,
}

impl Service for Tick {
    fn new() -> Self {
        Self::default()
    }

    fn update(&mut self) -> bool {
        let popups: Vec<u32> = popups(&Notifications::read(), &NotificationCenter::read())
            .iter()
            .map(|notification| notification.id())
            .collect();

        let minute = seconds_since(SystemTime::UNIX_EPOCH) / 60;

        let changed = popups != self.popups || minute != self.minute;

        self.popups = popups;
        self.minute = minute;

        changed
    }
}

// the one monitor notification popups show on, whichever monitor has focus
#[derive(Default)]
pub struct MainOutput {
    name: String,
}

impl Service for MainOutput {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        loop {
            refresh_main_output();

            // sway announces every monitor added, removed or moved
            for _ in amane::lines(r#"swaymsg -r -m -t subscribe '["output"]'"#) {
                refresh_main_output();
            }

            // not running under sway, or sway is going away
            thread::sleep(Duration::from_secs(5));
        }
    }
}

fn refresh_main_output() {
    let outputs = serde_json::from_str(&amane::output("swaymsg -r -t get_outputs")).unwrap_or_default();
    let name = main_output(&outputs);

    if MainOutput::read().name != name {
        MainOutput::write().name = name;
    }
}

// the leftmost, then topmost, enabled monitor: DP-1 on desktop, the laptop panel on g14
fn main_output(outputs: &serde_json::Value) -> String {
    outputs
        .as_array()
        .into_iter()
        .flatten()
        .filter(|output| output["active"] == true)
        .min_by_key(|output| (output["rect"]["x"].as_i64(), output["rect"]["y"].as_i64()))
        .and_then(|output| output["name"].as_str())
        .unwrap_or_default()
        .to_string()
}

// swaync's timeout, timeout-low and timeout-critical (0 = stays until closed)
fn timeout(notification: &Notification) -> Option<u64> {
    // amane-calendar's reminders stay until closed, like Noctalia's (its server drops expire_timeout)
    if notification.app_name() == "Calendar" {
        return None;
    }
    match notification.urgency() {
        Urgency::Low => Some(3),
        Urgency::Normal => Some(5),
        Urgency::Critical => None,
    }
}

fn seconds_since(time: SystemTime) -> u64 {
    SystemTime::now()
        .duration_since(time)
        .unwrap_or_default()
        .as_secs()
}

// newest first, like swaync
fn popups<'a>(notifications: &'a Notifications, center: &NotificationCenter) -> Vec<&'a Notification> {
    if center.dnd || center.open {
        return Vec::new();
    }

    notifications
        .list()
        .iter()
        .rev()
        // swaync's notification-visibility rule: low Spotify notifications are muted
        .filter(|notification| !(notification.app_name() == "Spotify" && notification.urgency() == Urgency::Low))
        .filter(|notification| center.popups_after.is_none_or(|after| notification.received() > after))
        .filter(|notification| {
            timeout(notification).is_none_or(|limit| seconds_since(notification.received()) < limit)
        })
        .collect()
}

// the keybind still means notifications; the bar's modules open their own pages
pub fn toggle(_: &[String]) -> String {
    toggle_page(Page::Notifications)
}

// a module's second click closes its page; another module's click moves the panel
pub fn toggle_from_bar(page: Page) {
    let center = NotificationCenter::read();
    let same = center.open && center.page == page;
    drop(center);

    if same {
        close();
    } else {
        show(page);
    }
}

// opens the panel on a page, or moves an open panel to it
pub fn show(page: Page) {
    if NotificationCenter::read().open {
        panel::select(page);
    } else {
        toggle_page(page);
    }
}

fn toggle_page(page: Page) -> String {
    if NotificationCenter::read().open {
        close();

        return String::from("closed");
    }

    let monitor = ui::focused_output();
    let mut center = NotificationCenter::write();

    center.open = true;
    center.page = page;
    center.monitor = monitor;
    drop(center);

    panel::entered(page);

    String::from("opened")
}

/*
 * popups waiting behind the center must not show in the frame it hides: Amane would
 * ack a configure the compositor already dropped (wrong configure serial) and die
 */
pub fn close() {
    let mut center = NotificationCenter::write();

    if center.open {
        center.open = false;
        center.popups_after = Some(SystemTime::now());

        let page = center.page;
        drop(center);

        panel::left(page);
    }
}

pub fn toggle_dnd() {
    let mut center = NotificationCenter::write();
    center.dnd = !center.dnd;
}

pub fn center_key(key: Key) {
    match key {
        Key::Escape => panel::dismiss(),
        // only with the list on screen, so a stray key on the home page can't wipe it unseen
        Key::Character('c') if NotificationCenter::read().page == Page::Notifications => Notifications::clear(),
        Key::Character('d') => toggle_dnd(),
        _ => {}
    }
}

fn relative(received: SystemTime) -> String {
    let seconds = seconds_since(received);

    match seconds {
        0..60 => String::from("now"),
        60..3600 => format!("{} min ago", seconds / 60),
        3600..86400 => format!("{} h ago", seconds / 3600),
        _ => format!("{} d ago", seconds / 86400),
    }
}

fn urgency_color(notification: &Notification, base: &[Color; 16]) -> Color {
    match notification.urgency() {
        Urgency::Critical => base[8],
        Urgency::Low => base[3],
        Urgency::Normal => base[0x0E],
    }
}

// the card swaync draws: icon, title, time, close button, body and action buttons
fn card(notification: &Notification, width: f32, in_center: bool, icons: &Icons, base: &[Color; 16]) -> Rectangle {
    let id = notification.id();
    let inner = width - 22.0;

    let icon_path = icons
        .find(notification.image())
        .or_else(|| icons.find(notification.icon()));

    let text_width = if icon_path.is_some() { inner - ICON - 10.0 } else { inner };

    let summary = ui::text(notification.summary(), MENU_TEXT, MENU_FONT)
        .color(base[5])
        .weight(Weight::from(700))
        .elide();

    let mut header: Vec<Box<dyn Widget>> = vec![Box::new(summary)];

    if in_center {
        header.push(Box::new(
            ui::text(relative(notification.received()), MENU_TEXT - 3.0, MENU_FONT).color(base[4]),
        ));
    }

    header.push(Box::new(
        Rectangle::new()
            .width(18.0)
            .height(18.0)
            .cursor(Pointer)
            .on_click(move |_| Notifications::dismiss(id))
            .align_child(Center, Center)
            .child(ui::text("\u{F0156}", MENU_TEXT, MENU_FONT).color(base[4])),
    ));

    let line = ui::height_of(&ui::text("A", MENU_TEXT, MENU_FONT));

    let body_text = strip_markup(notification.body());
    let body = ui::text(body_text.trim(), MENU_TEXT - 1.0, MENU_FONT)
        .color(base[4])
        .wrap()
        .max_lines(4);
    let body_height = if body_text.trim().is_empty() {
        0.0
    } else {
        body.height_in(text_width).min(line * 4.0)
    };

    let mut text_column: Vec<Box<dyn Widget>> = vec![Box::new(
        Row::new(header).width(text_width).height(line).gap(6.0).align(Center),
    )];

    if body_height > 0.0 {
        text_column.push(Box::new(Rectangle::new().width(text_width).height(body_height).child(body)));
    }

    let text_height = line + body_height + if body_height > 0.0 { 4.0 } else { 0.0 };

    let mut top: Vec<Box<dyn Widget>> = Vec::new();

    if let Some(path) = icon_path {
        top.push(Box::new(
            Rectangle::new()
                .width(ICON)
                .height(ICON)
                .radius(6.0)
                .clip()
                .fill(Image::contain(path).thumbnail(100, 100)),
        ));
    }

    top.push(Box::new(Column::new(text_column).gap(4.0)));

    let top_height = text_height.max(if top.len() > 1 { ICON } else { 0.0 });

    let mut rows: Vec<Box<dyn Widget>> = vec![Box::new(Row::new(top).gap(10.0).height(top_height))];
    let mut height = top_height;

    if !notification.actions().is_empty() {
        let buttons: Vec<Box<dyn Widget>> = notification
            .actions()
            .iter()
            .map(|action| {
                let key = action.key().to_string();

                Box::new(
                    Rectangle::new()
                        .width(Parent)
                        .height(28.0)
                        .fill(base[2])
                        .cursor(Pointer)
                        .on_click(move |_| invoked(id, &key))
                        .align_child(Center, Center)
                        .child(ui::text(action.label(), MENU_TEXT - 1.0, MENU_FONT).color(base[5]).elide()),
                ) as Box<dyn Widget>
            })
            .collect();

        rows.push(Box::new(Row::new(buttons).width(inner).height(28.0).gap(6.0)));
        height += 28.0 + 8.0;
    }

    Rectangle::new()
        .width(width)
        .height(height + 22.0)
        .radius(if in_center { 8.0 } else { 0.0 })
        .fill(base[1])
        .border(1.0, urgency_color(notification, base))
        .padding(11.0)
        .cursor(Pointer)
        .on_click(move |button| clicked(id, button))
        .child(Column::new(rows).gap(8.0))
}

// a click runs the default action or dismisses; hide-on-action closes the center
fn clicked(id: u32, button: Button) {
    match button {
        Button::Left => Notifications::click(id),
        _ => Notifications::dismiss(id),
    }

    close();
}

fn invoked(id: u32, key: &str) {
    Notifications::invoke(id, key);
    close();
}

pub fn popups_view(monitor: &Monitor) -> LayerWindow {
    let notifications = Notifications::read();
    let center = NotificationCenter::read();
    let _tick = Tick::read();
    let icons = Icons::read();
    let theme = Theme::read();
    let main = MainOutput::read();

    let shown = popups(&notifications, &center);
    let room = monitor.height as f32 - BAR_HEIGHT - MARGIN * 2.0;

    let mut cards: Vec<Box<dyn Widget>> = Vec::new();
    let mut height = 0.0;

    for notification in shown {
        let card = card(notification, POPUP_WIDTH, false, &icons, &theme.base);
        let card_height = ui::height_of(&card);

        if height + card_height > room {
            break;
        }

        height += card_height + 8.0;
        cards.push(Box::new(card));
    }

    let visible = !cards.is_empty() && ui::shown_on(&main.name, monitor);

    LayerWindow::new()
        .width(POPUP_WIDTH)
        .height(height.max(1.0))
        .anchor_vertical(Vertical::Top)
        .anchor_horizontal(Horizontal::Right)
        .margin(Margin {
            top: MARGIN as i32,
            right: MARGIN as i32,
            ..Margin::default()
        })
        .namespace("amane-notifications")
        .visible(visible)
        .child(Column::new(cards).gap(8.0))
}

// the panel's notifications tab
pub fn page(inner: f32, dnd: bool, base: &[Color; 16]) -> Column {
    let notifications = Notifications::read();
    let icons = Icons::read();

    let dnd_switch = Rectangle::new()
        .width(44.0)
        .height(22.0)
        .radius(11.0)
        .fill(if dnd { base[0x0E] } else { base[2] })
        .padding(3.0)
        .align_child(if dnd { Align::End } else { Align::Start }, Center)
        .cursor(Pointer)
        .on_click(|_| toggle_dnd())
        .child(Rectangle::new().width(16.0).height(16.0).radius(8.0).fill(base[5]));

    let clear = Rectangle::new()
        .width(40.0)
        .height(28.0)
        .radius(8.0)
        .fill(base[2])
        .cursor(Pointer)
        .on_click(|_| Notifications::clear())
        .align_child(Center, Center)
        .child(ui::text(" \u{F01B4} ", MENU_TEXT, MENU_FONT).color(base[5]));

    let controls = Row::new(children![
        ui::text("Do Not Disturb", MENU_TEXT, MENU_FONT).color(base[5]),
        Row::new(children![dnd_switch, clear]).gap(8.0).align(Center),
    ])
    .width(inner)
    .height(28.0)
    .justify(SpaceBetween)
    .align(Center);

    let list: Box<dyn Widget> = if notifications.list().is_empty() {
        Box::new(
            Rectangle::new()
                .width(inner)
                .height(Parent)
                .align_child(Center, Center)
                .child(ui::text("No Notifications", MENU_TEXT, MENU_FONT).color(base[3])),
        )
    } else {
        let cards: Vec<Box<dyn Widget>> = notifications
            .list()
            .iter()
            .rev()
            .map(|notification| Box::new(card(notification, inner, true, &icons, base)) as Box<dyn Widget>)
            .collect();

        Box::new(ScrollArea::new("notification-center", Column::new(cards).gap(8.0)).width(inner))
    };

    Column::new(vec![Box::new(controls), list]).gap(10.0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn picks_the_top_left_monitor() {
        let outputs = serde_json::json!([
            {"name": "HDMI-A-1", "active": true, "rect": {"x": 2560, "y": 0}},
            {"name": "eDP-1", "active": false, "rect": {"x": 0, "y": 0}},
            {"name": "DP-1", "active": true, "rect": {"x": 0, "y": 0}}
        ]);

        assert_eq!(main_output(&outputs), "DP-1");
        assert_eq!(main_output(&serde_json::json!([])), "");
    }
}
