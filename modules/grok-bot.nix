{ ... }:
{
  flake.nixosModules.grok-bot =
    { pkgs, ... }:
    let
      version = "0.71.2";
      src = pkgs.fetchurl {
        url = "https://downloads.cursor.com/grokbot/stable/92808c0ad869b2e3725dbc3b8fa2fcc991687502/linux/x64/Grok_Bot_${version}.AppImage";
        hash = "sha256-a8SI+sg9tWbojxx1BzkBLbceGPS8Z+af6Tz/M0nZH+g=";
      };
      extracted = pkgs.appimageTools.extract {
        pname = "grok-bot";
        inherit version src;
      };
      grok-bot = pkgs.appimageTools.wrapType2 {
        pname = "grok-bot";
        inherit version src;
      };
    in
    {
      environment.systemPackages = [ grok-bot ];

      home-manager.sharedModules = [
        {
          xdg.desktopEntries.grok-bot = {
            name = "Grok Bot";
            comment = "Grok Bot desktop agent";
            exec = "${grok-bot}/bin/grok-bot %U";
            icon = "${extracted}/resources/icon.png";
            terminal = false;
            categories = [ "Development" ];
            mimeType = [
              "x-scheme-handler/grokbot"
              "x-scheme-handler/sand"
            ];
            settings.StartupWMClass = "grok-bot";
          };
        }
      ];
    };
}
