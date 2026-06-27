#!/usr/bin/env bash
set -euo pipefail

swaymsg reload
noctalia-sway msg config-reload
