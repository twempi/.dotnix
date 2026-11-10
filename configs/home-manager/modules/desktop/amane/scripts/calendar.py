"""Print one day's events from the iCal feeds in ~/.config/amane-shell/calendars.

The file lists one address per line, such as Google Calendar's "Secret address in
iCal format". Each output line is "<time>\t<title>"; the shell's calendar tab draws them.
"""

import hashlib
import os
import sys
import time
import urllib.request
from datetime import date, datetime, timedelta
from pathlib import Path

import icalendar
import recurring_ical_events

REFRESH_SECONDS = 10 * 60

home = Path.home()
config = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
cache = Path(os.environ.get("XDG_CACHE_HOME", home / ".cache")) / "amane-shell"


def feeds():
    path = config / "amane-shell" / "calendars"
    lines = path.read_text().splitlines() if path.is_file() else []
    urls = [line.strip() for line in lines]
    urls = [url for url in urls if url and not url.startswith("#")]
    # webcal:// is how calendars hand out the same https address
    urls = ["https://" + url[9:] if url.startswith("webcal://") else url for url in urls]
    return [url for url in urls if url.startswith("https://")]


def fetch(url):
    # the secret address is the credential, so the file is named by a hash of it
    name = "calendar-" + hashlib.sha256(url.encode()).hexdigest()[:16] + ".ics"
    file = cache / name
    fresh = file.is_file() and time.time() - file.stat().st_mtime < REFRESH_SECONDS

    if not fresh:
        try:
            with urllib.request.urlopen(url, timeout=15) as response:
                data = response.read()
            icalendar.Calendar.from_ical(data)
            cache.mkdir(parents=True, exist_ok=True)
            partial = file.with_name(f"{name}.{os.getpid()}")
            partial.write_bytes(data)
            partial.replace(file)
        except Exception as error:
            # offline: the last copy is better than an empty day
            print(f"amane-calendar: {type(error).__name__}", file=sys.stderr)

    return file.read_bytes() if file.is_file() else None


def local(value):
    return value.astimezone() if value.tzinfo else value


def row(event):
    start = event.get("DTSTART").dt
    end = event.get("DTEND")
    title = " ".join(str(event.get("SUMMARY", "(No title)")).split())

    if not isinstance(start, datetime):
        return (0, 0.0), f"All day\t{title}"

    start = local(start)
    end = local(end.dt) if end and isinstance(end.dt, datetime) else start

    return (1, start.timestamp()), f"{start:%H:%M} - {end:%H:%M}\t{title}"


def day_events(feed, day):
    start = datetime.combine(day, datetime.min.time()).astimezone()
    end = start + timedelta(days=1)
    calendar = icalendar.Calendar.from_ical(feed)
    events = recurring_ical_events.of(calendar).between(start, end)

    return [event for event in events if event.get("STATUS") != "CANCELLED"]


def main():
    day = date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else date.today()
    rows = []

    for url in feeds():
        feed = fetch(url)
        if feed:
            rows.extend(row(event) for event in day_events(feed, day))

    for _, line in sorted(rows):
        print(line)


os.umask(0o077)
main()
