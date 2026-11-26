"""Calendar, weather and vault task data for the morning-briefing and weekly-deadlines jobs.

Hermes runs this before each job and puts the output in the prompt, so the agent gets exact
dates instead of digging them out of raw .ics files. Standard library only.
"""

import json
import os
import re
import urllib.request
from datetime import date, datetime, time, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

LOCAL = ZoneInfo("America/Los_Angeles")
# Covers the morning job's today plus 7 days, and on Sunday the weekly job's next Monday to Sunday.
WINDOW_DAYS = 8
# Hermes runs the job from /home/edward/Documents.
VAULT = Path("notes")
DAILY = Path("300 Personal/Daily")
WEEKLY = Path("300 Personal/Weekly")
TASK_FILES = [Path("100 School/School To Do's.md")]
FEEDS = [
    ("School calendar (Canvas; every entry is a deadline)", "CALENDAR_SCHOOL_ICS"),
    ("Personal calendar (classes, quizzes, exams and other events)", "CALENDAR_PERSONAL_ICS"),
]
WEATHER_URL = "https://wttr.in/San+Luis+Obispo?format=j1"
WEEKDAYS = ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
SUPPORTED_RULE_PARTS = {"FREQ", "INTERVAL", "UNTIL", "COUNT", "BYDAY", "BYMONTH", "BYMONTHDAY", "WKST"}
TASK_RE = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+\[([ xX])\]\s*(.*)$")


def fetch(url):
    url = re.sub(r"^webcal://", "https://", url)
    request = urllib.request.Request(url, headers={"User-Agent": "hermes-deadlines"})
    return urllib.request.urlopen(request, timeout=30).read().decode("utf-8", "replace")


def error_text(error):
    # Feed URLs carry private tokens; keep them out of the prompt.
    return re.sub(r"\S+://\S+", "<url>", f"{type(error).__name__}: {error}")[:200]


# ── iCalendar parsing ────────────────────────────────────────────────────


def parse_events(text):
    """Return each VEVENT as {NAME: [(params, value), ...]}."""
    text = re.sub(r"\r?\n[ \t]", "", text)
    events, current, depth = [], None, 0
    for line in text.splitlines():
        if line == "BEGIN:VEVENT":
            current, depth = {}, 0
        elif line == "END:VEVENT" and current is not None:
            events.append(current)
            current = None
        elif current is not None:
            # Alarms and other nested components inside an event are skipped.
            if line.startswith("BEGIN:"):
                depth += 1
            elif line.startswith("END:"):
                depth -= 1
            elif depth == 0 and ":" in line:
                head, value = line.split(":", 1)
                name, *raw_params = head.split(";")
                params = dict(p.split("=", 1) for p in raw_params if "=" in p)
                current.setdefault(name.upper(), []).append((params, value))
    return events


def unescape(value):
    return re.sub(r"\\([nN,;\\])", lambda m: " " if m.group(1) in "nN" else m.group(1), value).strip()


def parse_time(params, value):
    """A date for all-day values, else an aware datetime."""
    value = value.strip()
    if params.get("VALUE") == "DATE" or len(value) == 8:
        return date(int(value[:4]), int(value[4:6]), int(value[6:8]))
    moment = datetime.strptime(value.rstrip("Z"), "%Y%m%dT%H%M%S")
    if value.endswith("Z"):
        return moment.replace(tzinfo=timezone.utc)
    try:
        zone = ZoneInfo(params["TZID"].strip('"')) if "TZID" in params else LOCAL
    except (KeyError, ValueError):
        zone = LOCAL
    return moment.replace(tzinfo=zone)


def first(event, name):
    values = event.get(name)
    return values[0] if values else None


def moment_key(value):
    """Comparable identity for an occurrence start (RECURRENCE-ID and EXDATE matching)."""
    return value if not isinstance(value, datetime) else value.astimezone(timezone.utc)


class Unsupported(Exception):
    pass


def nth_weekdays(year, month, byday):
    """Dates in a month matching BYDAY entries such as TU, 2SU or -1FR."""
    days = []
    start = date(year, month, 1)
    end = date(year + month // 12, month % 12 + 1, 1)
    month_days = [start + timedelta(n) for n in range((end - start).days)]
    for entry in byday:
        match = re.fullmatch(r"([+-]?\d*)(MO|TU|WE|TH|FR|SA|SU)", entry)
        if not match:
            raise Unsupported(entry)
        matching = [d for d in month_days if d.weekday() == WEEKDAYS.index(match.group(2))]
        if match.group(1):
            index = int(match.group(1))
            if -len(matching) <= index <= len(matching) and index != 0:
                days.append(matching[index - 1 if index > 0 else index])
        else:
            days.extend(matching)
    return sorted(days)


def candidate_days(rule, start_day, stop_day):
    """Days that match the rule's date parts, from start_day up to stop_day, in order."""
    freq = rule["FREQ"]
    interval = int(rule.get("INTERVAL", "1"))
    byday = rule["BYDAY"].split(",") if "BYDAY" in rule else []
    if freq == "DAILY":
        day = start_day
        while day <= stop_day:
            if not byday or WEEKDAYS[day.weekday()] in byday:
                yield day
            day += timedelta(interval)
    elif freq == "WEEKLY":
        wanted = [WEEKDAYS.index(d[-2:]) for d in byday] or [start_day.weekday()]
        week_start_day = WEEKDAYS.index(rule.get("WKST", "MO"))
        week = start_day - timedelta((start_day.weekday() - week_start_day) % 7)
        while week <= stop_day:
            for offset in sorted((d - week_start_day) % 7 for d in wanted):
                yield week + timedelta(offset)
            week += timedelta(7 * interval)
    elif freq == "MONTHLY":
        year, month = start_day.year, start_day.month
        while date(year, month, 1) <= stop_day:
            yield from month_days(rule, year, month, start_day)
            month += interval
            year, month = year + (month - 1) // 12, (month - 1) % 12 + 1
    elif freq == "YEARLY":
        months = sorted(int(m) for m in rule["BYMONTH"].split(",")) if "BYMONTH" in rule else [start_day.month]
        if byday and "BYMONTH" not in rule:
            raise Unsupported("yearly BYDAY without BYMONTH")
        year = start_day.year
        while date(year, 1, 1) <= stop_day:
            for month in months:
                yield from month_days(rule, year, month, start_day)
            year += interval
    else:
        raise Unsupported(freq)


def month_days(rule, year, month, start_day):
    """Days in one month picked by BYDAY or BYMONTHDAY, defaulting to the start's day of month."""
    if "BYDAY" in rule:
        return nth_weekdays(year, month, rule["BYDAY"].split(","))
    days = []
    for day in sorted(int(d) for d in rule.get("BYMONTHDAY", str(start_day.day)).split(",")):
        try:
            days.append(date(year, month, day))
        except ValueError:
            pass  # e.g. the 31st in a 30-day month
    return days


def after_until(occurrence, until):
    if isinstance(occurrence, datetime) and isinstance(until, datetime):
        return occurrence > until
    day = occurrence.astimezone(LOCAL).date() if isinstance(occurrence, datetime) else occurrence
    return day > (until.astimezone(LOCAL).date() if isinstance(until, datetime) else until)


def occurrences(event, window_end):
    """Start values of the event up to the end of the window, expanded from its RRULE."""
    start = parse_time(*first(event, "DTSTART"))
    rule_line = first(event, "RRULE")
    if not rule_line:
        return [start]
    rule = dict(part.split("=", 1) for part in rule_line[1].split(";") if "=" in part)
    if set(rule) - SUPPORTED_RULE_PARTS:
        raise Unsupported(rule_line[1])
    until = parse_time({}, rule["UNTIL"]) if "UNTIL" in rule else None
    count = int(rule["COUNT"]) if "COUNT" in rule else None
    all_day = not isinstance(start, datetime)
    start_day = start if all_day else start.date()
    found, produced = [], 0
    for day in candidate_days(rule, start_day, window_end.date()):
        if day < start_day:
            continue
        occurrence = day if all_day else datetime.combine(day, start.timetz())
        if until is not None and after_until(occurrence, until):
            break
        produced += 1
        if count is not None and produced > count:
            break
        found.append(occurrence)
    return found


def as_local(value):
    """Start of the value in local time (all-day dates start at local midnight)."""
    if isinstance(value, datetime):
        return value.astimezone(LOCAL)
    return datetime.combine(value, time(), LOCAL)


def calendar_entries(text, window_start, window_end):
    """(start, end, summary, location) for every event overlapping the window, plus notes."""
    events = parse_events(text)
    overrides, standalone = {}, []
    for event in events:
        recurrence = first(event, "RECURRENCE-ID")
        uid = first(event, "UID")
        if recurrence and uid:
            try:
                overrides[(uid[1], moment_key(parse_time(*recurrence)))] = event
            except ValueError:
                # Unreadable link to its series: still list it at its own start.
                standalone.append(event)

    entries, notes = [], []

    def add(event, start):
        status = first(event, "STATUS")
        if status and status[1].upper() == "CANCELLED":
            return
        dtstart = parse_time(*first(event, "DTSTART"))
        dtend = first(event, "DTEND")
        if dtend:
            # Each occurrence of a repeating event keeps the first one's length.
            end = start + (parse_time(*dtend) - dtstart)
        else:
            end = None if isinstance(start, datetime) else start + timedelta(1)
        end_local = as_local(end) if end else as_local(start) + timedelta(seconds=1)
        if as_local(start) < window_end and end_local > window_start:
            entries.append((start, end, summary_of(event), unescape((first(event, "LOCATION") or ({}, ""))[1])))

    for event in events:
        if not first(event, "DTSTART") or first(event, "RECURRENCE-ID"):
            continue
        uid = (first(event, "UID") or ({}, ""))[1]
        try:
            excluded = {
                moment_key(parse_time(params, item))
                for params, value in event.get("EXDATE", [])
                for item in value.split(",")
            }
            for start in occurrences(event, window_end):
                key = moment_key(start)
                if key not in excluded and (uid, key) not in overrides:
                    add(event, start)
        except Unsupported as error:
            notes.append(f"UNSUPPORTED RECURRENCE (check this event yourself): {summary_of(event)} ({error})")
        except (ValueError, TypeError) as error:
            notes.append(f"UNREADABLE EVENT (check this event yourself): {summary_of(event)} ({error})")
    for event in [*overrides.values(), *standalone]:
        try:
            add(event, parse_time(*first(event, "DTSTART")))
        except (ValueError, TypeError) as error:
            notes.append(f"UNREADABLE EVENT (check this event yourself): {summary_of(event)} ({error})")
    entries.sort(key=lambda entry: as_local(entry[0]))
    return entries, notes


def summary_of(event):
    return unescape((first(event, "SUMMARY") or ({}, "(no title)"))[1])


def clock(moment):
    return moment.strftime("%I:%M %p").lstrip("0")


def describe(start, end):
    if not isinstance(start, datetime):
        last = (end - timedelta(1)) if end else start
        text = start.strftime("%Y-%m-%d %a") + " all day"
        return text if last <= start else text + " through " + last.strftime("%Y-%m-%d %a")
    start = start.astimezone(LOCAL)
    text = start.strftime("%Y-%m-%d %a ") + clock(start)
    if end:
        end = end.astimezone(LOCAL)
        text += "-" + (clock(end) if end.date() == start.date() else end.strftime("%Y-%m-%d %a ") + clock(end))
    return text


# ── Weather ──────────────────────────────────────────────────────────────


def weather_line(today):
    data = json.loads(fetch(WEATHER_URL))
    day = next((d for d in data["weather"] if d["date"] == today.isoformat()), data["weather"][0])
    # Conditions at roughly 9 AM, 12 PM and 3 PM local.
    conditions = []
    for hour in day["hourly"]:
        if hour["time"] in ("900", "1200", "1500"):
            text = hour["weatherDesc"][0]["value"].strip()
            if text not in conditions:
                conditions.append(text)
    return f"{day['date']}: {', '.join(conditions) or 'n/a'}; high {day['maxtempF']}F, low {day['mintempF']}F"


# ── Vault ────────────────────────────────────────────────────────────────


def vault_tasks(vault):
    """Every [hid:: ] task line in the daily notes, weekly notes and task files, grouped by id."""
    files = []
    for folder in (DAILY, WEEKLY):
        if (vault / folder).is_dir():
            files += sorted((vault / folder).glob("*.md"))
    files += [vault / path for path in TASK_FILES if (vault / path).is_file()]
    tasks = {}
    for path in files:
        for number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            match = TASK_RE.match(line)
            hid = re.search(r"\[hid::\s*([^\]]+?)\s*\]", line)
            if not (match and hid):
                continue
            task = tasks.setdefault(hid.group(1), {"due": None, "checked": [], "unchecked": []})
            due = re.search(r"\[due::\s*(\d{4}-\d{2}-\d{2})\s*\]", line)
            if due:
                task["due"] = due.group(1)
            where = f"{path.relative_to(vault)}:{number}"
            task["checked" if match.group(1) in "xX" else "unchecked"].append(where)
    return tasks


def iso_week_name(day):
    year, week, _ = day.isocalendar()
    return f"{year}-W{week:02d}"


def report(now, vault=VAULT, feeds=FEEDS, weather=True):
    today = now.date()
    window_start = datetime.combine(today, time(), LOCAL)
    window_end = window_start + timedelta(WINDOW_DAYS)
    last_day = today + timedelta(WINDOW_DAYS - 1)
    lines = [
        f"Generated {now.strftime('%Y-%m-%d %a %I:%M %p')} America/Los_Angeles.",
        f"Calendar window: {today.strftime('%Y-%m-%d %a')} through {last_day.strftime('%Y-%m-%d %a')}.",
    ]

    for title, variable in feeds:
        lines += ["", title + ":"]
        url = os.environ.get(variable)
        if not url:
            lines.append(f"SOURCE ERROR {variable} is not set")
            continue
        try:
            entries, notes = calendar_entries(fetch(url), window_start, window_end)
        except Exception as error:
            lines.append(f"SOURCE ERROR {title.split(' (')[0]}: {error_text(error)}")
            continue
        lines += [f"- {describe(start, end)} | {summary}" + (f" | {location}" if location else "")
                  for start, end, summary, location in entries]
        lines += notes
        if not entries and not notes:
            lines.append("(no events in the window)")

    if weather:
        lines += ["", "Weather (San Luis Obispo, today):"]
        try:
            lines.append(weather_line(today))
        except Exception as error:
            lines.append(f"SOURCE ERROR weather: {error_text(error)}")

    lines += ["", "Vault tracked tasks (lines with [hid:: ]; done means checked anywhere):"]
    tasks = vault_tasks(vault)
    for hid in sorted(tasks, key=lambda h: (tasks[h]["due"] or "9999", h)):
        task = tasks[hid]
        lines.append(
            f"- {hid} | {'done' if task['checked'] else 'open'} | due {task['due'] or '?'}"
            f" | unchecked: {', '.join(task['unchecked']) or 'none'}"
            f" | checked: {', '.join(task['checked']) or 'none'}"
        )
    if not tasks:
        lines.append("(none yet)")

    daily = sorted(p for p in (vault / DAILY).glob("*.md") if re.fullmatch(r"\d{4}-\d{2}-\d{2}", p.stem))
    earlier = [p for p in daily if p.stem < today.isoformat()]
    next_monday = today + timedelta(7 - today.weekday())
    week_note = WEEKLY / f"{iso_week_name(next_monday)}.md"
    today_note = DAILY / f"{today.isoformat()}.md"
    lines += [
        "",
        "Vault notes:",
        f"- Today's daily note {today_note}: {'exists' if (vault / today_note).exists() else 'missing'}",
        f"- Most recent earlier daily note: {earlier[-1].relative_to(vault) if earlier else 'none'}",
        f"- Next week's note (week of {next_monday.isoformat()}) {week_note}: "
        + ("exists" if (vault / week_note).exists() else "missing"),
    ]
    return "\n".join(lines)


if __name__ == "__main__":
    print(report(datetime.now(LOCAL)))
