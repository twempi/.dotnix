#!/usr/bin/env python3
"""Resolve one HF revision, download exact declared files, and verify SHA-256."""
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import time
import urllib.parse
import urllib.request

USER_AGENT = "declarative-comfyui-flux/1.0"


def request(url, headers=None):
    return urllib.request.urlopen(
        urllib.request.Request(
            url, headers={"User-Agent": USER_AGENT, **(headers or {})}
        ), timeout=120
    )


def digest(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(4 * 1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def download(url, destination, expected_size, expected_sha):
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.is_file() and destination.stat().st_size == expected_size:
        print(f"Verifying existing {destination.name}", flush=True)
        if digest(destination) == expected_sha:
            print(f"Already verified: {destination.name}", flush=True)
            return

    partial = destination.with_name(destination.name + ".part")
    offset = partial.stat().st_size if partial.exists() else 0
    if offset > expected_size:
        partial.unlink()
        offset = 0
    if offset < expected_size:
        headers = {"Range": f"bytes={offset}-"} if offset else {}
        with request(url, headers) as response:
            if response.status == 206:
                content_range = response.headers.get("Content-Range", "")
                if not content_range.startswith(f"bytes {offset}-"):
                    raise RuntimeError(f"Unexpected Content-Range: {content_range}")
            elif response.status == 200:
                # Some servers ignore Range: restart rather than append twice.
                offset = 0
            else:
                raise RuntimeError(f"Unexpected HTTP status: {response.status}")

            print(f"Downloading {destination.name}: {offset / 1e9:.2f}/{expected_size / 1e9:.2f} GB", flush=True)
            received, last_log = offset, time.monotonic()
            with partial.open("ab" if offset else "wb") as out:
                while chunk := response.read(4 * 1024 * 1024):
                    received += len(chunk)
                    if received > expected_size:
                        raise RuntimeError("Response is larger than declared model size")
                    out.write(chunk)
                    if time.monotonic() - last_log >= 10:
                        print(f"{destination.name}: {received / expected_size:.0%} ({received / 1e9:.2f}/{expected_size / 1e9:.2f} GB)", flush=True)
                        last_log = time.monotonic()

    if partial.stat().st_size != expected_size:
        raise RuntimeError(f"Incomplete download: {destination.name}; retry will resume")
    print(f"Verifying SHA-256: {destination.name}", flush=True)
    if digest(partial) != expected_sha:
        partial.unlink()
        raise RuntimeError(f"SHA-256 mismatch: {destination.name}; retry will start again")
    partial.chmod(0o640)
    os.replace(partial, destination)
    print(f"Ready: {destination.name}", flush=True)


def main(config_path):
    config = json.loads(Path(config_path).read_text())
    root = Path(config["data_directory"]).resolve()
    root.mkdir(parents=True, exist_ok=True)
    repo = config["repository"]
    repo_url = urllib.parse.quote(repo, safe="/")
    revision = urllib.parse.quote(config["revision"], safe="")
    with request(f"https://huggingface.co/api/models/{repo_url}/revision/{revision}?blobs=true") as response:
        metadata = json.load(response)

    commit = metadata["sha"]
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise RuntimeError("Hugging Face did not return a valid commit SHA")
    print(f"Resolved {repo}@{config['revision']} to {commit}", flush=True)
    siblings = {item["rfilename"]: item for item in metadata.get("siblings", [])}
    receipt = {"repository": repo, "requested_revision": config["revision"], "resolved_revision": commit, "files": []}

    # Validate every metadata entry before starting any multi-GB downloads.
    selected = []
    for item in config["files"]:
        source = item["source"]
        entry = siblings.get(source)
        if entry is None:
            raise RuntimeError(f"Declared file is missing from repository: {source}")
        lfs = entry.get("lfs") or {}
        sha = lfs.get("sha256") or lfs.get("oid", "").removeprefix("sha256:")
        size = lfs.get("size") or entry.get("size")
        if not re.fullmatch(r"[0-9a-f]{64}", sha) or not isinstance(size, int) or size <= 0:
            raise RuntimeError(f"No trusted LFS SHA-256/size metadata for {source}")
        destination = (root / item["destination"]).resolve()
        if not destination.is_relative_to(root):
            raise RuntimeError("Model destination escapes the configured data directory")
        selected.append((source, destination, size, sha))

    for source, destination, size, sha in selected:
        url = f"https://huggingface.co/{repo_url}/resolve/{commit}/{urllib.parse.quote(source, safe='/')}"
        download(url, destination, size, sha)
        receipt["files"].append({"source": source, "destination": str(destination.relative_to(root)), "size": size, "sha256": sha})

    pending = root / "model-receipt.json.part"
    pending.write_text(json.dumps(receipt, indent=2) + "\n")
    pending.chmod(0o640)
    os.replace(pending, root / "model-receipt.json")
    print("ALL MODEL FILES VERIFIED AND READY. Refresh ComfyUI, then load flux-klein-starter.json.", flush=True)


if __name__ == "__main__":
    try:
        main(sys.argv[1])
    except Exception as exc:
        print(f"Model provisioning failed: {exc}", file=sys.stderr, flush=True)
        raise SystemExit(1)
