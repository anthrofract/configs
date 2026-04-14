{ ... }:
{
  flake.nixosModules.gitea =
    { pkgs, ... }:
    {
      services.gitea = {
        enable = true;
        settings = {
          server.HTTP_PORT = 3000;
        };
      };
      networking.firewall.allowedTCPPorts = [ 3000 ];
    };
}
