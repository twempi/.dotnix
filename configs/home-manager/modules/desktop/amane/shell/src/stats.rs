use std::ffi::CString;
use std::fs;
use std::path::Path;
use std::thread;
use std::time::Duration;

use amane::Service;

// everything waybar polled, on waybar's own intervals, in one thread
#[derive(Default)]
pub struct Stats {
    tick: u64,
    cpu_last: (u64, u64),
    rx_last: Option<(String, u64)>,

    pub cpu: u8,
    pub memory: String,
    pub disk_free: String,
    pub down: String,
    pub battery: Option<BatteryState>,
}

#[derive(Clone, PartialEq, Default)]
pub struct BatteryState {
    pub capacity: u8,
    // waybar's status names: charging, discharging, plugged, full
    pub status: &'static str,
    pub time: String,
}

impl Service for Stats {
    fn new() -> Self {
        let mut stats = Self {
            cpu_last: cpu_times(),
            ..Self::default()
        };

        stats.down = pow_format(0.0, "b/s", false);
        stats.update();

        stats
    }

    fn update(&mut self) -> bool {
        let before = (
            self.cpu,
            self.memory.clone(),
            self.disk_free.clone(),
            self.down.clone(),
            self.battery.clone(),
        );

        // cpu: interval 1
        let times = cpu_times();
        let (idle, total) = (times.0 - self.cpu_last.0, times.1 - self.cpu_last.1);
        if let Some(idle_share) = (idle * 100).checked_div(total) {
            self.cpu = (100 - idle_share) as u8;
        }
        self.cpu_last = times;

        // custom/memory and network: interval 2
        if self.tick.is_multiple_of(2) {
            self.memory = memory_used();

            let now = default_interface().and_then(|name| rx_bytes(&name).map(|rx| (name, rx)));

            let rate = match (&self.rx_last, &now) {
                (Some((last, before)), Some((name, rx))) if last == name => {
                    rx.saturating_sub(*before) as f64 * 8.0 / 2.0
                }
                _ => 0.0,
            };

            self.down = pow_format(rate, "b/s", false);
            self.rx_last = now;
        }

        // disk: interval 20
        if self.tick.is_multiple_of(20) {
            self.disk_free = disk_free("/").map_or_else(String::new, |free| {
                pow_format(free as f64, "B", true)
            });
        }

        // battery: interval 1
        self.battery = battery();

        self.tick += 1;

        before
            != (
                self.cpu,
                self.memory.clone(),
                self.disk_free.clone(),
                self.down.clone(),
                self.battery.clone(),
            )
    }
}

// (idle, total) jiffies over all cores
fn cpu_times() -> (u64, u64) {
    let stat = fs::read_to_string("/proc/stat").unwrap_or_default();

    let fields: Vec<u64> = stat
        .lines()
        .next()
        .unwrap_or_default()
        .split_whitespace()
        .skip(1)
        .filter_map(|field| field.parse().ok())
        .collect();

    let idle = fields.get(3).copied().unwrap_or(0) + fields.get(4).copied().unwrap_or(0);

    (idle, fields.iter().sum())
}

// the htop-style figure from waybar/scripts/memory_usage.sh
fn memory_used() -> String {
    let meminfo = fs::read_to_string("/proc/meminfo").unwrap_or_default();

    let field = |key: &str| -> u64 {
        meminfo
            .lines()
            .find_map(|line| line.strip_prefix(key))
            .and_then(|rest| rest.split_whitespace().next())
            .and_then(|value| value.parse().ok())
            .unwrap_or(0)
    };

    let used = field("MemTotal:").saturating_sub(
        field("MemFree:")
            + field("Active(file):")
            + field("Inactive(file):")
            + field("SReclaimable:"),
    );

    format_memory(used)
}

fn format_memory(used_kib: u64) -> String {
    if used_kib < 1_048_576 {
        format!("{}MiB", used_kib / 1024)
    } else {
        format!("{:.1}GiB", used_kib as f64 / 1_048_576.0)
    }
}

// the interface with the default route, which is the one waybar reports
fn default_interface() -> Option<String> {
    let routes = fs::read_to_string("/proc/net/route").ok()?;

    routes
        .lines()
        .skip(1)
        .filter_map(|line| {
            let fields: Vec<&str> = line.split_whitespace().collect();
            let metric: u32 = fields.get(6)?.parse().ok()?;
            (fields.get(1) == Some(&"00000000")).then(|| (metric, fields[0].to_string()))
        })
        .min()
        .map(|(_, name)| name)
}

fn rx_bytes(interface: &str) -> Option<u64> {
    fs::read_to_string(format!("/sys/class/net/{interface}/statistics/rx_bytes"))
        .ok()?
        .trim()
        .parse()
        .ok()
}

fn disk_free(path: &str) -> Option<u64> {
    let path = CString::new(path).ok()?;

    let mut stats: libc::statvfs = unsafe { std::mem::zeroed() };

    // statvfs only writes into the struct it is given
    if unsafe { libc::statvfs(path.as_ptr(), &mut stats) } != 0 {
        return None;
    }

    Some(stats.f_bavail as u64 * stats.f_frsize as u64)
}

// waybar's pow_format: "{:.1f}{prefix}{unit}", 1000 or 1024 based
pub fn pow_format(value: f64, unit: &str, binary: bool) -> String {
    const UNITS: [&str; 6] = ["", "k", "M", "G", "T", "P"];

    let base = if binary { 1024.0 } else { 1000.0 };
    let mut fraction = value;
    let mut power = 0;

    while power + 1 < UNITS.len() && fraction / base >= 1.0 {
        fraction /= base;
        power += 1;
    }

    let binary_marker = if binary && power > 0 { "i" } else { "" };

    format!("{fraction:.1}{}{binary_marker}{unit}", UNITS[power])
}

fn read(path: &Path, name: &str) -> Option<String> {
    fs::read_to_string(path.join(name))
        .ok()
        .map(|value| value.trim().to_string())
}

fn number(path: &Path, name: &str) -> Option<f64> {
    read(path, name)?.parse().ok()
}

fn battery() -> Option<BatteryState> {
    let supplies: Vec<_> = fs::read_dir("/sys/class/power_supply")
        .ok()?
        .flatten()
        .map(|entry| entry.path())
        .collect();

    let batteries: Vec<_> = supplies
        .iter()
        .filter(|path| read(path, "type").as_deref() == Some("Battery"))
        .filter(|path| read(path, "scope").as_deref() != Some("Device"))
        .collect();

    if batteries.is_empty() {
        return None;
    }

    let plugged = supplies.iter().any(|path| {
        read(path, "type").as_deref() == Some("Mains") && read(path, "online").as_deref() == Some("1")
    });

    let capacity = batteries
        .iter()
        .filter_map(|path| number(path, "capacity"))
        .sum::<f64>()
        / batteries.len() as f64;

    let status = read(batteries[0], "status").unwrap_or_default();

    // energy in µWh and power in µW, or charge in µAh and current in µA
    let total = |names: [&str; 2]| -> f64 {
        batteries
            .iter()
            .filter_map(|path| number(path, names[0]).or_else(|| number(path, names[1])))
            .sum()
    };

    let now = total(["energy_now", "charge_now"]);
    let full = total(["energy_full", "charge_full"]);
    let rate = total(["power_now", "current_now"]);

    let status = match status.as_str() {
        "Charging" => "charging",
        "Full" => "full",
        "Discharging" | "Not charging" | "Unknown" if plugged => "plugged",
        _ => "discharging",
    };

    let hours = match status {
        "charging" if rate > 0.0 => (full - now) / rate,
        "discharging" if rate > 0.0 => now / rate,
        _ => 0.0,
    };

    Some(BatteryState {
        capacity: capacity.round().clamp(0.0, 100.0) as u8,
        status,
        time: format_time(hours),
    })
}

// waybar's default format-time, "{H} h {M} min"
pub fn format_time(hours: f64) -> String {
    if hours <= 0.0 {
        return String::new();
    }

    let minutes = (hours * 60.0).round() as u64;

    format!("{} h {} min", minutes / 60, minutes % 60)
}

pub struct Clock {
    pub text: String,
}

impl Service for Clock {
    fn new() -> Self {
        Self { text: now() }
    }

    fn update(&mut self) -> bool {
        let text = now();
        let changed = text != self.text;
        self.text = text;
        changed
    }
}

fn now() -> String {
    chrono::Local::now().format("%Y-%m-%d %H:%M:%S").to_string()
}

// the default sink's volume, read through pactl because it can go past 100%
#[derive(PartialEq, Clone, Default)]
pub struct Volume {
    pub percent: u32,
    pub muted: bool,
    pub bluetooth: bool,
}

impl Service for Volume {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        loop {
            refresh_volume();

            for line in amane::lines("pactl subscribe") {
                if line.contains("sink") || line.contains("server") {
                    refresh_volume();
                }
            }

            // pipewire-pulse restarted or isn't up yet
            thread::sleep(Duration::from_secs(2));
        }
    }
}

fn refresh_volume() {
    let volume = amane::output("pactl get-sink-volume @DEFAULT_SINK@");

    let current = Volume {
        percent: volume
            .split('/')
            .nth(1)
            .and_then(|part| part.trim().trim_end_matches('%').parse().ok())
            .unwrap_or(0),
        muted: amane::output("pactl get-sink-mute @DEFAULT_SINK@").contains("yes"),
        bluetooth: amane::output("pactl get-default-sink").starts_with("bluez"),
    };

    if *Volume::read() != current {
        *Volume::write() = current;
    }
}

// sway's binding mode, hidden while it is "default"
pub struct SwayMode {
    pub name: String,
}

impl Service for SwayMode {
    fn new() -> Self {
        Self {
            name: String::new(),
        }
    }

    fn listen() {
        loop {
            // -r keeps each event on one line
            for line in amane::lines(r#"swaymsg -r -m -t subscribe '["mode"]'"#) {
                let event: serde_json::Value = serde_json::from_str(&line).unwrap_or_default();

                let mode = event["change"].as_str().unwrap_or("default");

                Self::write().name = if mode == "default" {
                    String::new()
                } else {
                    mode.to_string()
                };
            }

            // not running under sway, or sway is going away
            thread::sleep(Duration::from_secs(5));
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn formats_like_waybar() {
        assert_eq!(pow_format(0.0, "b/s", false), "0.0b/s");
        assert_eq!(pow_format(12_345.0, "b/s", false), "12.3kb/s");
        assert_eq!(pow_format(3.0 * 1024.0 * 1024.0 * 1024.0, "B", true), "3.0GiB");
        assert_eq!(pow_format(512.0, "B", true), "512.0B");
    }

    #[test]
    fn formats_memory_like_the_script() {
        assert_eq!(format_memory(524_288), "512MiB");
        assert_eq!(format_memory(3_355_443), "3.2GiB");
    }

    #[test]
    fn formats_time_like_waybar() {
        assert_eq!(format_time(0.0), "");
        assert_eq!(format_time(1.5), "1 h 30 min");
    }
}
