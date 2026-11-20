{ ... }:
{
  flake.nixosModules.tailscale =
    { lib, ... }:
    {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = lib.mkDefault "client";
        extraSetFlags = [ "--ssh" ];
      };

      # Lets a switch rerun `tailscale set` when extraSetFlags change; a finished
      # oneshot counts as stopped, so switches would otherwise skip it until reboot.
      systemd.services.tailscaled-set.serviceConfig.RemainAfterExit = true;
    };

  flake.darwinModules.tailscale = {
    services.tailscale.enable = true;
  };
}
