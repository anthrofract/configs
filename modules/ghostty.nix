{ ... }:
{
  flake.commonModules.ghostty =
    { ... }:
    {
      home-manager.sharedModules = [
        (
          { pkgs, ... }:
          {
            programs.ghostty = {
              enable = true;
              package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
              settings = {
                confirm-close-surface = false;
                font-family = "JetBrains Mono";
                font-size = 13;
                initial-command = "${pkgs.nushell}/bin/nu -il -c \"tms ~/configs\"";
                maximize = true;
                mouse-scroll-multiplier = 1;
                quit-after-last-window-closed = true;
                theme = "Dimidium";
                window-padding-balance = false;
                window-padding-color = "extend-always";
                window-padding-x = 2;
                window-padding-y = "2,0";
                keybind = [
                  ''shift+enter=text:\x1b\r''
                  "super+-=decrease_font_size:1"
                  "super+==increase_font_size:1"
                  ''super+\=text:\x1b\\''
                  "super+c=copy_to_clipboard"
                  ''super+s=text:\x1bS''
                  "super+v=paste_from_clipboard"
                ];
              };
            };
          }
        )
      ];
    };
}
