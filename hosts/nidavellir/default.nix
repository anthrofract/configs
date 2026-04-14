{ self, inputs, ... }:
{
  flake = {
    nixosConfigurations.nidavellir = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.nidavellirConfiguration
      ];
    };

    nixosModules.nidavellirConfiguration =
      { pkgs, ... }:
      {
        imports = [
          ./hardware.nix
          self.nixosModules.baseHost
          self.nixosModules.bitcoind
          self.nixosModules.electrs
          self.nixosModules.gitea
          self.nixosModules.mempool
        ];

        networking.hostName = "nidavellir";
        system.stateVersion = "24.11";
        time.timeZone = "America/Chicago";
        boot.kernelPackages = pkgs.linuxPackages_latest;

        # Hack to stop a warning during nix build
        # TODO: Setup real alerts for issues with RAID?
        boot.swraid = {
          # Already enabled in hardware_configuration.nix
          mdadmConf = ''
            MAILADDR someone@example.com
          '';
        };

        services.tailscale = {
          useRoutingFeatures = "both";
          extraSetFlags = [
            "--advertise-exit-node"
            "--advertise-routes=192.168.1.0/24"
          ];
        };

        home-manager.sharedModules = [
          {
            home.stateVersion = "24.11";
          }
        ];

      };
  };
}
