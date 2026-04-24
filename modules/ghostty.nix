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
                  "ctrl+1=csi:27;5;49~"
                  "ctrl+2=csi:27;5;50~"
                  "ctrl+3=csi:27;5;51~"
                  "ctrl+4=csi:27;5;52~"
                  "ctrl+5=csi:27;5;53~"
                  "ctrl+6=csi:27;5;54~"
                  "ctrl+7=csi:27;5;55~"
                  "ctrl+8=csi:27;5;56~"
                  "ctrl+9=csi:27;5;57~"
                  "super+-=decrease_font_size:1"
                  "super+==increase_font_size:1"
                  "super+c=copy_to_clipboard"
                  "super+v=paste_from_clipboard"
                  ''shift+enter=text:\x1b\r''
                  ''super+\=text:\x1b\\''
                  ''super+s=text:\x1bS''
                ];
              };
            };
          }
        )
      ];
    };
}
