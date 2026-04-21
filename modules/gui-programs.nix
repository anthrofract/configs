{ self, ... }:
{
  flake.nixosModules.gui-programs =
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
              (pkgs.kdePackages.ksystemlog.overrideAttrs (old: {
                postInstall = (old.postInstall or "") + ''
                  substituteInPlace $out/share/applications/org.kde.ksystemlog.desktop \
                    --replace-quiet 'X-KDE-SubstituteUID=true' 'X-KDE-SubstituteUID=false'
                '';
              }))
              pkgs.chromium
              pkgs.google-chrome
              pkgs.haruna
              pkgs.kdePackages.ark
              pkgs.kdePackages.discover
              pkgs.kdePackages.dolphin
              pkgs.kdePackages.filelight
              pkgs.kdePackages.gwenview
              pkgs.kdePackages.isoimagewriter
              pkgs.kdePackages.kate
              pkgs.kdePackages.kcharselect
              pkgs.kdePackages.kclock
              pkgs.kdePackages.kcolorchooser
              pkgs.kdePackages.kolourpaint
              pkgs.kdePackages.okular
              pkgs.kdePackages.partitionmanager
              pkgs.kdePackages.spectacle
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
              pkgs.wezterm
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
