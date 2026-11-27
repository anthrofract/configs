{ self, ... }:
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
      # hyprland.lua routes the launcher, lock, OSD keys and more through Dux
      imports = [ self.nixosModules.dux ];

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
