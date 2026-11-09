use std::collections::HashMap;
use std::collections::hash_map::DefaultHasher;
use std::fs;
use std::hash::{Hash, Hasher};
use std::path::PathBuf;
use std::sync::OnceLock;
use std::sync::atomic::{AtomicU32, Ordering};
use std::thread;
use std::time::Duration;

use amane::{
    Button, Center, Color, Column, Full, Image, Key, LayerWindow, Margin, Monitor, Padding,
    Parent, Pointer, Rectangle, Row, Scroll, Service, Start, Vertical, Widget,
};
use zbus::blocking::{Connection, MessageIterator, connection};
use zbus::message::Header;
use zbus::object_server::SignalEmitter;
use zbus::zvariant::{OwnedObjectPath, OwnedValue, Value};
use zbus::{MatchRule, interface};

use crate::icons::{self, Icons};
use crate::theme::Theme;
use crate::ui::{self, BAR_HEIGHT, MENU_FONT, MENU_TEXT, Placement};

const ITEM: &str = "org.kde.StatusNotifierItem";
const MENU: &str = "com.canonical.dbusmenu";

static BUS: OnceLock<Connection> = OnceLock::new();

// where the pointer last was over a bar, so a menu opens under the icon that was clicked
static POINTER_X: AtomicU32 = AtomicU32::new(0);

pub fn track_pointer(x: f32) {
    POINTER_X.store(x.to_bits(), Ordering::Relaxed);
}

fn pointer_x() -> f32 {
    f32::from_bits(POINTER_X.load(Ordering::Relaxed))
}

#[derive(Clone, Default)]
pub struct Item {
    pub bus: String,
    pub path: String,
    owner: String,
    pub title: String,
    pub status: String,
    pub tooltip: String,
    pub icon_name: String,
    pub icon_file: Option<PathBuf>,
    pub menu: Option<String>,
    pub item_is_menu: bool,
}

impl Item {
    fn id(&self) -> String {
        format!("{}{}", self.bus, self.path)
    }
}

// the StatusNotifierWatcher and host in one: waybar's tray
#[derive(Default)]
pub struct Tray {
    pub items: Vec<Item>,
}

impl Service for Tray {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        let connection = connection::Builder::session()
            .and_then(|builder| builder.serve_at("/StatusNotifierWatcher", Watcher))
            .and_then(|builder| builder.build())
            .expect("failed to connect to the session bus");

        let _ = BUS.set(connection.clone());

        // items re-register when a watcher appears, so apps started earlier show up too
        if connection.request_name("org.kde.StatusNotifierWatcher").is_err() {
            eprintln!("amane-shell: another tray watcher is running, the tray stays empty");
            return;
        }

        thread::spawn(follow_item_signals);

        let rule = MatchRule::builder()
            .msg_type(zbus::message::Type::Signal)
            .sender("org.freedesktop.DBus")
            .and_then(|rule| rule.interface("org.freedesktop.DBus"))
            .and_then(|rule| rule.member("NameOwnerChanged"))
            .map(|rule| rule.build())
            .expect("failed to build match rule");

        let messages = MessageIterator::for_match_rule(rule, &connection, None)
            .expect("failed to follow name owners");

        for message in messages.flatten() {
            let Ok((name, _, new)) = message.body().deserialize::<(String, String, String)>() else {
                continue;
            };

            if new.is_empty() {
                remove_items(&name);
            }
        }
    }
}

fn connection() -> Option<&'static Connection> {
    BUS.get()
}

fn remove_items(name: &str) {
    let gone: Vec<String> = Tray::read()
        .items
        .iter()
        .filter(|item| item.bus == name || item.owner == name)
        .map(Item::id)
        .collect();

    if gone.is_empty() {
        return;
    }

    Tray::write()
        .items
        .retain(|item| item.bus != name && item.owner != name);

    let Some(connection) = connection() else {
        return;
    };

    for id in gone {
        let _ = connection.emit_signal(
            None::<&str>,
            "/StatusNotifierWatcher",
            "org.kde.StatusNotifierWatcher",
            "StatusNotifierItemUnregistered",
            &(id,),
        );
    }
}

struct Watcher;

#[interface(name = "org.kde.StatusNotifierWatcher")]
impl Watcher {
    async fn register_status_notifier_item(
        &self,
        service: &str,
        #[zbus(header)] header: Header<'_>,
        #[zbus(signal_emitter)] emitter: SignalEmitter<'_>,
    ) {
        let sender = header.sender().map(|name| name.to_string()).unwrap_or_default();

        // ayatana sends only its object path, others send a bus name, some both
        let (bus, path) = match service.find('/') {
            Some(0) => (sender, service.to_string()),
            Some(at) => (service[..at].to_string(), service[at..].to_string()),
            None => (service.to_string(), String::from("/StatusNotifierItem")),
        };

        let id = format!("{bus}{path}");

        thread::spawn(move || add_item(bus, path));

        let _ = Self::status_notifier_item_registered(&emitter, &id).await;
    }

    async fn register_status_notifier_host(
        &self,
        _service: &str,
        #[zbus(signal_emitter)] emitter: SignalEmitter<'_>,
    ) {
        let _ = Self::status_notifier_host_registered(&emitter).await;
    }

    #[zbus(property)]
    fn registered_status_notifier_items(&self) -> Vec<String> {
        Tray::read().items.iter().map(Item::id).collect()
    }

    #[zbus(property)]
    fn is_status_notifier_host_registered(&self) -> bool {
        true
    }

    #[zbus(property)]
    fn protocol_version(&self) -> i32 {
        0
    }

    #[zbus(signal)]
    async fn status_notifier_item_registered(
        emitter: &SignalEmitter<'_>,
        service: &str,
    ) -> zbus::Result<()>;

    #[zbus(signal)]
    async fn status_notifier_host_registered(emitter: &SignalEmitter<'_>) -> zbus::Result<()>;
}

fn add_item(bus: String, path: String) {
    let Some(connection) = connection() else {
        return;
    };

    let owner = zbus::blocking::fdo::DBusProxy::new(connection)
        .ok()
        .and_then(|proxy| proxy.get_name_owner(bus.as_str().try_into().ok()?).ok())
        .map(|owner| owner.to_string())
        .unwrap_or_else(|| bus.clone());

    let mut item = Item {
        bus,
        path,
        owner,
        ..Item::default()
    };

    if !refresh(&mut item) {
        return;
    }

    let mut tray = Tray::write();

    match tray.items.iter_mut().find(|known| known.id() == item.id()) {
        Some(known) => *known = item,
        None => tray.items.push(item),
    }
}

// one stream for every item's NewIcon, NewStatus, NewTitle and NewToolTip
fn follow_item_signals() {
    let Some(connection) = connection() else {
        return;
    };

    let rule = MatchRule::builder()
        .msg_type(zbus::message::Type::Signal)
        .interface(ITEM)
        .map(|rule| rule.build())
        .expect("failed to build match rule");

    let Ok(messages) = MessageIterator::for_match_rule(rule, connection, None) else {
        return;
    };

    for message in messages.flatten() {
        let header = message.header();

        let sender = header.sender().map(|name| name.to_string()).unwrap_or_default();
        let path = header.path().map(|path| path.to_string()).unwrap_or_default();

        let found = Tray::read()
            .items
            .iter()
            .find(|item| item.owner == sender && item.path == path)
            .cloned();

        let Some(mut item) = found else {
            continue;
        };

        if refresh(&mut item)
            && let Some(known) = Tray::write().items.iter_mut().find(|known| known.id() == item.id())
        {
            *known = item;
        }
    }
}

// reads every property at once; false when the item doesn't answer
fn refresh(item: &mut Item) -> bool {
    let Some(connection) = connection() else {
        return false;
    };

    let Ok(reply) = connection.call_method(
        Some(item.bus.as_str()),
        item.path.as_str(),
        Some("org.freedesktop.DBus.Properties"),
        "GetAll",
        &(ITEM,),
    ) else {
        return false;
    };

    let Ok(properties) = reply.body().deserialize::<HashMap<String, OwnedValue>>() else {
        return false;
    };

    let text = |name: &str| -> String {
        properties
            .get(name)
            .and_then(|value| String::try_from(value.clone()).ok())
            .unwrap_or_default()
    };

    item.title = text("Title");
    item.status = text("Status");

    let attention = item.status == "NeedsAttention";

    let (name, pixmap) = if attention && !text("AttentionIconName").is_empty() {
        (text("AttentionIconName"), "AttentionIconPixmap")
    } else {
        (text("IconName"), "IconPixmap")
    };

    item.icon_name = name;

    let previous = item.icon_file.take();

    item.icon_file = icons::find_in(&text("IconThemePath"), &item.icon_name).or_else(|| {
        properties
            .get(pixmap)
            .and_then(|value| <Vec<(i32, i32, Vec<u8>)>>::try_from(value.clone()).ok())
            .and_then(|pixmaps| save_pixmap(&pixmaps))
    });

    // a replaced pixmap file is only ours to remove when it changed
    if let Some(previous) = previous
        && Some(&previous) != item.icon_file.as_ref()
        && previous.starts_with(runtime_dir())
    {
        let _ = fs::remove_file(previous);
    }

    item.tooltip = properties
        .get("ToolTip")
        .and_then(|value| <(String, Vec<(i32, i32, Vec<u8>)>, String, String)>::try_from(value.clone()).ok())
        .map(|(_, _, title, body)| strip_markup(&[title, body].join("\n")).trim().to_string())
        .filter(|tip| !tip.is_empty())
        .unwrap_or_else(|| item.title.clone());

    item.menu = properties
        .get("Menu")
        .and_then(|value| OwnedObjectPath::try_from(value.clone()).ok())
        .map(|path| path.to_string())
        .filter(|path| path != "/");

    item.item_is_menu = properties
        .get("ItemIsMenu")
        .and_then(|value| bool::try_from(value.clone()).ok())
        .unwrap_or(false);

    true
}

pub fn runtime_dir() -> PathBuf {
    std::env::var_os("XDG_RUNTIME_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(std::env::temp_dir)
        .join("amane-shell")
}

// ARGB32 in network byte order, the size closest above 32 pixels
fn save_pixmap(pixmaps: &[(i32, i32, Vec<u8>)]) -> Option<PathBuf> {
    let (width, height, argb) = pixmaps
        .iter()
        .filter(|(width, height, data)| *width > 0 && data.len() == (*width * *height * 4) as usize)
        .min_by_key(|(width, _, _)| if *width >= 32 { *width - 32 } else { 1000 - *width })?;

    let mut rgba = Vec::with_capacity(argb.len());

    for pixel in argb.as_chunks::<4>().0 {
        rgba.extend_from_slice(&[pixel[1], pixel[2], pixel[3], pixel[0]]);
    }

    let mut hasher = DefaultHasher::new();
    rgba.hash(&mut hasher);

    let dir = runtime_dir();
    fs::create_dir_all(&dir).ok()?;

    let path = dir.join(format!("tray-{:x}.png", hasher.finish()));

    if path.exists() {
        return Some(path);
    }

    let file = fs::File::create(&path).ok()?;
    let mut encoder = png::Encoder::new(file, *width as u32, *height as u32);
    encoder.set_color(png::ColorType::Rgba);
    encoder.set_depth(png::BitDepth::Eight);
    encoder.write_header().ok()?.write_image_data(&rgba).ok()?;

    Some(path)
}

pub fn strip_markup(text: &str) -> String {
    let mut plain = String::new();
    let mut in_tag = false;

    for letter in text.chars() {
        match letter {
            '<' => in_tag = true,
            '>' if in_tag => in_tag = false,
            _ if !in_tag => plain.push(letter),
            _ => {}
        }
    }

    plain
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", "\"")
        .replace("&apos;", "'")
        .replace("&#39;", "'")
        .replace("&amp;", "&")
}

fn send<B>(item: &Item, method: &'static str, body: B)
where
    B: zbus::export::serde::Serialize + zbus::zvariant::DynamicType + Send + 'static,
{
    let Some(connection) = connection() else {
        return;
    };

    let (bus, path) = (item.bus.clone(), item.path.clone());

    thread::spawn(move || {
        let _ = connection.call_method(Some(bus.as_str()), path.as_str(), Some(ITEM), method, &body);
    });
}

// waybar: left activates (or opens the menu of a menu-only item), middle secondary, right the menu
pub fn clicked(item: &Item, button: Button, monitor: &str) {
    let x = pointer_x() as i32;

    match button {
        Button::Left if !item.item_is_menu => {
            send(item, "Activate", (x, 0i32));
        }
        Button::Middle => send(item, "SecondaryActivate", (x, 0i32)),
        _ => match &item.menu {
            Some(_) => open_menu(item.clone(), monitor.to_string()),
            None => send(item, "ContextMenu", (x, 0i32)),
        },
    }
}

pub fn scrolled(item: &Item, scroll: Scroll) {
    let (delta, orientation) = if scroll.y != 0.0 {
        (scroll.y.signum() as i32, "vertical")
    } else {
        (scroll.x.signum() as i32, "horizontal")
    };

    send(item, "Scroll", (delta, orientation));
}

// hover text for the tray, waybar shows the item's tooltip
#[derive(Default)]
pub struct Tip {
    pub text: String,
    pub monitor: String,
}

impl Service for Tip {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

pub fn hovered(item: &Item, inside: bool, monitor: &str) {
    let mut tip = Tip::write();

    if inside {
        tip.text = item.tooltip.clone();
        tip.monitor = monitor.to_string();
    } else if tip.text == item.tooltip {
        tip.text.clear();
    }
}

pub fn tip_view(monitor: &Monitor) -> LayerWindow {
    let tip = Tip::read();
    let theme = Theme::read();

    let visible = !tip.text.is_empty() && tip.monitor == monitor.name;

    let label = ui::text(tip.text.replace('\n', "  "), MENU_TEXT - 1.0, MENU_FONT).color(theme.base[5]);
    let width = ui::width_of(&label) + 16.0;
    let left = (pointer_x() - width / 2.0).clamp(0.0, (monitor.width as f32 - width).max(0.0));

    // a full-width strip that never moves: only the drawing follows the pointer, so the
    // compositor sees no layer changes besides showing and hiding (see notifications::close)
    LayerWindow::new()
        .width(Full)
        .height(26.0)
        .anchor_vertical(Vertical::Top)
        .margin(Margin {
            top: 4,
            ..Margin::default()
        })
        .namespace("amane-tooltip")
        .click_through()
        .visible(visible)
        .child(
            Rectangle::new()
                .width(Parent)
                .height(Parent)
                .padding(Padding {
                    left,
                    ..Padding::default()
                })
                .align_child(Start, Center)
                .child(
                    Rectangle::new()
                        .width(width)
                        .height(Parent)
                        .fill(theme.base[1])
                        .border(1.0, theme.base[3])
                        .align_child(Center, Center)
                        .child(label),
                ),
        )
}

#[derive(Clone, Default)]
struct Entry {
    id: i32,
    label: String,
    enabled: bool,
    separator: bool,
    toggle: String,
    toggled: bool,
    submenu: bool,
    children: Vec<Entry>,
}

// the open tray menu: the item it belongs to, its layout, and the submenus walked into
#[derive(Default)]
pub struct TrayMenu {
    open: bool,
    monitor: String,
    x: f32,
    bus: String,
    path: String,
    root: Entry,
    trail: Vec<usize>,
    selected: usize,
}

impl Service for TrayMenu {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

fn open_menu(item: Item, monitor: String) {
    let x = pointer_x();
    let Some(path) = item.menu.clone() else {
        return;
    };

    // hidden now, a frame before the menu shows; the next hover brings it back
    Tip::write().text.clear();

    thread::spawn(move || {
        let Some(root) = layout(&item.bus, &path, 0) else {
            return;
        };

        *TrayMenu::write() = TrayMenu {
            open: true,
            monitor,
            x,
            bus: item.bus,
            path,
            root,
            trail: Vec::new(),
            selected: 0,
        };
    });
}

fn layout(bus: &str, path: &str, parent: i32) -> Option<Entry> {
    let connection = connection()?;

    // electron and others fill a submenu only when told it is about to show
    let _ = connection.call_method(Some(bus), path, Some(MENU), "AboutToShow", &(parent,));

    let reply = connection
        .call_method(
            Some(bus),
            path,
            Some(MENU),
            "GetLayout",
            &(parent, -1i32, Vec::<String>::new()),
        )
        .ok()?;

    let (_, node) = reply
        .body()
        .deserialize::<(u32, (i32, HashMap<String, OwnedValue>, Vec<OwnedValue>))>()
        .ok()?;

    Some(entry(node))
}

fn entry((id, properties, children): (i32, HashMap<String, OwnedValue>, Vec<OwnedValue>)) -> Entry {
    let text = |name: &str| {
        properties
            .get(name)
            .and_then(|value| String::try_from(value.clone()).ok())
    };

    let flag = |name: &str| {
        properties
            .get(name)
            .and_then(|value| bool::try_from(value.clone()).ok())
    };

    let children = children
        .into_iter()
        .filter_map(|child| {
            let value: Value = child.into();

            // each child arrives wrapped in a variant
            let inner = match value {
                Value::Value(inner) => *inner,
                other => other,
            };

            <(i32, HashMap<String, OwnedValue>, Vec<OwnedValue>)>::try_from(inner).ok()
        })
        .filter(|(_, properties, _)| {
            properties
                .get("visible")
                .and_then(|value| bool::try_from(value.clone()).ok())
                .unwrap_or(true)
        })
        .map(entry)
        .collect::<Vec<_>>();

    Entry {
        id,
        label: mnemonic(&text("label").unwrap_or_default()),
        enabled: flag("enabled").unwrap_or(true),
        separator: text("type").as_deref() == Some("separator"),
        toggle: text("toggle-type").unwrap_or_default(),
        toggled: properties
            .get("toggle-state")
            .and_then(|value| i32::try_from(value.clone()).ok())
            == Some(1),
        submenu: text("children-display").as_deref() == Some("submenu") || !children.is_empty(),
        children,
    }
}

// "_File" shows as "File", "__" is a real underscore
fn mnemonic(label: &str) -> String {
    label.replace("__", "\u{0}").replace('_', "").replace('\u{0}', "_")
}

fn current(menu: &TrayMenu) -> &Entry {
    let mut node = &menu.root;

    for &index in &menu.trail {
        match node.children.get(index) {
            Some(child) => node = child,
            None => break,
        }
    }

    node
}

fn close_menu() {
    TrayMenu::write().open = false;
}

fn activate(index: usize) {
    let (bus, path, chosen) = {
        let menu = TrayMenu::read();
        let Some(chosen) = current(&menu).children.get(index).cloned() else {
            return;
        };
        (menu.bus.clone(), menu.path.clone(), chosen)
    };

    if chosen.separator || !chosen.enabled {
        return;
    }

    if chosen.submenu {
        thread::spawn(move || {
            let fresh = layout(&bus, &path, chosen.id);

            let mut menu = TrayMenu::write();
            menu.trail.push(index);
            menu.selected = 0;

            if let Some(fresh) = fresh {
                let trail = menu.trail.clone();
                let mut node = &mut menu.root;

                for at in trail {
                    match node.children.get_mut(at) {
                        Some(child) => node = child,
                        None => return,
                    }
                }

                node.children = fresh.children;
            }
        });

        return;
    }

    close_menu();

    thread::spawn(move || {
        if let Some(connection) = connection() {
            let _ = connection.call_method(
                Some(bus.as_str()),
                path.as_str(),
                Some(MENU),
                "Event",
                &(chosen.id, "clicked", Value::from(0i32), 0u32),
            );
        }
    });
}

fn back() {
    let mut menu = TrayMenu::write();

    if menu.trail.pop().is_none() {
        menu.open = false;
    }

    menu.selected = 0;
}

fn menu_key(key: Key) {
    let count = {
        let menu = TrayMenu::read();
        current(&menu).children.len()
    };

    match key {
        Key::Escape | Key::Left | Key::Backspace => back(),
        Key::Down | Key::Tab if count > 0 => {
            let mut menu = TrayMenu::write();
            menu.selected = (menu.selected + 1) % count;
        }
        Key::Up if count > 0 => {
            let mut menu = TrayMenu::write();
            menu.selected = (menu.selected + count - 1) % count;
        }
        Key::Enter | Key::Right | Key::Space => {
            let selected = TrayMenu::read().selected;
            activate(selected);
        }
        _ => {}
    }
}

pub fn menu_view(monitor: &Monitor) -> LayerWindow {
    let menu = TrayMenu::read();
    let theme = Theme::read();

    let visible = menu.open && menu.monitor == monitor.name;
    let node = current(&menu);

    let mut rows: Vec<Box<dyn Widget>> = Vec::new();

    if !menu.trail.is_empty() {
        rows.push(Box::new(menu_row("‹ Back".into(), true, false, theme.base, |_| back())));
    }

    for (index, child) in node.children.iter().enumerate() {
        if child.separator {
            rows.push(Box::new(Rectangle::new().width(Parent).height(1.0).fill(theme.base[3])));
            continue;
        }

        let mark = match (child.toggle.as_str(), child.toggled) {
            ("checkmark", true) => "✓ ",
            ("radio", true) => "● ",
            ("radio", false) => "○ ",
            ("checkmark", false) => "  ",
            _ => "",
        };

        let arrow = if child.submenu { "  ›" } else { "" };

        rows.push(Box::new(menu_row(
            format!("{mark}{}{arrow}", child.label),
            child.enabled,
            index == menu.selected,
            theme.base,
            move |_| activate(index),
        )));
    }

    if rows.is_empty() {
        rows.push(Box::new(menu_row("(empty)".into(), false, false, theme.base, |_| {})));
    }

    let height: f32 = rows.iter().map(|row| ui::height_of(row.as_ref())).sum::<f32>() + 10.0;

    let width = 260.0;
    let left = (menu.x - 20.0).clamp(0.0, (monitor.width as f32 - width).max(0.0));

    let panel = ui::swallow_clicks(
        Rectangle::new()
            .width(width)
            .height(height)
            .fill(theme.base[0])
            .border(1.0, theme.base[0x0A])
            .padding(5.0)
            .child(Column::new(rows)),
    );

    ui::overlay(
        "amane-traymenu",
        visible,
        Placement {
            horizontal: amane::Align::Start,
            vertical: amane::Align::Start,
            padding: Padding {
                top: BAR_HEIGHT,
                left,
                ..Padding::default()
            },
        },
        close_menu,
        menu_key,
        panel,
    )
}

fn menu_row(
    label: String,
    enabled: bool,
    selected: bool,
    base: [Color; 16],
    clicked: impl Fn(Button) + 'static,
) -> Rectangle {
    let (fill, color) = match (selected, enabled) {
        (true, true) => (base[0x0A], base[0]),
        (_, false) => (Color::TRANSPARENT, base[3]),
        _ => (Color::TRANSPARENT, base[5]),
    };

    Rectangle::new()
        .width(Parent)
        .height(26.0)
        .fill(fill)
        .padding(Padding {
            left: 8.0,
            right: 8.0,
            ..Padding::default()
        })
        .align_child(Start, Center)
        .cursor(Pointer)
        .on_click(clicked)
        .child(ui::text(label, MENU_TEXT - 1.0, MENU_FONT).color(color).elide())
}

// tray icons for the bar: 16 pixel icons, 8 apart, passive items hidden like waybar does
pub fn icons(monitor: &str) -> Row {
    let tray = Tray::read();
    let icons = Icons::read();
    let theme = Theme::read();

    let mut row: Vec<Box<dyn Widget>> = Vec::new();

    for item in tray.items.iter().filter(|item| item.status != "Passive") {
        let icon = item.icon_file.clone().or_else(|| icons.find(&item.icon_name));

        let base = Rectangle::new().width(16.0).height(16.0);

        let base = match icon {
            Some(path) => base.fill(Image::contain(path).thumbnail(16, 16)),
            // no icon found: the first letter of its title stands in
            None => base.align_child(Center, Center).child(
                ui::text(item.title.chars().next().unwrap_or('?').to_string(), 11.0, ui::BAR_FONT)
                    .color(theme.base[5]),
            ),
        };

        let (clicked, scrolled, hovered) = (item.clone(), item.clone(), item.clone());
        let (on_click_monitor, on_hover_monitor) = (monitor.to_string(), monitor.to_string());

        row.push(Box::new(
            base.cursor(Pointer)
                .on_click(move |button| self::clicked(&clicked, button, &on_click_monitor))
                .on_scroll(move |scroll| self::scrolled(&scrolled, scroll))
                .on_hover(move |inside| self::hovered(&hovered, inside, &on_hover_monitor)),
        ));
    }

    Row::new(row).gap(8.0).align(Center)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn strips_mnemonics() {
        assert_eq!(mnemonic("_Quit"), "Quit");
        assert_eq!(mnemonic("snake__case"), "snake_case");
    }

    #[test]
    fn strips_markup() {
        assert_eq!(strip_markup("<b>Hi</b> &amp; bye"), "Hi & bye");
    }

    #[test]
    fn converts_argb_pixmaps() {
        let pixel = vec![(1, 1, vec![255, 10, 20, 30])];
        let path = save_pixmap(&pixel).expect("saved");
        assert!(path.exists());
        let _ = fs::remove_file(path);
    }
}
