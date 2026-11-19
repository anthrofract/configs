{ config, ... }:
let
  id = config.secrets.identities.personal;
  authorizedKeys = config.secrets.authorizedKeys;
in
{
  flake.nixosModules.user =
    { pkgs, ... }:
    {
      users.users.${id.userName} = {
        isNormalUser = true;
        description = id.userName;
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        openssh.authorizedKeys.keys = authorizedKeys;
        shell = pkgs.nushell;
      };

      home-manager.users.${id.userName} = {
        home.preferXdgDirectories = true;
      };

      home-manager.sharedModules = [
        {
          home.username = id.userName;
          home.homeDirectory = "/home/${id.userName}";

          programs.home-manager.enable = true;
        }
      ];
    };
}
