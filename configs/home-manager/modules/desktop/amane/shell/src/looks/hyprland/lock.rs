use amane::{
    Center, Column, End, Full, Key, LayerWindow, Lock, Monitor, Parent, Rectangle, Row, Service, Start,
    TextInput, Weight, children,
};

use crate::logic::notifications::Tick;
use crate::logic::theme::Theme;
use crate::looks::hyprland::ui::{self, MENU_FONT, TEXT};
use crate::looks::tabs::controls::glyph;

const INPUT: &str = "lock-password";

const WIDTH: f32 = 380.0;

// how far the clock and the password sit from the bottom-left corner
const MARGIN: f32 = 72.0;

const GLYPH_LOCK: &str = "\u{EAE2}";

// the clock big in the corner, the password under it
pub fn view(_: &Monitor) -> LayerWindow {
    // the clock changes once a minute
    let _tick = Tick::read();
    let lock = Lock::read();
    let base = Theme::read().base;
    let now = chrono::Local::now();

    let (accent, status) = if lock.checking() {
        (base[0x0E], "Checking...")
    } else if lock.failed() {
        (base[8], "Wrong password")
    } else {
        (base[0x0E], "Password")
    };

    let line = ui::height_of(&ui::text("A", TEXT, MENU_FONT)) + 18.0;

    let icon = Rectangle::new()
        .width(line)
        .height(line)
        .fill(accent)
        .align_child(Center, Center)
        .child(glyph(GLYPH_LOCK, TEXT + 2.0, base[0]));

    let entry = Rectangle::new()
        .width(Parent)
        .height(line)
        .fill(base[1])
        .border(1.0, accent)
        .padding(10.0)
        .align_child(Start, Center)
        .child(
            TextInput::new(INPUT)
                .size(TEXT)
                .color(base[5])
                .placeholder(status)
                .password()
                .focused()
                .on_submit(|password| Lock::unlock(&password)),
        );

    LayerWindow::new()
        .width(Full)
        .height(Full)
        // Escape leaves the input; clearing it redraws, and the redraw focuses it again
        .on_key(|key| {
            if key == Key::Escape {
                TextInput::set_text(INPUT, "");
            }
        })
        .child(
            Rectangle::new()
                .width(Parent)
                .height(Parent)
                .fill(base[0])
                .padding(MARGIN)
                .align_child(Start, End)
                .child(
                    Column::new(children![
                        ui::text(now.format("%H:%M").to_string(), 120.0, MENU_FONT)
                            .color(base[0x0E])
                            .weight(Weight::Bold),
                        ui::text(now.format("%A, %B %-d").to_string().to_uppercase(), TEXT + 4.0, MENU_FONT).color(base[5]),
                        Rectangle::new().width(WIDTH).height(32.0),
                        Rectangle::new()
                            .width(WIDTH)
                            .height(line)
                            .child(Row::new(children![icon, entry])),
                    ])
                    .gap(6.0)
                    .align(Start),
                ),
        )
}
