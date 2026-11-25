{ self, ... }:
{
  machines.valhalla.nixos =
    { pkgs, ... }:
    {
      imports = [
        ./hardware.nix
        self.nixosModules.disko-ext4
        self.nixosModules.gui-host
        # self.nixosModules.local-ai
        self.nixosModules.nvidia
        self.nixosModules.reverse-proxy
        self.nixosModules.sunshine
      ];

      # The other NVMe disk holds Windows and is deliberately not declared
      disko.devices.disk.main = {
        device = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_2000GB_23034A800260";
        content.partitions = {
          ESP.uuid = "6c6389d0-6b5e-47b2-acf4-40818fd899dc";
          root.uuid = "3785a798-30ff-4f63-bdf1-9ed94b481ae6";
          swap.uuid = "53efa3c0-420e-462c-b667-68cbfbaf67c5";
        };
      };

      system.stateVersion = "24.11";
      boot.kernelPackages = pkgs.linuxPackages_latest;
      time.timeZone = "America/Chicago";

      services.reverse-proxy.domain = "valhalla";
      services.tailscale.extraSetFlags = [ "--exit-node-allow-lan-access=true" ];

      home-manager.sharedModules = [
        {
          home.stateVersion = "24.11";
          programs.plasma.powerdevil.AC.powerProfile = "performance";
        }
        (
          { config, ... }:
          {
            # Dux merges config.d files over settings.json; live link so its settings screen can edit it
            xdg.configFile."dms/config.d/valhalla.json".source =
              config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/configs/hosts/valhalla/dms.json";
          }
        )
      ];
    };
}
