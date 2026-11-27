-- == Settings ==

-- Hosts add rules for their own monitors in hosts/<host>/hypr.lua
hl.monitor({ output = "", mode = "highrr", position = "auto", scale = "auto" })

-- Dux "blue" theme colors
local activeColor = "rgb(42474e)"
local inactiveColor = "rgb(272a2f)"

hl.config({
  general = {
    gaps_in = 7,
    gaps_out = 14,
    col = {
      active_border = activeColor,
      inactive_border = inactiveColor,
    },
  },
  group = {
    -- Stacked windows have their own border colors
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
  decoration = {
    rounding = 6,
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
    vrr = 1,
    focus_on_activate = true,
    -- XDG_CURRENT_DESKTOP is Hyprland:KDE on purpose (uwsm/env-hyprland)
    disable_xdg_env_checks = true,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
  },
  render = {
    cm_auto_hdr = 0,
  },
  -- Keep X11 apps sharp; they scale themselves (Steam: Accessibility settings)
  xwayland = {
    force_zero_scaling = true,
  },
})

-- No gaps around a lone window
local loneWindowGaps = { top = 0, right = 0, bottom = 0, left = 0 }
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = loneWindowGaps, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = loneWindowGaps, gaps_in = 0 })

hl.layer_rule({ match = { namespace = "dms" }, no_anim = true })

-- Speed is in tenths of a second
hl.animation({ leaf = "global", enabled = true, speed = 1.5, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = false })

-- == Helpers ==

local mod = "SUPER"

local function app(cmd)
  return hl.dsp.exec_cmd("uwsm app -- " .. cmd)
end

-- Dux Shell IPC
local function dms(args)
  return hl.dsp.exec_cmd("dms ipc call " .. args)
end

local function playerctl(args)
  return hl.dsp.exec_cmd("playerctl " .. args)
end

local stackWorkspace = require("stack")

-- == Login ==

-- Host configs start their own apps through startup.lua
hl.on("hyprland.start", function()
  -- KWallet's PAM unlock only autostarts in Plasma
  hl.exec_cmd("systemctl --user start plasma-kwallet-pam.service")

  hl.dispatch(hl.dsp.focus({ workspace = 2 }))
end)

-- == Binds ==

-- Session
hl.bind(mod .. " + Return", app("ghostty"))
hl.bind(mod .. " + E", app("dolphin"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("uwsm stop"))

-- Dux Shell
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

-- Stacking
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

-- Focus and movement
for _, dir in ipairs({ "left", "right", "up", "down" }) do
  hl.bind(mod .. " + ALT + " .. dir, hl.dsp.focus({ direction = dir }))
  hl.bind("CTRL + ALT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

-- Workspaces
for i = 1, 9 do
  hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + 0", dms("hypr toggleOverview"))
for dir, workspace in pairs({ left = "e-1", right = "e+1" }) do
  hl.bind(mod .. " + CTRL + " .. dir, hl.dsp.focus({ workspace = workspace }))
  hl.bind(mod .. " + CTRL + SHIFT + " .. dir, hl.dsp.window.move({ workspace = workspace }))
  hl.bind(mod .. " + SHIFT + " .. dir, hl.dsp.window.move({ monitor = dir }))
end

-- Mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Media keys; volume and brightness go through Dux for its OSD
local held = { locked = true, repeating = true }
local locked = { locked = true }
for prefix, step in pairs({ [""] = 5, ["SHIFT + "] = 1 }) do
  hl.bind(prefix .. "XF86AudioRaiseVolume", dms("audio increment " .. step), held)
  hl.bind(prefix .. "XF86AudioLowerVolume", dms("audio decrement " .. step), held)
  hl.bind(prefix .. "XF86MonBrightnessUp", dms("brightness increment " .. step .. ' ""'), held)
  hl.bind(prefix .. "XF86MonBrightnessDown", dms("brightness decrement " .. step .. ' ""'), held)
end
hl.bind("XF86AudioMute", dms("audio mute"), locked)
hl.bind("XF86AudioMicMute", dms("audio micmute"), locked)
hl.bind(mod .. " + XF86AudioMute", dms("audio micmute"), locked)
hl.bind("XF86AudioPlay", playerctl("play-pause"), locked)
hl.bind("XF86AudioPause", playerctl("play-pause"), locked)
hl.bind("XF86AudioNext", playerctl("next"), locked)
hl.bind("XF86AudioPrev", playerctl("previous"), locked)
hl.bind("XF86AudioStop", playerctl("stop"), locked)

-- == Super+Tab workspace switcher ==

-- Super+Tab walks workspaces in most recently used order while Super is held, and
-- Super+Shift+Tab walks back. Lua can only see Hyprland's previous workspace, so the
-- order is tracked here. Workspaces passed during a walk don't count as used; only the
-- one you land on does.
local recentWorkspaces = {} -- addressable names, most recent first
local workspaceWalk

local function markUsed(workspace)
  if not workspace or workspace.special then
    return
  end
  local name = workspace.addressable_name
  for i, recent in ipairs(recentWorkspaces) do
    if recent == name then
      table.remove(recentWorkspaces, i)
      break
    end
  end
  table.insert(recentWorkspaces, 1, name)
end

-- Seed from window focus history, so a config reload keeps the order
do
  local windows = {}
  for _, window in ipairs(hl.get_windows()) do
    if window.mapped and window.workspace and window.focus_history_id >= 0 then
      table.insert(windows, window)
    end
  end
  table.sort(windows, function(a, b)
    return a.focus_history_id > b.focus_history_id
  end)
  for _, window in ipairs(windows) do
    markUsed(window.workspace)
  end
  markUsed(hl.get_active_workspace())
end

hl.on("workspace.active", function(workspace)
  if not workspaceWalk then
    markUsed(workspace)
  end
end)

-- Existing workspaces, most recently used first; never-visited ones keep Hyprland's order
local function walkOrder()
  local rank = {}
  for i, name in ipairs(recentWorkspaces) do
    rank[name] = i
  end

  local workspaces = {}
  for _, workspace in ipairs(hl.get_workspaces()) do
    if not workspace.special then
      local name = workspace.addressable_name
      table.insert(workspaces, {
        name = name,
        -- A selector rather than the object: an empty workspace is destroyed once left
        target = workspace.id or ("name:" .. name),
        rank = rank[name] or (#recentWorkspaces + #workspaces + 1),
      })
    end
  end
  table.sort(workspaces, function(a, b)
    return a.rank < b.rank
  end)
  return workspaces
end

local function walkWorkspaces(step)
  if not workspaceWalk then
    local workspaces = walkOrder()
    local active = hl.get_active_workspace()
    local index = 0
    for i, workspace in ipairs(workspaces) do
      if active and workspace.name == active.addressable_name then
        index = i
        break
      end
    end
    if #workspaces == 0 or (index > 0 and #workspaces == 1) then
      return
    end
    workspaceWalk = { workspaces = workspaces, index = index }
  end

  local count = #workspaceWalk.workspaces
  if workspaceWalk.index == 0 then
    workspaceWalk.index = step > 0 and 1 or count
  else
    workspaceWalk.index = (workspaceWalk.index - 1 + step) % count + 1
  end
  hl.dispatch(hl.dsp.focus({ workspace = workspaceWalk.workspaces[workspaceWalk.index].target }))
end

hl.bind(mod .. " + Tab", function()
  walkWorkspaces(1)
end)
hl.bind(mod .. " + SHIFT + Tab", function()
  walkWorkspaces(-1)
end)

-- Releasing Super (Super_L 133, Super_R 134; state 0) ends the walk. A release bind on a
-- modifier only fires when it's tapped alone, so watch raw key events instead.
hl.on("input.keyboard.key", function(keycode, _, state)
  if workspaceWalk and state == 0 and (keycode == 133 or keycode == 134) then
    workspaceWalk = nil
    markUsed(hl.get_active_workspace())
  end
end)

-- == Host ==

-- Per-host config from hosts/<host>/hypr.lua, linked to ~/.config/hypr/host.lua. It runs
-- last, so it can override anything above.
pcall(require, "host")
