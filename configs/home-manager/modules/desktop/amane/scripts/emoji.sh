# UNICODE_EMOJI_TEST is set by default.nix.
choice="$(
  python3 - <<'PY' | amane-dmenu -dmenu -i -p Emoji -theme emoji
import os
import re
from pathlib import Path

unicode_emoji_test = Path(os.environ["UNICODE_EMOJI_TEST"])

def read_lines(path):
    try:
        return path.read_text(encoding="utf-8", errors="ignore").splitlines()
    except OSError:
        return []

def plain_item(raw):
    line = raw.strip()
    if not line or line.startswith("#"):
        return None
    return line

def unicode_item(raw):
    if "#" not in raw or "; fully-qualified" not in raw:
        return None
    comment = raw.split("#", 1)[1].strip()
    match = re.match(r"(\S+)\s+E[0-9.]+\s+(.+)$", comment)
    if not match:
        return None
    value, description = match.groups()
    return f"{value} {description}"

def parse_item(raw):
    return unicode_item(raw) or plain_item(raw)

def emoji_source_lines():
    custom = os.environ.get("BEMOJI_CUSTOM_LIST")
    if custom:
        custom_path = Path(custom).expanduser()
        if custom_path.is_file():
            return read_lines(custom_path)

    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
    database = Path(os.environ.get("BEMOJI_DB_LOCATION", data_home / "bemoji")).expanduser()
    lines = []
    if database.is_dir():
        for path in sorted(database.glob("*.txt")):
            if path.is_file():
                lines.extend(read_lines(path))
    if lines:
        return lines

    return read_lines(unicode_emoji_test)

def history_lines():
    state_home = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
    history_dir = Path(os.environ.get("BEMOJI_HISTORY_LOCATION", state_home)).expanduser()
    history_file = history_dir / "bemoji-history.txt"
    counts = {}
    order = []

    for raw in read_lines(history_file):
        line = raw.strip()
        if not line:
            continue
        if line not in counts:
            counts[line] = 0
            order.append(line)
        counts[line] += 1

    return sorted(order, key=lambda line: (-counts[line], order.index(line)))

seen = set()
for raw in history_lines() + emoji_source_lines():
    item = parse_item(raw)
    if item is None or item in seen:
        continue
    seen.add(item)
    print(item)
PY
)"
menu_exit=$?

if [ "$menu_exit" -ne 0 ] || [ -z "$choice" ]; then
  exit 0
fi

value="$(python3 - "$choice" <<'PY'
import sys

line = sys.argv[1].strip()
print(line.split(None, 1)[0] if line else "")
PY
)"

if [ -z "$value" ]; then
  exit 0
fi

printf '%s' "$value" | wl-copy

history_dir="${BEMOJI_HISTORY_LOCATION:-${XDG_STATE_HOME:-$HOME/.local/state}}"
mkdir -p "$history_dir"
printf '%s\n' "$choice" >> "$history_dir/bemoji-history.txt"
