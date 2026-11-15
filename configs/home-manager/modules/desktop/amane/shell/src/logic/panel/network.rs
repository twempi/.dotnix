use std::thread;
use std::time::{Duration, Instant};

use amane::{Argument, Bus, Network, Service, TextInput, Value};

const NM: &str = "org.freedesktop.NetworkManager";

const NM_PATH: &str = "/org/freedesktop/NetworkManager";

const NM_ACTIVE: &str = "org.freedesktop.NetworkManager.Connection.Active";

const NM_DEVICE: &str = "org.freedesktop.NetworkManager.Device";

const NM_WIRED: &str = "org.freedesktop.NetworkManager.Device.Wired";

const NM_WIRELESS: &str = "org.freedesktop.NetworkManager.Device.Wireless";

const NM_AP: &str = "org.freedesktop.NetworkManager.AccessPoint";

const NM_IP4: &str = "org.freedesktop.NetworkManager.IP4Config";

const NM_SETTINGS: &str = "org.freedesktop.NetworkManager.Settings";

const NM_SETTINGS_PATH: &str = "/org/freedesktop/NetworkManager/Settings";

const NM_CONNECTION: &str = "org.freedesktop.NetworkManager.Settings.Connection";

const DEVICE_ETHERNET: u32 = 1;

const DEVICE_WIFI: u32 = 2;

const RSN_KEY_MGMT_8021X: u32 = 0x200;

pub const PASSWORD_INPUT: &str = "wifi-password";

const ACTION_TIMEOUT: Duration = Duration::from_secs(6);

const SCAN_TIMEOUT: Duration = Duration::from_secs(10);

// what Amane's Network service doesn't report
#[derive(Default, Clone, PartialEq)]
pub struct Extras {
    pub primary: String,
    pub ipv4: String,
    pub interface: String,
    pub frequency: u32,
    last_scan: i64,
    pub wired_device: Option<String>,
}

pub struct Prompt {
    pub ssid: String,
    pub enterprise: bool,
}

#[derive(Default)]
pub struct NetworkTab {
    pub visible: bool,
    pub extras: Extras,
    pub prompt: Option<Prompt>,
    pub password: String,
    pub revealed: bool,
    pub wifi_target: Option<(bool, Instant)>,
    pub action: Option<(bool, Instant)>,
    pub scan: Option<(i64, Instant)>,
}

impl Service for NetworkTab {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        loop {
            thread::sleep(Duration::from_secs(1));

            if Self::read().visible {
                refresh();
                settle();
            }
        }
    }
}

fn nm_property(path: &str, interface: &str, name: &str) -> Value {
    Bus::system().property(NM, path, interface, name)
}

fn fetch_extras() -> Extras {
    let primary = nm_property(NM_PATH, NM, "PrimaryConnection").text().to_string();
    let mut extras = Extras::default();

    if primary != "/" && !primary.is_empty() {
        let ip4 = nm_property(&primary, NM_ACTIVE, "Ip4Config").text().to_string();
        let addresses = nm_property(&ip4, NM_IP4, "AddressData");

        extras.ipv4 = addresses
            .list()
            .first()
            .map(|address| address.get("address").text().to_string())
            .unwrap_or_default();

        let devices = nm_property(&primary, NM_ACTIVE, "Devices");

        if let Some(device) = devices.list().first() {
            extras.interface = nm_property(device.text(), NM_DEVICE, "Interface").text().to_string();
        }

        extras.primary = primary;
    }

    for device in nm_property(NM_PATH, NM, "AllDevices").list() {
        let path = device.text();
        let kind = nm_property(path, NM_DEVICE, "DeviceType").number() as u32;

        if kind == DEVICE_WIFI {
            let ap = nm_property(path, NM_WIRELESS, "ActiveAccessPoint").text().to_string();

            extras.last_scan = nm_property(path, NM_WIRELESS, "LastScan").number() as i64;

            if ap != "/" {
                extras.frequency = nm_property(&ap, NM_AP, "Frequency").number() as u32;
            }
        } else if kind == DEVICE_ETHERNET
            && nm_property(path, NM_WIRED, "Carrier").bool()
            && !nm_property(path, NM_DEVICE, "AvailableConnections").list().is_empty()
        {
            extras.wired_device = Some(path.to_string());
        }
    }

    extras
}

pub fn refresh() {
    let extras = fetch_extras();

    if NetworkTab::read().extras != extras {
        NetworkTab::write().extras = extras;
    }
}

// clears the "waiting for it to happen" states once it has, or after their timeouts
fn settle() {
    let (wifi_on, connected) = {
        let network = Network::read();

        (network.wifi_enabled(), network.connected())
    };

    let (clear_wifi, clear_action, clear_scan) = {
        let tab = NetworkTab::read();

        (
            tab.wifi_target
                .is_some_and(|(target, since)| target == wifi_on || since.elapsed() > ACTION_TIMEOUT),
            tab.action
                .is_some_and(|(was, since)| was != connected || since.elapsed() > ACTION_TIMEOUT),
            tab.scan
                .is_some_and(|(before, since)| before != tab.extras.last_scan || since.elapsed() > SCAN_TIMEOUT),
        )
    };

    if clear_wifi || clear_action || clear_scan {
        let mut tab = NetworkTab::write();

        if clear_wifi {
            tab.wifi_target = None;
        }

        if clear_action {
            tab.action = None;
        }

        if clear_scan {
            tab.scan = None;
        }
    }
}

pub fn start_scan() {
    {
        let mut tab = NetworkTab::write();
        let before = tab.extras.last_scan;

        tab.scan = Some((before, Instant::now()));
    }

    Network::scan();
}

pub fn entered() {
    NetworkTab::write().visible = true;

    thread::spawn(|| {
        refresh();
        start_scan();
    });
}

pub fn left() {
    close_prompt();
    NetworkTab::write().visible = false;
}

pub fn close_prompt() {
    let mut tab = NetworkTab::write();

    tab.prompt = None;
    tab.password.clear();
    tab.revealed = false;
    drop(tab);

    TextInput::set_text(PASSWORD_INPUT, "");
}

fn open_prompt(ssid: String, enterprise: bool) {
    close_prompt();
    NetworkTab::write().prompt = Some(Prompt { ssid, enterprise });
}

pub fn submit_password(password: &str) {
    let ssid = NetworkTab::read().prompt.as_ref().map(|prompt| prompt.ssid.clone());

    if let Some(ssid) = ssid {
        Network::connect(&ssid, Some(password));
    }

    close_prompt();
}

fn ssid_of(bytes: &Value) -> String {
    let raw: Vec<u8> = bytes.list().iter().map(|byte| byte.number() as u8).collect();

    String::from_utf8_lossy(&raw).into_owned()
}

fn is_enterprise(ssid: &str) -> bool {
    for device in nm_property(NM_PATH, NM, "AllDevices").list() {
        if nm_property(device.text(), NM_DEVICE, "DeviceType").number() as u32 != DEVICE_WIFI {
            continue;
        }

        for ap in nm_property(device.text(), NM_WIRELESS, "AccessPoints").list() {
            if ssid_of(&nm_property(ap.text(), NM_AP, "Ssid")) == ssid
                && nm_property(ap.text(), NM_AP, "RsnFlags").number() as u32 & RSN_KEY_MGMT_8021X != 0
            {
                return true;
            }
        }
    }

    false
}

pub fn activate(ssid: String, secured: bool, saved: bool, active: bool) {
    if active {
        return;
    }

    if !secured || saved {
        Network::connect(&ssid, None);
        return;
    }

    thread::spawn(move || {
        let enterprise = is_enterprise(&ssid);

        open_prompt(ssid, enterprise);
    });
}

pub fn forget(ssid: String) {
    thread::spawn(move || {
        let bus = Bus::system();

        for path in bus.call(NM, NM_SETTINGS_PATH, NM_SETTINGS, "ListConnections", &[]).list() {
            let settings = bus.call(NM, path.text(), NM_CONNECTION, "GetSettings", &[]);

            if ssid_of(settings.get("802-11-wireless").get("ssid")) == ssid {
                bus.call(NM, path.text(), NM_CONNECTION, "Delete", &[]);
            }
        }
    });
}

pub fn disconnect_clicked(connected: bool, primary: String, wired_device: Option<String>) {
    NetworkTab::write().action = Some((connected, Instant::now()));

    thread::spawn(move || {
        let bus = Bus::system();

        if connected {
            bus.call(NM, NM_PATH, NM, "DeactivateConnection", &[Argument::Path(primary)]);
        } else if let Some(device) = wired_device {
            let none = || Argument::Path(String::from("/"));

            bus.call(NM, NM_PATH, NM, "ActivateConnection", &[none(), Argument::Path(device), none()]);
        }
    });
}

pub fn set_wifi(on: bool) {
    NetworkTab::write().wifi_target = Some((on, Instant::now()));
    Network::set_wifi(on);
}

pub fn signal_band(strength: u8) -> u8 {
    match strength {
        80.. => 4,
        60..=79 => 3,
        35..=59 => 2,
        15..=34 => 1,
        _ => 0,
    }
}

fn frequency_band(mhz: u32) -> Option<&'static str> {
    match mhz {
        2400..=2500 => Some("2.4 GHz"),
        4900..=5924 => Some("5 GHz"),
        5925.. => Some("6 GHz"),
        _ => None,
    }
}

pub fn current_detail(ipv4: &str, wifi: Option<(u8, u32)>) -> String {
    let mut parts = Vec::new();

    if !ipv4.is_empty() {
        parts.push(ipv4.to_string());
    }

    if let Some((strength, frequency)) = wifi {
        if strength > 0 {
            parts.push(format!("{strength}%"));
        }

        if let Some(band) = frequency_band(frequency) {
            parts.push(band.to_string());
        }
    }

    parts.join("  •  ")
}

#[derive(Clone)]
pub struct ApRow {
    pub ssid: String,
    pub strength: u8,
    pub secured: bool,
    pub active: bool,
    pub saved: bool,
}

// active first, then signal band: raw strength would reshuffle rows on every scan
pub fn sorted(mut aps: Vec<ApRow>) -> Vec<ApRow> {
    aps.sort_by(|a, b| {
        b.active
            .cmp(&a.active)
            .then_with(|| signal_band(b.strength).cmp(&signal_band(a.strength)))
            .then_with(|| a.ssid.cmp(&b.ssid))
    });

    aps
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn labels_frequency_bands() {
        assert_eq!(frequency_band(2412), Some("2.4 GHz"));
        assert_eq!(frequency_band(5180), Some("5 GHz"));
        assert_eq!(frequency_band(5955), Some("6 GHz"));
        assert_eq!(frequency_band(0), None);
    }

    #[test]
    fn joins_detail_like_noctalia() {
        assert_eq!(
            current_detail("192.168.68.66", Some((56, 5180))),
            "192.168.68.66  •  56%  •  5 GHz"
        );
        assert_eq!(current_detail("10.0.0.2", None), "10.0.0.2");
    }

    #[test]
    fn sorts_active_then_band_then_name() {
        let ap = |ssid: &str, strength, active| ApRow {
            ssid: ssid.to_string(),
            strength,
            secured: false,
            active,
            saved: false,
        };

        let names: Vec<String> = sorted(vec![ap("a", 40, false), ap("b", 90, false), ap("c", 20, true), ap("d", 85, false)])
            .into_iter()
            .map(|ap| ap.ssid)
            .collect();

        assert_eq!(names, ["c", "b", "d", "a"]);
    }
}
