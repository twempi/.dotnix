use amane::{
    Center, Color, Column, Horizontal, Image, LayerWindow, Margin, Monitor, Notification,
    Notifications, Parent, Pointer, Rectangle, Row, ScrollArea, Service, SpaceBetween,
    Start, Urgency, Vertical, Weight, Widget, children,
};

use crate::logic::compositor::{self, MainOutput};
use crate::logic::icons::Icons;
use crate::logic::notifications::{
    NotificationCenter, Tick, clicked, invoked, popups, relative, toggle_dnd,
};
use crate::logic::theme::Theme;
use crate::logic::tray::strip_markup;
use crate::looks::hyprland::ui::{self, BELOW, BORDER, GAP, MENU_FONT, TEXT, appear, forget};
use crate::looks::tabs::controls::{FONT_BODY, Ui, Variant, glyph, label, text_button, toggle};

const POPUP_WIDTH: f32 = 360.0;

const ICON: f32 = 40.0;

const PAD: f32 = 10.0;

// the urgency's color, down the card's left edge
const STRIPE: f32 = 3.0;

const SMALL: f32 = 11.5;

const ACTION: f32 = 26.0;

const GLYPH_CLOSE: &str = "\u{EB55}";

fn urgency_color(notification: &Notification, base: &[Color; 16]) -> Color {
    match notification.urgency() {
        Urgency::Critical => base[8],
        Urgency::Low => base[3],
        Urgency::Normal => base[0x0E],
    }
}

// the app and its age over the summary, then the body beside the icon, then the actions
fn card(notification: &Notification, width: f32, in_center: bool, icons: &Icons, base: &[Color; 16]) -> Rectangle {
    let id = notification.id();
    let inner = width - BORDER * 2.0 - STRIPE - PAD * 2.0;

    let icon_path = icons
        .find(notification.image())
        .or_else(|| icons.find(notification.icon()));

    let text_width = if icon_path.is_some() { inner - ICON - PAD } else { inner };

    let small_line = ui::height_of(&ui::text("A", SMALL, MENU_FONT));
    let line = ui::height_of(&ui::text("A", TEXT, MENU_FONT));

    let app = match notification.app_name() {
        "" => "Notification",
        name => name,
    };

    let about = ui::text(
        format!("{} · {}", app.to_uppercase(), relative(notification.received())),
        SMALL,
        MENU_FONT,
    )
    .color(base[4]);

    let close = Rectangle::new()
        .width(16.0)
        .height(small_line)
        .cursor(Pointer)
        .on_click(move |_| Notifications::dismiss(id))
        .align_child(Center, Center)
        .child(glyph(GLYPH_CLOSE, 12.0, base[4]));

    let header = Row::new(children![
        Rectangle::new()
            .width(inner - 24.0)
            .height(small_line)
            .align_child(Start, Center)
            .child(about.elide()),
        close,
    ])
    .width(inner)
    .height(small_line)
    .justify(SpaceBetween)
    .align(Center);

    let summary = ui::text(notification.summary(), TEXT, MENU_FONT)
        .color(base[5])
        .weight(Weight::from(700))
        .elide();

    let body_text = strip_markup(notification.body());
    let body = ui::text(body_text.trim(), TEXT - 1.0, MENU_FONT)
        .color(base[4])
        .wrap()
        .max_lines(3);
    let body_height = if body_text.trim().is_empty() {
        0.0
    } else {
        body.height_in(text_width).min(line * 3.0)
    };

    let mut words: Vec<Box<dyn Widget>> = vec![Box::new(Rectangle::new().width(text_width).height(line).child(summary))];

    if body_height > 0.0 {
        words.push(Box::new(Rectangle::new().width(text_width).height(body_height).child(body)));
    }

    let words_height = line + if body_height > 0.0 { body_height + 2.0 } else { 0.0 };

    let mut middle: Vec<Box<dyn Widget>> = Vec::new();

    if let Some(path) = icon_path {
        middle.push(Box::new(
            Rectangle::new()
                .width(ICON)
                .height(ICON)
                .clip()
                .fill(Image::contain(path).thumbnail(80, 80)),
        ));
    }

    let middle_height = words_height.max(if middle.is_empty() { 0.0 } else { ICON });
    middle.push(Box::new(Column::new(words).gap(2.0)));

    let mut rows: Vec<Box<dyn Widget>> = vec![
        Box::new(header),
        Box::new(Row::new(middle).height(middle_height).gap(PAD)),
    ];
    let mut height = small_line + 6.0 + middle_height;

    if !notification.actions().is_empty() {
        let buttons: Vec<Box<dyn Widget>> = notification
            .actions()
            .iter()
            .map(|action| {
                let key = action.key().to_string();

                Box::new(
                    Rectangle::new()
                        .width(Parent)
                        .height(ACTION)
                        .fill(base[2])
                        .cursor(Pointer)
                        .on_click(move |_| invoked(id, &key))
                        .align_child(Center, Center)
                        .child(ui::text(action.label(), TEXT - 1.0, MENU_FONT).color(base[5]).elide()),
                ) as Box<dyn Widget>
            })
            .collect();

        rows.push(Box::new(Row::new(buttons).width(inner).height(ACTION).gap(6.0)));
        height += 6.0 + ACTION;
    }

    let (fill, border) = if in_center { (base[1], base[2]) } else { (base[0], base[0x0E]) };

    Rectangle::new()
        .width(width)
        .height(height + PAD * 2.0 + BORDER * 2.0)
        .fill(fill)
        .border(BORDER, border)
        .padding(BORDER)
        .cursor(Pointer)
        .on_click(move |button| clicked(id, button))
        .child(Row::new(children![
            Rectangle::new().width(STRIPE).height(Parent).fill(urgency_color(notification, base)),
            Rectangle::new()
                .width(Parent)
                .height(Parent)
                .padding(PAD)
                .child(Column::new(rows).gap(6.0)),
        ]))
}

// popups drop under the right island, on the main monitor only, newest on top
pub fn popups_view(monitor: &Monitor) -> LayerWindow {
    let notifications = Notifications::read();
    let center = NotificationCenter::read();
    let _tick = Tick::read();
    let icons = Icons::read();
    let theme = Theme::read();
    let main = MainOutput::read();

    let on_main = compositor::shown_on(&main.name, monitor);
    let shown = if on_main { popups(&notifications, &center) } else { Vec::new() };
    let room = monitor.height as f32 - BELOW - GAP;

    let prefix = format!("popup:{}:", monitor.name);
    let mut keys = Vec::new();
    let mut cards: Vec<Box<dyn Widget>> = Vec::new();
    let mut height = 0.0;

    for notification in shown {
        let card = card(notification, POPUP_WIDTH, false, &icons, &theme.base);
        let card_height = ui::height_of(&card);

        if height + card_height > room {
            break;
        }

        // each card slides in from the right as it arrives
        let key = format!("{prefix}{}", notification.id());
        let settled = appear(&key, true);
        keys.push(key);

        height += card_height + GAP;
        cards.push(Box::new(card.translate((1.0 - settled) * 24.0, 0.0).opacity(settled)));
    }

    forget(|key| key.starts_with(&prefix) && !keys.iter().any(|kept| kept == key));

    LayerWindow::new()
        .width(POPUP_WIDTH)
        .height(height.max(1.0))
        .anchor_vertical(Vertical::Top)
        .anchor_horizontal(Horizontal::Right)
        .margin(Margin {
            top: GAP as i32,
            right: GAP as i32,
            ..Margin::default()
        })
        .namespace("amane-notifications")
        .visible(!cards.is_empty())
        .child(Column::new(cards).gap(GAP))
}

// the panel's notifications tab
pub fn page(ui: &Ui, inner: f32, dnd: bool, base: &[Color; 16]) -> Column {
    let notifications = Notifications::read();
    let icons = Icons::read();

    let controls = Row::new(children![
        label("Do Not Disturb", FONT_BODY, ui.c.on_surface),
        Row::new(children![
            toggle(ui, "notifications:dnd", dnd, false).on_click(|_| toggle_dnd()),
            text_button(ui, "notifications:clear", "Clear", Variant::Outline).on_click(|_| Notifications::clear()),
        ])
        .gap(12.0)
        .align(Center),
    ])
    .width(inner)
    .height(38.0)
    .justify(SpaceBetween)
    .align(Center);

    let list: Box<dyn Widget> = if notifications.list().is_empty() {
        Box::new(
            Rectangle::new()
                .width(inner)
                .height(Parent)
                .align_child(Center, Center)
                .child(label("No Notifications", FONT_BODY, ui.c.variant)),
        )
    } else {
        let cards: Vec<Box<dyn Widget>> = notifications
            .list()
            .iter()
            .rev()
            .map(|notification| Box::new(card(notification, inner, true, &icons, base)) as Box<dyn Widget>)
            .collect();

        Box::new(ScrollArea::new("notification-center", Column::new(cards).gap(GAP)).width(inner))
    };

    Column::new(vec![
        Box::new(controls),
        Box::new(Rectangle::new().width(inner).height(1.0).fill(ui.c.outline)),
        list,
    ])
    .gap(10.0)
}
