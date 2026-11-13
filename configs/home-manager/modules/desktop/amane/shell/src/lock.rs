use amane::{
    Center, Column, Full, Key, LayerWindow, Lock, Monitor, Parent, Rectangle, Row, Service, Start, TextInput,
    Weight, children,
};

use crate::notifications::Tick;
use crate::panel::controls::glyph;
use crate::theme::Theme;
use crate::ui::{self, MENU_FONT, MENU_TEXT};

const INPUT: &str = "lock-password";
const WIDTH: f32 = 360.0;

// `amane ipc call lock`, from the power menu
pub fn lock(_: &[String]) -> String {
    Lock::start();

    String::from("locked")
}

// the launcher's look: the palette's background, the accent border and the power menu's glyph box
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

    let line = ui::height_of(&ui::text("A", MENU_TEXT, MENU_FONT)) + 16.0;

    let icon = Rectangle::new()
        .width(40.0)
        .height(line)
        .fill(accent)
        .align_child(Center, Center)
        .child(glyph("\u{EAE2}", MENU_TEXT + 2.0, base[0]));

    let entry = Rectangle::new()
        .width(Parent)
        .height(line)
        .border(1.0, accent)
        .padding(8.0)
        .align_child(Start, Center)
        .child(
            TextInput::new(INPUT)
                .size(MENU_TEXT)
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
                .align_child(Center, Center)
                .child(
                    Column::new(children![
                        ui::text(now.format("%H:%M").to_string(), 96.0, MENU_FONT)
                            .color(base[0x0E])
                            .weight(Weight::Bold),
                        ui::text(now.format("%A, %B %-d").to_string(), MENU_TEXT + 4.0, MENU_FONT).color(base[5]),
                        Rectangle::new().width(WIDTH).height(24.0),
                        Rectangle::new()
                            .width(WIDTH)
                            .height(line)
                            .child(Row::new(children![icon, entry]).gap(8.0)),
                    ])
                    .gap(8.0)
                    .align(Center),
                ),
        )
}
