// Noctalia's controls, squared and recolored to match the bar and launcher

use std::collections::{HashMap, HashSet};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use amane::{
    Arc, Canvas, Cap, Center, Color, Column, End, Padding, Parent, Pointer, Rectangle, Row, Service,
    Shape, Size, Stack, Start, Text, TextInput, Widget, children, request_frame,
};

use crate::ui::{height_of, width_of};

pub const TEXT_FONT: &str = "Iosevka";
pub const ICON_FONT: &str = "noctalia-tabler-icons";

pub const RADIUS_SM: f32 = 0.0;
pub const RADIUS_MD: f32 = 0.0;
pub const RADIUS_LG: f32 = 0.0;
pub const RADIUS_XL: f32 = 0.0;

pub const SPACE_XS: f32 = 4.0;
pub const SPACE_SM: f32 = 8.0;
pub const SPACE_MD: f32 = 12.0;

pub const FONT_MINI: f32 = 11.0;
pub const FONT_CAPTION: f32 = 13.0;
pub const FONT_BODY: f32 = 14.0;
pub const FONT_TITLE: f32 = 16.0;

pub const CONTROL_SM: f32 = 32.0;
pub const CONTROL: f32 = 38.0;
pub const GLYPH: f32 = 16.0;

const WHEEL_STEP: f32 = 56.0;
const SCROLLBAR: f32 = 6.0;
const SCROLLBAR_HOVER: f32 = 12.0;
const SCROLLBAR_GAP: f32 = 8.0;
const SCROLLBAR_MIN_THUMB: f32 = 32.0;
const SPINNER_MS: u128 = 1200;
const SPINNER_TRAIL: f32 = 266.0;
const DISABLED_OPACITY: f32 = 0.55;

#[derive(Clone, Copy)]
pub struct Roles {
    pub primary: Color,
    pub on_primary: Color,
    pub secondary: Color,
    pub hover: Color,
    pub on_hover: Color,
    pub surface: Color,
    pub container: Color,
    pub on_surface: Color,
    pub variant: Color,
    pub outline: Color,
    pub error: Color,
    pub on_error: Color,
    pub calendars: [Color; 8],
}

impl Roles {
    pub fn new(base: &[Color; 16]) -> Self {
        Self {
            // the bar's accent; a hovered control gets its workspace box's tint
            primary: base[0x0E],
            on_primary: base[0x00],
            secondary: base[0x0D],
            hover: with_alpha(base[0x0E], 0.33),
            on_hover: base[0x05],
            surface: base[0x00],
            container: base[0x01],
            on_surface: base[0x05],
            variant: base[0x04],
            outline: base[0x03],
            error: base[0x08],
            on_error: base[0x00],
            // one per calendar, in Google's order, starting with the accent
            calendars: [base[0x0E], base[0x0D], base[0x0B], base[0x09], base[0x0C], base[0x08], base[0x0A], base[0x0F]],
        }
    }
}

// what the pointer is doing in the panel, which only the panel's own views need
#[derive(Default, Clone)]
pub struct Interaction {
    hovered: HashSet<String>,
    offsets: HashMap<&'static str, f32>,
}

impl Service for Interaction {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

impl Interaction {
    fn set_hovered(key: &str, inside: bool) {
        // told about a key it doesn't hold: the layout shifted under the pointer, so Amane named the wrong target
        if !inside && !Self::read().hovered.contains(key) {
            if !Self::read().hovered.is_empty() {
                Self::write().hovered.clear();
            }

            return;
        }

        let mut state = Self::write();

        if inside {
            state.hovered.insert(key.to_string());
        } else {
            state.hovered.remove(key);
        }
    }

    pub fn clear_hover() {
        if !Self::read().hovered.is_empty() {
            Self::write().hovered.clear();
        }
    }

    fn scroll_to(id: &'static str, offset: f32, max: f32) {
        let offset = offset.clamp(0.0, max);

        if Self::read().offsets.get(id).copied().unwrap_or(0.0) != offset {
            Self::write().offsets.insert(id, offset);
        }
    }
}

// everything a view needs, read once per frame: the services must not be read again further down
pub struct Ui {
    pub c: Roles,
    interaction: Interaction,
}

impl Ui {
    pub fn new(base: &[Color; 16]) -> Self {
        Self {
            c: Roles::new(base),
            interaction: Interaction::read().clone(),
        }
    }

    pub fn hovered(&self, key: &str) -> bool {
        self.interaction.hovered.contains(key)
    }

    pub fn scroll_offset(&self, id: &str) -> f32 {
        self.interaction.offsets.get(id).copied().unwrap_or(0.0)
    }
}

pub fn label(content: impl Into<String>, size: f32, color: Color) -> Text {
    crate::ui::text(content, size, TEXT_FONT).color(color)
}

// a square the size of the glyph, as Noctalia lays icons out; the ink is centered in it
pub fn glyph(codepoint: &str, size: f32, color: Color) -> Rectangle {
    Rectangle::new()
        .width(size)
        .height(size)
        .align_child(Center, Center)
        .child(crate::ui::text(codepoint, size, ICON_FONT).color(color).tight())
}

pub fn hoverable(rectangle: Rectangle, key: String) -> Rectangle {
    rectangle.on_hover(move |inside| Interaction::set_hovered(&key, inside))
}

#[derive(Clone, Copy, PartialEq)]
pub enum Variant {
    Default,
    Ghost,
    Primary,
    Destructive,
    Outline,
    TabActive,
}

pub struct Look {
    pub fill: Color,
    pub border: Option<Color>,
    pub content: Color,
}

pub fn look(c: &Roles, variant: Variant, hovered: bool) -> Look {
    if hovered && variant != Variant::TabActive {
        return Look {
            fill: c.hover,
            border: None,
            content: c.on_hover,
        };
    }

    match variant {
        Variant::Default => Look {
            fill: c.container,
            border: Some(c.outline),
            content: c.on_surface,
        },
        Variant::Ghost => Look {
            fill: Color::TRANSPARENT,
            border: None,
            content: c.on_surface,
        },
        Variant::Primary | Variant::TabActive => Look {
            fill: c.primary,
            border: None,
            content: c.on_primary,
        },
        Variant::Destructive => Look {
            fill: c.error,
            border: Some(c.outline),
            content: c.on_error,
        },
        Variant::Outline => Look {
            fill: c.surface,
            border: Some(c.outline),
            content: c.on_surface,
        },
    }
}

// a button's box; the caller adds on_click, which a disabled button should leave out
fn button_box(ui: &Ui, key: String, width: f32, height: f32, radius: f32, variant: Variant) -> (Rectangle, Color) {
    let look = look(&ui.c, variant, ui.hovered(&key));

    let rectangle = Rectangle::new()
        .width(width)
        .height(height)
        .radius(radius)
        .fill(look.fill)
        .cursor(Pointer)
        .align_child(Center, Center);

    let rectangle = match look.border {
        Some(border) => rectangle.border(1.0, border),
        None => rectangle,
    };

    (hoverable(rectangle, key), look.content)
}

pub fn icon_button(
    ui: &Ui,
    key: impl Into<String>,
    codepoint: &str,
    (size, glyph_size, radius): (f32, f32, f32),
    variant: Variant,
) -> Rectangle {
    let (rectangle, content) = button_box(ui, key.into(), size, size, radius, variant);

    rectangle.child(glyph(codepoint, glyph_size, content))
}

pub fn text_button(ui: &Ui, key: impl Into<String>, text: &str, variant: Variant) -> Rectangle {
    let width = width_of(&label(text, FONT_BODY, ui.c.on_surface)) + SPACE_MD * 2.0;
    let (rectangle, content) = button_box(ui, key.into(), width, CONTROL, RADIUS_MD, variant);

    rectangle.child(label(text, FONT_BODY, content))
}

pub fn disabled(button: Rectangle) -> Rectangle {
    button.opacity(DISABLED_OPACITY)
}

// a card whose height follows its content, which must have a fixed height
pub fn card(ui: &Ui, width: f32, content: impl Widget + 'static) -> Rectangle {
    let height = height_of(&content) + SPACE_MD * 2.0;

    sized_card(ui, width, height).child(content)
}

pub fn sized_card(ui: &Ui, width: impl Into<Size>, height: impl Into<Size>) -> Rectangle {
    Rectangle::new()
        .width(width)
        .height(height)
        .radius(RADIUS_XL)
        .fill(ui.c.container)
        .border(1.0, ui.c.outline)
        .padding(SPACE_MD)
}

pub fn toggle(ui: &Ui, key: impl Into<String>, on: bool, small: bool) -> Rectangle {
    let key = key.into();
    let (thumb, inset, travel) = if small { (14.0, 2.0, 12.0) } else { (18.0, 3.0, 16.0) };
    let height = thumb + inset * 2.0;
    let border = if ui.hovered(&key) { ui.c.primary } else { ui.c.outline };

    let track = Rectangle::new()
        .width(height + travel)
        .height(height)
        .radius(height / 2.0)
        .fill(if on { ui.c.primary } else { ui.c.outline })
        .border(1.0, border)
        .cursor(Pointer)
        .align_child(Start, Center)
        .child(
            Rectangle::new()
                .width(thumb)
                .height(thumb)
                .radius(thumb / 2.0)
                .fill(ui.c.on_primary)
                .translate(inset + if on { travel } else { 0.0 }, 0.0),
        );

    hoverable(track, key)
}

const SLIDER_TRACK: f32 = 8.0;
const SLIDER_THUMB: f32 = 18.0;
const SLIDER_PADDING: f32 = 2.0;

pub fn slider(
    ui: &Ui,
    key: impl Into<String>,
    (width, control): (f32, f32),
    value: f32,
    on_change: impl Fn(f32) + 'static,
) -> Rectangle {
    let key = key.into();
    let track_width = width - SLIDER_PADDING * 2.0;
    let thumb_center = SLIDER_PADDING + value.clamp(0.0, 1.0) * track_width;
    let thumb_x = (thumb_center - SLIDER_THUMB / 2.0).clamp(SLIDER_PADDING, SLIDER_PADDING + track_width - SLIDER_THUMB);
    let border = if ui.hovered(&key) { ui.c.primary } else { ui.c.outline };

    let bar = |bar_width: f32, color: Color| {
        Rectangle::new()
            .width(bar_width)
            .height(SLIDER_TRACK)
            .radius(SLIDER_TRACK / 2.0)
            .fill(color)
            .translate(SLIDER_PADDING, (control - SLIDER_TRACK) / 2.0)
    };

    hoverable(
        Rectangle::new()
            .width(width)
            .height(control)
            .cursor(Pointer)
            .on_drag(move |point| on_change(((point.x - SLIDER_PADDING) / track_width).clamp(0.0, 1.0)))
            .child(
                Stack::new(children![
                    bar(track_width, ui.c.outline),
                    bar(thumb_center - SLIDER_PADDING, ui.c.primary),
                    Rectangle::new()
                        .width(SLIDER_THUMB)
                        .height(SLIDER_THUMB)
                        .radius(SLIDER_THUMB / 2.0)
                        .fill(ui.c.on_primary)
                        .border(1.0, border)
                        .translate(thumb_x, (control - SLIDER_THUMB) / 2.0),
                ])
                .width(width)
                .height(control),
            ),
        key,
    )
}

// the view keeps drawing while one is on screen
pub fn spinner(size: f32, color: Color) -> Canvas {
    request_frame();

    let millis = SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or_default().as_millis();
    let turned = (millis % SPINNER_MS) as f32 / SPINNER_MS as f32 * 360.0;

    Canvas::new().width(size).height(size).shapes(vec![Box::new(
        Arc::new()
            .start(turned)
            .sweep(SPINNER_TRAIL)
            .stroke(2.0, color)
            .cap(Cap::Round),
    )])
}

/*
 * Noctalia's scroll view: a wheel moves it 56 px, the content narrows by the scrollbar's
 * gutter only when it overflows. ScrollArea keeps its offset private, so it can't draw this bar
 */
pub fn scroll_view(ui: &Ui, id: &'static str, (width, height): (f32, f32), content: impl Fn(f32) -> Column) -> Rectangle {
    let view = Rectangle::new().width(width).height(height);
    let whole = content(width);
    let whole_height = height_of(&whole);

    if whole_height <= height {
        return view.child(whole);
    }

    let inner = width - SCROLLBAR - SCROLLBAR_GAP;
    let list = content(inner);
    let full = height_of(&list);
    let max = (full - height).max(0.0);
    let offset = ui.scroll_offset(id).clamp(0.0, max);

    let key = format!("scroll:{id}");
    let thickness = if ui.hovered(&key) { SCROLLBAR_HOVER } else { SCROLLBAR };
    let thumb = (height * height / full).max(SCROLLBAR_MIN_THUMB.max(thickness)).min(height);
    let travel = height - thumb;
    let thumb_y = if max > 0.0 { offset / max * travel } else { 0.0 };

    let viewport = Rectangle::new().width(inner).height(height).clip().child(
        Rectangle::new().width(inner).height(full).translate(0.0, -offset).child(list),
    );

    let track = Rectangle::new()
        .width(thickness)
        .height(height)
        .radius(thickness / 2.0)
        .fill(with_alpha(ui.c.outline, 0.55))
        .translate(SCROLLBAR - thickness, 0.0);

    let thumb_bar = Rectangle::new()
        .width(thickness)
        .height(thumb)
        .radius(thickness / 2.0)
        .fill(with_alpha(ui.c.variant, 0.5))
        .translate(SCROLLBAR - thickness, thumb_y);

    let bar = hoverable(
        Rectangle::new()
            .width(SCROLLBAR)
            .height(height)
            .cursor(Pointer)
            .on_drag(move |point| {
                let at = if travel > 0.0 { (point.y - thumb / 2.0) / travel * max } else { 0.0 };
                Interaction::scroll_to(id, at, max);
            })
            .child(Stack::new(children![track, thumb_bar]).width(SCROLLBAR).height(height)),
        key,
    );

    view.on_scroll(move |scroll| Interaction::scroll_to(id, offset + scroll.y * WHEEL_STEP, max))
        .child(Row::new(children![viewport, bar]).width(width).height(height).gap(SCROLLBAR_GAP).justify(End))
}

pub fn with_alpha(color: Color, alpha: f32) -> Color {
    Color::rgba(color.red(), color.green(), color.blue(), (alpha * 255.0) as u8)
}

// drops whole characters until `...` and what's left fit, as Noctalia does for device names
pub fn elide_middle(text: &str, size: f32, width: f32) -> String {
    let fits = |candidate: &str| width_of(&crate::ui::text(candidate, size, TEXT_FONT)) <= width;

    if fits(text) {
        return text.to_string();
    }

    let chars: Vec<char> = text.chars().collect();

    for kept in (0..chars.len()).rev() {
        let tail = kept / 2;
        let head = kept - tail;
        let candidate = format!(
            "{}...{}",
            chars[..head].iter().collect::<String>(),
            chars[chars.len() - tail..].iter().collect::<String>()
        );

        if fits(&candidate) {
            return candidate;
        }
    }

    String::from("...")
}

// Noctalia's input frame around Amane's text field
pub fn input_box(ui: &Ui, input: TextInput) -> Rectangle {
    Rectangle::new()
        .width(Parent)
        .height(CONTROL)
        .radius(RADIUS_MD)
        .fill(ui.c.surface)
        .border(1.0, ui.c.outline)
        .padding(Padding {
            left: SPACE_MD,
            right: SPACE_MD,
            ..Padding::default()
        })
        .align_child(Start, Center)
        .child(input.width(Parent).size(FONT_BODY).color(ui.c.on_surface))
}
