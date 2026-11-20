{ self, ... }:
{
  machines.asgard.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        ./hardware.nix
        self.nixosModules.gui-host
      ];

      system.stateVersion = "24.11";
      boot.kernelPackages = pkgs.linuxPackages_latest;
      services.automatic-timezoned.enable = true;
      services.geoclue2.geoProviderUrl = "https://api.beacondb.net/v1/geolocate";

      # Fingerprint reader. SDDM logs in with the password only, so KDE Wallet always unlocks;
      # the lock screen accepts either, since Plasma checks both at the same time.
      services.fprintd.enable = true;
      security.pam.services = {
        login.fprintAuth = false;
      }
      # Ask for the password first; an empty password falls through to the fingerprint reader.
      // lib.genAttrs [ "sudo" "sudo-i" "su" "polkit-1" ] (name: {
        rules.auth.fprintd.order = config.security.pam.services.${name}.rules.auth.unix.order + 10;
      });

      # Intel Quick Sync Video
      hardware.graphics.extraPackages = [ pkgs.vpl-gpu-rt ];

      boot.initrd.kernelModules = [ "i915" ];
      boot.kernelParams = [
        "i915.fastboot=1"
      ];

      home-manager.sharedModules = [
        {
          home.stateVersion = "24.11";
          programs.plasma.powerdevil.AC.powerProfile = "balanced";
          programs.plasma.powerdevil.battery.powerProfile = "balanced";
          programs.plasma.powerdevil.lowBattery.powerProfile = "powerSaving";
        }
      ];
    };
}
