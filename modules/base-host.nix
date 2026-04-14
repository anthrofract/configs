{ self, ... }:
{
  flake.nixosModules.baseHost =
    { ... }:
    {
      imports = [
        self.nixosModules.baseSettings
        self.nixosModules.cli
        self.nixosModules.docker
        self.nixosModules.homeManager
        self.nixosModules.homeSymlinks
        self.nixosModules.nixSettings
        self.nixosModules.ssh
        self.nixosModules.syncthing
        self.nixosModules.tailscale
        self.nixosModules.user
        self.nixosModules.vcs
      ];
    };
}
