{ ... }:
{
  flake.nixosModules.fonts =
    { pkgs, ... }:
    {
      fonts.packages = [
        pkgs.cascadia-code
        pkgs.commit-mono
        pkgs.dejavu_fonts
        pkgs.fira-code
        pkgs.font-awesome
        pkgs.garamond-libre
        pkgs.gelasio
        pkgs.iosevka
        pkgs.iosevka-comfy.comfy
        pkgs.jetbrains-mono
        pkgs.libre-baskerville
        pkgs.lilex
        pkgs.nerd-fonts.symbols-only
        pkgs.noto-fonts
        pkgs.noto-fonts-color-emoji
        pkgs.roboto-mono
      ];

      home-manager.sharedModules = [
        {
          fonts.fontconfig.enable = true;
        }
      ];
    };
}
