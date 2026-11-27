{ inputs, ... }:
{
  flake.nixosModules.hyprland =
    {
      hostName,
      lib,
      pkgs,
      ...
    }:
    let
      # The Hyprland session also lists KDE in XDG_CURRENT_DESKTOP, which would start these
      # KDE-only autostart entries. A copy in ~/.config/autostart replaces the system entry;
      # NotShowIn=Hyprland skips it in Hyprland while Plasma still starts it.
      kdeAutostarts = {
        "kwrited-autostart.desktop" = pkgs.kdePackages.kwrited;
        "org.kde.discover.notifier.desktop" = pkgs.kdePackages.discover;
        "org.kde.plasma-fallback-session-restore.desktop" = pkgs.kdePackages.plasma-workspace;
      };
    in
    {
      imports = [ inputs.dux-calendar.nixosModules.default ];

      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };

      # Hyprland's portal only covers screenshots, screen sharing and global shortcuts; KDE's
      # provides the rest, including the file picker, as in Plasma
      xdg.portal.config.hyprland.default = [
        "hyprland"
        "kde"
      ];

      programs.dux-shell = {
        enable = true;
        package = inputs.dux-shell.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell;
        # Plasma also reaches graphical-session.target, so start Dux only with this Hyprland
        # session target. dms.service is After=graphical-session.target, and a target is ordered
        # after the units it wants; wayland-session@ is Before=graphical-session.target and would
        # form a cycle, while this one already comes after graphical-session.target.
        systemd.target = "wayland-session-xdg-autostart@hyprland.desktop.target";
        excludePackages = [ pkgs.matugen ];
        plugins.Calculator.src = inputs.dank-calculator;
      };

      programs.dank-calendar = {
        enable = true;
        systemd.enable = true;
        systemd.target = "wayland-session-xdg-autostart@hyprland.desktop.target";
      };

      environment.systemPackages = [ pkgs.playerctl ];

      home-manager.sharedModules = [
        {
          xdg.configFile = lib.mapAttrs' (
            name: package:
            lib.nameValuePair "autostart/${name}" {
              source = pkgs.runCommand name { } ''
                sed '/^\[Desktop Entry\]/a NotShowIn=Hyprland;' ${package}/etc/xdg/autostart/${name} > $out
              '';
            }
          ) kdeAutostarts;
        }
        {
          # Its scripts are hardcoded to the user plugin dir, so it can't go in programs.dux-shell.plugins
          xdg.configFile."dms/plugins/dankCalendarAgenda".source = pkgs.applyPatches {
            name = "dms-dankcalendar";
            src = inputs.dms-dankcalendar;
            # Join opens links through `dms open`, which always shows the browser picker
            patches = [ ./hyprland/dank-calendar-agenda-xdg-open.patch ];
          };
        }
        (
          { config, ... }:
          {
            # Per-host config loaded at the end of hyprland.lua; live link so edits apply without a rebuild
            xdg.configFile."hypr/host.lua".source =
              config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/configs/hosts/${hostName}/hypr.lua";
          }
        )
      ];
    };
}
