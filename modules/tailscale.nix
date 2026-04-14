{ ... }:
{
  flake.nixosModules.tailscale =
    { lib, pkgs, ... }:
    {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = lib.mkDefault "client";
      };
    };
}
