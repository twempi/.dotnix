use amane::{
    Center, Column, Link, Network, Padding, Parent, Pointer, Rectangle, Row, Service,
    TextInput, Weight, Widget, children,
};

use crate::logic::panel::network::{
    ApRow, NetworkTab, PASSWORD_INPUT, Prompt, activate, close_prompt, current_detail,
    disconnect_clicked, forget, set_wifi, signal_band, sorted, start_scan, submit_password,
};
use super::controls::{
    CONTROL_SM, FONT_BODY, FONT_CAPTION, FONT_MINI, FONT_TITLE, GLYPH, RADIUS_MD, RADIUS_SM, SPACE_MD,
    SPACE_SM, SPACE_XS, Ui, Variant, card, disabled, glyph, hoverable, icon_button, input_box, label,
    scroll_view, spinner, text_button, toggle,
};

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

fn signal_glyph(strength: u8) -> &'static str {
    match signal_band(strength) {
        4 => "\u{EB52}",
        3 => "\u{EBFC}",
        2 => "\u{EBA5}",
        1 => "\u{EBA4}",
        _ => "\u{EBA3}",
    }
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
    let width = crate::looks::ui::width_of(&text) + SPACE_SM * 2.0;

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
    let current_height = crate::looks::ui::height_of(&current);

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
