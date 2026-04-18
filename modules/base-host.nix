{ self, ... }:
{
  flake.nixosModules.baseHost =
    { ... }:
    {
      imports = [
        self.commonModules.env
        self.commonModules.homeSymlinks
        self.commonModules.vcs
        self.nixosModules.baseSettings
        self.nixosModules.cli
        self.nixosModules.docker
        self.nixosModules.homeManager
        self.nixosModules.nixSettings
        self.nixosModules.ssh
        self.nixosModules.syncthing
        self.nixosModules.tailscale
        self.nixosModules.user
      ];
    };
}
