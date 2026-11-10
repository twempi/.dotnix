use std::thread;
use std::time::{Duration, Instant};

use amane::{
    Argument, Bus, Center, Column, Link, Network, Padding, Parent, Pointer, Rectangle, Row, Service,
    TextInput, Value, Weight, Widget, children,
};

use super::controls::{
    CONTROL_SM, FONT_BODY, FONT_CAPTION, FONT_MINI, FONT_TITLE, GLYPH, RADIUS_MD, RADIUS_SM, SPACE_MD,
    SPACE_SM, SPACE_XS, Ui, Variant, card, disabled, glyph, hoverable, icon_button, input_box, label,
    scroll_view, spinner, text_button, toggle,
};

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
const PASSWORD_INPUT: &str = "wifi-password";

const ACTION_TIMEOUT: Duration = Duration::from_secs(6);
const SCAN_TIMEOUT: Duration = Duration::from_secs(10);
const ROW: f32 = 48.0;
const PILL_HEIGHT: f32 = 19.0;

const GLYPH_REFRESH: &str = "\u{EB13}";
const GLYPH_PLUG: &str = "\u{EBD9}";
const GLYPH_PLUG_OFF: &str = "\u{F180}";
const GLYPH_TRASH: &str = "\u{EB41}";
const GLYPH_CHECK: &str = "\u{EA5E}";
const GLYPH_LOCK: &str = "\u{EAE2}";
const GLYPH_EYE: &str = "\u{EA9A}";
const GLYPH_EYE_OFF: &str = "\u{ECF0}";

// what Amane's Network service doesn't report
#[derive(Default, Clone, PartialEq)]
struct Extras {
    primary: String,
    ipv4: String,
    interface: String,
    frequency: u32,
    last_scan: i64,
    wired_device: Option<String>,
}

struct Prompt {
    ssid: String,
    enterprise: bool,
}

#[derive(Default)]
pub struct NetworkTab {
    visible: bool,
    extras: Extras,
    prompt: Option<Prompt>,
    password: String,
    revealed: bool,
    wifi_target: Option<(bool, Instant)>,
    action: Option<(bool, Instant)>,
    scan: Option<(i64, Instant)>,
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

fn refresh() {
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

fn start_scan() {
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

fn close_prompt() {
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

fn submit_password(password: &str) {
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

fn activate(ssid: String, secured: bool, saved: bool, active: bool) {
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

fn forget(ssid: String) {
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

fn disconnect_clicked(connected: bool, primary: String, wired_device: Option<String>) {
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

fn set_wifi(on: bool) {
    NetworkTab::write().wifi_target = Some((on, Instant::now()));
    Network::set_wifi(on);
}

fn signal_band(strength: u8) -> u8 {
    match strength {
        80.. => 4,
        60..=79 => 3,
        35..=59 => 2,
        15..=34 => 1,
        _ => 0,
    }
}

fn signal_glyph(strength: u8) -> &'static str {
    match signal_band(strength) {
        4 => "\u{EB52}",
        3 => "\u{EBFC}",
        2 => "\u{EBA5}",
        1 => "\u{EBA4}",
        _ => "\u{EBA3}",
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

fn current_detail(ipv4: &str, wifi: Option<(u8, u32)>) -> String {
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

fn current_card(ui: &Ui, tab: &NetworkTab, network: &Network, width: f32) -> Rectangle {
    let c = &ui.c;
    let connected = network.connected();
    let is_wifi = connected && network.link() == Link::Wifi && !network.ssid().is_empty();
    let is_wired = connected && network.link() == Link::Wired;

    let title = if is_wifi {
        network.ssid().to_string()
    } else if is_wired {
        if tab.extras.interface.is_empty() {
            String::from("Wired connection")
        } else {
            tab.extras.interface.clone()
        }
    } else {
        String::from("Not connected")
    };

    let detail = if connected {
        let wifi = is_wifi.then_some((network.strength(), tab.extras.frequency));

        current_detail(&tab.extras.ipv4, wifi)
    } else if network.wifi_enabled() {
        String::from("Wi-Fi is on")
    } else {
        String::from("Wi-Fi is off")
    };

    let can_reconnect = !connected && tab.extras.wired_device.is_some();
    let pending = tab.action.is_some();

    let mut row: Vec<Box<dyn Widget>> = vec![
        Box::new(label(title, FONT_BODY, c.on_surface).weight(Weight::Bold)),
        Box::new(
            Rectangle::new()
                .width(Parent)
                .height(CONTROL_SM)
                .align_child(amane::Start, Center)
                .child(label(detail, FONT_CAPTION, c.variant).elide()),
        ),
    ];

    if connected || can_reconnect || pending {
        let (code, variant) = if connected {
            (GLYPH_PLUG_OFF, Variant::Destructive)
        } else {
            (GLYPH_PLUG, Variant::Default)
        };

        let button = icon_button(ui, "net:disconnect", code, (CONTROL_SM, GLYPH, RADIUS_SM), variant);
        let primary = tab.extras.primary.clone();
        let wired_device = tab.extras.wired_device.clone();

        row.push(Box::new(if pending {
            disabled(button)
        } else {
            button.on_click(move |_| disconnect_clicked(connected, primary.clone(), wired_device.clone()))
        }));
    }

    card(
        ui,
        width,
        Column::new(children![
            label("Current Connection", FONT_TITLE, c.on_surface).weight(Weight::Bold),
            Row::new(row).width(Parent).height(CONTROL_SM).gap(SPACE_SM).align(Center),
        ])
        .width(Parent)
        .gap(SPACE_SM),
    )
}

fn password_card(ui: &Ui, tab: &NetworkTab, prompt: &Prompt, width: f32) -> Rectangle {
    let c = &ui.c;

    if prompt.enterprise {
        return card(
            ui,
            width,
            Column::new(children![
                label(format!("Enter password for {}", prompt.ssid), FONT_BODY, c.on_surface).weight(Weight::Bold),
                label("This network needs an 802.1X sign-in, which this panel can't set up yet.", FONT_CAPTION, c.error),
                Row::new(children![text_button(ui, "wifi:cancel", "Cancel", Variant::Ghost).on_click(|_| close_prompt())])
                    .height(38.0),
            ])
            .width(Parent)
            .gap(SPACE_MD),
        );
    }

    let input = TextInput::new(PASSWORD_INPUT)
        .placeholder("Password")
        .focused()
        .on_change(|text| NetworkTab::write().password = text)
        .on_submit(|text| submit_password(&text));
    let input = if tab.revealed { input } else { input.password() };
    let eye = if tab.revealed { GLYPH_EYE_OFF } else { GLYPH_EYE };

    let row = Row::new(children![
        input_box(ui, input),
        icon_button(ui, "wifi:eye", eye, (CONTROL_SM, GLYPH, RADIUS_MD), Variant::Ghost).on_click(|_| {
            let mut tab = NetworkTab::write();
            tab.revealed = !tab.revealed;
        }),
        text_button(ui, "wifi:connect", "Connect", Variant::Default).on_click(|_| {
            let password = NetworkTab::read().password.clone();
            submit_password(&password);
        }),
        text_button(ui, "wifi:cancel", "Cancel", Variant::Ghost).on_click(|_| close_prompt()),
    ])
    .width(Parent)
    .height(38.0)
    .gap(SPACE_SM)
    .align(Center);

    card(
        ui,
        width,
        Column::new(children![
            label(format!("Enter password for {}", prompt.ssid), FONT_BODY, c.on_surface).weight(Weight::Bold),
            row,
        ])
        .width(Parent)
        .gap(SPACE_MD),
    )
}

#[derive(Clone)]
struct ApRow {
    ssid: String,
    strength: u8,
    secured: bool,
    active: bool,
    saved: bool,
}

fn ap_row(ui: &Ui, ap: &ApRow) -> Rectangle {
    let c = &ui.c;
    let key = format!("ap:{}", ap.ssid);
    let hovered = ui.hovered(&key);

    let ssid = label(ap.ssid.clone(), FONT_BODY, c.on_surface).elide();
    let ssid = if ap.active { ssid.weight(Weight::Bold) } else { ssid };

    let mut row: Vec<Box<dyn Widget>> = vec![
        Box::new(glyph(signal_glyph(ap.strength), GLYPH, c.on_surface)),
        Box::new(Rectangle::new().width(Parent).height(CONTROL_SM).align_child(amane::Start, Center).child(ssid)),
    ];

    if ap.secured {
        row.push(Box::new(glyph(GLYPH_LOCK, GLYPH, c.variant)));
    }

    row.push(Box::new(label(format!("{}%", ap.strength), FONT_CAPTION, c.variant)));

    let action_size = (CONTROL_SM, GLYPH, RADIUS_SM);
    let action_key = format!("ap:action:{}", ap.ssid);

    row.push(Box::new(if ap.active {
        icon_button(ui, action_key, GLYPH_CHECK, action_size, Variant::Ghost).on_click(|_| {})
    } else if ap.saved {
        let ssid = ap.ssid.clone();

        icon_button(ui, action_key, GLYPH_TRASH, action_size, Variant::Ghost).on_click(move |_| forget(ssid.clone()))
    } else {
        // keeps its space, so the percentages line up with the rows that have a button
        Rectangle::new().width(CONTROL_SM).height(CONTROL_SM).on_click(|_| {})
    }));

    let (ssid, secured, saved, active) = (ap.ssid.clone(), ap.secured, ap.saved, ap.active);

    let rectangle = Rectangle::new()
        .width(Parent)
        .height(ROW)
        .radius(RADIUS_MD)
        .fill(c.surface)
        .cursor(Pointer)
        .padding(Padding {
            left: SPACE_MD,
            right: SPACE_MD,
            top: SPACE_SM,
            bottom: SPACE_SM,
        })
        .on_click(move |_| activate(ssid.clone(), secured, saved, active))
        .child(Row::new(row).width(Parent).height(CONTROL_SM).gap(SPACE_SM).align(Center));

    let rectangle = if hovered { rectangle.border(1.0, c.primary) } else { rectangle };

    hoverable(rectangle, key)
}

fn bucket_header(ui: &Ui, title: &str) -> Row {
    let text = label(title, FONT_MINI, ui.c.variant).weight(Weight::Bold);
    let width = crate::ui::width_of(&text) + SPACE_SM * 2.0;

    Row::new(children![
        Rectangle::new()
            .width(width)
            .height(PILL_HEIGHT)
            .radius(RADIUS_SM)
            .fill(ui.c.container)
            .align_child(Center, Center)
            .child(text),
    ])
    .height(PILL_HEIGHT)
}

// active first, then signal band: raw strength would reshuffle rows on every scan
fn sorted(mut aps: Vec<ApRow>) -> Vec<ApRow> {
    aps.sort_by(|a, b| {
        b.active
            .cmp(&a.active)
            .then_with(|| signal_band(b.strength).cmp(&signal_band(a.strength)))
            .then_with(|| a.ssid.cmp(&b.ssid))
    });

    aps
}

fn bucket(ui: &Ui, title: &str, rows: &[ApRow]) -> Vec<Box<dyn Widget>> {
    if rows.is_empty() {
        return Vec::new();
    }

    let mut group: Vec<Box<dyn Widget>> = vec![Box::new(bucket_header(ui, title))];

    group.extend(rows.iter().map(|ap| Box::new(ap_row(ui, ap)) as Box<dyn Widget>));

    vec![Box::new(Column::new(group).width(Parent).gap(SPACE_XS))]
}

fn wifi_card(ui: &Ui, tab: &NetworkTab, network: &Network, width: f32) -> Rectangle {
    let c = &ui.c;
    let on = tab.wifi_target.map_or(network.wifi_enabled(), |(target, _)| target);

    let mut header: Vec<Box<dyn Widget>> = vec![Box::new(
        Rectangle::new()
            .width(Parent)
            .height(CONTROL_SM)
            .align_child(amane::Start, Center)
            .child(label("Wi-Fi", FONT_BODY, c.on_surface).weight(Weight::Bold)),
    )];

    if tab.scan.is_some() {
        header.push(Box::new(spinner(GLYPH, c.primary)));
    }

    header.push(Box::new(
        icon_button(ui, "wifi:rescan", GLYPH_REFRESH, (CONTROL_SM, GLYPH, RADIUS_SM), Variant::Ghost)
            .on_click(|_| start_scan()),
    ));

    let wifi_toggle = toggle(ui, "wifi:toggle", on, false);

    header.push(Box::new(if tab.wifi_target.is_some() {
        disabled(wifi_toggle)
    } else {
        wifi_toggle.on_click(move |_| set_wifi(!on))
    }));

    let mut rows: Vec<Box<dyn Widget>> = vec![Box::new(
        Row::new(header).width(Parent).height(CONTROL_SM).gap(SPACE_SM).align(Center),
    )];

    let aps = sorted(
        network
            .access_points()
            .iter()
            .map(|ap| ApRow {
                ssid: ap.ssid().to_string(),
                strength: ap.strength(),
                secured: ap.secured(),
                active: ap.active(),
                saved: ap.saved(),
            })
            .collect(),
    );

    if aps.is_empty() {
        let text = if network.wifi_enabled() { "No networks in range" } else { "Wi-Fi is off" };

        rows.push(Box::new(label(text, FONT_BODY, c.variant)));
    } else {
        let (active, others): (Vec<ApRow>, Vec<ApRow>) = aps.into_iter().partition(|ap| ap.active);
        let (saved, available): (Vec<ApRow>, Vec<ApRow>) = others.into_iter().partition(|ap| ap.saved);

        rows.extend(active.iter().map(|ap| Box::new(ap_row(ui, ap)) as Box<dyn Widget>));
        rows.extend(bucket(ui, "Saved", &saved));
        rows.extend(bucket(ui, "Available", &available));
    }

    card(ui, width, Column::new(rows).width(Parent).gap(SPACE_SM))
}

pub fn view(ui: &Ui, width: f32, height: f32) -> Column {
    let tab = NetworkTab::read();
    let network = Network::read();
    let current = current_card(ui, &tab, &network, width);
    let current_height = crate::ui::height_of(&current);

    let list = scroll_view(ui, "network", (width, height - current_height - SPACE_MD), |list_width| {
        let mut column: Vec<Box<dyn Widget>> = Vec::new();

        if let Some(prompt) = &tab.prompt {
            column.push(Box::new(password_card(ui, &tab, prompt, list_width)));
        }

        column.push(Box::new(wifi_card(ui, &tab, &network, list_width)));

        Column::new(column).width(list_width).gap(SPACE_MD)
    });

    Column::new(children![current, list]).width(width).height(height).gap(SPACE_MD)
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
