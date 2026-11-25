use std::time::{Duration, SystemTime};

use amane::{Button, Key, Notification, Notifications, Service, Urgency};

use crate::logic::compositor;
use crate::logic::panel;

// the panel's tabs, see looks/sway/panel.rs
#[derive(Default, Clone, Copy, PartialEq)]
pub enum Page {
    #[default]
    Home,
    Audio,
    Network,
    Bluetooth,
    Calendar,
    Usage,
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
pub fn popups<'a>(notifications: &'a Notifications, center: &NotificationCenter) -> Vec<&'a Notification> {
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

    let monitor = compositor::focused_output();
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

pub fn relative(received: SystemTime) -> String {
    let seconds = seconds_since(received);

    match seconds {
        0..60 => String::from("now"),
        60..3600 => format!("{} min ago", seconds / 60),
        3600..86400 => format!("{} h ago", seconds / 3600),
        _ => format!("{} d ago", seconds / 86400),
    }
}

// a click runs the default action or dismisses; hide-on-action closes the center
pub fn clicked(id: u32, button: Button) {
    match button {
        Button::Left => Notifications::click(id),
        _ => Notifications::dismiss(id),
    }

    close();
}

pub fn invoked(id: u32, key: &str) {
    Notifications::invoke(id, key);
    close();
}
