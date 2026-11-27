{ inputs, ... }:
{
  flake.nixosModules.dux =
    { pkgs, ... }:
    let
      sessionTarget = "wayland-session-xdg-autostart@hyprland.desktop.target";
    in
    {
      imports = [ inputs.dux-calendar.nixosModules.default ];

      programs.dux-shell = {
        enable = true;
        package = inputs.dux-shell.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell;
        systemd.target = sessionTarget;
        excludePackages = [ pkgs.matugen ];
        plugins.Calculator.src = inputs.dank-calculator;
      };

      programs.dank-calendar = {
        enable = true;
        systemd.enable = true;
        systemd.target = sessionTarget;
      };

      home-manager.sharedModules = [
        {
          # Its scripts are hardcoded to the user plugin dir, so it can't go in programs.dux-shell.plugins
          xdg.configFile."dms/plugins/dankCalendarAgenda".source = pkgs.applyPatches {
            name = "dms-dankcalendar";
            src = inputs.dms-dankcalendar;
            # Join opens links through `dms open`, which always shows the browser picker
            patches = [ ./dux/dank-calendar-agenda-xdg-open.patch ];
          };
        }
      ];
    };
}
