-- Hyprland config for asgard, loaded at the end of home/.config/hypr/hyprland.lua

hl.monitor({ output = "eDP-1", mode = "highrr", position = "auto", scale = 1.8 })

require("startup").launch({
  { workspace = 1, desktop = "helium.desktop" },
  { workspace = 2, desktop = "com.mitchellh.ghostty.desktop", class = "com.mitchellh.ghostty" },
  { workspace = 3, desktop = "slack.desktop", class = "slack" },
  { workspace = 4, desktop = "fastmail.desktop", class = "com.fastmail.Fastmail" },
  { workspace = 4, desktop = "signal.desktop", class = "signal" },
  { workspace = 5, desktop = "spotify.desktop", class = "spotify" },
  { workspace = 6, desktop = "org.keepassxc.KeePassXC.desktop", class = "org.keepassxc.KeePassXC" },
})
