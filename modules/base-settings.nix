{ ... }:
{
  flake.nixosModules.baseSettings =
    { pkgs, ... }:
    {
      # Boot
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.systemd-boot.enable = true;

      # Dbus
      services.dbus.implementation = "broker";

      # Select internationalisation properties.
      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };

      # Networking
      networking.networkmanager.enable = true;
      services.resolved.enable = true;
      services.resolved.settings.Resolve.DNSOverTLS = "opportunistic";
      # Trust the NextDNS Root CA so block pages can be served over HTTPS
      security.pki.certificateFiles = [
        (pkgs.fetchurl {
          url = "https://nextdns.io/ca";
          hash = "sha256-yl+2q4H/a8SLGv4Mt+g8+03uy9ihZxACbsj3uCTog34=";
        })
      ];
    };
}
