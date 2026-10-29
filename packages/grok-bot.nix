{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.grok-bot =
        let
          version = "0.78.1";
          src = pkgs.fetchurl {
            url = "https://downloads.cursor.com/grokbot/stable/72e130b4e6be3fdc47b97e809b6b420908ce2dd8/linux/x64/Grok_Bot_${version}.AppImage";
            hash = "sha256-BQ11I8bvoEYmYROuLjsfPOlAlVSSwrlS/T5pi2DXP7g=";
          };
          extracted = pkgs.appimageTools.extract {
            pname = "grok-bot";
            inherit version src;
          };
          desktopItem = pkgs.makeDesktopItem {
            name = "grok-bot";
            desktopName = "Grok Bot";
            comment = "Grok Bot desktop agent";
            exec = "grok-bot %U";
            icon = "grok-bot";
            terminal = false;
            categories = [ "Development" ];
            mimeTypes = [
              "x-scheme-handler/grokbot"
              "x-scheme-handler/sand"
            ];
            startupWMClass = "grok-bot";
          };
        in
        pkgs.appimageTools.wrapType2 {
          pname = "grok-bot";
          inherit version src;

          extraInstallCommands = ''
            install -Dm644 ${desktopItem}/share/applications/grok-bot.desktop \
              "$out/share/applications/grok-bot.desktop"
            substituteInPlace "$out/share/applications/grok-bot.desktop" \
              --replace-fail "Exec=grok-bot" "Exec=$out/bin/grok-bot"
            install -Dm644 ${extracted}/resources/icon.png \
              "$out/share/pixmaps/grok-bot.png"
          '';

          meta = {
            description = "Grok Bot desktop agent";
            mainProgram = "grok-bot";
            platforms = [ "x86_64-linux" ];
          };
        };
    };
}
