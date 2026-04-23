{ ... }:
{
  flake.nixosModules.gui-system =
    { pkgs, ... }:
    {
      # Booting
      boot = {
        consoleLogLevel = 3;
        initrd.verbose = false;
        plymouth = {
          enable = true;
          theme = "script";
        };
        kernelParams = [
          "quiet"
          "splash"
          "boot.shell_on_fail"
          "udev.log_priority=3"
          "rd.systemd.show_status=auto"
          "plymouth.use-simpledrm"
        ];
      };

      # Enable SDDM
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };

      # SDDM theme override and Wayland tooling
      environment.systemPackages = [
        (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
          [General]
          background=${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Path/contents/images/2560x1440.jpg
        '')
        pkgs.wayland-utils
        pkgs.wl-clipboard-rs
      ];

      # Kmscon
      services.kmscon = {
        enable = true;
        fonts = [
          {
            name = "JetBrains Mono";
            package = pkgs.jetbrains-mono;
          }
        ];
        extraConfig = "font-dpi=192";
      };

      # Enable OpenGL
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      # Enable CUPS to print documents.
      services.printing.enable = true;

      # Enable sound with pipewire.
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        # If you want to use JACK applications, uncomment this
        #jack.enable = true;

        # use the example session manager (no others are packaged yet so this is enabled by default,
        # no need to redefine it in your config for now)
        #media-session.enable = true;
      };

      # Bluetooth support
      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = true;

      programs.appimage.enable = true;
    };
}
