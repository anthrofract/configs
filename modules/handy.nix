{ ... }:
{
  flake.nixosModules.handy =
    { pkgs, ... }:
    let
      version = "0.8.3";
      src = pkgs.fetchurl {
        url = "https://github.com/cjpais/Handy/releases/download/v${version}/Handy_${version}_amd64.AppImage";
        sha256 = "1518gs96hs3mywdn1gmhr40sbj7xf23k92sw3bbx5j81j1b0kd7j";
      };
      extracted = pkgs.appimageTools.extract {
        pname = "handy";
        inherit version src;
      };
      handy = pkgs.appimageTools.wrapType2 {
        pname = "handy";
        inherit version src;
      };
    in
    {
      environment.systemPackages = [
        handy
        pkgs.dotool
      ];

      home-manager.sharedModules = [
        {
          xdg.desktopEntries.handy = {
            name = "Handy";
            comment = "Speech-to-text";
            exec = "${handy}/bin/handy";
            icon = "${extracted}/usr/share/icons/hicolor/128x128/apps/handy.png";
            terminal = false;
            categories = [
              "Utility"
              "Audio"
            ];
          };

          # systemd.user.services.handy = {
          #   Unit = {
          #     Description = "Handy speech-to-text";
          #     After = [ "graphical-session.target" ];
          #     PartOf = [ "graphical-session.target" ];
          #   };
          #   Service = {
          #     ExecStart = "${handy}/bin/handy --start-hidden";
          #     Restart = "on-failure";
          #     RestartSec = 5;
          #   };
          #   Install.WantedBy = [ "graphical-session.target" ];
          # };
        }
      ];
    };
}
