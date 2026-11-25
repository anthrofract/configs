{ self, ... }:
{
  machines.valhalla.nixos =
    { pkgs, ... }:
    {
      imports = [
        ./hardware.nix
        self.nixosModules.gui-host
        # self.nixosModules.local-ai
        self.nixosModules.nvidia
        self.nixosModules.reverse-proxy
        self.nixosModules.sunshine
      ];

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
