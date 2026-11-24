hl.monitor({ output = "", mode = "highrr", position = "auto", scale = "auto" })
hl.monitor({ output = "eDP-1", mode = "highrr", position = "auto", scale = 1.8 })
hl.monitor({ output = "desc:Samsung Electric Company Odyssey G8", mode = "highrr", position = "auto", scale = 1.25 })

-- Dux's dark "purple" theme: surfaceVariant and surfaceContainerHigh (its widget pills)
local activeColor = "rgb(49454e)"
local inactiveColor = "rgb(2b292f)"

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    col = {
      active_border = activeColor,
      inactive_border = inactiveColor,
    },
  },
  group = {
    -- Stacked windows use these instead of the general border colors
    col = {
      border_active = activeColor,
      border_inactive = inactiveColor,
    },
    groupbar = {
      render_titles = false,
      height = 1,
      indicator_height = 3,
      gaps_in = 0,
      gaps_out = 0,
      keep_upper_gap = false,
      rounding = 0,
      col = {
        active = activeColor,
        inactive = inactiveColor,
      },
    },
  },
  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },
  input = {
    repeat_delay = 250,
    repeat_rate = 30,
  },
  misc = {
    vrr = "fullscreen",
    -- XDG_CURRENT_DESKTOP is Hyprland:KDE on purpose; see ~/.config/uwsm/env-hyprland
    disable_xdg_env_checks = true,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
  },
  -- X11 apps render at full resolution instead of being stretched; each one scales itself,
  -- e.g. Steam via its Accessibility settings
  xwayland = {
    force_zero_scaling = true,
  },
})

-- No gaps around a lone tiled or maximized window, except 1px at the top: at asgard's 1.8 scale
-- the Dux bar draws slightly past its reserved space and would cover the top border
local loneWindowGaps = { top = 1, right = 0, bottom = 0, left = 0 }
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = loneWindowGaps, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = loneWindowGaps, gaps_in = 0 })

hl.layer_rule({ match = { namespace = "dms" }, no_anim = true })

-- Speed is in tenths of a second
hl.animation({ leaf = "global", enabled = true, speed = 1.5, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = false })

local mod = "SUPER"

local function app(cmd)
  return hl.dsp.exec_cmd("uwsm app -- " .. cmd)
end

-- Launched at login; each app's first window opens on its workspace
local startupApps = {
  { workspace = 1, desktop = "helium.desktop" },
  { workspace = 2, desktop = "com.mitchellh.ghostty.desktop", class = "com.mitchellh.ghostty" },
  { workspace = 3, desktop = "slack.desktop", class = "slack" },
  { workspace = 4, desktop = "signal.desktop", class = "signal" },
  { workspace = 5, desktop = "spotify.desktop", class = "spotify" },
  { workspace = 6, desktop = "org.keepassxc.KeePassXC.desktop", class = "org.keepassxc.KeePassXC" },
}

for _, startupApp in ipairs(startupApps) do
  hl.workspace_rule({ workspace = tostring(startupApp.workspace), persistent = true })
end

hl.window_rule({ match = { class = "^(helium)$" }, workspace = "1 silent" })

local function stackWorkspace(workspace, anchor)
  local windows = {}
  for _, window in ipairs(hl.get_workspace_windows(workspace)) do
    if not window.floating then
      table.insert(windows, window)
    end
  end
  if #windows < 2 then
    return
  end

  local group
  for _, window in ipairs(windows) do
    if window.group then
      group = window.group
      break
    end
  end
  if not group then
    anchor = anchor or windows[1]
    hl.dispatch(hl.dsp.group.toggle({ window = anchor }))
    group = anchor.group
  end

  for _, window in ipairs(windows) do
    if not window.group then
      group:add(window)
    end
  end
end

-- Moving a window from window.open doesn't stick, so use one-shot window rules instead
local startupRules = {}
local stackingStartupHelium = false

hl.on("hyprland.start", function()
  -- Plasma's KWallet unlock service doesn't start outside Plasma
  hl.exec_cmd("systemctl --user start plasma-kwallet-pam.service")

  hl.dispatch(hl.dsp.focus({ workspace = 2 }))
  stackingStartupHelium = true
  hl.timer(function()
    stackingStartupHelium = false
  end, { timeout = 30000, type = "oneshot" })

  for _, startupApp in ipairs(startupApps) do
    if startupApp.class then
      startupRules[startupApp.class] = hl.window_rule({
        match = { class = "^" .. startupApp.class .. "$" },
        workspace = startupApp.workspace .. " silent",
      })
    end
    hl.dispatch(app(startupApp.desktop))
  end
end)

hl.on("window.open", function(window)
  local rule = startupRules[window.class]
  if rule then
    startupRules[window.class] = nil
    rule:set_enabled(false)
  end

  -- Stack the Helium windows restored at login once Hyprland has placed each one
  if stackingStartupHelium and window.class == "helium" then
    local workspace = window.workspace
    hl.timer(function()
      stackWorkspace(workspace)
    end, { timeout = 100, type = "oneshot" })
  end
end)

-- Session
hl.bind(mod .. " + Return", app("ghostty"))
hl.bind(mod .. " + E", app("dolphin"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("uwsm stop"))

-- Dux Shell
local function dms(args)
  return hl.dsp.exec_cmd("dms ipc call " .. args)
end
hl.bind(mod .. " + space", dms("spotlight toggle"))
hl.bind(mod .. " + comma", dms("settings focusOrToggle"))
hl.bind("CTRL + ALT + L", dms("lock lock"))
hl.bind("Print", hl.dsp.exec_cmd("dms screenshot"))

-- Window state
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + CTRL + Escape", hl.dsp.window.kill())
hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + Page_Up", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + Page_Down", hl.dsp.window.move({ workspace = "special:minimized" }))
hl.bind(mod .. " + BackSpace", hl.dsp.workspace.toggle_special("minimized"))

hl.bind(mod .. " + SHIFT + grave", function()
  local active = hl.get_active_window()
  if active and active.group then
    hl.dispatch(hl.dsp.group.toggle({ window = active }))
  else
    local anchor = active and not active.floating and active or nil
    stackWorkspace(hl.get_active_workspace(), anchor)
  end
end)

hl.bind(mod .. " + grave", function()
  local active = hl.get_active_window()
  if active and active.group then
    hl.dispatch(hl.dsp.group.next())
  else
    hl.dispatch(hl.dsp.window.cycle_next())
  end
end)

hl.bind(mod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))

-- Focus and movement
for _, dir in ipairs({ "left", "right", "up", "down" }) do
  hl.bind(mod .. " + ALT + " .. dir, hl.dsp.focus({ direction = dir }))
  hl.bind("CTRL + ALT + " .. dir, hl.dsp.window.move({ direction = dir }))
end
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.move({ monitor = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ monitor = "right" }))

-- Workspaces
for i = 1, 9 do
  hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + 0", dms("hypr toggleOverview"))
hl.bind(mod .. " + CTRL + left", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + CTRL + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + CTRL + SHIFT + left", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(mod .. " + CTRL + SHIFT + right", hl.dsp.window.move({ workspace = "e+1" }))

-- Mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Media keys; Dux shows an on-screen indicator for volume and brightness
local held = { locked = true, repeating = true }
local locked = { locked = true }
hl.bind("XF86AudioRaiseVolume", dms("audio increment 5"), held)
hl.bind("XF86AudioLowerVolume", dms("audio decrement 5"), held)
hl.bind("SHIFT + XF86AudioRaiseVolume", dms("audio increment 1"), held)
hl.bind("SHIFT + XF86AudioLowerVolume", dms("audio decrement 1"), held)
hl.bind("XF86AudioMute", dms("audio mute"), locked)
hl.bind("XF86AudioMicMute", dms("audio micmute"), locked)
hl.bind(mod .. " + XF86AudioMute", dms("audio micmute"), locked)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), locked)
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), locked)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), locked)
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), locked)
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), locked)
hl.bind("XF86MonBrightnessUp", dms([[brightness increment 5 ""]]), held)
hl.bind("XF86MonBrightnessDown", dms([[brightness decrement 5 ""]]), held)
hl.bind("SHIFT + XF86MonBrightnessUp", dms([[brightness increment 1 ""]]), held)
hl.bind("SHIFT + XF86MonBrightnessDown", dms([[brightness decrement 1 ""]]), held)
