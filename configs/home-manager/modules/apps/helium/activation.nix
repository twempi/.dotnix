{
  heliumProfileDir,
  lib,
  pkgs,
  profilePreferences,
}:
lib.hm.dag.entryAfter ["writeBoundary"] ''
  prefs_dir="$HOME/.config/net.imput.helium/${heliumProfileDir}"
  prefs_file="$prefs_dir/Preferences"
  nix_prefs='${builtins.toJSON profilePreferences}'

  run mkdir -p "$prefs_dir"

  if [ -f "$prefs_file" ]; then
    merged=$(${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$prefs_file" - <<< "$nix_prefs")
    if [ -n "$merged" ]; then
      printf '%s\n' "$merged" > "$prefs_file"
    fi
  else
    printf '%s\n' "$nix_prefs" > "$prefs_file"
  fi

  local_state_dir="$HOME/.config/net.imput.helium"
  local_state_file="$local_state_dir/Local State"
  local_state_fallback='{"browser":{"enabled_labs_experiments":["vertical-tabs@1"]}}'

  run mkdir -p "$local_state_dir"

  if [ -f "$local_state_file" ]; then
    merged=$(${pkgs.jq}/bin/jq '
      .browser.enabled_labs_experiments =
        (((.browser.enabled_labs_experiments // []) + ["vertical-tabs@1"]) | unique)
    ' "$local_state_file")
    if [ -n "$merged" ]; then
      printf '%s\n' "$merged" > "$local_state_file"
    fi
  else
    printf '%s\n' "$local_state_fallback" > "$local_state_file"
  fi

''
