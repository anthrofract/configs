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
        self.nixosModules.disko-ext4
        self.nixosModules.gui-host
      ];

      disko.devices.disk.main = {
        device = "/dev/disk/by-id/nvme-SKHynix_HFS001TEJ9X162N_AYCBN02871CB9BP2D";
        content.partitions = {
          ESP.uuid = "4cd9665e-cfea-4869-b720-2b86f6cf0b72";
          root.uuid = "48ba4768-2fd0-479f-bd94-7e93076c4380";
          swap.uuid = "77a10c1e-66a6-41c2-8097-59fc440f7ec2";
        };
      };

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
        (
          { config, ... }:
          {
            # Dux merges config.d files over settings.json; live link so its settings screen can edit it
            xdg.configFile."dms/config.d/asgard.json".source =
              config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/configs/hosts/asgard/dms.json";
          }
        )
      ];
    };
}
