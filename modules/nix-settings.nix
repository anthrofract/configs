{ config, self, ... }:
{
  flake.commonModules.nix-settings = {
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
        "github.com=${config.secrets.tokens.github}"
      ];

      http-connections = 50;
      use-xdg-base-directories = true;
      warn-dirty = false;
    };
  };

  flake.nixosModules.nix-settings = {
    imports = [ self.commonModules.nix-settings ];

    programs.nh = {
      enable = true;
      flake = "/home/${config.secrets.identities.personal.userName}/configs";

      clean = {
        enable = true;
        dates = "daily";
        extraArgs = "--keep-since 3d --keep 2";
      };
    };

    programs.nix-ld.enable = true;
  };

  flake.darwinModules.nix-settings =
    { pkgs, ... }:
    {
      imports = [ self.commonModules.nix-settings ];

      launchd.daemons.nh-clean = {
        serviceConfig = {
          ProgramArguments = [
            "${pkgs.nh}/bin/nh"
            "clean"
            "all"
            "--keep-since"
            "3d"
            "--keep"
            "2"
          ];
          StartCalendarInterval = [
            {
              Hour = 3;
              Minute = 15;
            }
          ];
        };
      };
    };
}
