{ self, ... }:
{
  flake.nixosModules.guiHost =
    { ... }:
    {
      imports = [
        self.nixosModules.baseHost
        self.nixosModules.development
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
