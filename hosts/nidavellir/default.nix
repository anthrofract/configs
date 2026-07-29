{
  config,
  self,
  inputs,
  ...
}:
{
  flake = {
    nixosConfigurations.nidavellir = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.nidavellir-configuration
      ];
    };

    nixosModules.nidavellir-configuration =
      { pkgs, ... }:
      {
        imports = [
          ./hardware.nix
          self.nixosModules.base-host
          self.nixosModules.bitcoind
          self.nixosModules.electrs
          self.nixosModules.gitea
          # self.nixosModules.hermes
          self.nixosModules.media-server
          self.nixosModules.mempool
          self.nixosModules.reverse-proxy
        ];

        networking.hostName = "nidavellir";
        system.stateVersion = "24.11";
        time.timeZone = "America/Chicago";
        boot.kernelPackages = pkgs.linuxPackages_latest;
        boot.kernelParams = [ "i915.enable_guc=2" ];

        hardware.graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-compute-runtime-legacy1
            intel-media-driver
          ];
        };

        virtualisation.docker = {
          enable = true;
          rootless = {
            enable = false;
            setSocketVariable = false;
          };
        };
        users.users.${config.secrets.identities.personal.userName}.extraGroups = [ "docker" ];

        services.reverse-proxy.domain = "nidavellir";

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
            "--exit-node=auto:any"
            "--exit-node-allow-lan-access=true"
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
