#!/usr/bin/env bash
set -euo pipefail

mmsg dispatch reload_config
noctalia-mango msg config-reload
