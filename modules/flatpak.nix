{ ... }:
{
  flake.nixosModules.flatpak =
    { pkgs, ... }:
    {
      services.flatpak.enable = true;
      system.activationScripts.flatpak-repo = {
        text = ''
          ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        '';
      };
    };
}
