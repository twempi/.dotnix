use amane::{Center, Full, LayerWindow, Monitor, Padding, Parent, Rectangle, Row, Service, Start, Vertical, children};

use crate::logic::osd::Osd;
use crate::logic::theme::Theme;
use crate::looks::hyprland::ui::{self, BORDER, GAP, MENU_FONT, TEXT, appear, frame, settle};

const HEIGHT: f32 = 36.0;

// shown on every monitor, unlike notifications, right under the media island
pub fn view(monitor: &Monitor) -> LayerWindow {
    let osd = Osd::read();
    let base = Theme::read().base;

    let (glyph, text, on) = osd.shown.map_or(("", "", false), |(message, _)| message);
    let visible = osd.shown.is_some();
    let settled = appear(&format!("osd:{}", monitor.name), visible);

    // what turned off gets a dim block, what turned on the accent
    let (fill, ink) = if on { (base[0x0E], base[0]) } else { (base[2], base[4]) };

    let words = ui::text(text, TEXT, MENU_FONT).color(base[5]);
    let width = (HEIGHT + 12.0 + ui::width_of(&words) + 16.0 + BORDER * 2.0).ceil();

    let content = Row::new(children![
        Rectangle::new()
            .width(HEIGHT)
            .height(HEIGHT)
            .fill(fill)
            .align_child(Center, Center)
            .child(ui::text(glyph, TEXT + 4.0, MENU_FONT).color(ink)),
        words,
    ])
    .gap(12.0)
    .align(Center);

    // a full-width strip that never moves, like the tray tooltip (see notifications::close)
    LayerWindow::new()
        .width(Full)
        .height(GAP * 2.0 + HEIGHT + BORDER * 2.0)
        .anchor_vertical(Vertical::Top)
        .namespace("amane-osd")
        .click_through()
        .visible(visible)
        .child(
            Rectangle::new()
                .width(Parent)
                .height(Parent)
                .padding(Padding {
                    top: GAP,
                    ..Padding::default()
                })
                .align_child(Center, Start)
                .child(settle(
                    frame(Rectangle::new().width(width).height(HEIGHT + BORDER * 2.0), &base)
                        .padding(BORDER)
                        .align_child(Start, Center)
                        .child(content),
                    settled,
                )),
        )
}
