{ config, ... }:
let
  id = config.flake.secrets.identities.personal;
  authorizedKeys = config.flake.secrets.authorizedKeys;
in
{
  flake.nixosModules.user =
    { pkgs, ... }:
    {
      users.users.${id.userName} = {
        isNormalUser = true;
        description = id.userName;
        extraGroups = [
          "input"
          "networkmanager"
          "wheel"
        ];
        openssh.authorizedKeys.keys = authorizedKeys;
        shell = pkgs.nushell;
      };

      security.sudo-rs = {
        enable = true;
        extraConfig = ''
          Defaults lecture=never
          Defaults env_keep += "EDITOR PATH"
        '';
      };

      home-manager.users.${id.userName} = {
        home.preferXdgDirectories = true;
      };

      home-manager.sharedModules = [
        (
          {
            config,
            lib,
            ...
          }:
          {
            home.username = id.userName;
            home.homeDirectory = "/home/${id.userName}";

            programs.home-manager.enable = true;

            # Make some directories
            home.activation.mkDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              mkdir -p ${config.home.homeDirectory}/.local/share/nushell/vendor/autoload
              mkdir -p ${config.home.homeDirectory}/projects
              mkdir -p ${config.home.homeDirectory}/repos
              mkdir -p ${config.home.homeDirectory}/scratch
              mkdir -p ${config.home.homeDirectory}/work
            '';
          }
        )
      ];
    };
}
