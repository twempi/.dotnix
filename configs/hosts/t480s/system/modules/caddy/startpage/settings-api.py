#!/usr/bin/env python3
import json
import os
import tempfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse


SETTINGS_FILE = Path(os.environ.get("STARTPAGE_SETTINGS_FILE", "/var/lib/startpage/settings.json"))
HOST = os.environ.get("STARTPAGE_SETTINGS_HOST", "127.0.0.1")
PORT = int(os.environ.get("STARTPAGE_SETTINGS_PORT", "4919"))
ALLOWED_ORIGIN = os.environ.get("STARTPAGE_SETTINGS_ORIGIN", "https://t480s.tailae03d0.ts.net")
MAX_BODY_BYTES = 256 * 1024
CHROME_EXTENSION_ID_CHARS = set("abcdefghijklmnop")

SEARCH_ENGINES = {"brave", "google", "ddg", "bing"}
BADGE_MODES = {"live", "route", "off"}
WEATHER_UNITS = {"celsius", "fahrenheit"}
THEMES = {"stylix"}
SYNTAX_COLOR_KEYS = {"cmd", "theme", "search", "version", "url", "unknown"}
DIR_EXTENSION_KEYS = {"media", "books", "music", "software", "images"}


class SettingsError(Exception):
    def __init__(self, status, message):
        super().__init__(message)
        self.status = status
        self.message = message


def is_allowed_extension_origin(origin):
    parsed = urlparse(origin)
    extension_id = parsed.netloc
    return (
        parsed.scheme == "chrome-extension"
        and len(extension_id) == 32
        and all(ch in CHROME_EXTENSION_ID_CHARS for ch in extension_id)
        and not parsed.path
        and not parsed.params
        and not parsed.query
        and not parsed.fragment
    )


def is_allowed_origin(origin):
    return origin == ALLOWED_ORIGIN or is_allowed_extension_origin(origin)


def clean_string(value, field, *, allow_empty=False, allow_null=False, max_length=2048):
    if value is None and allow_null:
        return None
    if not isinstance(value, str):
        raise SettingsError(400, f"{field} must be a string")
    value = value.strip()
    if not value and not allow_empty:
        raise SettingsError(400, f"{field} cannot be empty")
    if len(value) > max_length:
        raise SettingsError(400, f"{field} is too long")
    return value


def clean_bool(value, field):
    if not isinstance(value, bool):
        raise SettingsError(400, f"{field} must be a boolean")
    return value


def normalize_bookmark_list(value, field, *, require_one):
    if not isinstance(value, list):
        raise SettingsError(400, f"{field} must be a list")

    result = []
    for item in value:
        if not isinstance(item, dict):
            continue

        href = str(item.get("href", "")).strip()
        title = str(item.get("title", href)).strip()
        category = str(item.get("category", "")).strip()

        if not href or not title:
            continue
        if len(href) > 4096 or len(title) > 256 or len(category) > 128:
            raise SettingsError(400, f"{field} contains a value that is too long")

        bookmark = {"href": href, "title": title}
        if category:
            bookmark["category"] = category
        result.append(bookmark)

    if require_one and not result:
        raise SettingsError(400, f"{field} must contain at least one valid bookmark")
    return result


def normalize_syntax_colors(value):
    if not isinstance(value, dict):
        raise SettingsError(400, "syntaxColors must be an object")

    colors = {}
    for key, color in value.items():
        if key not in SYNTAX_COLOR_KEYS:
            continue
        if not isinstance(color, str):
            continue
        color = color.strip().lower()
        if len(color) == 7 and color.startswith("#"):
            digits = color[1:]
            if all(ch in "0123456789abcdef" for ch in digits):
                colors[key] = color
    return colors


def normalize_string_map(value, field):
    if not isinstance(value, dict):
        raise SettingsError(400, f"{field} must be an object")

    result = {}
    for key, val in value.items():
        key = str(key).strip()
        if not key:
            continue
        if not isinstance(val, str):
            continue
        val = val.strip()
        if not val:
            continue
        if len(key) > 64 or len(val) > 4096:
            raise SettingsError(400, f"{field} contains a value that is too long")
        result[key] = val
    return result


def normalize_custom_tags(value):
    if not isinstance(value, list):
        raise SettingsError(400, "customTags must be a list")

    tags = []
    for item in value:
        if not isinstance(item, dict):
            continue

        prefix = "".join(ch for ch in str(item.get("prefix", "")).strip().lower() if ch.isalnum())
        url = str(item.get("url", "")).strip()
        if not prefix or not url:
            continue
        if len(prefix) > 32 or len(url) > 4096:
            raise SettingsError(400, "customTags contains a value that is too long")
        tags.append({"prefix": prefix, "url": url})
    return tags


def normalize_dir_extensions(value):
    if not isinstance(value, dict):
        raise SettingsError(400, "dirExtensions must be an object")

    result = {}
    for key, exts in value.items():
        if key not in DIR_EXTENSION_KEYS:
            continue
        if not isinstance(exts, list):
            continue

        clean_exts = []
        seen = set()
        for ext in exts:
            clean_ext = "".join(ch for ch in str(ext).strip().lower() if ch.isalnum())
            if not clean_ext or clean_ext in seen:
                continue
            if len(clean_ext) > 12:
                raise SettingsError(400, "dirExtensions contains an extension that is too long")
            seen.add(clean_ext)
            clean_exts.append(clean_ext)

        if clean_exts:
            result[key] = clean_exts
    return result


def normalize_prompts(value):
    if not isinstance(value, list):
        raise SettingsError(400, "terminalPrompts must be a list")

    prompts = []
    for prompt in value:
        if not isinstance(prompt, str):
            continue
        prompt = prompt.strip()
        if not prompt:
            continue
        if len(prompt) > 240:
            raise SettingsError(400, "terminalPrompts contains a prompt that is too long")
        prompts.append(prompt)
    return prompts


def normalize_choice(value, field, choices):
    value = clean_string(value, field, max_length=64).lower()
    if value not in choices:
        raise SettingsError(400, f"{field} is invalid")
    return value


def normalize_settings(raw):
    if not isinstance(raw, dict):
        raise SettingsError(400, "settings payload must be a JSON object")

    schema_version = raw.get("_schemaVersion", 1)
    if schema_version != 1:
        raise SettingsError(400, "_schemaVersion must be 1")

    return {
        "_schemaVersion": 1,
        "username": clean_string(raw.get("username"), "username", max_length=80),
        "weatherLocation": clean_string(raw.get("weatherLocation"), "weatherLocation", max_length=160),
        "weatherUnit": normalize_choice(raw.get("weatherUnit"), "weatherUnit", WEATHER_UNITS),
        "timezone": clean_string(raw.get("timezone"), "timezone", allow_null=True, max_length=128),
        "aiModeEnabled": clean_bool(raw.get("aiModeEnabled"), "aiModeEnabled"),
        "aiRouteBadgeMode": normalize_choice(raw.get("aiRouteBadgeMode"), "aiRouteBadgeMode", BADGE_MODES),
        "searchEngine": normalize_choice(raw.get("searchEngine"), "searchEngine", SEARCH_ENGINES),
        "theme": normalize_choice(raw.get("theme"), "theme", THEMES),
        "bookmarks": normalize_bookmark_list(raw.get("bookmarks"), "bookmarks", require_one=True),
        "shelfBookmarks": normalize_bookmark_list(raw.get("shelfBookmarks", []), "shelfBookmarks", require_one=False),
        "syntaxColors": normalize_syntax_colors(raw.get("syntaxColors", {})),
        "searchOverrides": normalize_string_map(raw.get("searchOverrides", {}), "searchOverrides"),
        "customTags": normalize_custom_tags(raw.get("customTags", [])),
        "dirExtensions": normalize_dir_extensions(raw.get("dirExtensions", {})),
        "terminalPrompts": normalize_prompts(raw.get("terminalPrompts", [])),
    }


def write_settings(settings):
    SETTINGS_FILE.parent.mkdir(mode=0o750, parents=True, exist_ok=True)
    data = json.dumps(settings, indent=2, ensure_ascii=False) + "\n"

    fd, temp_path = tempfile.mkstemp(
        prefix=f".{SETTINGS_FILE.name}.",
        suffix=".tmp",
        dir=str(SETTINGS_FILE.parent),
        text=True,
    )

    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(data)
            fh.flush()
            os.fsync(fh.fileno())

        os.chmod(temp_path, 0o640)
        os.replace(temp_path, SETTINGS_FILE)

        dir_fd = os.open(SETTINGS_FILE.parent, os.O_RDONLY)
        try:
            os.fsync(dir_fd)
        finally:
            os.close(dir_fd)
    except Exception:
        try:
            os.unlink(temp_path)
        except FileNotFoundError:
            pass
        raise


class SettingsHandler(BaseHTTPRequestHandler):
    server_version = "StartpageSettingsAPI/1.0"

    def do_OPTIONS(self):
        try:
            if urlparse(self.path).path != "/api/settings":
                raise SettingsError(404, "not found")

            origin = self.headers.get("Origin")
            if not origin or not is_allowed_origin(origin):
                raise SettingsError(403, "origin is not allowed")

            self.send_empty(204, extra_headers=self.cors_headers(preflight=True))
        except SettingsError as err:
            self.send_json(err.status, {"ok": False, "error": err.message})

    def do_GET(self):
        self.send_json(405, {"ok": False, "error": "GET is not supported"}, extra_headers={"Allow": "PUT"})

    def do_POST(self):
        self.send_json(405, {"ok": False, "error": "POST is not supported"}, extra_headers={"Allow": "PUT"})

    def do_PUT(self):
        try:
            if urlparse(self.path).path != "/api/settings":
                raise SettingsError(404, "not found")

            self.validate_request_headers()
            payload = self.read_json_body()
            settings = normalize_settings(payload)
            write_settings(settings)
            self.send_json(200, {"ok": True, "settings": settings})
        except SettingsError as err:
            self.send_json(err.status, {"ok": False, "error": err.message})
        except json.JSONDecodeError:
            self.send_json(400, {"ok": False, "error": "invalid JSON"})
        except Exception:
            self.send_json(500, {"ok": False, "error": "failed to write settings"})

    def validate_request_headers(self):
        origin = self.headers.get("Origin")
        if origin and not is_allowed_origin(origin):
            raise SettingsError(403, "origin is not allowed")

        is_extension_origin = bool(origin and is_allowed_extension_origin(origin))
        sec_fetch_site = self.headers.get("Sec-Fetch-Site")
        if sec_fetch_site and sec_fetch_site.lower() not in {"same-origin", "none"} and not is_extension_origin:
            raise SettingsError(403, "cross-site writes are not allowed")

        content_type = self.headers.get("Content-Type", "").split(";", 1)[0].strip().lower()
        if content_type != "application/json":
            raise SettingsError(415, "Content-Type must be application/json")

    def read_json_body(self):
        length_header = self.headers.get("Content-Length")
        if not length_header:
            raise SettingsError(411, "Content-Length is required")
        try:
            length = int(length_header)
        except ValueError:
            raise SettingsError(400, "Content-Length is invalid") from None

        if length > MAX_BODY_BYTES:
            raise SettingsError(413, "request body is too large")

        return json.loads(self.rfile.read(length).decode("utf-8"))

    def cors_headers(self, *, preflight=False):
        origin = self.headers.get("Origin")
        if not origin or not is_allowed_origin(origin):
            return {}

        headers = {
            "Access-Control-Allow-Origin": origin,
            "Vary": "Origin",
        }

        if preflight:
            headers.update({
                "Access-Control-Allow-Methods": "PUT, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
            })

        return headers

    def send_empty(self, status, *, extra_headers=None):
        headers = dict(extra_headers or {})
        self.send_response(status)
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.send_header("Content-Length", "0")
        for key, value in headers.items():
            self.send_header(key, value)
        self.end_headers()

    def send_json(self, status, payload, *, extra_headers=None):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        headers = self.cors_headers()
        headers.update(extra_headers or {})

        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.send_header("Content-Length", str(len(body)))
        for key, value in headers.items():
            self.send_header(key, value)
        self.end_headers()
        self.wfile.write(body)


def main():
    server = ThreadingHTTPServer((HOST, PORT), SettingsHandler)
    server.serve_forever()


if __name__ == "__main__":
    main()
