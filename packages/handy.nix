{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.handy =
        let
          version = "0.9.8";
          src = pkgs.fetchurl {
            url = "https://github.com/cjpais/Handy/releases/download/v${version}/Handy_${version}_amd64.AppImage";
            sha256 = "0kqqwxjjyzn4r9nk7yv8354mnfnkj81lias5a2blg6igfsbdr0yn";
          };
          extracted = pkgs.appimageTools.extract {
            pname = "handy";
            inherit version src;
          };
          desktopItem = pkgs.makeDesktopItem {
            name = "handy";
            desktopName = "Handy";
            comment = "Speech-to-text";
            exec = "handy";
            icon = "handy";
            terminal = false;
            categories = [
              "Utility"
              "Audio"
            ];
          };
        in
        pkgs.appimageTools.wrapType2 {
          pname = "handy";
          inherit version src;
          extraPkgs = pkgs: [
            pkgs.libgpg-error
            pkgs.dotool
          ];

          extraInstallCommands = ''
            install -Dm644 ${desktopItem}/share/applications/handy.desktop \
              "$out/share/applications/handy.desktop"
            substituteInPlace "$out/share/applications/handy.desktop" \
              --replace-fail "Exec=handy" "Exec=$out/bin/handy"
            install -Dm644 ${extracted}/usr/share/icons/hicolor/128x128/apps/handy.png \
              "$out/share/icons/hicolor/128x128/apps/handy.png"
          '';

          meta = {
            description = "Speech-to-text";
            homepage = "https://github.com/cjpais/Handy";
            mainProgram = "handy";
            platforms = [ "x86_64-linux" ];
          };
        };
    };
}
