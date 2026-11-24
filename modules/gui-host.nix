{ self, ... }:
{
  flake.nixosModules.gui-host =
    { ... }:
    {
      imports = [
        self.commonModules.development
        self.nixosModules.base-host
        self.nixosModules.flake-inputs
        self.nixosModules.flatpak
        self.nixosModules.fonts
        self.nixosModules.gaming
        self.nixosModules.gui-programs
        self.nixosModules.gui-system
        self.nixosModules.hyprland
        self.nixosModules.plasma
        self.nixosModules.wallpapers
        self.nixosModules.encryption
        self.nixosModules.xremap
      ];

      programs.kdeconnect.enable = true;
    };
}
