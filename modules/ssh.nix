{ config, ... }:
let
  hostNames = config.flake.secrets.hosts |> builtins.attrNames;
  foreignHostPattern = ([ "*" ] ++ map (host: "!${host}") hostNames) |> builtins.concatStringsSep " ";
in
{
  flake.nixosModules.ssh =
    { pkgs, ... }:
    {
      services.openssh = {
        enable = true;
        ports = [ 22 ];
        settings = {
          PasswordAuthentication = false;
          AllowUsers = null;
          X11Forwarding = false;
        };
      };

      programs.mosh.enable = true;

      environment.systemPackages = [
        pkgs.ghostty.terminfo
      ];

      home-manager.sharedModules = [
        (
          { ... }:
          {
            programs.ssh = {
              enable = true;
              enableDefaultConfig = false;
              # Keep the default TERM for known hosts that have Ghostty terminfo installed,
              # and force a broadly supported fallback for everything else.
              matchBlocks."${foreignHostPattern}" = {
                setEnv = {
                  TERM = "xterm-256color";
                };
              };
            };
          }
        )
      ];
    };
}
