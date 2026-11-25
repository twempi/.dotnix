"""Print how much of the Claude and Codex subscriptions' limits is used, for the Usage tab.

It reads the sign-ins Claude Code and Codex keep and asks the usage endpoints their own
/usage and /status screens use. These are undocumented and may change. It never refreshes
or writes a sign-in: a refresh would rotate the token under the running agent and sign it
out. An expired sign-in shows the last answer until the agent next refreshes it.

Prints a JSON list, one entry per subscription:
{"name", "plan", "note", "fetched", "windows": [{"label", "used", "resets"}]}
with "used" in percent and "fetched" and "resets" in Unix seconds (0 when unknown).
"""

import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path

# opening the tab again within this reuses the last answer; Anthropic throttles polling
FRESH_SECONDS = 60
TIMEOUT = 10

home = Path.home()
cache = Path(os.environ.get("XDG_CACHE_HOME", home / ".cache")) / "amane-shell"
claude_home = Path(os.environ.get("CLAUDE_CONFIG_DIR", home / ".claude"))
codex_home = Path(os.environ.get("CODEX_HOME", home / ".codex"))

CLAUDE_URL = "https://api.anthropic.com/api/oauth/usage"
CODEX_URL = "https://chatgpt.com/backend-api/wham/usage"

CLAUDE_WINDOWS = {
    "five_hour": "Session",
    "seven_day": "Weekly",
    "seven_day_opus": "Weekly · Opus",
    "seven_day_sonnet": "Weekly · Sonnet",
}


class Expired(Exception):
    pass


def write(file, data):
    file.parent.mkdir(parents=True, exist_ok=True)
    partial = file.with_name(f"{file.name}.{os.getpid()}")
    partial.write_bytes(data)
    partial.replace(file)


def get(url, headers):
    request = urllib.request.Request(url, headers={"Accept": "application/json", **headers})
    with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
        return json.load(response)


def epoch(value):
    """Unix seconds from an ISO 8601 string or a number of seconds or milliseconds."""
    if isinstance(value, (int, float)):
        return int(value / 1000 if value > 1e11 else value)
    if isinstance(value, str) and value:
        moment = datetime.fromisoformat(value.replace("Z", "+00:00"))
        if moment.tzinfo is None:
            moment = moment.replace(tzinfo=timezone.utc)
        return int(moment.timestamp())
    return 0


def claude():
    login = json.loads((claude_home / ".credentials.json").read_text())["claudeAiOauth"]
    if login.get("expiresAt", 0) / 1000 < time.time():
        raise Expired("open Claude Code to refresh it")

    reply = get(CLAUDE_URL, {
        "Authorization": f"Bearer {login['accessToken']}",
        "anthropic-beta": "oauth-2025-04-20",
        # without a Claude Code user agent the endpoint refuses OAuth
        "User-Agent": "claude-cli/2.1.0 (external, cli)",
    })

    windows = []
    for key, label in CLAUDE_WINDOWS.items():
        window = reply.get(key)
        if isinstance(window, dict) and isinstance(window.get("utilization"), (int, float)):
            windows.append({"label": label, "used": window["utilization"], "resets": epoch(window.get("resets_at"))})

    extra = reply.get("extra_usage")
    if isinstance(extra, dict) and extra.get("is_enabled") and isinstance(extra.get("utilization"), (int, float)):
        windows.append({"label": "Extra usage", "used": extra["utilization"], "resets": 0})

    return "", windows


def jwt_expiry(token):
    payload = token.split(".")[1]
    return json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4))).get("exp", 0)


def window_label(seconds):
    hours = round(seconds / 3600)
    # the names Claude's windows get too
    if hours == 5:
        return "Session"
    if hours == 24 * 7:
        return "Weekly"
    if hours % 24 == 0 and hours >= 24:
        return f"{hours // 24}-day"
    return f"{hours}-hour"


def codex():
    tokens = json.loads((codex_home / "auth.json").read_text())["tokens"]
    if jwt_expiry(tokens["access_token"]) < time.time():
        raise Expired("open Codex to refresh it")

    reply = get(CODEX_URL, {
        "Authorization": f"Bearer {tokens['access_token']}",
        "ChatGPT-Account-Id": tokens.get("account_id", ""),
        "User-Agent": "codex_cli_rs",
    })

    limits = reply.get("rate_limit") or {}
    windows = []
    # which window is which follows its length, not its place: some plans have only a weekly one
    for key in ("primary_window", "secondary_window"):
        window = limits.get(key)
        if isinstance(window, dict) and isinstance(window.get("used_percent"), (int, float)):
            windows.append({
                "seconds": window.get("limit_window_seconds") or 0,
                "label": window_label(window.get("limit_window_seconds") or 0),
                "used": window["used_percent"],
                "resets": epoch(window.get("reset_at")),
            })
    windows.sort(key=lambda window: window.pop("seconds"))

    return str(reply.get("plan_type") or "").replace("_", " ").title(), windows


def usage(name, fetch):
    file = cache / f"usage-{name.lower()}.json"
    saved = json.loads(file.read_text()) if file.is_file() else None
    entry = {"name": name, "plan": "", "note": "", "fetched": 0, "windows": []}
    if saved:
        entry.update(saved)

    if saved and time.time() - saved["fetched"] < FRESH_SECONDS:
        return entry

    try:
        plan, windows = fetch()
        fresh = {"plan": plan, "fetched": int(time.time()), "windows": windows}
        write(file, json.dumps(fresh).encode())
        entry.update(fresh)
    except FileNotFoundError:
        entry["note"] = "Not signed in"
    except Expired as error:
        entry["note"] = f"Sign-in expired: {error}"
    except urllib.error.HTTPError as error:
        entry["note"] = "Sign-in refused" if error.code in (401, 403) else f"Couldn't update (HTTP {error.code})"
    except urllib.error.URLError:
        entry["note"] = "Offline"
    except Exception as error:
        # never the error's text: it could quote a token
        entry["note"] = "Couldn't update"
        print(f"amane-usage: {name}: {type(error).__name__}", file=sys.stderr)

    return entry


os.umask(0o077)
with ThreadPoolExecutor() as pool:
    found = list(pool.map(lambda job: usage(*job), [("Claude", claude), ("Codex", codex)]))
print(json.dumps(found))
