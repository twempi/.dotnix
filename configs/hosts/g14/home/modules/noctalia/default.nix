{
  lib,
  pkgs,
  ...
}: let
  gpuMode = pkgs.writeShellApplication {
    name = "noctalia-gpu-mode";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      gnused
      libnotify
      supergfxctl
    ];
    text = ''
      usage() {
        printf 'usage: noctalia-gpu-mode <Integrated|Hybrid|AsusMuxDgpu>\n' >&2
      }

      notify() {
        notify-send "$1" "$2" --app-name=noctalia-gpu-mode 2>/dev/null || true
      }

      normalize() {
        printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g'
      }

      case "''${1:-}" in
        Integrated|Hybrid|AsusMuxDgpu)
          target="$1"
          ;;
        *)
          usage
          notify "GPU mode failed" "Expected Integrated, Hybrid, or AsusMuxDgpu"
          exit 2
          ;;
      esac

      if ! current="$(supergfxctl --get 2>&1)"; then
        notify "GPU mode failed" "$current"
        printf '%s\n' "$current" >&2
        exit 1
      fi

      if ! supported="$(supergfxctl --supported 2>&1)"; then
        notify "GPU mode failed" "$supported"
        printf '%s\n' "$supported" >&2
        exit 1
      fi

      target_norm="$(normalize "$target")"
      supported_norm="$(normalize "$supported")"

      if ! printf '%s' "$supported_norm" | grep -q "$target_norm"; then
        message="$target is not reported by supergfxctl --supported"
        notify "GPU mode unsupported" "$message"
        printf '%s\n' "$message" >&2
        exit 1
      fi

      if ! output="$(supergfxctl --mode "$target" 2>&1)"; then
        notify "GPU mode failed" "$output"
        printf '%s\n' "$output" >&2
        exit 1
      fi

      pending_action="$(supergfxctl --pend-action 2>/dev/null || true)"
      pending_mode="$(supergfxctl --pend-mode 2>/dev/null || true)"

      body="Requested: $target"
      if [ -n "$current" ]; then
        body="$body
Current: $current"
      fi
      if [ -n "$output" ]; then
        body="$body
Output: $output"
      fi
      if [ -n "$pending_mode" ] && [ "$pending_mode" != "None" ]; then
        body="$body
Pending: $pending_mode"
      fi
      if [ -n "$pending_action" ] && [ "$pending_action" != "None" ]; then
        body="$body
Action: $pending_action"
      fi

      notify "GPU mode switched" "$body"
    '';
  };

  gpuAction = label: mode: {
    action = "command";
    command = "${lib.getExe gpuMode} ${mode}";
    inherit label;
    glyph = "device-desktop-cog";
    variant = "outline";
  };
in {
  home.packages = [
    gpuMode
  ];

  edward.noctalia.extraSessionActions = [
    (gpuAction "GPU Integrated" "Integrated")
    (gpuAction "GPU Hybrid" "Hybrid")
    (gpuAction "GPU AMDMuxDgpu" "AsusMuxDgpu")
  ];
}
