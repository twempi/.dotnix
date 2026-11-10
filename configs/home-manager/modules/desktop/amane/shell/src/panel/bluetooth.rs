use std::collections::{HashMap, HashSet};
use std::fs;
use std::sync::OnceLock;
use std::thread;
use std::time::{Duration, Instant};

use amane::{
    Argument, Bus, Center, Column, Padding, Parent, Pointer, Rectangle, Row, Service, TextInput,
    Value, Weight, Widget, children,
};
use zbus::blocking::{Connection, MessageIterator};
use zbus::message::Type;
use zbus::zvariant::{ObjectPath, OwnedObjectPath};
use zbus::{MatchRule, Message};

use super::controls::{
    CONTROL_SM, FONT_BODY, FONT_CAPTION, FONT_TITLE, GLYPH, RADIUS_MD, RADIUS_SM, SPACE_MD, SPACE_SM,
    SPACE_XS, Ui, Variant, card, disabled, glyph, icon_button, input_box, label, scroll_view, spinner,
    text_button, toggle,
};
use crate::notifications::{self, Page};

const BLUEZ: &str = "org.bluez";
const ADAPTER: &str = "org.bluez.Adapter1";
const DEVICE: &str = "org.bluez.Device1";
const OBJECT_MANAGER: &str = "org.freedesktop.DBus.ObjectManager";
const AGENT_PATH: &str = "/org/amane/BluetoothAgent";
const AGENT_INTERFACE: &str = "org.bluez.Agent1";
const AGENT_MANAGER: &str = "org.bluez.AgentManager1";
const REJECTED: &str = "org.bluez.Error.Rejected";
const CANCELED: &str = "org.bluez.Error.Canceled";
const PAIR_INPUT: &str = "bluetooth-pair-code";

const SCAN_WINDOW: Duration = Duration::from_secs(10);
const ROW: f32 = 48.0;

const GLYPH_BLUETOOTH: &str = "\u{EA37}";
const GLYPH_REFRESH: &str = "\u{EB13}";
const GLYPH_PLUG: &str = "\u{EBD9}";
const GLYPH_PLUG_OFF: &str = "\u{F180}";
const GLYPH_TRASH: &str = "\u{EB41}";
const GLYPH_CHEVRON: &str = "\u{EA5F}";
const GLYPH_BATTERY: &str = "\u{EA34}";
const GLYPH_SIGNAL: &str = "\u{ECCB}";

#[derive(Default, Clone, PartialEq)]
struct Adapter {
    path: String,
    powered: bool,
    discoverable: bool,
    discovering: bool,
    blocked: bool,
}

#[derive(Default, Clone, PartialEq)]
struct Device {
    path: String,
    name: String,
    address: String,
    glyph: &'static str,
    paired: bool,
    connected: bool,
    trusted: bool,
    rssi: Option<i16>,
    battery: Option<u8>,
}

impl Device {
    fn bucket(&self) -> usize {
        if self.connected {
            0
        } else if self.paired {
            1
        } else {
            2
        }
    }
}

// the tab's own view of BlueZ: Amane's Bluetooth service has no RSSI, trust or discoverable state
#[derive(Default)]
pub struct BluetoothTab {
    visible: bool,
    adapter: Option<Adapter>,
    devices: Vec<Device>,
    scan_until: Option<Instant>,
    connecting: HashSet<String>,
    expanded: HashSet<String>,
    first_seen: HashMap<String, usize>,
    code: String,
}

impl Service for BluetoothTab {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        loop {
            thread::sleep(Duration::from_secs(1));

            if Self::read().visible {
                refresh();
                expire_scan();
            }
        }
    }
}

fn signal_percent(rssi: i16) -> i32 {
    ((i32::from(rssi).clamp(-100, -40) + 100) * 100 + 30) / 60
}

fn signal_band(rssi: i16) -> i32 {
    (signal_percent(rssi) / 20).min(4)
}

fn glyph_from_class(class: u32) -> &'static str {
    let (major, minor) = ((class >> 8) & 0x1F, (class >> 2) & 0x3F);

    match (major, minor) {
        (0x01, _) => "\u{EB64}",
        (0x02, _) => "\u{EA8A}",
        (0x04, 0x01 | 0x02) => "\u{EB90}",
        (0x04, 0x05 | 0x07) => "\u{EA8B}",
        (0x04, 0x04) => "\u{EAF0}",
        (0x04, 0x0A | 0x0B) => "\u{EA8D}",
        (0x04, _) => "\u{EABD}",
        (0x05, minor) if minor & 0x0F == 0x02 => "\u{F1D7}",
        (0x07, _) => "\u{EBF9}",
        (0x08, _) => "\u{F1D2}",
        _ => GLYPH_BLUETOOTH,
    }
}

fn device_glyph(icon: &str, class: u32) -> &'static str {
    match icon {
        "audio-headset" => "\u{EB90}",
        "audio-headphones" => "\u{EABD}",
        "audio-card" | "audio-speakers" => "\u{EA8B}",
        "input-mouse" => "\u{F1D7}",
        "input-gaming" => "\u{F1D2}",
        "phone" => "\u{EA8A}",
        "computer" => "\u{EB64}",
        "video-display" => "\u{EA8D}",
        "input-keyboard" => GLYPH_BLUETOOTH,
        _ => glyph_from_class(class),
    }
}

fn soft_blocked() -> bool {
    let Ok(entries) = fs::read_dir("/sys/class/rfkill") else {
        return false;
    };

    entries.flatten().any(|entry| {
        let is_bluetooth = fs::read_to_string(entry.path().join("type"))
            .is_ok_and(|kind| kind.trim() == "bluetooth");

        is_bluetooth && fs::read_to_string(entry.path().join("soft")).is_ok_and(|soft| soft.trim() == "1")
    })
}

fn fetch() -> (Option<Adapter>, Vec<Device>) {
    let objects = Bus::system().call(BLUEZ, "/", OBJECT_MANAGER, "GetManagedObjects", &[]);
    let Value::Map(objects) = objects else {
        return (None, Vec::new());
    };

    let mut adapter = None;
    let mut devices = Vec::new();

    for (path, interfaces) in &objects {
        let found = interfaces.get(ADAPTER);

        if found != &Value::Nothing && adapter.is_none() {
            adapter = Some(Adapter {
                path: path.clone(),
                powered: found.get("Powered").bool(),
                discoverable: found.get("Discoverable").bool(),
                discovering: found.get("Discovering").bool(),
                blocked: soft_blocked() || found.get("PowerState").text() == "off-blocked",
            });
        }

        let device = interfaces.get(DEVICE);

        if device != &Value::Nothing {
            let address = device.get("Address").text();
            let name = match device.get("Alias").text() {
                "" => address,
                alias => alias,
            };

            devices.push(Device {
                path: path.clone(),
                name: name.to_string(),
                address: address.to_string(),
                glyph: device_glyph(device.get("Icon").text(), device.get("Class").number() as u32),
                paired: device.get("Paired").bool(),
                connected: device.get("Connected").bool(),
                trusted: device.get("Trusted").bool(),
                rssi: (device.get("RSSI") != &Value::Nothing).then(|| device.get("RSSI").number() as i16),
                battery: match interfaces.get("org.bluez.Battery1").get("Percentage") {
                    Value::Nothing => None,
                    percent => Some(percent.number() as u8),
                },
            });
        }
    }

    (adapter, devices)
}

// bucket, then for available devices signal band, so a scan can't reshuffle rows under the pointer
fn sort_devices(devices: &mut [Device]) {
    devices.sort_by(|a, b| {
        a.bucket()
            .cmp(&b.bucket())
            .then_with(|| {
                if a.bucket() != 2 {
                    return std::cmp::Ordering::Equal;
                }

                b.rssi
                    .is_some()
                    .cmp(&a.rssi.is_some())
                    .then_with(|| match (a.rssi, b.rssi) {
                        (Some(a), Some(b)) => signal_band(b).cmp(&signal_band(a)),
                        _ => std::cmp::Ordering::Equal,
                    })
            })
            .then_with(|| a.name.cmp(&b.name))
            .then_with(|| a.path.cmp(&b.path))
    });
}

// available devices keep the slot they were first listed in
fn slot_available(devices: &mut [Device], first_seen: &mut HashMap<String, usize>) {
    for device in devices.iter().filter(|device| device.bucket() == 2) {
        if !first_seen.contains_key(&device.path) {
            let next = first_seen.len();
            first_seen.insert(device.path.clone(), next);
        }
    }

    devices.sort_by_key(|device| {
        let slot = if device.bucket() == 2 { first_seen[&device.path] } else { 0 };

        (device.bucket(), slot)
    });
}

fn refresh() {
    let (adapter, mut devices) = fetch();

    sort_devices(&mut devices);

    let mut first_seen = BluetoothTab::read().first_seen.clone();

    slot_available(&mut devices, &mut first_seen);

    let unchanged = {
        let tab = BluetoothTab::read();

        tab.adapter == adapter && tab.devices == devices
    };

    if !unchanged {
        let mut tab = BluetoothTab::write();

        tab.adapter = adapter;
        tab.devices = devices;
        tab.first_seen = first_seen;
    }
}

fn expire_scan() {
    let expired = {
        let tab = BluetoothTab::read();
        let powered = tab.adapter.as_ref().is_some_and(|adapter| adapter.powered);

        tab.scan_until.is_some_and(|until| !powered || Instant::now() >= until)
    };

    if expired {
        stop_scan();
    }
}

fn adapter_path() -> Option<String> {
    BluetoothTab::read().adapter.as_ref().map(|adapter| adapter.path.clone())
}

fn adapter_call(method: &'static str) {
    let Some(adapter) = adapter_path() else {
        return;
    };

    thread::spawn(move || {
        Bus::system().call(BLUEZ, &adapter, ADAPTER, method, &[]);
        refresh();
    });
}

fn stop_scan() {
    if BluetoothTab::write().scan_until.take().is_some() {
        adapter_call("StopDiscovery");
    }
}

// repeated clicks renew the window instead of restarting discovery
fn rescan() {
    let start = BluetoothTab::write()
        .scan_until
        .replace(Instant::now() + SCAN_WINDOW)
        .is_none();

    if start {
        adapter_call("StartDiscovery");
    }
}

fn set_adapter_property(name: &'static str, value: bool) {
    let Some(adapter) = adapter_path() else {
        return;
    };

    thread::spawn(move || {
        Bus::system().set_property(BLUEZ, &adapter, ADAPTER, name, Argument::from(value));
        refresh();
    });
}

fn set_powered(on: bool) {
    let Some(adapter) = adapter_path() else {
        return;
    };

    thread::spawn(move || {
        if on {
            amane::output("rfkill unblock bluetooth");
        }

        Bus::system().set_property(BLUEZ, &adapter, ADAPTER, "Powered", Argument::from(on));
        refresh();
    });
}

fn device_call(path: String, method: &'static str) {
    thread::spawn(move || {
        Bus::system().call(BLUEZ, &path, DEVICE, method, &[]);
        refresh();
    });
}

fn with_connecting(path: String, work: impl FnOnce(&str) + Send + 'static) {
    BluetoothTab::write().connecting.insert(path.clone());

    thread::spawn(move || {
        work(&path);
        BluetoothTab::write().connecting.remove(&path);
        refresh();
    });
}

fn set_trusted(path: &str, trusted: bool) {
    Bus::system().set_property(BLUEZ, path, DEVICE, "Trusted", Argument::from(trusted));
}

fn pair(path: String) {
    with_connecting(path, |path| {
        if Bus::system().call(BLUEZ, path, DEVICE, "Pair", &[]) == Value::Nothing {
            set_trusted(path, true);
        }
    });
}

fn connect(path: String) {
    with_connecting(path, |path| {
        Bus::system().call(BLUEZ, path, DEVICE, "Connect", &[]);
    });
}

fn forget(path: String) {
    let Some(adapter) = adapter_path() else {
        return;
    };

    thread::spawn(move || {
        Bus::system().call(BLUEZ, &adapter, ADAPTER, "RemoveDevice", &[Argument::Path(path)]);
        refresh();
    });
}

pub fn entered() {
    BluetoothTab::write().visible = true;
    thread::spawn(refresh);
}

pub fn left() {
    stop_scan();

    let mut tab = BluetoothTab::write();

    tab.visible = false;
    tab.first_seen.clear();
}

fn toggle_expanded(path: &str) {
    let mut tab = BluetoothTab::write();

    if !tab.expanded.remove(path) {
        tab.expanded.insert(path.to_string());
    }
}

// BlueZ Agent1, so devices that need a code can pair: zbus directly for its error replies

#[derive(Clone, Copy, PartialEq)]
enum PairingKind {
    Confirm,
    Authorize,
    AuthorizeService,
    DisplayPinCode,
    DisplayPasskey,
    PinCode,
    Passkey,
}

#[derive(Clone)]
struct Pairing {
    kind: PairingKind,
    device: String,
    code: String,
    uuid: String,
    // none for DisplayPasskey, which has no answer
    message: Option<Message>,
}

#[derive(Default)]
pub struct Agent {
    pending: Option<Pairing>,
}

static CONNECTION: OnceLock<Connection> = OnceLock::new();

impl Service for Agent {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        let Ok(connection) = Connection::system() else {
            return;
        };

        let connection = CONNECTION.get_or_init(|| connection);

        let Some(messages) = agent_messages(connection) else {
            return;
        };

        // already-registered answers with an error, so this only registers again after bluez restarts
        thread::spawn(move || {
            loop {
                register_agent(connection);
                thread::sleep(Duration::from_secs(30));
            }
        });

        for message in messages.flatten() {
            handle_agent_call(connection, message);
        }
    }
}

fn agent_messages(connection: &Connection) -> Option<MessageIterator> {
    let rule = MatchRule::builder()
        .msg_type(Type::MethodCall)
        .path(AGENT_PATH)
        .ok()?
        .interface(AGENT_INTERFACE)
        .ok()?
        .build();

    MessageIterator::for_match_rule(rule, connection, None).ok()
}

fn register_agent(connection: &Connection) {
    let Ok(path) = ObjectPath::try_from(AGENT_PATH) else {
        return;
    };

    let registered = connection.call_method(
        Some(BLUEZ),
        "/org/bluez",
        Some(AGENT_MANAGER),
        "RegisterAgent",
        &(&path, "KeyboardDisplay"),
    );

    if registered.is_ok() {
        let _ = connection.call_method(Some(BLUEZ), "/org/bluez", Some(AGENT_MANAGER), "RequestDefaultAgent", &path);
    }
}

fn set_pending(connection: &Connection, message: Message, kind: PairingKind, device: String, code: String, uuid: String) {
    if Agent::read().pending.is_some() {
        let _ = connection.reply_error(&message.header(), REJECTED, &"another pairing request is already pending");
        return;
    }

    show_pairing(Pairing {
        kind,
        device,
        code,
        uuid,
        message: Some(message),
    });
}

// BlueZ cancels unanswered requests after a few seconds, so the card comes up on its own
fn show_pairing(pairing: Pairing) {
    Agent::write().pending = Some(pairing);
    BluetoothTab::write().code.clear();
    TextInput::set_text(PAIR_INPUT, "");
    notifications::show(Page::Bluetooth);
}

fn handle_agent_call(connection: &Connection, message: Message) {
    let header = message.header();
    let member = header.member().map(|member| member.as_str().to_string()).unwrap_or_default();
    let body = message.body();

    match member.as_str() {
        "RequestPinCode" | "RequestPasskey" | "RequestAuthorization" => {
            let Ok(device) = body.deserialize::<OwnedObjectPath>() else {
                return;
            };

            let kind = match member.as_str() {
                "RequestPinCode" => PairingKind::PinCode,
                "RequestPasskey" => PairingKind::Passkey,
                _ => PairingKind::Authorize,
            };

            set_pending(connection, message.clone(), kind, device.to_string(), String::new(), String::new());
        }
        "DisplayPinCode" => {
            let Ok((device, pin)) = body.deserialize::<(OwnedObjectPath, String)>() else {
                return;
            };

            set_pending(connection, message.clone(), PairingKind::DisplayPinCode, device.to_string(), pin, String::new());
        }
        "RequestConfirmation" => {
            let Ok((device, passkey)) = body.deserialize::<(OwnedObjectPath, u32)>() else {
                return;
            };

            set_pending(connection, message.clone(), PairingKind::Confirm, device.to_string(), format!("{passkey:06}"), String::new());
        }
        "AuthorizeService" => {
            let Ok((device, uuid)) = body.deserialize::<(OwnedObjectPath, String)>() else {
                return;
            };

            set_pending(connection, message.clone(), PairingKind::AuthorizeService, device.to_string(), String::new(), uuid);
        }
        "DisplayPasskey" => {
            let Ok((device, passkey, _entered)) = body.deserialize::<(OwnedObjectPath, u32, u16)>() else {
                return;
            };

            let device = device.to_string();
            let code = format!("{passkey:06}");
            let shown = Agent::read().pending.as_ref().map(|pending| (pending.kind, pending.device.clone()));

            match shown {
                Some((PairingKind::DisplayPasskey, path)) if path == device => {
                    if let Some(pending) = Agent::write().pending.as_mut() {
                        pending.code = code;
                    }
                }
                None => show_pairing(Pairing {
                    kind: PairingKind::DisplayPasskey,
                    device,
                    code,
                    uuid: String::new(),
                    message: None,
                }),
                _ => {}
            }
        }
        "Cancel" => {
            cancel_pairing();
            let _ = connection.reply(&header, &());
        }
        "Release" => {
            let _ = connection.reply(&header, &());
        }
        _ => {}
    }
}

fn take_pairing() -> Option<(&'static Connection, Pairing)> {
    let pairing = Agent::write().pending.take()?;

    Some((CONNECTION.get()?, pairing))
}

fn accept_pairing() {
    let Some((connection, pairing)) = take_pairing() else {
        return;
    };

    if let Some(message) = &pairing.message {
        let _ = connection.reply(&message.header(), &());
    }
}

fn reject_pairing(error: &str) {
    let Some((connection, pairing)) = take_pairing() else {
        return;
    };

    if let Some(message) = &pairing.message {
        let _ = connection.reply_error(&message.header(), error, &"user canceled");
    }
}

fn cancel_pairing() {
    let error = match Agent::read().pending.as_ref().map(|pending| pending.kind) {
        Some(PairingKind::PinCode | PairingKind::Passkey) => CANCELED,
        _ => REJECTED,
    };

    reject_pairing(error);
}

fn submit_code(code: &str) {
    let kind = Agent::read().pending.as_ref().map(|pending| pending.kind);

    match kind {
        Some(PairingKind::PinCode) => {
            if let Some((connection, pairing)) = take_pairing()
                && let Some(message) = &pairing.message
            {
                let _ = connection.reply(&message.header(), &code);
            }
        }
        Some(PairingKind::Passkey) => match code.trim().parse::<u32>() {
            Ok(passkey) => {
                if let Some((connection, pairing)) = take_pairing()
                    && let Some(message) = &pairing.message
                {
                    let _ = connection.reply(&message.header(), &passkey);
                }
            }
            Err(_) => cancel_pairing(),
        },
        _ => {}
    }
}

fn accept_clicked() {
    let (kind, code) = {
        let code = BluetoothTab::read().code.clone();

        (Agent::read().pending.as_ref().map(|pending| pending.kind), code)
    };

    match kind {
        Some(PairingKind::Confirm | PairingKind::Authorize | PairingKind::AuthorizeService | PairingKind::DisplayPinCode) => {
            accept_pairing();
        }
        Some(PairingKind::PinCode | PairingKind::Passkey) => submit_code(&code),
        _ => {}
    }
}

fn trust_and_allow() {
    if let Some(device) = Agent::read().pending.as_ref().map(|pending| pending.device.clone()) {
        thread::spawn(move || set_trusted(&device, true));
    }

    accept_pairing();
}

fn pairing_card(ui: &Ui, pairing: &Pairing, name: &str, width: f32) -> Rectangle {
    let c = &ui.c;
    let needs_input = matches!(pairing.kind, PairingKind::PinCode | PairingKind::Passkey);
    let shows_code = matches!(
        pairing.kind,
        PairingKind::Confirm | PairingKind::DisplayPasskey | PairingKind::DisplayPinCode
    );

    let detail = match pairing.kind {
        PairingKind::Confirm => "Confirm that this code matches the one shown on the device:".to_string(),
        PairingKind::Authorize => "Accept the incoming pairing request?".to_string(),
        PairingKind::AuthorizeService => format!("Allow access to service {}?", pairing.uuid),
        PairingKind::DisplayPinCode => "Enter this PIN on the device:".to_string(),
        PairingKind::DisplayPasskey => "Enter this code on the device:".to_string(),
        PairingKind::PinCode => "Enter the PIN shown on the device:".to_string(),
        PairingKind::Passkey => "Enter the passkey shown on the device:".to_string(),
    };

    let mut rows: Vec<Box<dyn Widget>> = vec![
        Box::new(label(format!("Pair {name}"), FONT_BODY, c.on_surface).weight(Weight::Bold)),
        Box::new(label(detail, FONT_CAPTION, c.variant)),
    ];

    if shows_code {
        rows.push(Box::new(label(pairing.code.clone(), FONT_TITLE, c.primary).weight(Weight::Bold)));
    }

    if needs_input {
        rows.push(Box::new(
            Row::new(children![input_box(
                ui,
                TextInput::new(PAIR_INPUT)
                    .placeholder("Enter code")
                    .focused()
                    .on_change(|text| BluetoothTab::write().code = text)
                    .on_submit(|text| submit_code(&text)),
            )])
            .width(Parent)
            .height(38.0),
        ));
    }

    let mut buttons: Vec<Box<dyn Widget>> = Vec::new();

    if pairing.kind != PairingKind::DisplayPasskey {
        buttons.push(Box::new(
            text_button(ui, "pair:accept", "Accept", Variant::Default).on_click(|_| accept_clicked()),
        ));
    }

    if pairing.kind == PairingKind::AuthorizeService {
        buttons.push(Box::new(
            text_button(ui, "pair:trust", "Trust and allow", Variant::Default).on_click(|_| trust_and_allow()),
        ));
    }

    buttons.push(Box::new(
        text_button(ui, "pair:reject", "Reject", Variant::Ghost).on_click(|_| cancel_pairing()),
    ));

    rows.push(Box::new(Row::new(buttons).height(38.0).gap(SPACE_SM)));

    card(ui, width, Column::new(rows).width(Parent).gap(SPACE_SM))
}

fn adapter_card(ui: &Ui, adapter: Option<&Adapter>, width: f32) -> Rectangle {
    let c = &ui.c;
    let present = adapter.is_some();
    let powered = adapter.is_some_and(|adapter| adapter.powered);
    let discoverable = adapter.is_some_and(|adapter| adapter.discoverable);
    let scanning = adapter.is_some_and(|adapter| adapter.discovering && adapter.powered);

    let mut power: Vec<Box<dyn Widget>> = vec![Box::new(
        Rectangle::new()
            .width(Parent)
            .height(CONTROL_SM)
            .align_child(amane::Start, Center)
            .child(label("Bluetooth", FONT_BODY, c.on_surface)),
    )];

    if scanning {
        power.push(Box::new(spinner(GLYPH, c.primary)));
    }

    let refresh_button = icon_button(ui, "bt:rescan", GLYPH_REFRESH, (24.0, GLYPH, RADIUS_SM), Variant::Ghost);

    power.push(Box::new(if powered {
        refresh_button.on_click(|_| rescan())
    } else {
        disabled(refresh_button)
    }));

    let power_toggle = toggle(ui, "bt:power", powered, false);

    power.push(Box::new(if present {
        power_toggle.on_click(move |_| set_powered(!powered))
    } else {
        disabled(power_toggle)
    }));

    let visible_toggle = toggle(ui, "bt:visible", discoverable, false);

    card(
        ui,
        width,
        Column::new(children![
            Row::new(power).width(Parent).height(CONTROL_SM).gap(SPACE_SM).align(Center),
            Row::new(children![
                Rectangle::new()
                    .width(Parent)
                    .height(CONTROL_SM)
                    .align_child(amane::Start, Center)
                    .child(label("Discoverable by nearby devices", FONT_BODY, c.on_surface)),
                if present && powered {
                    visible_toggle.on_click(move |_| set_adapter_property("Discoverable", !discoverable))
                } else {
                    disabled(visible_toggle)
                },
            ])
            .width(Parent)
            .height(CONTROL_SM)
            .gap(SPACE_SM)
            .align(Center),
        ])
        .width(Parent)
        .gap(SPACE_SM),
    )
}

fn metric(ui: &Ui, code: &str, value: String) -> Row {
    Row::new(children![
        glyph(code, FONT_CAPTION, ui.c.variant),
        label(value, FONT_CAPTION, ui.c.variant),
    ])
    .gap(SPACE_XS / 2.0)
    .align(Center)
}

fn device_row(ui: &Ui, tab: &BluetoothTab, device: &Device) -> Rectangle {
    let c = &ui.c;
    let path = device.path.clone();
    let bucket = device.bucket();
    let expanded = tab.expanded.contains(&device.path);
    let connecting = tab.connecting.contains(&device.path);

    let name = label(device.name.clone(), FONT_BODY, c.on_surface).elide();
    let name = if device.connected { name.weight(Weight::Bold) } else { name };

    let mut row: Vec<Box<dyn Widget>> = vec![
        Box::new(glyph(device.glyph, FONT_BODY, c.on_surface)),
        Box::new(Rectangle::new().width(Parent).height(CONTROL_SM).align_child(amane::Start, Center).child(name)),
    ];

    if let Some(battery) = device.battery {
        row.push(Box::new(metric(ui, GLYPH_BATTERY, format!("{battery}%"))));
    }

    if let (2, Some(rssi)) = (bucket, device.rssi) {
        row.push(Box::new(metric(ui, GLYPH_SIGNAL, format!("{}%", signal_percent(rssi)))));
    }

    if connecting {
        row.push(Box::new(spinner(GLYPH, c.primary)));
    } else {
        let (code, variant) = match bucket {
            0 => (GLYPH_PLUG_OFF, Variant::Destructive),
            1 => (GLYPH_PLUG, Variant::Default),
            _ => (GLYPH_BLUETOOTH, Variant::Default),
        };
        let target = path.clone();

        row.push(Box::new(
            icon_button(ui, format!("bt:act:{path}"), code, (CONTROL_SM, FONT_BODY, RADIUS_SM), variant).on_click(
                move |_| match bucket {
                    0 => device_call(target.clone(), "Disconnect"),
                    1 => connect(target.clone()),
                    _ => pair(target.clone()),
                },
            ),
        ));
    }

    if device.paired {
        let target = path.clone();

        row.push(Box::new(
            icon_button(ui, format!("bt:trash:{path}"), GLYPH_TRASH, (CONTROL_SM, FONT_BODY, RADIUS_SM), Variant::Ghost)
                .on_click(move |_| forget(target.clone())),
        ));
    }

    let chevron = Rectangle::new()
        .width(FONT_BODY)
        .height(FONT_BODY)
        .rotate(if expanded { 180.0 } else { 0.0 })
        .align_child(Center, Center)
        .child(glyph(GLYPH_CHEVRON, FONT_BODY, c.variant));

    let target = path.clone();

    let header = Rectangle::new()
        .width(Parent)
        .height(ROW)
        .cursor(Pointer)
        .on_click(move |_| toggle_expanded(&target))
        .padding(Padding {
            left: SPACE_MD * 2.0,
            right: SPACE_MD,
            top: SPACE_SM,
            bottom: SPACE_SM,
        })
        .child(
            Row::new(children![
                Row::new(row).width(Parent).height(CONTROL_SM).gap(SPACE_SM).align(Center),
                chevron,
            ])
            .height(CONTROL_SM)
            .gap(SPACE_MD + SPACE_XS)
            .align(Center),
        );

    let mut column: Vec<Box<dyn Widget>> = vec![Box::new(header)];
    let mut height = ROW;

    if expanded {
        let mut rows: Vec<Box<dyn Widget>> = Vec::new();

        if device.paired {
            let target = path.clone();
            let trusted = device.trusted;

            rows.push(Box::new(
                Row::new(children![
                    Rectangle::new()
                        .width(Parent)
                        .height(18.0)
                        .align_child(amane::Start, Center)
                        .child(label("Auto-reconnect", FONT_CAPTION, c.variant)),
                    toggle(ui, format!("bt:trust:{path}"), trusted, true).on_click(move |_| {
                        let path = target.clone();
                        thread::spawn(move || {
                            set_trusted(&path, !trusted);
                            refresh();
                        });
                    }),
                ])
                .width(Parent)
                .height(18.0)
                .gap(SPACE_SM)
                .align(Center),
            ));
        }

        rows.push(Box::new(
            Row::new(children![
                Rectangle::new()
                    .width(Parent)
                    .height(18.0)
                    .align_child(amane::Start, Center)
                    .child(label("Address", FONT_CAPTION, c.variant)),
                label(device.address.clone(), FONT_CAPTION, c.on_surface),
            ])
            .width(Parent)
            .height(18.0)
            .gap(SPACE_SM)
            .align(Center),
        ));

        let body = Column::new(rows).width(Parent).gap(SPACE_SM);
        let body_height = crate::ui::height_of(&body) + SPACE_XS + SPACE_SM;

        column.push(Box::new(
            Rectangle::new()
                .width(Parent)
                .height(body_height)
                .padding(Padding {
                    left: SPACE_MD,
                    right: SPACE_MD,
                    top: SPACE_XS,
                    bottom: SPACE_SM,
                })
                .child(body),
        ));

        height += body_height;
    }

    Rectangle::new()
        .width(Parent)
        .height(height)
        .radius(RADIUS_MD)
        .fill(c.surface)
        .child(Column::new(column).width(Parent).height(height))
}

fn bucket_card(ui: &Ui, title: &str, rows: Vec<Box<dyn Widget>>, width: f32) -> Rectangle {
    let mut column: Vec<Box<dyn Widget>> = vec![Box::new(
        Rectangle::new()
            .width(Parent)
            .height(CONTROL_SM)
            .align_child(amane::Start, Center)
            .child(label(title, FONT_BODY, ui.c.on_surface).weight(Weight::Bold)),
    )];

    column.extend(rows);

    card(ui, width, Column::new(column).width(Parent).gap(SPACE_SM))
}

fn device_list(ui: &Ui, tab: &BluetoothTab, width: f32) -> Column {
    let c = &ui.c;
    let adapter = tab.adapter.as_ref();
    let powered = adapter.is_some_and(|adapter| adapter.powered);

    let mut column: Vec<Box<dyn Widget>> = vec![Box::new(adapter_card(ui, adapter, width))];

    if !powered {
        let text = if adapter.is_some_and(|adapter| adapter.blocked) {
            "Bluetooth is blocked by the system. Turn it on to clear the block."
        } else {
            "Bluetooth is off"
        };

        column.push(Box::new(label(text, FONT_BODY, c.variant)));
    } else if tab.devices.is_empty() {
        column.push(Box::new(label(
            "No devices found. Start scanning to discover nearby Bluetooth devices.",
            FONT_BODY,
            c.variant,
        )));
    } else {
        for (bucket, title) in ["Connected", "Paired", "Available"].iter().enumerate() {
            let rows: Vec<Box<dyn Widget>> = tab
                .devices
                .iter()
                .filter(|device| device.bucket() == bucket)
                .map(|device| Box::new(device_row(ui, tab, device)) as Box<dyn Widget>)
                .collect();

            if !rows.is_empty() {
                column.push(Box::new(bucket_card(ui, title, rows, width)));
            }
        }
    }

    Column::new(column).width(width).gap(SPACE_MD)
}

pub fn view(ui: &Ui, width: f32, height: f32) -> Column {
    let tab = BluetoothTab::read();
    let agent = Agent::read();

    let mut column: Vec<Box<dyn Widget>> = Vec::new();
    let mut used = 0.0;

    if let Some(pairing) = &agent.pending {
        let name = tab
            .devices
            .iter()
            .find(|device| device.path == pairing.device)
            .map(|device| device.name.clone())
            .unwrap_or_else(|| pairing.device.rsplit('/').next().unwrap_or_default().to_string());

        let card = pairing_card(ui, pairing, &name, width);

        used = crate::ui::height_of(&card) + SPACE_MD;
        column.push(Box::new(card));
    }

    column.push(Box::new(scroll_view(ui, "bluetooth", (width, height - used), |list| {
        device_list(ui, &tab, list)
    })));

    Column::new(column).width(width).height(height).gap(SPACE_MD)
}

// the agent's thread starts on the first read, and pairing can begin with the panel closed
pub fn start_agent() {
    drop(Agent::read());
}

#[cfg(test)]
mod tests {
    use super::*;

    fn device(name: &str, connected: bool, paired: bool, rssi: Option<i16>) -> Device {
        Device {
            path: format!("/{name}"),
            name: name.to_string(),
            connected,
            paired,
            rssi,
            ..Device::default()
        }
    }

    #[test]
    fn signal_matches_noctalia() {
        assert_eq!(signal_percent(-40), 100);
        assert_eq!(signal_percent(-100), 0);
        assert_eq!(signal_percent(-70), 50);
        assert_eq!(signal_band(-40), 4);
        assert_eq!(signal_band(-100), 0);
    }

    #[test]
    fn sorts_by_bucket_then_band() {
        let mut devices = vec![
            device("weak", false, false, Some(-95)),
            device("strong", false, false, Some(-45)),
            device("mine", false, true, None),
            device("link", true, true, None),
            device("silent", false, false, None),
        ];

        sort_devices(&mut devices);

        let names: Vec<&str> = devices.iter().map(|device| device.name.as_str()).collect();

        assert_eq!(names, ["link", "mine", "strong", "weak", "silent"]);
    }

    #[test]
    fn available_keep_first_seen_slots() {
        let mut seen = HashMap::new();
        let mut first = vec![device("a", false, false, Some(-90)), device("b", false, false, Some(-90))];
        slot_available(&mut first, &mut seen);

        let mut later = vec![device("b", false, false, Some(-40)), device("c", false, false, Some(-40)), device("a", false, false, Some(-99))];
        slot_available(&mut later, &mut seen);

        let names: Vec<&str> = later.iter().map(|device| device.name.as_str()).collect();

        assert_eq!(names, ["a", "b", "c"]);
    }
}
