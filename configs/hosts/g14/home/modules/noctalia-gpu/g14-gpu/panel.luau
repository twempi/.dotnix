--!nonstrict

local SUPERGFXCTL = "supergfxctl"

local MODES = {
  { mode = "Integrated", label = "Integrated", glyph = "battery-eco", callback = "selectIntegrated" },
  { mode = "Hybrid", label = "Hybrid", glyph = "switch", callback = "selectHybrid" },
  { mode = "AsusMuxDgpu", label = "AMDMuxDgpu", glyph = "device-desktop-cog", callback = "selectAsusMuxDgpu" },
}

local state = {
  current = "",
  error = "",
  generation = 0,
  loading = false,
  switching = false,
  switchingLabel = "",
  supported = "",
}

local function trim(value)
  return noctalia.string.trim(tostring(value or ""))
end

local function commandOutput(result)
  local stdout = trim(result.stdout)
  local stderr = trim(result.stderr)

  if stdout ~= "" then
    return stdout
  end

  return stderr
end

local function normalize(value)
  local normalized = ""
  local text = tostring(value or ""):lower()

  for index = 1, #text do
    local char = text:sub(index, index)

    if char:match("%w") then
      normalized = normalized .. char
    end
  end

  return normalized
end

local function supergfx(args, callback)
  return noctalia.runAsync(SUPERGFXCTL .. " " .. args, callback)
end

local function modeById(id)
  for _, mode in MODES do
    if mode.mode == id then
      return mode
    end
  end

  return nil
end

local function modeLabel(value)
  local normalized = normalize(value)

  for _, mode in MODES do
    if normalize(mode.mode) == normalized then
      return mode.label
    end
  end

  local text = trim(value)
  if text == "" then
    return "Unknown"
  end

  return text
end

local function meaningful(value)
  local text = trim(value)
  local normalized = normalize(text)

  return text ~= "" and normalized ~= "unknown"
end

local function actionMessage(pendingAction)
  local action = trim(pendingAction)
  local normalized = normalize(action)

  if normalized == "" or normalized == "unknown" or normalized == "noactionrequired" or normalized == "nothing" then
    return "No action required."
  end

  if normalized:find("logout", 1, true) then
    return "Log out and back in to fully apply the change."
  end

  if normalized:find("reboot", 1, true) then
    return "Reboot to fully apply the change."
  end

  return action
end

local function notifySwitched(label, pendingMode, pendingAction)
  local body = "Requested: " .. label

  if meaningful(pendingMode) then
    body = body .. "\nPending mode: " .. modeLabel(pendingMode)
  end

  body = body .. "\n" .. actionMessage(pendingAction)
  noctalia.notify("GPU mode switched", body)
end

local function supportedModes()
  local modes = {}
  local supportedNorm = normalize(state.supported)

  for _, mode in MODES do
    if supportedNorm:find(normalize(mode.mode), 1, true) then
      table.insert(modes, mode)
    end
  end

  return modes
end

local function statusText()
  if state.switching then
    return "Switching to " .. state.switchingLabel .. "..."
  end

  if state.loading then
    return "Reading GPU modes..."
  end

  if state.error ~= "" then
    return state.error
  end

  if trim(state.current) ~= "" then
    return "Current mode: " .. modeLabel(state.current)
  end

  return "Current mode unknown"
end

local function controlsEnabled()
  return not state.loading and not state.switching
end

local function modeButton(mode)
  local isCurrent = normalize(state.current) == normalize(mode.mode)
  local text = mode.label

  if isCurrent then
    text = text .. " (current)"
  end

  return ui.button({
    key = "mode-" .. mode.mode,
    text = text,
    glyph = mode.glyph,
    variant = isCurrent and "primary" or "outline",
    selected = isCurrent,
    enabled = controlsEnabled() and not isCurrent,
    onClick = mode.callback,
    height = 42,
  })
end

local function modeButtons()
  local children = {}
  local modes = supportedModes()

  if state.loading then
    table.insert(children, ui.label({
      key = "loading",
      text = "Reading supported GPU modes...",
      color = "on_surface_variant",
      fontSize = 13,
      maxLines = 2,
    }))
    return children
  end

  if state.error ~= "" then
    table.insert(children, ui.label({
      key = "error",
      text = "GPU switcher unavailable.",
      color = "error",
      fontSize = 13,
      fontWeight = "medium",
      maxLines = 2,
    }))
    return children
  end

  if #modes == 0 then
    table.insert(children, ui.label({
      key = "empty",
      text = "No supported GPU modes reported.",
      color = "on_surface_variant",
      fontSize = 13,
      maxLines = 2,
    }))
    return children
  end

  for _, mode in modes do
    table.insert(children, modeButton(mode))
  end

  return children
end

local function render()
  panel.render(ui.column({
    padding = 18,
    gap = 12,
    align = "stretch",
  }, {
    ui.row({
      key = "header",
      align = "center",
      gap = 10,
    }, {
      ui.glyph({
        key = "header-icon",
        name = "device-desktop-cog",
        size = 24,
        color = "primary",
      }),
      ui.column({
        key = "header-text",
        gap = 2,
        flexGrow = 1,
      }, {
        ui.label({
          key = "title",
          text = "GPU Mode",
          fontSize = 18,
          fontWeight = "semibold",
          color = "on_surface",
          maxLines = 1,
        }),
        ui.label({
          key = "status",
          text = statusText(),
          fontSize = 12,
          color = state.error ~= "" and "error" or "on_surface_variant",
          maxLines = 2,
        }),
      }),
      ui.button({
        key = "close",
        glyph = "close",
        variant = "ghost",
        enabled = true,
        onClick = "closePanel",
        width = 38,
        height = 34,
      }),
    }),
    ui.separator({
      key = "separator",
      orientation = "horizontal",
      spacing = 2,
      color = "outline",
    }),
    ui.column({
      key = "modes",
      gap = 8,
      align = "stretch",
      flexGrow = 1,
    }, modeButtons()),
    ui.row({
      key = "footer",
      align = "center",
      gap = 8,
      justify = "end",
    }, {
      ui.button({
        key = "refresh",
        text = "Refresh",
        glyph = "refresh",
        variant = "ghost",
        enabled = controlsEnabled(),
        onClick = "refresh",
        height = 34,
      }),
      ui.button({
        key = "done",
        text = "Close",
        glyph = "close",
        variant = "default",
        enabled = true,
        onClick = "closePanel",
        height = 34,
      }),
    }),
  }))
end

local function showError(message)
  local text = trim(message)

  if text == "" then
    text = "supergfxctl did not report an error."
  end

  state.loading = false
  state.switching = false
  state.error = text
  render()
end

function refresh()
  state.generation = state.generation + 1
  local generation = state.generation

  state.loading = true
  state.switching = false
  state.switchingLabel = ""
  state.error = ""
  render()

  if not supergfx("--get", function(currentResult)
    if generation ~= state.generation then
      return
    end

    if currentResult.exitCode ~= 0 then
      showError(commandOutput(currentResult))
      return
    end

    state.current = commandOutput(currentResult)

    if not supergfx("--supported", function(supportedResult)
      if generation ~= state.generation then
        return
      end

      if supportedResult.exitCode ~= 0 then
        showError(commandOutput(supportedResult))
        return
      end

      state.supported = commandOutput(supportedResult)
      state.loading = false
      state.error = ""
      render()
    end) then
      if generation == state.generation then
        showError("Failed to run supergfxctl --supported")
      end
    end
  end) then
    if generation == state.generation then
      showError("Failed to run supergfxctl --get")
    end
  end
end

local function readPendingAndNotify(label)
  if not supergfx("--pend-mode", function(pendingModeResult)
    local pendingMode = ""

    if pendingModeResult.exitCode == 0 then
      pendingMode = commandOutput(pendingModeResult)
    end

    if not supergfx("--pend-action", function(pendingActionResult)
      local pendingAction = ""

      if pendingActionResult.exitCode == 0 then
        pendingAction = commandOutput(pendingActionResult)
      end

      notifySwitched(label, pendingMode, pendingAction)
      panel.close()
    end) then
      notifySwitched(label, pendingMode, "")
      panel.close()
    end
  end) then
    notifySwitched(label, "", "")
    panel.close()
  end
end

local function selectMode(id)
  if state.loading or state.switching then
    return
  end

  local selected = modeById(id)

  if selected == nil then
    noctalia.notifyError("GPU switch failed", "Unknown selection: " .. tostring(id))
    return
  end

  if normalize(state.current) == normalize(selected.mode) then
    noctalia.notify("GPU mode unchanged", selected.label .. " is already active.")
    return
  end

  state.generation = state.generation + 1
  state.switching = true
  state.switchingLabel = selected.label
  state.error = ""
  render()

  if not supergfx("--mode " .. selected.mode, function(switchResult)
    if switchResult.exitCode ~= 0 then
      noctalia.notifyError("GPU switch failed", commandOutput(switchResult))
      state.switching = false
      state.switchingLabel = ""
      state.error = commandOutput(switchResult)
      render()
      return
    end

    readPendingAndNotify(selected.label)
  end) then
    noctalia.notifyError("GPU switch failed", "Failed to run supergfxctl --mode " .. selected.mode)
    state.switching = false
    state.switchingLabel = ""
    state.error = "Failed to run supergfxctl --mode " .. selected.mode
    render()
  end
end

function closePanel()
  panel.close()
end

function selectIntegrated()
  selectMode("Integrated")
end

function selectHybrid()
  selectMode("Hybrid")
end

function selectAsusMuxDgpu()
  selectMode("AsusMuxDgpu")
end

function onOpen()
  refresh()
end

render()
