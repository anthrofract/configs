{ inputs, ... }:
{
  flake.nixosModules.plasma =
    { pkgs, ... }:
    let
      windows95StartupSound = pkgs.fetchurl {
        name = "windows-95-startup.wav";
        url = "https://archive.org/download/windows95_startup_hifi/windows95_startup_hifi.wav";
        hash = "sha256-qdAqPmtD+P0iQdXA7DH1extTsM+O5iHPTq//RnKQ9yc=";
      };
    in
    {
      # Enable the KDE Plasma Desktop Environment.
      services.desktopManager.plasma6.enable = true;
      programs.kdeconnect.enable = true;

      environment.systemPackages = [
        pkgs.kdePackages.plasma-browser-integration
        pkgs.kdePackages.plasma-workspace-wallpapers
        pkgs.kdePackages.sddm-kcm
      ];

      home-manager.sharedModules = [
        (
          { ... }:
          {
            imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

            programs.plasma = {
              enable = true;

              input.keyboard = {
                options = [ "caps:escape" ];
                repeatDelay = 250;
                repeatRate = 30;
              };
              session.sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";

              workspace = {
                lookAndFeel = "org.kde.breezedark.desktop";
              };

              configFile = {
                kwinrc.TabBox = {
                  ApplicationsMode = 1;
                  LayoutName = "big_icons";
                };
                krunnerrc.Plugins."krunner_appstreamEnabled" = false;
                baloofilerc."Basic Settings" = {
                  "Indexing-Enabled" = false;
                };
              };

              kwin = {
                effects = {
                  translucency.enable = true;
                  blur.enable = true;
                };
                nightLight = {
                  enable = true;
                  mode = "times";
                  temperature.night = 5750;
                  time = {
                    morning = "07:00";
                    evening = "19:00";
                  };
                  transitionTime = 30;
                };
              };

              krunner = {
                position = "center";
                shortcuts.launch = "Meta+Alt+Space";
              };

              shortcuts = {
                kwin = {
                  "Edit Tiles" = [ ]; # Free up Meta+T
                  "view_actual_size" = [ ]; # Was Meta+0
                  "Window Fullscreen" = [ ]; # Free up Meta+Z
                  "Window Quick Tile Bottom" = [ "Ctrl+Alt+Down" ]; # Changed from Meta+Down
                  "Window Quick Tile Top" = [ "Ctrl+Alt+Up" ]; # Changed from Meta+Up
                  "Window Quick Tile Left" = [ "Ctrl+Alt+Left" ]; # Changed from Meta+Left
                  "Window Quick Tile Right" = [ "Ctrl+Alt+Right" ]; # Changed from Meta+Right
                  "Suspend Compositing" = [ ]; # Free up Meta+Shift+F12
                  "Switch to Next Desktop" = [ ]; # Free up Meta+N
                  "view_zoom_in" = [ ]; # Free up Meta+Plus
                  "view_zoom_out" = [ ]; # Free up Meta+Minus
                  "MoveMouseToCenter" = [ ]; # Free up Meta+F6
                  "MoveMouseToFocus" = [ ]; # Free up Meta+F5
                  "Overview" = [ "Meta+0" ]; # Moved from Meta+W
                  "Window Close" = [ "Meta+Q" ]; # Mac-like quit
                  "Toggle Grid View" = [ ]; # Free up Meta+G
                  "Show Desktop" = [ ]; # Free up Meta+D
                };
                plasmashell = {
                  "show-on-mouse-pos" = [ ]; # Was Meta+V
                  "stop current activity" = [ ]; # Free up Meta+S
                  "manage activities" = [ ]; # Free up Meta+Q
                  "activate application launcher" = [ "Meta+Space" ];
                };
                org_kde_powerdevil = {
                  "powerProfile" = [ ]; # Free up Meta+B
                };
                ksmserver = {
                  "Lock Session" = [ "Ctrl+Alt+L" ]; # Changed from Meta+L
                };
              };

              panels = [
                {
                  location = "bottom";
                  height = 40;
                  floating = false;
                  opacity = "opaque";

                  widgets = [
                    {
                      kickoff = {
                        icon = "nix-snowflake-white";
                        favoritesDisplayMode = "list";
                        settings.General.highlightNewlyInstalledApps = false;
                      };
                    }

                    "org.kde.plasma.marginsseparator"

                    {
                      iconTasks = {
                        launchers = [
                          "applications:helium.desktop"
                          "applications:com.mitchellh.ghostty.desktop"
                          "applications:slack.desktop"
                          "applications:signal.desktop"
                          "applications:spotify.desktop"
                          "applications:org.keepassxc.KeePassXC.desktop"
                          "applications:org.kde.dolphin.desktop"
                          "applications:systemsettings.desktop"
                          "applications:steam.desktop"
                        ];
                        behavior = {
                          minimizeActiveTaskOnClick = false;
                        };
                      };
                    }

                    "org.kde.plasma.marginsseparator"
                    {
                      systemTray.items = {
                        shown = [
                          "org.kde.plasma.bluetooth"
                          "org.kde.plasma.networkmanagement"
                          "org.kde.plasma.volume"
                        ];
                        hidden = [
                          "Syncthing Tray"
                          "org.kde.kdeconnect"
                          "org.kde.plasma.brightness"
                          "org.kde.plasma.clipboard"
                          "org.kde.plasma.notifications"
                        ];
                      };
                    }
                    "org.kde.plasma.digitalclock"
                  ];
                }
              ];
            };

            systemd.user.services.windows-95-startup-sound = {
              Unit = {
                Description = "Play Windows 95 startup sound";
                PartOf = [ "graphical-session.target" ];
                After = [
                  "graphical-session.target"
                  "pipewire-pulse.service"
                ];
              };
              Service = {
                Type = "oneshot";
                ExecStart = "${pkgs.pipewire}/bin/pw-play ${windows95StartupSound}";
              };
              Install.WantedBy = [ "graphical-session.target" ];
            };
          }
        )
      ];
    };
}
