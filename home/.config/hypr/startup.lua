-- Starts apps at login, each on its workspace. Host configs call launch with their apps.
local stackWorkspace = require("stack")

-- Fastmail and Signal share a workspace; whichever window opens first ends up left
local function keepFastmailLeftOfSignal(workspace)
  local fastmail, signal
  for _, window in ipairs(hl.get_workspace_windows(workspace)) do
    if window.class == "com.fastmail.Fastmail" then
      fastmail = window
    elseif window.class == "signal" then
      signal = window
    end
  end
  if fastmail and signal and fastmail.at.x > signal.at.x then
    hl.dispatch(hl.dsp.window.swap({ window = fastmail, target = signal }))
  end
end

local function launch(apps)
  local persistentWorkspaces = {}
  for _, startupApp in ipairs(apps) do
    persistentWorkspaces[startupApp.workspace] = true
  end
  for workspace in pairs(persistentWorkspaces) do
    hl.workspace_rule({ workspace = tostring(workspace), persistent = true })
  end

  -- One-shot rules: moving a window from window.open doesn't stick
  local startupRules = {}
  -- Helium restores several windows at login, so its rule stays on for a while instead
  local startupHeliumRule

  hl.on("hyprland.start", function()
    startupHeliumRule = hl.window_rule({ match = { class = "^helium$" }, workspace = "1 silent" })
    hl.timer(function()
      startupHeliumRule:set_enabled(false)
      startupHeliumRule = nil
    end, { timeout = 30000, type = "oneshot" })

    for _, startupApp in ipairs(apps) do
      if startupApp.class then
        startupRules[startupApp.class] = hl.window_rule({
          match = { class = "^" .. startupApp.class .. "$" },
          workspace = startupApp.workspace .. " silent",
        })
      end
      hl.dispatch(hl.dsp.exec_cmd("uwsm app -- " .. startupApp.desktop))
    end
  end)

  hl.on("window.open", function(window)
    local rule = startupRules[window.class]
    if rule then
      startupRules[window.class] = nil
      rule:set_enabled(false)
    end
    -- Stack the Helium windows restored at login
    local stack = startupHeliumRule and window.class == "helium"

    if rule or stack then
      local workspace = window.workspace
      -- Wait until the window is placed
      hl.timer(function()
        if rule then
          keepFastmailLeftOfSignal(workspace)
        end
        if stack then
          stackWorkspace(workspace)
        end
      end, { timeout = 100, type = "oneshot" })
    end
  end)
end

return { launch = launch }
