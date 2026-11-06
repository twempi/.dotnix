#!/usr/bin/env bash
set -euo pipefail

swaymsg reload
pkill -USR2 -x waybar || true
swaync-client -R
swaync-client -rs
