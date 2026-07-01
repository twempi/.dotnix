{
  lib,
  pkgs,
  ...
}: let
  windowManagers = [
    "hyprland"
    "sway"
    "mango"
  ];

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

  gpuSwitcherManifest = pkgs.writeText "noctalia-gpu-switcher-plugin.toml" ''
    id = "edward/gpu-switcher"
    name = "GPU Switcher"
    version = "1.0.0"
    min_noctalia = "5.0.0"
    author = "Edward"
    icon = "device-desktop-cog"
    description = "Switch ASUS GPU modes with supergfxctl."

    [[panel]]
    id = "main"
    entry = "panel.luau"
    width = 420
    height = 260
    placement = "floating"
    position = "center"
  '';

  gpuSwitcherPanel = pkgs.writeText "noctalia-gpu-switcher-panel.luau" ''
    local supergfxctlCommand = "${pkgs.supergfxctl}/bin/supergfxctl"
    local gpuModeCommand = "${lib.getExe gpuMode}"

    local modes = {
      {
        label = "Integrated",
        mode = "Integrated",
        callback = "chooseIntegrated",
        aliases = { "Integrated" },
      },
      {
        label = "Hybrid",
        mode = "Hybrid",
        callback = "chooseHybrid",
        aliases = { "Hybrid" },
      },
      {
        label = "AMDMuxDgpu",
        mode = "AsusMuxDgpu",
        callback = "chooseDgpu",
        aliases = { "AsusMuxDgpu", "AMDMuxDgpu" },
      },
    }

    local current = ""
    local supported = ""
    local status = "Checking GPU modes"
    local loading = false
    local busy = false

    local function trim(value)
      local stripped = (value or ""):gsub("^%s+", "")
      stripped = stripped:gsub("%s+$", "")
      return stripped
    end

    local function normalize(value)
      local cleaned = (value or ""):lower():gsub("[^a-z0-9]", "")
      return cleaned
    end

    local function resultMessage(result, fallback)
      if result.timedOut then
        return fallback .. " timed out"
      end

      local message = trim(result.stderr)
      if message == "" then
        message = trim(result.stdout)
      end
      if message == "" then
        message = fallback
      end
      return message
    end

    local function hasAlias(value, mode)
      local normalizedValue = normalize(value)
      for _, alias in ipairs(mode.aliases) do
        if normalizedValue == normalize(alias) then
          return true
        end
      end
      return false
    end

    local function supportedMode(mode)
      local supportedNorm = normalize(supported)
      if supportedNorm == "" then
        return false
      end

      for _, alias in ipairs(mode.aliases) do
        if supportedNorm:find(normalize(alias), 1, true) ~= nil then
          return true
        end
      end
      return false
    end

    local function statusColor()
      local lower = status:lower()
      if lower:find("failed", 1, true) ~= nil or lower:find("unable", 1, true) ~= nil then
        return "error"
      end
      if busy then
        return "primary"
      end
      return "on_surface_variant"
    end

    local function currentStatus()
      if current == "" then
        return "Current: Unknown"
      end
      return "Current: " .. current
    end

    local function modeButton(mode)
      local selected = hasAlias(current, mode)
      local enabled = supportedMode(mode) and not loading and not busy

      return ui.button({
        key = mode.mode,
        text = mode.label,
        glyph = "device-desktop-cog",
        variant = selected and "primary" or "outline",
        enabled = enabled,
        selected = selected,
        onClick = mode.callback,
        height = 44,
      })
    end

    function render()
      local children = {
        ui.row({ gap = 10, align = "center" }, {
          ui.glyph({ name = "device-desktop-cog", size = 24, color = "primary" }),
          ui.label({
            text = "GPU Mode",
            fontSize = 20,
            fontWeight = "bold",
            color = "on_surface",
            flexGrow = 1,
          }),
        }),
        ui.label({
          key = "status",
          text = status,
          fontSize = 13,
          color = statusColor(),
          maxLines = 3,
        }),
        ui.separator({ orientation = "horizontal", thickness = 1, spacing = 2 }),
      }

      for _, mode in ipairs(modes) do
        table.insert(children, modeButton(mode))
      end

      panel.render(ui.column({ padding = 18, gap = 12, align = "stretch" }, children))
    end

    local function querySupported()
      local launched = noctalia.runAsync(supergfxctlCommand .. " --supported", function(result)
        loading = false
        if result.exitCode ~= 0 or result.timedOut then
          supported = ""
          status = "Unable to read supported GPU modes: " .. resultMessage(result, "supergfxctl --supported failed")
          render()
          return
        end

        supported = trim(result.stdout)
        status = currentStatus()
        render()
      end, 5000)

      if not launched then
        loading = false
        supported = ""
        status = "Unable to query supported GPU modes"
        render()
      end
    end

    function refresh()
      loading = true
      busy = false
      current = ""
      supported = ""
      status = "Checking GPU modes"
      render()

      local launched = noctalia.runAsync(supergfxctlCommand .. " --get", function(result)
        if result.exitCode ~= 0 or result.timedOut then
          loading = false
          status = "Unable to read current GPU mode: " .. resultMessage(result, "supergfxctl --get failed")
          render()
          return
        end

        current = trim(result.stdout)
        status = currentStatus()
        querySupported()
      end, 5000)

      if not launched then
        loading = false
        status = "Unable to query current GPU mode"
        render()
      end
    end

    local function switchMode(target, label)
      if busy or loading then
        return
      end

      busy = true
      status = "Switching to " .. label
      render()

      local launched = noctalia.runAsync(gpuModeCommand .. " " .. target, function(result)
        busy = false
        if result.exitCode == 0 and not result.timedOut then
          panel.close()
          return
        end

        status = "Switch failed: " .. resultMessage(result, "noctalia-gpu-mode failed")
        render()
      end, 60000)

      if not launched then
        busy = false
        status = "Switch failed: unable to start noctalia-gpu-mode"
        render()
      end
    end

    function chooseIntegrated()
      switchMode("Integrated", "Integrated")
    end

    function chooseHybrid()
      switchMode("Hybrid", "Hybrid")
    end

    function chooseDgpu()
      switchMode("AsusMuxDgpu", "AMDMuxDgpu")
    end

    function onOpen()
      refresh()
    end

    render()
  '';

  gpuSwitcherFiles =
    lib.mkMerge (
      map (wm: {
        "noctalia-${wm}/noctalia/plugins/gpu-switcher/plugin.toml".source = gpuSwitcherManifest;
        "noctalia-${wm}/noctalia/plugins/gpu-switcher/panel.luau".source = gpuSwitcherPanel;
      })
      windowManagers
    );
in {
  home.packages = [
    gpuMode
  ];

  edward.noctalia.extraEnabledPlugins = [
    "edward/gpu-switcher"
  ];

  xdg.dataFile = gpuSwitcherFiles;
}
