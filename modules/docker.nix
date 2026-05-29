{ ... }:
{
  flake.nixosModules.docker =
    { lib, ... }:
    {
      virtualisation.docker = {
        enable = lib.mkDefault false;
        rootless = {
          enable = lib.mkDefault true;
          setSocketVariable = lib.mkDefault true;
        };
      };
    };
}
