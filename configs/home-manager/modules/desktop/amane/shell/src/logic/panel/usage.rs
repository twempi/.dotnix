use std::thread;
use std::time::Duration;

use amane::Service;
use serde_json::Value;

// the Claude and Codex subscriptions' limits, from amane-usage
pub struct UsageState {
    pub loading: bool,
    pub providers: Vec<Provider>,
}

#[derive(Debug, PartialEq)]
pub struct Provider {
    pub name: String,
    pub plan: String,
    // why the numbers may be old: signed out, expired, offline
    pub note: String,
    pub fetched: i64,
    pub windows: Vec<Window>,
}

#[derive(Debug, PartialEq)]
pub struct Window {
    pub label: String,
    pub used: f32,
    // 0 when the limit has no reset, like Claude's extra usage
    pub resets: i64,
}

impl Service for UsageState {
    fn new() -> Self {
        Self {
            loading: false,
            providers: Vec::new(),
        }
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

pub fn refresh() {
    {
        let mut state = UsageState::write();

        if state.loading {
            return;
        }

        state.loading = true;
    }

    // the helper downloads, so it runs off the drawing thread
    thread::spawn(|| {
        let providers = parse(&amane::output("amane-usage"));
        let mut state = UsageState::write();

        state.loading = false;

        // a helper that failed outright leaves the last numbers up
        if !providers.is_empty() {
            state.providers = providers;
        }
    });
}

fn parse(output: &str) -> Vec<Provider> {
    let Ok(Value::Array(entries)) = serde_json::from_str(output) else {
        return Vec::new();
    };

    entries
        .iter()
        .filter_map(|entry| {
            Some(Provider {
                name: entry["name"].as_str()?.to_string(),
                plan: entry["plan"].as_str().unwrap_or_default().to_string(),
                note: entry["note"].as_str().unwrap_or_default().to_string(),
                fetched: entry["fetched"].as_i64().unwrap_or(0),
                windows: entry["windows"]
                    .as_array()
                    .map(|windows| {
                        windows
                            .iter()
                            .filter_map(|window| {
                                Some(Window {
                                    label: window["label"].as_str()?.to_string(),
                                    used: window["used"].as_f64()? as f32,
                                    resets: window["resets"].as_i64().unwrap_or(0),
                                })
                            })
                            .collect()
                    })
                    .unwrap_or_default(),
            })
        })
        .collect()
}

// what is left of the window; one whose reset has passed since the last answer is whole again
pub fn left(window: &Window, now: i64) -> f32 {
    if window.resets > 0 && window.resets <= now {
        100.0
    } else {
        100.0 - window.used.clamp(0.0, 100.0)
    }
}

pub fn until_reset(resets: i64, now: i64) -> String {
    if resets <= 0 {
        return String::new();
    }

    if resets <= now {
        return String::from("now");
    }

    let minutes = (resets - now + 59) / 60;
    let (days, hours, minutes) = (minutes / 1440, minutes / 60 % 24, minutes % 60);

    if days > 0 {
        format!("{days}d {hours}h")
    } else if hours > 0 {
        format!("{hours}h {minutes}m")
    } else {
        format!("{minutes}m")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_the_helpers_json() {
        let providers = parse(
            r#"[{"name": "Claude", "plan": "", "note": "Offline", "fetched": 100,
                 "windows": [{"label": "5-hour", "used": 12.5, "resets": 200}, {"label": "bad"}]},
                {"plan": "Plus"}]"#,
        );

        assert_eq!(
            providers,
            vec![Provider {
                name: String::from("Claude"),
                plan: String::new(),
                note: String::from("Offline"),
                fetched: 100,
                windows: vec![Window { label: String::from("5-hour"), used: 12.5, resets: 200 }],
            }]
        );
        assert!(parse("").is_empty());
        assert!(parse("{}").is_empty());
    }

    #[test]
    fn counts_down_to_the_reset() {
        assert_eq!(until_reset(0, 100), "");
        assert_eq!(until_reset(100, 100), "now");
        assert_eq!(until_reset(100 + 59, 100), "1m");
        assert_eq!(until_reset(100 + 3 * 3600 + 120, 100), "3h 2m");
        assert_eq!(until_reset(100 + 2 * 86400 + 5 * 3600, 100), "2d 5h");

        let window = Window { label: String::new(), used: 140.0, resets: 200 };
        assert_eq!(left(&window, 100), 0.0);
        assert_eq!(left(&window, 200), 100.0);
        assert_eq!(left(&Window { label: String::new(), used: 19.0, resets: 0 }, 100), 81.0);
    }
}
