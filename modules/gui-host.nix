{ self, ... }:
{
  flake.nixosModules.gui-host =
    { ... }:
    {
      imports = [
        self.commonModules.development
        self.nixosModules.base-host
        self.nixosModules.flatpak
        self.nixosModules.fonts
        self.nixosModules.gaming
        self.nixosModules.gui-programs
        self.nixosModules.gui-system
        self.nixosModules.plasma
        self.nixosModules.smartcards
        self.nixosModules.xremap
      ];
    };
}
