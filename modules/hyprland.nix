{ inputs, ... }:
{
  flake.nixosModules.hyprland =
    { lib, pkgs, ... }:
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
      ];
    };
}
