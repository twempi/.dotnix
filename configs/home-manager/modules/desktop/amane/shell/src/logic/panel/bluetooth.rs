use std::collections::{HashMap, HashSet};
use std::fs;
use std::sync::OnceLock;
use std::thread;
use std::time::{Duration, Instant};

use amane::{Argument, Bus, Service, TextInput, Value};
use zbus::blocking::{Connection, MessageIterator};
use zbus::message::Type;
use zbus::zvariant::{ObjectPath, OwnedObjectPath};
use zbus::{MatchRule, Message};

use crate::logic::notifications::{self, Page};

const BLUEZ: &str = "org.bluez";

const ADAPTER: &str = "org.bluez.Adapter1";

const DEVICE: &str = "org.bluez.Device1";

const OBJECT_MANAGER: &str = "org.freedesktop.DBus.ObjectManager";

const AGENT_PATH: &str = "/org/amane/BluetoothAgent";

const AGENT_INTERFACE: &str = "org.bluez.Agent1";

const AGENT_MANAGER: &str = "org.bluez.AgentManager1";

const REJECTED: &str = "org.bluez.Error.Rejected";

const CANCELED: &str = "org.bluez.Error.Canceled";

pub const PAIR_INPUT: &str = "bluetooth-pair-code";

const SCAN_WINDOW: Duration = Duration::from_secs(10);

pub const GLYPH_BLUETOOTH: &str = "\u{EA37}";

#[derive(Default, Clone, PartialEq)]
pub struct Adapter {
    pub path: String,
    pub powered: bool,
    pub discoverable: bool,
    pub discovering: bool,
    pub blocked: bool,
}

#[derive(Default, Clone, PartialEq)]
pub struct Device {
    pub path: String,
    pub name: String,
    pub address: String,
    pub glyph: &'static str,
    pub paired: bool,
    pub connected: bool,
    pub trusted: bool,
    pub rssi: Option<i16>,
    pub battery: Option<u8>,
}

impl Device {
    pub fn bucket(&self) -> usize {
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
    pub visible: bool,
    pub adapter: Option<Adapter>,
    pub devices: Vec<Device>,
    scan_until: Option<Instant>,
    pub connecting: HashSet<String>,
    pub expanded: HashSet<String>,
    first_seen: HashMap<String, usize>,
    pub code: String,
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

pub fn signal_percent(rssi: i16) -> i32 {
    ((i32::from(rssi).clamp(-100, -40) + 100) * 100 + 30) / 60
}

pub fn signal_band(rssi: i16) -> i32 {
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

pub fn refresh() {
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
pub fn rescan() {
    let start = BluetoothTab::write()
        .scan_until
        .replace(Instant::now() + SCAN_WINDOW)
        .is_none();

    if start {
        adapter_call("StartDiscovery");
    }
}

pub fn set_adapter_property(name: &'static str, value: bool) {
    let Some(adapter) = adapter_path() else {
        return;
    };

    thread::spawn(move || {
        Bus::system().set_property(BLUEZ, &adapter, ADAPTER, name, Argument::from(value));
        refresh();
    });
}

pub fn set_powered(on: bool) {
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

pub fn device_call(path: String, method: &'static str) {
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

pub fn set_trusted(path: &str, trusted: bool) {
    Bus::system().set_property(BLUEZ, path, DEVICE, "Trusted", Argument::from(trusted));
}

pub fn pair(path: String) {
    with_connecting(path, |path| {
        if Bus::system().call(BLUEZ, path, DEVICE, "Pair", &[]) == Value::Nothing {
            set_trusted(path, true);
        }
    });
}

pub fn connect(path: String) {
    with_connecting(path, |path| {
        Bus::system().call(BLUEZ, path, DEVICE, "Connect", &[]);
    });
}

pub fn forget(path: String) {
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

pub fn toggle_expanded(path: &str) {
    let mut tab = BluetoothTab::write();

    if !tab.expanded.remove(path) {
        tab.expanded.insert(path.to_string());
    }
}

// BlueZ Agent1, so devices that need a code can pair: zbus directly for its error replies

#[derive(Clone, Copy, PartialEq)]
pub enum PairingKind {
    Confirm,
    Authorize,
    AuthorizeService,
    DisplayPinCode,
    DisplayPasskey,
    PinCode,
    Passkey,
}

#[derive(Clone)]
pub struct Pairing {
    pub kind: PairingKind,
    pub device: String,
    pub code: String,
    pub uuid: String,
    // none for DisplayPasskey, which has no answer
    pub message: Option<Message>,
}

#[derive(Default)]
pub struct Agent {
    pub pending: Option<Pairing>,
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

pub fn cancel_pairing() {
    let error = match Agent::read().pending.as_ref().map(|pending| pending.kind) {
        Some(PairingKind::PinCode | PairingKind::Passkey) => CANCELED,
        _ => REJECTED,
    };

    reject_pairing(error);
}

pub fn submit_code(code: &str) {
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

pub fn accept_clicked() {
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

pub fn trust_and_allow() {
    if let Some(device) = Agent::read().pending.as_ref().map(|pending| pending.device.clone()) {
        thread::spawn(move || set_trusted(&device, true));
    }

    accept_pairing();
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
