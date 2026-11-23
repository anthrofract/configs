{ self, ... }:
{
  flake.nixosModules.gui-programs =
    { pkgs, ... }:
    {
      imports = [
        # self.nixosModules.emacs
        self.commonModules.ghostty
        self.nixosModules.helium
      ];

      # Zoom
      programs.zoom-us.enable = true;

      # polkitd only reads actions from the system profile; KeePassXC Quick Unlock needs this one
      environment.systemPackages = [
        (pkgs.runCommand "keepassxc-polkit-action" { } ''
          mkdir -p $out/share/polkit-1/actions
          ln -s ${pkgs.keepassxc}/share/polkit-1/actions/*.policy $out/share/polkit-1/actions/
        '')
      ];

      home-manager.sharedModules = [
        (
          { pkgs, latestPkgs, ... }:
          {
            home.packages = [
              latestPkgs.slack
              latestPkgs.sparrow
              latestPkgs.zed-editor-fhs
              pkgs.chromium
              pkgs.discord
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
              pkgs.kdePackages.ksystemlog
              pkgs.kdePackages.okular
              pkgs.kdePackages.partitionmanager
              pkgs.kdePackages.spectacle
              pkgs.keepassxc
              pkgs.libreoffice-qt
              pkgs.obsidian
              pkgs.qalculate-qt
              pkgs.signal-desktop
              pkgs.spotify
              pkgs.timg
              pkgs.tor-browser
              pkgs.transmission_4-qt
              pkgs.vscodium-fhs
              pkgs.wezterm
              self.packages.${pkgs.stdenv.hostPlatform.system}.grok-bot
              self.packages.${pkgs.stdenv.hostPlatform.system}.handy
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
