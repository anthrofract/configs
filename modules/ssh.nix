{
  config,
  lib,
  self,
  ...
}:
let
  hostNames = config.machines |> lib.attrNames;
  foreignHostPattern = ([ "*" ] ++ map (host: "!${host}") hostNames) |> lib.concatStringsSep " ";
in
{
  flake.commonModules.ssh-known-hosts = {
    programs.ssh.knownHosts =
      config.machines
      |> lib.filterAttrs (_: machine: machine.ssh.hostKey != null)
      |> lib.mapAttrs (_: machine: { publicKey = machine.ssh.hostKey; });
  };

  flake.nixosModules.ssh =
    { pkgs, ... }:
    {
      imports = [ self.commonModules.ssh-known-hosts ];

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
              settings.work-mbp.SetEnv = {
                TERMINFO = "/run/current-system/sw/share/terminfo";
              };
              settings."${foreignHostPattern}" = {
                SetEnv = {
                  TERM = "xterm-256color";
                };
              };
            };
          }
        )
      ];
    };
}
