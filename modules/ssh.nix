{
  config,
  lib,
  self,
  ...
}:
let
  hostNames = config.machines |> lib.attrNames;
  foreignHostPattern = ([ "*" ] ++ map (host: "!${host}") hostNames) |> lib.concatStringsSep " ";
  sshHosts = config.machines |> lib.filterAttrs (_: machine: machine.ssh.hostKey != null);
  tailnetName = name: "${name}.${config.secrets.tailnetDomain}";
in
{
  flake.commonModules.ssh-client = {
    programs.ssh.knownHosts =
      sshHosts
      |> lib.mapAttrs (
        name: machine: {
          hostNames = [
            name
            (tailnetName name)
          ];
          publicKey = machine.ssh.hostKey;
        }
      );

    home-manager.sharedModules = [
      {
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings."*" = {
            ControlMaster = "auto";
            ControlPath = "~/.ssh/control-%C";
            ControlPersist = "10m";
          };
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
      {
        # A bare name can also resolve to the router's LAN record, which bypasses Tailscale SSH
        programs.ssh.settings = sshHosts |> lib.mapAttrs (name: _: { HostName = tailnetName name; });
      }
    ];
  };

  flake.nixosModules.ssh =
    { pkgs, ... }:
    {
      imports = [ self.commonModules.ssh-client ];

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
    };
}
