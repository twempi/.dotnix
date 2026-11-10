"""Print the events from the iCal feeds in the google_calendars secret.

The secret lists one address per line, such as Google Calendar's "Secret address in
iCal format". `amane-calendar FIRST LAST` prints the events between two dates.
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
SECRET = Path("/run/secrets/google_calendars")

home = Path.home()
config = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
cache = Path(os.environ.get("XDG_CACHE_HOME", home / ".cache")) / "amane-shell"


def feeds():
    # the sops secret syncs through the repo; the plain file is for a machine without it
    path = SECRET if SECRET.is_file() else config / "amane-shell" / "calendars"
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


def rows(event, feed, first, last):
    """One line per day the event covers, as "<date>\t<feed>\t<time>\t<title>"."""
    # icalendar fills in an end from DURATION, or the default length
    start, end = event.start, event.end
    title = " ".join(str(event.get("SUMMARY", "(No title)")).split())

    if isinstance(start, datetime):
        start, end = local(start), local(end)
        kind, order, time = 1, start.timestamp(), f"{start:%H:%M} - {end:%H:%M}"
        day = start.date()
        final = (end - timedelta(microseconds=1)).date() if end > start else day
    else:
        kind, order, time = 0, 0.0, "All day"
        day = start
        final = end - timedelta(days=1) if end > start else day

    day, final = max(day, first), min(final, last)
    lines = []

    while day <= final:
        lines.append(((day, kind, order, feed), f"{day}\t{feed}\t{time}\t{title}"))
        day += timedelta(days=1)

    return lines


def events(feed, first, last):
    start = datetime.combine(first, datetime.min.time()).astimezone()
    end = datetime.combine(last + timedelta(days=1), datetime.min.time()).astimezone()
    calendar = icalendar.Calendar.from_ical(feed)
    found = recurring_ical_events.of(calendar).between(start, end)

    return [event for event in found if event.get("STATUS") != "CANCELLED"]


def main():
    # the first and last day to list; the shell asks for the six weeks it draws
    first = date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else date.today()
    last = date.fromisoformat(sys.argv[2]) if len(sys.argv) > 2 else first
    lines = []

    # a feed's place in the list is its color in the shell, even while it can't be fetched
    for index, url in enumerate(feeds()):
        feed = fetch(url)
        if not feed:
            continue

        for event in events(feed, first, last):
            try:
                lines.extend(rows(event, index, first, last))
            except Exception as error:
                print(f"amane-calendar: skipped an event: {type(error).__name__}", file=sys.stderr)

    for _, line in sorted(lines):
        print(line)


os.umask(0o077)
main()
