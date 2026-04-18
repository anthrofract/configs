{ self, ... }:
{
  flake.nixosModules.guiHost =
    { ... }:
    {
      imports = [
        self.commonModules.development
        self.nixosModules.baseHost
        self.nixosModules.flatpak
        self.nixosModules.fonts
        self.nixosModules.gaming
        self.nixosModules.guiPrograms
        self.nixosModules.guiSystem
        self.nixosModules.plasma
        self.nixosModules.smartcards
        self.nixosModules.xremap
      ];
    };
}
