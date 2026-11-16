use std::sync::{Mutex, PoisonError};
use std::time::{Duration, Instant};

use amane::{
    Align, Full, Key, Keyboard, Layer, LayerWindow, Padding, Parent, Rectangle, Size, Text, Widget,
    Zone, request_frame,
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

const SETTLE: Duration = Duration::from_millis(160);

// how far a popup drops as it settles
const DROP: f32 = 8.0;

// when each thing on screen first appeared, keyed by what it is and on which monitor
static SINCE: Mutex<Vec<(String, Instant)>> = Mutex::new(Vec::new());

/*
 * 0 when something has just come on screen, 1 once it has settled; the window keeps
 * drawing frames until then. Only the drawing moves, the layer surface never changes size
 */
pub fn appear(key: &str, shown: bool) -> f32 {
    let mut since = SINCE.lock().unwrap_or_else(PoisonError::into_inner);
    let found = since.iter().position(|(name, _)| name == key);

    if !shown {
        if let Some(index) = found {
            since.swap_remove(index);
        }

        return 1.0;
    }

    let started = match found {
        Some(index) => since[index].1,
        None => {
            since.push((key.to_string(), Instant::now()));
            Instant::now()
        }
    };

    let progress = (started.elapsed().as_secs_f32() / SETTLE.as_secs_f32()).min(1.0);

    if progress < 1.0 {
        request_frame();
    }

    1.0 - (1.0 - progress).powi(3)
}

// what left the screen without appear(key, false), like a popup that timed out
pub fn forget(stale: impl Fn(&str) -> bool) {
    SINCE.lock().unwrap_or_else(PoisonError::into_inner).retain(|(name, _)| !stale(name));
}

// slides a popup down into place while it fades in
pub fn settle(rectangle: Rectangle, progress: f32) -> Rectangle {
    rectangle.translate(0.0, (progress - 1.0) * DROP).opacity(progress)
}
