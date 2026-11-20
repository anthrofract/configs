{ self, ... }:
{
  machines.work-mbp.darwin = {
    imports = [ self.darwinModules.darwin ];

    system.stateVersion = 6;
    home-manager.sharedModules = [
      {
        home.stateVersion = "25.05";
      }
    ];
  };
}
