use amane::{
    Center, Full, LayerWindow, Margin, Monitor, Parent, Rectangle, Row, Service, Vertical,
    children,
};

use crate::logic::osd::Osd;
use crate::logic::theme::Theme;
use crate::looks::sway::ui::{self, MENU_FONT, MENU_TEXT};

// shown on every monitor, unlike notifications
pub fn view(_: &Monitor) -> LayerWindow {
    let osd = Osd::read();
    let theme = Theme::read();
    let base = theme.base;

    let (glyph, text, on) = osd.shown.map_or(("", "", false), |(message, _)| message);
    let visible = osd.shown.is_some();

    // what turned off gets a dim glyph, as Noctalia's inactive lock keys do
    let content = Row::new(children![
        ui::text(glyph, MENU_TEXT + 4.0, MENU_FONT).color(if on { base[0x0E] } else { base[3] }),
        ui::text(text, MENU_TEXT, MENU_FONT).color(base[5]),
    ])
    .gap(10.0)
    .align(Center);

    let width = ui::width_of(&content) + 32.0;

    // a full-width strip that never moves, like the tray tooltip (see notifications::close)
    LayerWindow::new()
        .width(Full)
        .height(40.0)
        .anchor_vertical(Vertical::Top)
        .margin(Margin {
            top: 10,
            ..Margin::default()
        })
        .namespace("amane-osd")
        .click_through()
        .visible(visible)
        .child(
            Rectangle::new()
                .width(Parent)
                .height(Parent)
                .align_child(Center, Center)
                .child(
                    Rectangle::new()
                        .width(width)
                        .height(Parent)
                        .fill(base[0])
                        .border(1.0, base[0x0E])
                        .align_child(Center, Center)
                        .child(content),
                ),
        )
}
