{ config, ... }:
let
  userName = config.secrets.identities.personal.userName;
in
{
  flake.nixosModules.wallpapers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      dux = config.programs.dux-shell;
      wallpaperDir = "/home/${userName}/Pictures/wallpapers/Spyro_Skyboxes";
      sddmWallpaper = "/var/lib/sddm/spyro-wallpaper/current-wallpaper";
      syncSpyroWallpaper = pkgs.writers.writeNuBin "sync-spyro-wallpaper" ''
        def selected-wallpaper [] {
          let wallpaper_dir = "${wallpaperDir}"

          if not ($wallpaper_dir | path exists) {
            error make { msg: $"Wallpaper directory does not exist: ($wallpaper_dir)" }
          }

          let wallpapers = (
            glob $"($wallpaper_dir)/**/*"
            | where { |path|
                (${pkgs.file}/bin/file --brief --mime-type $path) | str starts-with "image/"
              }
            | sort
          )

          if (($wallpapers | length) == 0) {
            error make { msg: $"No wallpapers found in: ($wallpaper_dir)" }
          }

          let day_of_year = (date now | format date "%j" | into int)
          let index = ($day_of_year mod ($wallpapers | length))
          $wallpapers | get $index
        }

        def sync-plasma [] {
          let wallpaper = selected-wallpaper

          ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image
          ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image $"file://($wallpaper)"
          ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-wallpaperimage $wallpaper
        }

        def sync-sddm [] {
          let wallpaper = selected-wallpaper
          let sddm_wallpaper = "${sddmWallpaper}"

          ${pkgs.coreutils}/bin/mkdir --parents ($sddm_wallpaper | path dirname)
          ${pkgs.coreutils}/bin/cp --force $wallpaper $sddm_wallpaper
          ${pkgs.coreutils}/bin/chmod 0644 $sddm_wallpaper
        }

        def sync-dux [] {
          let wallpaper = selected-wallpaper

          ${dux.package}/bin/dms ipc call wallpaper set $wallpaper
        }

        def main [target: string] {
          match $target {
            "plasma" => { sync-plasma }
            "sddm" => { sync-sddm }
            "dux" => { sync-dux }
            _ => { error make { msg: $"Unknown wallpaper sync target: ($target)" } }
          }
        }
      '';
    in
    {
      environment.systemPackages = [
        (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
          [General]
          background=${sddmWallpaper}
        '')
      ];

      systemd.services.spyro-sddm-wallpaper = {
        description = "Sync Spyro Skyboxes SDDM wallpaper";
        before = [ "display-manager.service" ];
        wantedBy = [ "display-manager.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${syncSpyroWallpaper}/bin/sync-spyro-wallpaper sddm";
        };
      };

      systemd.timers.spyro-sddm-wallpaper = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          Unit = "spyro-sddm-wallpaper.service";
        };
      };

      home-manager.sharedModules = [
        (
          { ... }:
          {
            systemd.user.services.spyro-plasma-wallpaper = {
              Unit = {
                Description = "Sync Spyro Skyboxes Plasma wallpaper";
                PartOf = [ "plasma-workspace.target" ];
                After = [ "plasma-workspace.target" ];
              };
              Service = {
                Type = "oneshot";
                ExecStart = "${syncSpyroWallpaper}/bin/sync-spyro-wallpaper plasma";
              };
              Install.WantedBy = [ "plasma-workspace.target" ];
            };

            systemd.user.timers.spyro-plasma-wallpaper = {
              Unit = {
                Description = "Daily Spyro Skyboxes wallpaper sync";
                PartOf = [ "plasma-workspace.target" ];
              };
              Timer = {
                OnCalendar = "daily";
                Persistent = true;
                Unit = "spyro-plasma-wallpaper.service";
              };
              Install.WantedBy = [ "plasma-workspace.target" ];
            };

            systemd.user.services.spyro-dux-wallpaper = lib.mkIf dux.enable {
              Unit = {
                Description = "Sync Spyro Skyboxes Dux Shell wallpaper";
                PartOf = [ dux.systemd.target ];
                After = [ "dms.service" ];
              };
              Service = {
                Type = "oneshot";
                ExecStart = "${syncSpyroWallpaper}/bin/sync-spyro-wallpaper dux";
              };
              Install.WantedBy = [ dux.systemd.target ];
            };

            systemd.user.timers.spyro-dux-wallpaper = lib.mkIf dux.enable {
              Unit = {
                Description = "Daily Spyro Skyboxes Dux Shell wallpaper sync";
                PartOf = [ dux.systemd.target ];
              };
              Timer = {
                OnCalendar = "daily";
                Persistent = true;
                Unit = "spyro-dux-wallpaper.service";
              };
              Install.WantedBy = [ dux.systemd.target ];
            };
          }
        )
      ];
    };
}
