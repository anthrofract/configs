{ ... }:
{
  flake.commonModules.ghostty =
    { pkgs, latestPkgs, ... }:
    let
      # Linux: Ghostty 1.3.1 + systemd 262 can intermittently fail to launch from
      # KDE's panel via D-Bus. Confirmed in the journal on 2026-10-22:
      # "lacks handler for reload signal USR2, refusing service startup"
      # followed by "Failed with result 'protocol'"; later attempts succeed.
      # Dark-mode startup can send READY=1 before the SIGUSR2 handler is installed,
      # which systemd rejects for Ghostty's Type=notify-reload service.
      # The desktop ID com.mitchellh.ghostty is correct; no Plasma pin change needed.
      # Upstream bug: https://github.com/ghostty-org/ghostty/issues/14398
      # Upstream fix: https://github.com/ghostty-org/ghostty/pull/14399
      # No workaround applied. If needed, Type=dbus on the Ghostty user service
      # uses bus-name readiness instead, but gives up notify-reload semantics.
      # Remove this note once the packaged Ghostty includes the upstream fix.
      ghosttyPackage =
        if pkgs.stdenv.hostPlatform.isDarwin then latestPkgs.ghostty-bin else latestPkgs.ghostty;
    in
    {
      environment.systemPackages = [ ghosttyPackage.terminfo ];

      home-manager.sharedModules = [
        (
          { lib, ... }:
          {
            programs.ghostty = {
              enable = true;
              package = ghosttyPackage;
              settings = {
                confirm-close-surface = false;
                cursor-color = "#ffffff";
                custom-shader = "${./ghostty/cursor-smear.glsl}";
                font-family = "JetBrains Mono NL";
                font-size = lib.mkDefault 13;
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
                  ''super+left=text:\x08''
                  ''super+down=text:\x0a''
                  ''super+up=text:\x0b''
                  ''super+right=text:\x0c''
                  ''super+\=text:\x1c''
                  ''super+s=text:\x1bS''
                ];
              };
            };
          }
        )
      ];
    };
}
