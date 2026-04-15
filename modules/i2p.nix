{ ... }:
{
  flake.nixosModules.i2p =
    { ... }:
    {
      services.i2pd = {
        enable = true;
        proto.http = {
          enable = true;
          address = "0.0.0.0";
          strictHeaders = false;
        };
        proto.httpProxy = {
          enable = true;
          address = "0.0.0.0";
        };
        proto.socksProxy = {
          enable = true;
          address = "0.0.0.0";
        };
      };
      networking.firewall.allowedTCPPorts = [
        7070 # i2pd web console
        4444 # i2pd HTTP proxy
        4447 # i2pd SOCKS proxy
      ];
    };
}
