use std::collections::HashMap;

use amane::{
    Center, Color, Column, Parent, Pointer, Rectangle, Row, Weight, Widget, children,
    request_frame,
};
use chrono::{Datelike, Local, NaiveDate};

use crate::logic::panel::calendar::{
    Agenda, CalendarState, Event, cells, change_month, clicked, day_feeds, reset,
};
use super::controls::{
    CONTROL, FONT_BODY, FONT_CAPTION, FONT_TITLE, GLYPH, RADIUS_MD, SPACE_MD, SPACE_SM, SPACE_XS, Ui, Variant,
    hoverable, icon_button, label, look, scroll_view, sized_card, spinner, with_alpha,
};

const CHEVRON_LEFT: &str = "\u{EA60}";

const CHEVRON_RIGHT: &str = "\u{EA61}";

pub const EVENTS_ON: &str = "\u{EA52}";

pub const EVENTS_OFF: &str = "\u{EE1F}";

const CALENDAR_WIDTH: f32 = 291.0;

const EVENTS_WIDTH: f32 = 194.0;

const CELL: f32 = 48.0;

const WEEKDAY: f32 = 17.0;

const DOTS: f32 = 5.0;

const DOT_GAP: f32 = 2.0;

const SIDE_GAP: f32 = 48.0;

const SLIDE_MS: f32 = 100.0;

const EVENT_ROW: f32 = 38.0;

const MAX_DOTS: usize = 3;

const WEEKDAYS: [&str; 7] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

fn feed_color(ui: &Ui, feed: usize) -> Color {
    ui.c.calendars[feed % ui.c.calendars.len()]
}

// the old month leaves for 100 ms, then the new one arrives; (month, x, opacity)
fn slide_frame(state: &CalendarState, travel: f32) -> (NaiveDate, f32, f32) {
    let Some(slide) = &state.slide else {
        return (state.month, 0.0, 1.0);
    };

    let elapsed = slide.started.elapsed().as_secs_f32() * 1000.0;

    if elapsed >= SLIDE_MS * 2.0 {
        return (state.month, 0.0, 1.0);
    }

    request_frame();

    if elapsed < SLIDE_MS {
        let moved = elapsed / SLIDE_MS;

        return (slide.from, -slide.direction * travel * moved, 1.0 - 0.3 * moved);
    }

    let moved = (elapsed - SLIDE_MS) / SLIDE_MS;

    (state.month, slide.direction * travel * (1.0 - moved), 0.7 + 0.3 * moved)
}

fn dots(ui: &Ui, feeds: &[usize], size: f32, in_month: bool) -> Rectangle {
    let dots: Vec<Box<dyn Widget>> = feeds
        .iter()
        .take(MAX_DOTS)
        .map(|&feed| {
            let color = feed_color(ui, feed);
            let color = if in_month { color } else { with_alpha(color, 0.5) };

            Box::new(Rectangle::new().width(DOTS).height(DOTS).radius(ui.round(DOTS / 2.0)).fill(color)) as Box<dyn Widget>
        })
        .collect();

    Rectangle::new()
        .width(size)
        .height(DOTS)
        .align_child(Center, Center)
        .child(Row::new(dots).gap(DOT_GAP))
}

fn day_button(ui: &Ui, date: NaiveDate, month: NaiveDate, selected: NaiveDate, size: f32, feeds: &[usize]) -> Rectangle {
    let c = &ui.c;
    let today = Local::now().date_naive();
    let in_month = date.month() == month.month();
    let is_selected = in_month && date == selected;
    let key = format!("day:{date}");
    let hovered = ui.hovered(&key);
    let variant = if is_selected { Variant::Primary } else { Variant::Ghost };
    let look = look(c, variant, hovered);

    let color = if hovered || is_selected {
        look.content
    } else if !in_month {
        with_alpha(c.variant, 0.75)
    } else if date == today {
        c.primary
    } else {
        look.content
    };

    let text = label(date.day().to_string(), FONT_BODY, color);
    let text = if in_month && !is_selected { text.weight(Weight::Bold) } else { text };
    let month_shift = (date.year() - month.year()) * 12 + date.month() as i32 - month.month() as i32;

    Rectangle::new()
        .width(size)
        .height(size + DOT_GAP + DOTS)
        .cursor(Pointer)
        .on_click(move |button| clicked(date, month_shift, button))
        .child(
            Column::new(children![
                hoverable(
                    Rectangle::new()
                        .width(size)
                        .height(size)
                        .radius(RADIUS_MD)
                        .fill(look.fill)
                        .align_child(Center, Center)
                        .child(text),
                    key,
                ),
                dots(ui, feeds, size, in_month),
            ])
            .gap(DOT_GAP),
        )
}

fn month_grid(ui: &Ui, month: NaiveDate, selected: NaiveDate, column: f32, feeds: &HashMap<NaiveDate, Vec<usize>>) -> Column {
    let size = (CELL - 7.0).min(column).min(44.0).floor();

    let weekdays: Vec<Box<dyn Widget>> = WEEKDAYS
        .iter()
        .map(|&day| {
            let color = if day == "Sun" || day == "Sat" { ui.c.secondary } else { ui.c.variant };

            Box::new(
                Rectangle::new()
                    .width(Parent)
                    .height(WEEKDAY)
                    .align_child(Center, Center)
                    .child(label(day, FONT_CAPTION, color).weight(Weight::Medium)),
            ) as Box<dyn Widget>
        })
        .collect();

    let mut rows: Vec<Box<dyn Widget>> = vec![Box::new(Row::new(weekdays).width(Parent).height(WEEKDAY).gap(SPACE_SM))];

    for week in cells(month).chunks(7) {
        let days: Vec<Box<dyn Widget>> = week
            .iter()
            .map(|&date| {
                Box::new(
                    Rectangle::new()
                        .width(Parent)
                        .height(CELL)
                        .align_child(Center, Center)
                        .child(day_button(ui, date, month, selected, size, feeds.get(&date).map_or(&[], Vec::as_slice))),
                ) as Box<dyn Widget>
            })
            .collect();

        rows.push(Box::new(Row::new(days).width(Parent).height(CELL).gap(SPACE_SM)));
    }

    Column::new(rows).width(Parent).gap(SPACE_SM)
}

fn calendar_card(ui: &Ui, state: &CalendarState, width: f32, height: f32) -> Rectangle {
    let inner = width - SPACE_MD * 2.0;
    let column = (inner - SIDE_GAP) / 7.0;
    let (month, x, opacity) = slide_frame(state, inner);
    let grid_height = WEEKDAY + SPACE_SM + 6.0 * CELL + 5.0 * SPACE_SM;
    let chevron = (CONTROL, GLYPH, RADIUS_MD);

    let today_label = Rectangle::new()
        .width(Parent)
        .height(17.0)
        .cursor(Pointer)
        .on_click(|_| reset())
        .align_child(amane::Start, Center)
        .child(
            label(
                Local::now().format("%A, %m/%d/%Y").to_string(),
                FONT_TITLE,
                ui.c.secondary,
            )
            .weight(Weight::Medium),
        )
        .translate(0.0, 2.0);

    let header = Row::new(children![
        icon_button(ui, "cal:prev", CHEVRON_LEFT, chevron, Variant::Ghost).on_click(|_| change_month(-1)),
        Rectangle::new().width(Parent).height(CONTROL).align_child(Center, Center).child(
            label(state.month.format("%B %Y").to_string(), FONT_TITLE + 4.0, ui.c.on_surface).weight(Weight::Bold),
        ),
        icon_button(ui, "cal:next", CHEVRON_RIGHT, chevron, Variant::Ghost).on_click(|_| change_month(1)),
    ])
    .width(Parent)
    .height(CONTROL);

    let viewport_height = height - SPACE_MD * 2.0 - 17.0 - CONTROL - SPACE_MD * 2.0;

    // a bit taller than the room left, and centered there, as Noctalia's grid is
    let viewport = Rectangle::new()
        .width(inner)
        .height(grid_height)
        .translate(0.0, (viewport_height - grid_height) / 2.0)
        .clip()
        .on_scroll(|scroll| change_month(if scroll.y > 0.0 { 1 } else { -1 }))
        .child(
            Rectangle::new()
                .width(inner)
                .height(grid_height)
                .translate(x, 0.0)
                .opacity(opacity)
                .child(month_grid(ui, month, state.selected, column, &day_feeds(&state.agenda))),
        );

    sized_card(ui, width, height).child(
        Column::new(children![today_label, header, viewport])
            .width(Parent)
            .height(Parent)
            .gap(SPACE_MD),
    )
}

// the bar's look: a line in the calendar's color beside the text
fn event_row(ui: &Ui, event: &Event, width: f32) -> Row {
    let color = feed_color(ui, event.feed);

    Row::new(children![
        Rectangle::new().width(2.0).height(EVENT_ROW).fill(color),
        Column::new(children![
            label(event.time.clone(), FONT_CAPTION, color).elide(),
            label(event.title.clone(), FONT_BODY, ui.c.on_surface).weight(Weight::Bold).elide(),
        ])
        .width(Parent)
        .gap(SPACE_XS),
    ])
    .width(width)
    .height(EVENT_ROW)
    .gap(SPACE_SM)
    .align(Center)
}

fn events_card(ui: &Ui, state: &CalendarState, width: f32, height: f32) -> Rectangle {
    let c = &ui.c;
    let inner = width - SPACE_MD * 2.0;
    let title = label(state.selected.format("%A %e %B").to_string(), FONT_TITLE, c.on_surface)
        .weight(Weight::Bold)
        .elide();
    let list_height = height - SPACE_MD * 3.0 - crate::looks::ui::height_of(&title);

    let body: Box<dyn Widget> = match &state.agenda {
        Agenda::Unconnected => Box::new(
            Column::new(children![
                label("No calendar connected.", FONT_CAPTION, c.variant),
                label("Sign in to Google with", FONT_CAPTION, c.variant),
                label("amane-calendar --login", FONT_CAPTION, c.secondary).elide(),
            ])
            .width(Parent)
            .gap(SPACE_XS),
        ),
        Agenda::Loading => Box::new(spinner(GLYPH, c.primary)),
        Agenda::Ready(events) => {
            let day: Vec<&Event> = events.iter().filter(|event| event.date == state.selected).collect();

            if day.is_empty() {
                Box::new(label("No events.", FONT_CAPTION, c.variant))
            } else {
                Box::new(scroll_view(ui, "calendar-events", (inner, list_height), |list_width| {
                    let rows: Vec<Box<dyn Widget>> = day
                        .iter()
                        .map(|event| Box::new(event_row(ui, event, list_width)) as Box<dyn Widget>)
                        .collect();

                    Column::new(rows).width(list_width).gap(SPACE_SM)
                }))
            }
        }
    };

    sized_card(ui, width, height).child(
        Column::new(vec![Box::new(title) as Box<dyn Widget>, body])
            .width(Parent)
            .height(Parent)
            .gap(SPACE_MD),
    )
}

pub fn view(ui: &Ui, state: &CalendarState, width: f32, height: f32) -> Row {
    if !state.events {
        return Row::new(children![calendar_card(ui, state, width, height)]);
    }

    Row::new(children![
        calendar_card(ui, state, CALENDAR_WIDTH, height),
        events_card(ui, state, EVENTS_WIDTH, height),
    ])
    .gap(SPACE_MD)
}
