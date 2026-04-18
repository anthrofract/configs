{ config, self, ... }:
{
  flake.commonModules.nixSettings = {
    nixpkgs.config.allowUnfree = true;

    nix.settings = {
      auto-optimise-store = true;
      download-buffer-size = 268435456;

      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];

      substituters = [
        "https://nix-community.cachix.org/"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      trusted-users = [
        "root"
        "@wheel"
      ];

      access-tokens = [
        "github.com=${config.flake.secrets.tokens.github}"
      ];

      http-connections = 50;
      use-xdg-base-directories = true;
      warn-dirty = false;
    };
  };

  flake.nixosModules.nixSettings = {
    imports = [ self.commonModules.nixSettings ];

    nix.gc.dates = "daily";
    nix.gc.automatic = true;
    nix.gc.options = "--delete-older-than 10d";
  };
}
