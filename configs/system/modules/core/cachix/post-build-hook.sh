set +e

socket="/run/cachix-daemon/socket"
out_paths="${OUT_PATHS:-}"
drv_path="${DRV_PATH:-unknown derivation}"

if [ -z "$out_paths" ]; then
  exit 0
fi

if [ ! -S "$socket" ]; then
  echo "Cachix daemon socket missing at $socket; skipping upload for $drv_path" >&2
  exit 0
fi

# OUT_PATHS is a space-separated list of Nix store paths.
# shellcheck disable=SC2086
cachix daemon push --socket "$socket" $out_paths
status="$?"

if [ "$status" -ne 0 ]; then
  echo "Cachix daemon push failed with status $status for $drv_path" >&2
fi

exit 0
