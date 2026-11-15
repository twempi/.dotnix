use std::collections::HashMap;
use std::path::Path;
use std::time::{Duration, Instant};
use std::{env, fs, thread};

use amane::{Apps, Button, Service};
use chrono::{Datelike, Days, Local, Months, NaiveDate};

use crate::logic::notifications;

pub struct Slide {
    pub from: NaiveDate,
    pub direction: f32,
    pub started: Instant,
}

pub struct CalendarState {
    pub month: NaiveDate,
    pub selected: NaiveDate,
    pub events: bool,
    pub slide: Option<Slide>,
    pub agenda: Agenda,
}

// the grid's six weeks of events, from amane-calendar
pub enum Agenda {
    Unconnected,
    Loading,
    Ready(Vec<Event>),
}

#[derive(Debug, PartialEq)]
pub struct Event {
    pub date: NaiveDate,
    // the calendar's place in Google's list, which picks its color
    pub feed: usize,
    pub time: String,
    pub title: String,
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
pub fn cells(month: NaiveDate) -> Vec<NaiveDate> {
    let start = month - Days::new(u64::from(month.weekday().num_days_from_sunday()));

    (0..42).map(|day| start + Days::new(day)).collect()
}

pub fn change_month(by: i32) {
    let mut state = CalendarState::write();
    let from = state.month;

    state.month = shifted(from, by);
    state.slide = Some(Slide {
        from,
        direction: by as f32,
        started: Instant::now(),
    });

    let month = state.month;
    drop(state);

    load_agenda(month);
}

pub fn reset() {
    let today = Local::now().date_naive();
    let mut state = CalendarState::write();

    state.month = first_of(today);
    state.selected = today;
    state.slide = None;
    drop(state);

    load_agenda(first_of(today));
}

// amane-calendar's Google sign-in, from sops
pub fn connected() -> bool {
    Path::new("/run/secrets/google_calendar_account").is_file()
}

fn load_agenda(month: NaiveDate) {
    if !connected() {
        CalendarState::write().agenda = Agenda::Unconnected;
        return;
    }

    // the last month's events stay up until these arrive, so paging doesn't flash a spinner
    {
        let mut state = CalendarState::write();

        if matches!(state.agenda, Agenda::Unconnected) {
            state.agenda = Agenda::Loading;
        }
    }

    // the helper may download from Google, so it runs off the drawing thread
    thread::spawn(move || {
        let days = cells(month);
        let events = parse_agenda(&amane::output(&format!("amane-calendar {} {}", days[0], days[41])));
        let mut state = CalendarState::write();

        // paging on since then: that month's own load owns the grid
        if state.month == month {
            state.agenda = Agenda::Ready(events);
        }
    });
}

// "<date>\t<feed>\t<time>\t<title>" lines; anything else is skipped
fn parse_agenda(output: &str) -> Vec<Event> {
    output
        .lines()
        .filter_map(|line| {
            let mut fields = line.splitn(4, '\t');

            Some(Event {
                date: NaiveDate::parse_from_str(fields.next()?, "%Y-%m-%d").ok()?,
                feed: fields.next()?.parse().ok()?,
                time: fields.next()?.to_string(),
                title: fields.next()?.to_string(),
            })
        })
        .collect()
}

// each day's calendars, once each, in the order their events come
pub fn day_feeds(agenda: &Agenda) -> HashMap<NaiveDate, Vec<usize>> {
    let mut days: HashMap<NaiveDate, Vec<usize>> = HashMap::new();

    if let Agenda::Ready(events) = agenda {
        for event in events {
            let feeds = days.entry(event.date).or_default();

            if !feeds.contains(&event.feed) {
                feeds.push(event.feed);
            }
        }
    }

    days
}

pub fn toggle_events() {
    let mut state = CalendarState::write();
    state.events = !state.events;
}

pub fn select(date: NaiveDate, month_shift: i32) {
    CalendarState::write().selected = date;

    if month_shift != 0 {
        change_month(month_shift);
    }
}

pub fn clicked(date: NaiveDate, month_shift: i32, button: Button) {
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
        let events = parse_agenda("2026-11-09\t0\tAll day\tHoliday\n2026-11-12\t2\t09:00 - 10:30\tEE\t101\nstray\nbad\tx\ty\tz");

        assert_eq!(
            events,
            vec![
                Event { date: date(2026, 11, 9), feed: 0, time: String::from("All day"), title: String::from("Holiday") },
                Event { date: date(2026, 11, 12), feed: 2, time: String::from("09:00 - 10:30"), title: String::from("EE\t101") },
            ]
        );
        assert!(parse_agenda("").is_empty());

        // one dot per calendar, however many events it has that day
        let feeds = day_feeds(&Agenda::Ready(vec![
            Event { date: date(2026, 11, 9), feed: 1, time: String::new(), title: String::new() },
            Event { date: date(2026, 11, 9), feed: 0, time: String::new(), title: String::new() },
            Event { date: date(2026, 11, 9), feed: 1, time: String::new(), title: String::new() },
        ]));
        assert_eq!(feeds[&date(2026, 11, 9)], vec![1, 0]);
    }

    #[test]
    fn months_shift_across_years() {
        assert_eq!(shifted(date(2026, 12, 1), 1), date(2027, 1, 1));
        assert_eq!(shifted(date(2026, 1, 1), -1), date(2025, 12, 1));
    }
}
