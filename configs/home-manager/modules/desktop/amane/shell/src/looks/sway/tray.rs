use amane::{
    Button, Center, Color, Column, Full, Image, LayerWindow, Margin, Monitor, Padding,
    Parent, Pointer, Rectangle, Row, Service, Start, Vertical, Widget,
};

use crate::logic::icons::Icons;
use crate::logic::stats;
use crate::logic::theme::Theme;
use crate::logic::tray::{
    Tip, Tray, TrayMenu, activate, back, clicked, close_menu, current, hovered, menu_key, pointer_x,
    scrolled,
};
use crate::looks::sway::ui::{self, BAR_HEIGHT, MENU_FONT, MENU_TEXT, Placement};

// room for the longest details; the window never resizes, only its drawing does
const TIP_HEIGHT: f32 = 120.0;

pub fn tip_view(monitor: &Monitor) -> LayerWindow {
    let tip = Tip::read();
    let theme = Theme::read();

    let lines = match tip.detail {
        Some(detail) => stats::details(detail),
        None if !tip.text.is_empty() => vec![tip.text.replace('\n', "  ")],
        None => Vec::new(),
    };

    let visible = !lines.is_empty() && tip.monitor == monitor.name;

    let labels: Vec<_> = lines
        .into_iter()
        .map(|line| ui::text(line, MENU_TEXT - 1.0, MENU_FONT).color(theme.base[5]))
        .collect();

    let width = labels.iter().map(|label| ui::width_of(label)).fold(0.0, f32::max) + 16.0;
    let height = labels.iter().map(|label| ui::height_of(label)).sum::<f32>().max(16.0) + 10.0;
    let boxed: Vec<Box<dyn Widget>> = labels.into_iter().map(|label| Box::new(label) as Box<dyn Widget>).collect();

    let left = (pointer_x() - width / 2.0).clamp(0.0, (monitor.width as f32 - width).max(0.0));

    // a full-width strip that never moves: only the drawing follows the pointer, so the
    // compositor sees no layer changes besides showing and hiding (see notifications::close)
    LayerWindow::new()
        .width(Full)
        .height(TIP_HEIGHT)
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
                .align_child(Start, Start)
                .child(
                    Rectangle::new()
                        .width(width)
                        .height(height.min(TIP_HEIGHT))
                        .fill(theme.base[1])
                        .border(1.0, theme.base[3])
                        .padding(Padding {
                            left: 8.0,
                            ..Padding::default()
                        })
                        .align_child(Start, Center)
                        .child(Column::new(boxed)),
                ),
        )
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
        )
        // the pointer moves the same highlight the arrow keys do
        .on_hover(move |inside| {
            if inside {
                TrayMenu::write().selected = index;
            }
        })));
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
            .border(1.0, theme.base[0x0E])
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
        (true, true) => (base[0x0E], base[0]),
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
