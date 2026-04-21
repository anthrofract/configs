{ self, ... }:
{
  flake.nixosModules.guiPrograms =
    { ... }:
    {
      imports = [
        self.commonModules.ghostty
        self.nixosModules.helium
      ];

      # Zoom
      programs.zoom-us.enable = true;

      home-manager.sharedModules = [
        (
          { pkgs, ... }:
          {
            home.packages = [
              pkgs.chromium
              pkgs.code-cursor-fhs
              pkgs.google-chrome
              pkgs.haruna
              pkgs.keepassxc
              pkgs.krita
              pkgs.libreoffice-qt
              pkgs.obsidian
              pkgs.qalculate-qt
              pkgs.signal-desktop
              pkgs.slack
              pkgs.sparrow
              pkgs.spotify
              pkgs.timg
              pkgs.tor-browser
              pkgs.transmission_4-qt
              pkgs.vscodium-fhs
              pkgs.wezterm
              pkgs.zed-editor-fhs
            ];

            systemd.user.services.tailscale-systray = {
              Unit = {
                Description = "Tailscale systray";
                PartOf = [ "graphical-session.target" ];
                After = [ "graphical-session.target" ];
              };
              Service = {
                ExecStart = "${pkgs.tailscale}/bin/tailscale systray";
                Restart = "on-failure";
              };
              Install.WantedBy = [ "graphical-session.target" ];
            };
          }
        )
      ];
    };
}
