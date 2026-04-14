{
  self,
  config,
  inputs,
  ...
}:
{
  flake.darwinConfigurations.${config.flake.secrets.hosts.work-mbp.localHostName} =
    inputs.nix-darwin.lib.darwinSystem
      {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          self.darwinModules.darwin
          {
            system.stateVersion = 6;
            home-manager.sharedModules = [
              {
                home.stateVersion = "25.05";
              }
            ];
          }
        ];
      };
}
