use amane::{
    Align, Full, Key, Keyboard, Layer, LayerWindow, Padding, Parent, Rectangle, Size, Text, Widget,
    Zone,
};

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
