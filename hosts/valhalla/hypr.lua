-- Hyprland config for valhalla, loaded at the end of home/.config/hypr/hyprland.lua

hl.monitor({ output = "desc:Samsung Electric Company Odyssey G8", mode = "highrr", position = "auto", scale = 1.25 })

require("startup").launch({
  { workspace = 1, desktop = "helium.desktop" },
  { workspace = 2, desktop = "com.mitchellh.ghostty.desktop", class = "com.mitchellh.ghostty" },
  { workspace = 3, desktop = "slack.desktop", class = "slack" },
  { workspace = 4, desktop = "fastmail.desktop", class = "com.fastmail.Fastmail" },
  { workspace = 4, desktop = "signal.desktop", class = "signal" },
  { workspace = 5, desktop = "spotify.desktop", class = "spotify" },
  { workspace = 6, desktop = "org.keepassxc.KeePassXC.desktop", class = "org.keepassxc.KeePassXC" },
})
