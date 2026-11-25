use amane::{
    Canvas, Cap, Center, Color, Column, End, Line, Padding, Parent, Rectangle, Row, Shape, SpaceBetween, Stack,
    Start, Weight, Widget, children,
};
use chrono::{DateTime, Local, Utc};

use crate::logic::panel::usage::{Provider, UsageState, Window, left, until_reset};
use crate::looks::ui::width_of;
use super::controls::{
    FONT_BODY, FONT_CAPTION, FONT_MINI, FONT_TITLE, GLYPH, RADIUS_MD, RADIUS_SM, SPACE_MD, SPACE_SM, SPACE_XS, Ui,
    card, glyph, label, scroll_view, spinner, with_alpha,
};

pub const GLYPH_USAGE: &str = "\u{EAB1}";

pub const GLYPH_REFRESH: &str = "\u{EB13}";

const GLYPH_OPENAI: &str = "\u{F78E}";

const ICON: f32 = 18.0;

// the big number and its label, beside the bar
const FIGURE: f32 = 112.0;

const FIGURE_SIZE: f32 = 26.0;

const BAR: f32 = 30.0;

const HATCH_STEP: f32 = 6.0;

const PILL_HEIGHT: f32 = 19.0;

// this little left turns the number and the bar the error color
const LOW_PERCENT: f32 = 10.0;

// Claude's mark, a burst of rays; the icon font has none
fn claude_icon(color: Color) -> Canvas {
    let middle = ICON / 2.0;

    let rays: Vec<Box<dyn Shape>> = (0..12)
        .map(|ray| {
            let (sin, cos) = (ray as f32 * 30.0 + 8.0).to_radians().sin_cos();
            let reach = if ray % 2 == 0 { middle - 0.5 } else { middle - 2.5 };

            Box::new(
                Line::new()
                    .from(middle + cos * 1.5, middle + sin * 1.5)
                    .to(middle + cos * reach, middle + sin * reach)
                    .stroke(1.8, color)
                    .cap(Cap::Round),
            ) as Box<dyn Shape>
        })
        .collect();

    Canvas::new().width(ICON).height(ICON).shapes(rays)
}

// each subscription in its own colors: Claude in the scheme's orange, Codex in grey
fn identity(ui: &Ui, provider: &str) -> (Box<dyn Widget>, Color) {
    if provider == "Claude" {
        (Box::new(claude_icon(ui.c.orange)), ui.c.orange)
    } else {
        (Box::new(glyph(GLYPH_OPENAI, ICON, ui.c.on_surface)), ui.c.variant)
    }
}

fn plan_pill(ui: &Ui, plan: &str) -> Rectangle {
    let text = label(plan, FONT_MINI, ui.c.variant).weight(Weight::Bold);

    Rectangle::new()
        .width(width_of(&text) + SPACE_SM * 2.0)
        .height(PILL_HEIGHT)
        .radius(RADIUS_SM)
        .fill(ui.c.surface)
        .border(1.0, ui.c.outline)
        .align_child(Center, Center)
        .child(text)
}

// an opaque tint, so the hatching under the bar only shows past its end
fn blend(base: Color, tint: Color, amount: f32) -> Color {
    let mix = |from: u8, to: u8| (from as f32 + (to as f32 - from as f32) * amount).round() as u8;

    Color::rgba(mix(base.red(), tint.red()), mix(base.green(), tint.green()), mix(base.blue(), tint.blue()), 255)
}

// the used part of the bar is hatched, like an emptied gauge
fn hatching(width: f32, color: Color) -> Canvas {
    let mut lines: Vec<Box<dyn Shape>> = Vec::new();
    let mut x = -BAR;

    while x < width {
        lines.push(Box::new(Line::new().from(x, BAR).to(x + BAR, 0.0).stroke(1.0, color)));
        x += HATCH_STEP;
    }

    Canvas::new().width(width).height(BAR).shapes(lines)
}

fn reset_pill(ui: &Ui, reset: String) -> Rectangle {
    let text = label(reset, FONT_MINI, ui.c.on_surface);
    let width = width_of(&text) + 12.0 + SPACE_XS + SPACE_SM * 2.0;

    Rectangle::new()
        .width(width)
        .height(PILL_HEIGHT + 2.0)
        .radius(RADIUS_SM)
        .fill(ui.c.surface)
        .align_child(Center, Center)
        .child(Row::new(children![glyph(GLYPH_REFRESH, 12.0, ui.c.on_surface), text]).gap(SPACE_XS).align(Center))
}

fn bar(ui: &Ui, width: f32, percent: f32, color: Color, reset: String) -> Stack {
    let inset = Padding {
        left: SPACE_SM,
        right: SPACE_XS,
        ..Padding::default()
    };

    let track = Rectangle::new()
        .width(width)
        .height(BAR)
        .radius(RADIUS_MD)
        .clip()
        .fill(ui.c.surface)
        .child(hatching(width, with_alpha(ui.c.outline, 0.8)));

    let mut layers: Vec<Box<dyn Widget>> = vec![
        Box::new(track),
        Box::new(Rectangle::new().width(width * percent / 100.0).height(BAR).radius(RADIUS_MD).fill(color)),
        Box::new(
            Rectangle::new()
                .width(width)
                .height(BAR)
                .padding(inset)
                .align_child(Start, Center)
                .child(label(format!("{percent:.0}%"), FONT_CAPTION, ui.c.on_surface).weight(Weight::Bold)),
        ),
    ];

    if !reset.is_empty() {
        layers.push(Box::new(
            Rectangle::new()
                .width(width)
                .height(BAR)
                .padding(inset)
                .align_child(End, Center)
                .child(reset_pill(ui, reset)),
        ));
    }

    Stack::new(layers).width(width).height(BAR)
}

fn window_card(ui: &Ui, window: &Window, tint: Color, width: f32, now: i64) -> Rectangle {
    let c = &ui.c;
    let percent = left(window, now);
    let low = percent <= LOW_PERCENT;
    let figure_color = if low { c.error } else { c.on_surface };
    let bar_color = blend(c.surface, if low { c.error } else { tint }, 0.45);
    let bar_width = width - SPACE_MD * 2.0 - FIGURE - SPACE_MD;

    let figure = Column::new(children![
        label(window.label.clone(), FONT_BODY, c.on_surface).elide(),
        Row::new(children![
            label(format!("{percent:.0}%"), FIGURE_SIZE, figure_color).weight(Weight::Bold),
            label("left", FONT_CAPTION, c.variant),
        ])
        .gap(SPACE_XS)
        .align(End),
    ])
    .width(FIGURE)
    .gap(SPACE_XS);

    card(
        ui,
        width,
        Row::new(children![figure, bar(ui, bar_width, percent, bar_color, until_reset(window.resets, now))])
            .width(Parent)
            .gap(SPACE_MD)
            .align(Center),
    )
}

// the subscription's name over a card for each of its limits
fn provider_section(ui: &Ui, provider: &Provider, width: f32, now: i64) -> Column {
    let c = &ui.c;
    let (icon, tint) = identity(ui, &provider.name);

    let mut title: Vec<Box<dyn Widget>> = vec![
        icon,
        Box::new(label(provider.name.clone(), FONT_TITLE, c.on_surface).weight(Weight::Bold)),
    ];

    if !provider.plan.is_empty() {
        title.push(Box::new(plan_pill(ui, &provider.plan)));
    }

    let updated = DateTime::from_timestamp(provider.fetched, 0)
        .filter(|_| provider.fetched > 0)
        .map(|time| time.with_timezone(&Local).format("Updated %H:%M").to_string())
        .unwrap_or_default();

    let mut rows: Vec<Box<dyn Widget>> = vec![Box::new(
        Row::new(children![
            Row::new(title).gap(SPACE_SM).align(Center),
            label(updated, FONT_CAPTION, c.variant),
        ])
        .width(width)
        .justify(SpaceBetween)
        .align(Center),
    )];

    if !provider.note.is_empty() {
        rows.push(Box::new(label(provider.note.clone(), FONT_CAPTION, c.error).elide()));
    }

    if provider.windows.is_empty() && provider.note.is_empty() {
        rows.push(Box::new(label("No limits reported", FONT_CAPTION, c.variant)));
    }

    rows.extend(
        provider
            .windows
            .iter()
            .map(|window| Box::new(window_card(ui, window, tint, width, now)) as Box<dyn Widget>),
    );

    Column::new(rows).width(width).gap(SPACE_SM)
}

pub fn view(ui: &Ui, state: &UsageState, width: f32, height: f32) -> Column {
    if state.providers.is_empty() {
        let body: Box<dyn Widget> = if state.loading {
            Box::new(spinner(GLYPH, ui.c.primary))
        } else {
            Box::new(label("No usage to show", FONT_BODY, ui.c.variant))
        };

        return Column::new(vec![Box::new(
            Rectangle::new().width(width).height(height).align_child(Center, Center).child(Column::new(vec![body])),
        ) as Box<dyn Widget>])
        .width(width)
        .height(height);
    }

    let now = Utc::now().timestamp();

    let list = scroll_view(ui, "usage", (width, height), |list_width| {
        let sections: Vec<Box<dyn Widget>> = state
            .providers
            .iter()
            .map(|provider| Box::new(provider_section(ui, provider, list_width, now)) as Box<dyn Widget>)
            .collect();

        Column::new(sections).width(list_width).gap(SPACE_MD + SPACE_SM)
    });

    Column::new(children![list]).width(width).height(height)
}
