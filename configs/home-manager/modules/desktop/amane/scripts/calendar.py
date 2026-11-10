"""Print the events from the Google calendars ticked in Google, through the Calendar API.

`amane-calendar --login CLIENT.json` signs in to Google, like Noctalia's Google account:
CLIENT.json is a "Desktop app" OAuth client downloaded from Google Cloud. It prints the
sign-in for the google_calendar_account secret, so every machine shares it through sops.

`amane-calendar FIRST LAST` prints the events between two dates.
`amane-calendar --remind` sends the reminders that are due, see remind().
"""

import base64
import hashlib
import http.server
import json
import math
import os
import secrets
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import webbrowser
from collections import namedtuple
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

REFRESH_SECONDS = 10 * 60
# the client and refresh token that --login prints; the shell checks for it too
ACCOUNT = Path("/run/secrets/google_calendar_account")

AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URL = "https://oauth2.googleapis.com/token"
API = "https://www.googleapis.com/calendar/v3"
SCOPES = ["https://www.googleapis.com/auth/calendar.calendarlist.readonly",
          "https://www.googleapis.com/auth/calendar.events.readonly"]
# Noctalia's sync window (src/calendar/calendar_service.cpp)
WINDOW = timedelta(days=365)

# Noctalia's reminder rules (src/calendar/calendar_reminders.h) and default settings
DEFAULT_LEAD = timedelta(minutes=10)
MAX_LEAD = timedelta(days=30)
MAX_LEADS = 5
LATE_GRACE = timedelta(minutes=5)
MAX_CATCH_UP = 3
DIGEST_TIME = "09:00"
MAX_DIGEST_TITLES = 5

home = Path.home()
cache = Path(os.environ.get("XDG_CACHE_HOME", home / ".cache")) / "amane-shell"
state = Path(os.environ.get("XDG_STATE_HOME", home / ".local" / "state")) / "amane-shell"
# the hash of the secret's refresh token once Google refuses it, so a new one is tried again
refused = state / "google-refused"

# start and end are dates for an all-day event and local datetimes otherwise. leads are the
# times before the start to remind at: None means DEFAULT_LEAD, [] means never.
Event = namedtuple("Event", "feed uid title start end location leads declined")


def write(file, data):
    file.parent.mkdir(parents=True, exist_ok=True)
    partial = file.with_name(f"{file.name}.{os.getpid()}")
    partial.write_bytes(data)
    partial.replace(file)


def notify(summary, body):
    # Noctalia's reminders stay until closed; the shell keeps the Calendar app's popups up
    subprocess.run(["notify-send", "--app-name=Calendar", "--urgency=normal", "--expire-time=0",
                    "--icon=x-office-calendar", summary, body], check=False)


def normalized(leads):
    return sorted({lead for lead in leads if timedelta(0) <= lead <= MAX_LEAD})[:MAX_LEADS]


def google_token(login, **grant):
    data = urllib.parse.urlencode({"client_id": login["client_id"], "client_secret": login["client_secret"], **grant})
    with urllib.request.urlopen(TOKEN_URL, data.encode(), timeout=15) as response:
        return json.load(response)


def google_pages(url, token, **query):
    # a page can come back short, or empty, while more remain
    while True:
        request = urllib.request.Request(f"{url}?{urllib.parse.urlencode(query)}",
                                         headers={"Authorization": f"Bearer {token}"})
        with urllib.request.urlopen(request, timeout=15) as response:
            page = json.load(response)
        yield page
        if "nextPageToken" not in page:
            return
        query["pageToken"] = page["nextPageToken"]


def google_download(login):
    try:
        token = google_token(login, grant_type="refresh_token", refresh_token=login["refresh_token"])["access_token"]
    except urllib.error.HTTPError as error:
        # the refresh token was revoked or ran out, so every later try would fail the same way
        if error.code == 400 and b"invalid_grant" in error.read():
            write(refused, hashlib.sha256(login["refresh_token"].encode()).hexdigest().encode())
            notify("Google Calendar signed out", "Sign in again with amane-calendar --login and update the google_calendar_account secret.")
        raise

    now = datetime.now(timezone.utc)
    window = {"timeMin": (now - WINDOW).isoformat(), "timeMax": (now + WINDOW).isoformat()}
    calendars = []

    # the calendars ticked in Google, in the list's order, which is also their color in the shell
    for page in google_pages(f"{API}/users/me/calendarList", token):
        calendars.extend(item for item in page.get("items", []) if item.get("selected"))

    synced = []
    for item in calendars:
        url = f"{API}/calendars/{urllib.parse.quote(item['id'], safe='')}/events"
        pages = list(google_pages(url, token, singleEvents="true", orderBy="startTime", maxResults=2500, **window))
        synced.append({
            # the calendar's own reminders, for the events that use them
            "defaults": pages[0].get("defaultReminders", []),
            "items": [event for page in pages for event in page.get("items", [])],
        })

    return synced


def google_sync():
    file = cache / "google.json"
    fresh = file.is_file() and time.time() - file.stat().st_mtime < REFRESH_SECONDS
    if not ACCOUNT.is_file():
        return []
    login = json.loads(ACCOUNT.read_text())
    expired = refused.is_file() and refused.read_text() == hashlib.sha256(login["refresh_token"].encode()).hexdigest()

    if not fresh and not expired:
        try:
            write(file, json.dumps(google_download(login)).encode())
        except Exception as error:
            # offline: the last copy is better than an empty day
            print(f"amane-calendar: {type(error).__name__}", file=sys.stderr)

    return json.loads(file.read_text()) if file.is_file() else []


def popup_leads(reminders):
    # "email" is sent by Google itself
    popups = [reminder for reminder in reminders if reminder.get("method", "popup") in ("popup", "display")]
    return normalized(timedelta(minutes=popup["minutes"]) for popup in popups if isinstance(popup.get("minutes"), int))


def google_leads(reminders, defaults):
    """The event's reminders, like Noctalia's googleEventReminders."""
    if not isinstance(reminders, dict):
        return None
    if own := popup_leads(reminders.get("overrides", [])):
        return own
    if not isinstance(reminders.get("useDefault"), bool):
        return None
    if reminders["useDefault"]:
        return popup_leads(defaults) or None
    # the event's notifications were turned off
    return []


def google_time(node):
    return date.fromisoformat(node["date"]) if "date" in node else datetime.fromisoformat(node["dateTime"]).astimezone()


def google_event(item, feed, defaults):
    start = google_time(item["start"])
    end = google_time(item["end"]) if "end" in item else start
    title = " ".join(item.get("summary", "").split())
    location = " ".join(item.get("location", "").split())
    attendees = item.get("attendees", [])
    declined = any(person.get("self") and person.get("responseStatus") == "declined" for person in attendees)
    leads = google_leads(item.get("reminders"), defaults)

    return Event(feed, item.get("id", ""), title, start, end, location, leads, declined)


def google_events():
    found = []

    for feed, calendar in enumerate(google_sync()):
        for item in calendar["items"]:
            if item.get("status") == "cancelled":
                continue
            try:
                found.append(google_event(item, feed, calendar["defaults"]))
            except Exception as error:
                print(f"amane-calendar: skipped an event: {type(error).__name__}", file=sys.stderr)

    return found


def rows(event, first, last):
    """One line per day the event covers, as "<date>\t<feed>\t<time>\t<title>"."""
    start, end = event.start, event.end

    if isinstance(start, datetime):
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
        lines.append(((day, kind, order, event.feed), f"{day}\t{event.feed}\t{time}\t{event.title or '(No title)'}"))
        day += timedelta(days=1)

    return lines


def main():
    # the first and last day to list; the shell asks for the six weeks it draws
    first = date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else date.today()
    last = date.fromisoformat(sys.argv[2]) if len(sys.argv) > 2 else first
    lines = []

    for event in google_events():
        lines.extend(rows(event, first, last))

    for _, line in sorted(lines):
        print(line)


def reminder_body(start, now, location):
    minutes = math.ceil((start - now).total_seconds() / 60)
    when = f"Starts in {minutes} min · {start:%H:%M}" if minutes > 0 else f"Starts now · {start:%H:%M}"
    return f"{when}\n{location}" if location else when


def remind():
    """Send the reminders that came due since the last run, the way Noctalia does.

    A timed event alerts at its own pop-up reminders, or DEFAULT_LEAD before it starts when
    it has none. A reminder still fires when it is late, until its event has started or for
    LATE_GRACE after it came due. All-day events get no reminders of their own; their titles
    go out together once a day, at DIGEST_TIME or the first run after it. Declined events
    get neither.
    """
    now = datetime.now().astimezone()
    today = now.date()
    file = state / "calendar-reminders.json"
    saved = json.loads(file.read_text()) if file.is_file() else {}
    # a fired key ends in the event's start; past the grace its reminder can never fire again
    fired = {key for key in saved.get("fired", []) if int(key.split("|")[-2]) > (now - LATE_GRACE).timestamp()}
    due, all_day = [], []

    for event in google_events():
        if event.declined:
            continue

        if not isinstance(event.start, datetime):
            last = event.end - timedelta(days=1) if event.end > event.start else event.start
            if event.start <= today <= last:
                all_day.append(event.title or "Untitled event")
            continue

        if event.start < now - LATE_GRACE:
            continue
        uid = event.uid or "h" + hashlib.sha256(event.title.encode()).hexdigest()[:16]
        # -1 marks the default lead, so changing DEFAULT_LEAD never repeats a fired reminder
        choices = [(lead, int(lead.total_seconds())) for lead in event.leads] if event.leads is not None else [(DEFAULT_LEAD, -1)]

        for lead, lead_key in choices:
            key = f"{uid}|{int(event.start.timestamp())}|{lead_key}"
            if key in fired or event.start - lead > now:
                continue
            if event.start > now or now - (event.start - lead) <= LATE_GRACE:
                due.append((event.start, event.title, lead, key, event.location))

    # one notification per meeting, from the reminder closest to it, and a few at most
    shown, notified = None, 0
    for start, title, lead, key, location in sorted(due):
        fired.add(key)
        if (start, title) == shown:
            continue
        shown = (start, title)
        if notified < MAX_CATCH_UP:
            notify(title or "Untitled event", reminder_body(start, now, location))
        notified += 1
    if notified > MAX_CATCH_UP:
        notify("More upcoming events", f"{notified - MAX_CATCH_UP} more events are starting soon.")

    digest = saved.get("digest")
    digest_at = datetime.combine(today, datetime.strptime(DIGEST_TIME, "%H:%M").time()).astimezone()
    if all_day and now >= digest_at and digest != str(today):
        titles = all_day[:MAX_DIGEST_TITLES]
        if len(all_day) > MAX_DIGEST_TITLES:
            titles.append(f"+{len(all_day) - MAX_DIGEST_TITLES} more")
        notify("All-day today", "\n".join(titles))
        digest = str(today)

    record = {"fired": sorted(fired), "digest": digest}
    if record != {"fired": sorted(saved.get("fired", [])), "digest": saved.get("digest")}:
        write(file, json.dumps(record).encode())


def sign_in(path):
    """Sign in through Google's flow for desktop apps: a loopback redirect with PKCE."""
    client = json.loads(Path(path).read_text()).get("installed")
    if not client:
        sys.exit("amane-calendar: expected the JSON of a Desktop app OAuth client")

    verifier = secrets.token_urlsafe(64)
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
    nonce = secrets.token_urlsafe(16)
    reply = {}

    class Redirect(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            reply.update(urllib.parse.parse_qsl(urllib.parse.urlsplit(self.path).query))
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(b"You can close this tab and go back to the terminal.")

        def log_message(self, *args):
            pass

    with http.server.HTTPServer(("127.0.0.1", 0), Redirect) as server:
        redirect = f"http://127.0.0.1:{server.server_port}"
        url = AUTH_URL + "?" + urllib.parse.urlencode({
            "client_id": client["client_id"],
            "redirect_uri": redirect,
            "response_type": "code",
            "scope": " ".join(SCOPES),
            "code_challenge": challenge,
            "code_challenge_method": "S256",
            "state": nonce,
            # a refresh token, even when this client was allowed before
            "access_type": "offline",
            "prompt": "consent",
        })
        print(f"Sign in to Google in the browser. If it didn't open, visit:\n{url}")
        webbrowser.open(url)
        # the browser may ask for other paths, like a favicon, before the redirect comes
        while "code" not in reply and "error" not in reply:
            server.handle_request()

    if reply.get("state") != nonce or "code" not in reply:
        sys.exit(f"amane-calendar: sign-in failed: {reply.get('error', 'the reply did not match')}")

    login = {"client_id": client["client_id"], "client_secret": client["client_secret"]}
    tokens = google_token(login, grant_type="authorization_code", code=reply["code"],
                          redirect_uri=redirect, code_verifier=verifier)
    if not set(SCOPES) <= set(tokens.get("scope", "").split()):
        sys.exit("amane-calendar: Google didn't grant calendar access; tick both boxes when signing in")

    login["refresh_token"] = tokens["refresh_token"]
    # JSON has no single quotes, so the line is valid YAML as it is
    print("Signed in. Add this line with `sops edit secrets/calendar.yaml`, then rebuild NixOS:", file=sys.stderr)
    print(f"google_calendar_account: '{json.dumps(login)}'")


os.umask(0o077)
if sys.argv[1:2] == ["--login"]:
    if len(sys.argv) != 3:
        sys.exit("usage: amane-calendar --login CLIENT.json")
    sign_in(sys.argv[2])
elif sys.argv[1:] == ["--remind"]:
    remind()
else:
    main()
