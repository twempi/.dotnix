use std::thread;

use amane::{
    Center, Column, Padding, Parent, Pointer, Rectangle, Row, Service, TextInput, Weight, Widget, children,
};

use crate::logic::panel::bluetooth::{
    Adapter, Agent, BluetoothTab, Device, GLYPH_BLUETOOTH, PAIR_INPUT, Pairing, PairingKind,
    accept_clicked, cancel_pairing, connect, device_call, forget, pair, refresh, rescan,
    set_adapter_property, set_powered, set_trusted, signal_percent, submit_code, toggle_expanded,
    trust_and_allow,
};
use super::controls::{
    CONTROL_SM, FONT_BODY, FONT_CAPTION, FONT_TITLE, GLYPH, RADIUS_MD, RADIUS_SM, SPACE_MD, SPACE_SM,
    SPACE_XS, Ui, Variant, card, disabled, glyph, icon_button, input_box, label, scroll_view, spinner,
    text_button, toggle,
};

const ROW: f32 = 48.0;

const GLYPH_REFRESH: &str = "\u{EB13}";

const GLYPH_PLUG: &str = "\u{EBD9}";

const GLYPH_PLUG_OFF: &str = "\u{F180}";

const GLYPH_TRASH: &str = "\u{EB41}";

const GLYPH_CHEVRON: &str = "\u{EA5F}";

const GLYPH_BATTERY: &str = "\u{EA34}";

const GLYPH_SIGNAL: &str = "\u{ECCB}";

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
        let body_height = crate::looks::ui::height_of(&body) + SPACE_XS + SPACE_SM;

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

        used = crate::looks::ui::height_of(&card) + SPACE_MD;
        column.push(Box::new(card));
    }

    column.push(Box::new(scroll_view(ui, "bluetooth", (width, height - used), |list| {
        device_list(ui, &tab, list)
    })));

    Column::new(column).width(width).height(height).gap(SPACE_MD)
}
