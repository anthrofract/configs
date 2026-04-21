{ self, inputs, ... }:
{
  flake = {
    nixosConfigurations.valhalla = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.valhalla-configuration
      ];
    };

    nixosModules.valhalla-configuration =
      { pkgs, ... }:
      {
        imports = [
          ./hardware.nix
          self.nixosModules.gui-host
          self.nixosModules.nvidia
          self.nixosModules.sunshine
        ];

        networking.hostName = "valhalla";
        system.stateVersion = "24.11";
        boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
        time.timeZone = "America/Chicago";

        home-manager.sharedModules = [
          {
            home.stateVersion = "24.11";
            programs.plasma.powerdevil.AC.powerProfile = "performance";
          }
        ];
      };
  };
}
