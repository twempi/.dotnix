use amane::{
    Align, Full, Key, Keyboard, Layer, LayerWindow, Monitor, Padding, Parent, Rectangle, Service,
    Size, Text, Widget, Workspaces, Zone,
};

// waybar's sway.css font, 11pt
pub const BAR_FONT: &str = "IosevkaTerm Nerd Font Propo";
pub const BAR_TEXT: f32 = 14.5;

// rofi's theme font, "JetBrainsMono Nerd Font 11"
pub const MENU_FONT: &str = "JetBrainsMono Nerd Font";
pub const MENU_TEXT: f32 = 14.5;

pub const BAR_HEIGHT: f32 = 24.0;

pub fn text(content: impl Into<String>, size: f32, font: &str) -> Text {
    Text::new(content).size(size).font(font)
}

// a fixed-size widget's width, so a rectangle can wrap it tightly
pub fn width_of(widget: &dyn Widget) -> f32 {
    match widget.width() {
        Size::Fixed(width) => width,
        Size::Parent => 0.0,
    }
}

pub fn height_of(widget: &dyn Widget) -> f32 {
    match widget.height() {
        Size::Fixed(height) => height,
        Size::Parent => 0.0,
    }
}

// the monitor a popup opens on: where the focused workspace is
pub fn focused_output() -> String {
    Workspaces::read()
        .list()
        .iter()
        .find(|workspace| workspace.focused())
        .and_then(|workspace| workspace.output())
        .unwrap_or_default()
        .to_string()
}

// an empty monitor name means the focused one wasn't known, so every monitor shows it
pub fn shown_on(wanted: &str, monitor: &Monitor) -> bool {
    wanted.is_empty() || wanted == monitor.name
}

pub struct Placement {
    pub horizontal: Align,
    pub vertical: Align,
    pub padding: Padding,
}

impl Placement {
    pub fn center() -> Self {
        Self {
            horizontal: Align::Center,
            vertical: Align::Center,
            padding: Padding::default(),
        }
    }
}

/*
 * popups cover the whole monitor with a clear backdrop, like rofi and swaync do,
 * so a click outside the panel closes it
 */
pub fn overlay(
    namespace: &'static str,
    visible: bool,
    placement: Placement,
    dismiss: fn(),
    on_key: impl Fn(Key) + 'static,
    panel: impl Widget + 'static,
) -> LayerWindow {
    let keyboard = if visible {
        Keyboard::Exclusive
    } else {
        Keyboard::None
    };

    LayerWindow::new()
        .width(Full)
        .height(Full)
        .layer(Layer::Overlay)
        .space(Zone::Ignore)
        .keyboard(keyboard)
        .namespace(namespace)
        .visible(visible)
        .on_key(on_key)
        .child(
            Rectangle::new()
                .width(Parent)
                .height(Parent)
                .on_click(move |_| dismiss())
                .padding(placement.padding)
                .align_child(placement.horizontal, placement.vertical)
                .child(panel),
        )
}

// a panel's own empty space must not count as a click on the backdrop
pub fn swallow_clicks(panel: Rectangle) -> Rectangle {
    panel.on_click(|_| {})
}

// swaynotificationcenter and rofi both run commands through sway, so launched
// programs don't live in the shell's service and survive a shell restart
pub fn run(command: &str) {
    if std::env::var_os("SWAYSOCK").is_none() {
        amane::spawn(command);
        return;
    }

    amane::spawn(&format!("swaymsg {}", quote(&format!("exec {command}"))));
}

pub fn quote(value: &str) -> String {
    format!("'{}'", value.replace('\'', r"'\''"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn quotes_for_sh() {
        assert_eq!(quote("a b"), "'a b'");
        assert_eq!(quote("it's"), r"'it'\''s'");
    }
}
