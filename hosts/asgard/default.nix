{ self, inputs, ... }:
{
  flake = {
    nixosConfigurations.asgard = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.asgardConfiguration
      ];
    };

    nixosModules.asgardConfiguration =
      { pkgs, ... }:
      {
        imports = [
          ./hardware.nix
          self.nixosModules.guiHost
        ];

        networking.hostName = "asgard";
        system.stateVersion = "24.11";
        boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
        services.automatic-timezoned.enable = true;
        services.geoclue2.geoProviderUrl = "https://api.beacondb.net/v1/geolocate";

        # Fingerprint reader
        # For some reason this seems to cause a problem with kdewallet sometimes. If you keep getting
        # annoying popups asking for access to kdewallet, you can solve this by deleting the wallet:
        # rm -rf ~/.local/share/kwalletd/
        # systemd.services.fprintd = {
        #   wantedBy = [ "multi-user.target" ];
        #   serviceConfig.Type = "simple";
        # };
        # services.fprintd.enable = true;

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
  };
}
