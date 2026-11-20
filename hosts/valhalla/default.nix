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
      ];
    };
}
