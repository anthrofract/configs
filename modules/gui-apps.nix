{ inputs, ... }:
{
  flake.nixosModules.guiApps =
    { ... }:
    {
      # Zoom
      programs.zoom-us.enable = true;

      home-manager.sharedModules = [
        (
          { pkgs, ... }:
          {
            home.packages = [
              inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
              pkgs.chromium
              pkgs.code-cursor-fhs
              pkgs.ghostty
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
              pkgs.tor-browser
              pkgs.transmission_4-qt
              pkgs.vscodium-fhs
              pkgs.wezterm
              pkgs.zed-editor-fhs
            ];
          }
        )
      ];
    };
}
