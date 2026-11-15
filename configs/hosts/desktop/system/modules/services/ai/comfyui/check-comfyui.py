#!/usr/bin/env python3
"""Validate starter node availability and model choices without generating images."""
import argparse
import json
from pathlib import Path
import sys
import urllib.request


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="http://127.0.0.1:8188")
    parser.add_argument("--workflow", type=Path, required=True)
    args = parser.parse_args()
    workflow = json.loads(args.workflow.read_text())
    with urllib.request.urlopen(args.url.rstrip("/") + "/object_info", timeout=30) as response:
        info = json.load(response)
    errors = []
    for node in workflow.values():
        kind = node["class_type"]
        if kind not in info:
            errors.append(f"Missing node: {kind}; check ComfyUI/custom-node version and startup logs")
            continue
        schema = info[kind].get("input", {})
        inputs = node["inputs"]
        for name, definition in schema.get("required", {}).items():
            if name not in inputs:
                errors.append(f"Missing required input: {kind}.{name}")
        for name in ("unet_name", "clip_name", "vae_name", "type", "sampler_name"):
            if name not in inputs:
                continue
            definition = schema.get("required", {}).get(name) or schema.get("optional", {}).get(name)
            if definition and isinstance(definition[0], list) and inputs[name] not in definition[0]:
                errors.append(f"Unavailable choice: {kind}.{name} = {inputs[name]!r}")
    if errors:
        print("Not ready:")
        print("\n".join(f"- {message}" for message in errors))
        return 1
    print("Starter nodes and all three model filenames are available.")
    print("Schema check passed; image-generation quality/VRAM still require a first run.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as exc:
        print(f"Cannot check ComfyUI: {exc}", file=sys.stderr)
        raise SystemExit(1)
