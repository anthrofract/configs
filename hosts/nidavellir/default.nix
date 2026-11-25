{
  config,
  inputs,
  self,
  ...
}:
{
  machines.nidavellir.nixos =
    { pkgs, ... }:
    {
      imports = [
        ./hardware.nix
        ./disko.nix
        inputs.disko.nixosModules.disko
        self.nixosModules.base-host
        self.nixosModules.bitcoind
        self.nixosModules.electrs
        self.nixosModules.encryption
        self.nixosModules.gitea
        self.nixosModules.media-server
        self.nixosModules.mempool
        self.nixosModules.reverse-proxy
      ];

      system.stateVersion = "24.11";
      time.timeZone = "America/Chicago";
      boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.kernelParams = [ "i915.enable_guc=2" ];

      fileSystems."/data" = {
        device = "/dev/disk/by-uuid/d83d8680-41e4-445b-9147-94ec3699803b";
        fsType = "ext4";
      };

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
}
