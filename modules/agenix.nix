{ config, inputs, ... }:
let
  sshKey = config.secrets.identities.personal.sshKey;
in
{
  flake.commonModules.agenix = {
    home-manager.sharedModules = [
      (
        { config, ... }:
        {
          imports = [ inputs.agenix.homeManagerModules.default ];

          age.identityPaths = [ "${config.home.homeDirectory}/.ssh/${sshKey}" ];
          age.secretsDir = "${config.xdg.stateHome}/agenix";
        }
      )
    ];
  };
}
