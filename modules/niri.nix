{ inputs, ... }:
{
  flake.nixosModules.niri =
    { lib, pkgs, ... }:
    {
      programs.niri = {
        enable = true;
        useNautilus = false;
      };

      environment.systemPackages = [ pkgs.xwayland-satellite ];

      services = {
        accounts-daemon.enable = true;
        geoclue2.enable = true;
        gnome.gnome-keyring.enable = false;
        power-profiles-daemon.enable = true;
      };
      security.polkit.enable = true;

      xdg.portal.config.niri = lib.mkForce {
        default = [
          "kde"
          "gtk"
        ];
        "org.freedesktop.impl.portal.ScreenCast" = "gnome";
        "org.freedesktop.impl.portal.Screenshot" = "gnome";
        "org.freedesktop.impl.portal.Secret" = "kwallet";
        "org.freedesktop.impl.portal.Settings" = "gtk";
      };

      home-manager.sharedModules = [
        inputs.dms.homeModules.dank-material-shell
        (
          { ... }:
          {
            home.file.".config/DankMaterialShell/settings.json".force = true;

            programs.dank-material-shell = {
              enable = true;
              systemd = {
                enable = true;
                target = "niri.service";
              };
            };
          }
        )
      ];
    };
}
