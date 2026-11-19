{ ... }:
{
  flake.commonModules.home-dirs = {
    home-manager.sharedModules = [
      (
        { config, lib, ... }:
        {
          home.activation.mkDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
