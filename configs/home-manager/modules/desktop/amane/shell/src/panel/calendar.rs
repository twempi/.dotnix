use std::path::Path;
use std::time::{Duration, Instant};
use std::{env, fs, thread};

use amane::{
    Apps, Button, Center, Column, Parent, Pointer, Rectangle, Row, Service, Weight, Widget, children,
    request_frame,
};
use chrono::{Datelike, Days, Local, Months, NaiveDate};

use super::controls::{
    CONTROL, FONT_BODY, FONT_CAPTION, FONT_TITLE, GLYPH, RADIUS_MD, SPACE_MD, SPACE_SM, SPACE_XS, Ui, Variant,
    hoverable, icon_button, label, look, scroll_view, sized_card, spinner, with_alpha,
};
use crate::notifications;
use crate::theme::config_home;

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
const WEEKDAYS: [&str; 7] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

struct Slide {
    from: NaiveDate,
    direction: f32,
    started: Instant,
}

pub struct CalendarState {
    month: NaiveDate,
    selected: NaiveDate,
    pub events: bool,
    slide: Option<Slide>,
    agenda: Agenda,
}

// the selected day's events, from amane-calendar and the feeds in ~/.config/amane-shell/calendars
enum Agenda {
    Unconnected,
    Loading,
    Ready(Vec<(String, String)>),
}

impl Service for CalendarState {
    fn new() -> Self {
        let today = Local::now().date_naive();

        Self {
            month: first_of(today),
            selected: today,
            events: true,
            slide: None,
            agenda: Agenda::Unconnected,
        }
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

fn first_of(date: NaiveDate) -> NaiveDate {
    date.with_day(1).unwrap_or(date)
}

fn shifted(month: NaiveDate, by: i32) -> NaiveDate {
    let months = Months::new(by.unsigned_abs());

    if by >= 0 { month + months } else { month - months }
}

// six Sunday-first weeks, Noctalia's fixed 42 cells
fn cells(month: NaiveDate) -> Vec<NaiveDate> {
    let start = month - Days::new(u64::from(month.weekday().num_days_from_sunday()));

    (0..42).map(|day| start + Days::new(day)).collect()
}

fn change_month(by: i32) {
    let mut state = CalendarState::write();
    let from = state.month;

    state.month = shifted(from, by);
    state.slide = Some(Slide {
        from,
        direction: by as f32,
        started: Instant::now(),
    });
}

pub fn reset() {
    let today = Local::now().date_naive();
    let mut state = CalendarState::write();

    state.month = first_of(today);
    state.selected = today;
    state.slide = None;
    drop(state);

    load_agenda(today);
}

fn feeds_file() -> std::path::PathBuf {
    config_home().join("amane-shell/calendars")
}

fn load_agenda(date: NaiveDate) {
    if !feeds_file().is_file() {
        CalendarState::write().agenda = Agenda::Unconnected;
        return;
    }

    CalendarState::write().agenda = Agenda::Loading;

    // the helper may download the feeds, so it runs off the drawing thread
    thread::spawn(move || {
        let events = parse_agenda(&amane::output(&format!("amane-calendar {date}")));
        let mut state = CalendarState::write();

        // a quicker click on another day already owns the card
        if state.selected == date {
            state.agenda = Agenda::Ready(events);
        }
    });
}

fn parse_agenda(output: &str) -> Vec<(String, String)> {
    output
        .lines()
        .filter_map(|line| line.split_once('\t'))
        .map(|(time, title)| (time.to_string(), title.to_string()))
        .collect()
}

pub fn toggle_events() {
    let mut state = CalendarState::write();
    state.events = !state.events;
}

fn select(date: NaiveDate, month_shift: i32) {
    CalendarState::write().selected = date;
    load_agenda(date);

    if month_shift != 0 {
        change_month(month_shift);
    }
}

fn clicked(date: NaiveDate, month_shift: i32, button: Button) {
    match button {
        Button::Right => {
            thread::spawn(open_calendar_app);
        }
        _ => select(date, month_shift),
    }
}

// Noctalia launches the default handler for text/calendar and closes the panel if there is one
fn open_calendar_app() {
    let id = amane::output("xdg-mime query default text/calendar");
    let Some(name) = desktop_entry_name(id.trim()) else {
        return;
    };

    if let Some(app) = Apps::read().list().iter().find(|app| app.name() == name) {
        app.launch();
        notifications::close();
    }
}

fn desktop_entry_name(id: &str) -> Option<String> {
    if id.is_empty() {
        return None;
    }

    let dirs = env::var("XDG_DATA_DIRS").unwrap_or_default();

    dirs.split(':')
        .find_map(|dir| fs::read_to_string(Path::new(dir).join("applications").join(id)).ok())
        .and_then(|entry| {
            entry
                .lines()
                .find_map(|line| line.strip_prefix("Name=").map(str::to_string))
        })
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

fn day_button(ui: &Ui, date: NaiveDate, month: NaiveDate, selected: NaiveDate, size: f32) -> Rectangle {
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
        )
}

fn month_grid(ui: &Ui, month: NaiveDate, selected: NaiveDate, column: f32) -> Column {
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
                        .child(day_button(ui, date, month, selected, size)),
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
                .child(month_grid(ui, month, state.selected, column)),
        );

    sized_card(ui, width, height).child(
        Column::new(children![today_label, header, viewport])
            .width(Parent)
            .height(Parent)
            .gap(SPACE_MD),
    )
}

// the bar's look: a line in the accent beside the text
fn event_row(ui: &Ui, (time, title): &(String, String), width: f32) -> Row {
    Row::new(children![
        Rectangle::new().width(2.0).height(EVENT_ROW).fill(ui.c.primary),
        Column::new(children![
            label(time.clone(), FONT_CAPTION, ui.c.secondary).elide(),
            label(title.clone(), FONT_BODY, ui.c.on_surface).weight(Weight::Bold).elide(),
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
    let list_height = height - SPACE_MD * 3.0 - crate::ui::height_of(&title);

    let body: Box<dyn Widget> = match &state.agenda {
        Agenda::Unconnected => Box::new(
            Column::new(children![
                label("No calendar connected.", FONT_CAPTION, c.variant),
                label("Add an iCal address to", FONT_CAPTION, c.variant),
                label("~/.config/amane-shell/calendars", FONT_CAPTION, c.secondary).elide(),
            ])
            .width(Parent)
            .gap(SPACE_XS),
        ),
        Agenda::Loading => Box::new(spinner(GLYPH, c.primary)),
        Agenda::Ready(events) if events.is_empty() => Box::new(label("No events.", FONT_CAPTION, c.variant)),
        Agenda::Ready(events) => Box::new(scroll_view(ui, "calendar-events", (inner, list_height), |list_width| {
            let rows: Vec<Box<dyn Widget>> = events
                .iter()
                .map(|event| Box::new(event_row(ui, event, list_width)) as Box<dyn Widget>)
                .collect();

            Column::new(rows).width(list_width).gap(SPACE_SM)
        })),
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

#[cfg(test)]
mod tests {
    use super::*;

    fn date(year: i32, month: u32, day: u32) -> NaiveDate {
        NaiveDate::from_ymd_opt(year, month, day).unwrap()
    }

    #[test]
    fn grid_starts_on_sunday_with_six_weeks() {
        let days = cells(date(2026, 11, 1));

        assert_eq!(days.len(), 42);
        assert_eq!(days[0], date(2026, 11, 1));
        assert_eq!(cells(date(2026, 12, 1))[0], date(2026, 11, 29));
        assert_eq!(days[41], date(2026, 12, 12));
    }

    #[test]
    fn reads_the_helpers_lines() {
        assert_eq!(
            parse_agenda("All day\tHoliday\n09:00 - 10:30\tEE 101\nstray"),
            vec![
                (String::from("All day"), String::from("Holiday")),
                (String::from("09:00 - 10:30"), String::from("EE 101")),
            ]
        );
        assert!(parse_agenda("").is_empty());
    }

    #[test]
    fn months_shift_across_years() {
        assert_eq!(shifted(date(2026, 12, 1), 1), date(2027, 1, 1));
        assert_eq!(shifted(date(2026, 1, 1), -1), date(2025, 12, 1));
    }
}
