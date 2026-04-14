{ ... }:
{
  flake.nixosModules.bitcoind =
    { ... }:
    {
      services.bitcoind.mainnet = {
        enable = true;
        dbCache = 4096;
        extraConfig = ''
          server=1
          txindex=1
          rpcbind=0.0.0.0
          rpcallowip=127.0.0.1
          rpcallowip=192.168.0.0/16
          rpcallowip=172.18.0.0/16
        '';
      };

      networking.firewall.allowedTCPPorts = [
        8332
        8333
      ];
    };
}
