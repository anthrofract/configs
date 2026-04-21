{ self, ... }:
{
  flake.nixosModules.base-host =
    { ... }:
    {
      imports = [
        self.commonModules.env
        self.commonModules.home-symlinks
        self.commonModules.vcs
        self.nixosModules.base-settings
        self.nixosModules.cli
        self.nixosModules.docker
        self.nixosModules.home-manager
        self.nixosModules.nix-settings
        self.nixosModules.ssh
        self.nixosModules.syncthing
        self.nixosModules.tailscale
        self.nixosModules.user
      ];
    };
}
