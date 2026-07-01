--!nonstrict

local SUPERGFXCTL = "supergfxctl"

local MODES = {
  { mode = "Integrated", label = "Integrated", glyph = "battery-eco" },
  { mode = "Hybrid", label = "Hybrid", glyph = "switch" },
  { mode = "AsusMuxDgpu", label = "AMDMuxDgpu", glyph = "device-desktop-cog" },
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
    body = body .. "\nPending mode: " .. trim(pendingMode)
  end

  body = body .. "\n" .. actionMessage(pendingAction)
  noctalia.notify("GPU mode switched", body)
end

local function supportedRows(query, filter, current, supported)
  local rows = {}
  local currentNorm = normalize(current)
  local supportedNorm = normalize(supported)

  for _, mode in MODES do
    local modeNorm = normalize(mode.mode)

    if supportedNorm:find(modeNorm, 1, true) then
      local searchText = mode.label .. " " .. mode.mode
      local score = nil

      if filter ~= "" then
        score = noctalia.fuzzyScore(filter, searchText)
      end

      if filter == "" or score ~= nil then
        local isCurrent = currentNorm == modeNorm
        local subtitle = "Switch to " .. mode.label

        if isCurrent then
          subtitle = "Current mode"
        end

        table.insert(rows, {
          id = mode.mode,
          title = mode.label,
          subtitle = subtitle,
          glyph = mode.glyph,
          score = score,
        })
      end
    end
  end

  if #rows == 0 then
    table.insert(rows, {
      id = "__empty",
      title = "No matching GPU modes",
      subtitle = query == "" and "No supported GPU modes reported" or "Try another filter",
      glyph = "alert-circle",
    })
  end

  return rows
end

local function showError(query, message)
  launcher.setResults(query, {
    {
      id = "__error",
      title = "GPU switcher unavailable",
      subtitle = message,
      glyph = "alert-circle",
    },
  })
end

function onQuery(query)
  local filter = trim(query)

  launcher.setResults(query, {
    {
      id = "__loading",
      title = "Reading GPU modes...",
      subtitle = "supergfxctl --get / --supported",
      glyph = "loader",
    },
  })

  if not supergfx("--get", function(currentResult)
    if currentResult.exitCode ~= 0 then
      showError(query, commandOutput(currentResult))
      return
    end

    local current = commandOutput(currentResult)

    if not supergfx("--supported", function(supportedResult)
      if supportedResult.exitCode ~= 0 then
        showError(query, commandOutput(supportedResult))
        return
      end

      launcher.setResults(query, supportedRows(query, filter, current, commandOutput(supportedResult)))
    end) then
      showError(query, "Failed to run supergfxctl --supported")
    end
  end) then
    showError(query, "Failed to run supergfxctl --get")
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
    end) then
      notifySwitched(label, pendingMode, "")
    end
  end) then
    notifySwitched(label, "", "")
  end
end

function onActivate(id)
  if id == "__loading" or id == "__error" or id == "__empty" or id == "" then
    return
  end

  local selected = modeById(id)

  if selected == nil then
    noctalia.notifyError("GPU switch failed", "Unknown selection: " .. tostring(id))
    return
  end

  if not supergfx("--get", function(currentResult)
    if currentResult.exitCode ~= 0 then
      noctalia.notifyError("GPU switch failed", commandOutput(currentResult))
      return
    end

    if normalize(commandOutput(currentResult)) == normalize(selected.mode) then
      noctalia.notify("GPU mode unchanged", selected.label .. " is already active.")
      return
    end

    if not supergfx("--mode " .. selected.mode, function(switchResult)
      if switchResult.exitCode ~= 0 then
        noctalia.notifyError("GPU switch failed", commandOutput(switchResult))
        return
      end

      readPendingAndNotify(selected.label)
    end) then
      noctalia.notifyError("GPU switch failed", "Failed to run supergfxctl --mode " .. selected.mode)
    end
  end) then
    noctalia.notifyError("GPU switch failed", "Failed to run supergfxctl --get")
  end
end
