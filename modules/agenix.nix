{ config, inputs, ... }:
let
  identityPath = home: "${home}/.ssh/${config.secrets.identities.personal.sshKey}";
in
{
  flake.nixosModules.agenix = {
    imports = [ inputs.agenix.nixosModules.default ];

    age.identityPaths = [ (identityPath "/home/${config.secrets.identities.personal.userName}") ];
  };

  flake.darwinModules.agenix = {
    imports = [ inputs.agenix.darwinModules.default ];

    age.identityPaths = [ (identityPath "/Users/${config.secrets.identities.personal.userName}") ];
  };
}
