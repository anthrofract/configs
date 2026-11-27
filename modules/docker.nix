{ ... }:
{
  flake.nixosModules.docker =
    { config, lib, ... }:
    {
      virtualisation.docker = {
        enable = lib.mkDefault false;
        rootless = {
          enable = lib.mkDefault true;
          setSocketVariable = lib.mkDefault true;
        };
      };

      # The rootless user service starts for every user, so skip system users such as the login screen's greeter.
      # This replaces nixpkgs' "!root", since root is a system user too.
      systemd.user.services = lib.mkIf config.virtualisation.docker.rootless.enable {
        docker.unitConfig.ConditionUser = lib.mkForce "!@system";
      };
    };
}
