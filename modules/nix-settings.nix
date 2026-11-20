{
  config,
  lib,
  self,
  ...
}:
let
  settings = {
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

    http-connections = 50;
    use-xdg-base-directories = true;
    warn-dirty = false;
  };
in
{
  flake.commonModules.nix-settings = {
    nixpkgs.config.allowUnfree = true;
  };

  flake.nixosModules.nix-settings =
    { pkgs, ... }:
    {
      imports = [ self.commonModules.nix-settings ];

      # nh needs dix on a remote --target-host to diff against its current system.
      environment.systemPackages = [ pkgs.dix ];

      nix.settings = settings // {
        auto-optimise-store = true;
        trusted-users = [
          "root"
          "@wheel"
        ];
      };

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

      environment.etc."nix/nix.custom.conf" = {
        knownSha256Hashes = [ "3bd68ef979a42070a44f8d82c205cfd8e8cca425d91253ec2c10a88179bb34aa" ];
        text =
          settings // { trusted-users = [ "@admin" ]; }
          |> lib.mapAttrsToList (
            name: value:
            if lib.isList value then
              "extra-${name} = ${lib.concatStringsSep " " value}"
            else
              "${name} = ${if lib.isBool value then lib.boolToString value else toString value}"
          )
          |> lib.concatLines;
      };

      environment.systemPackages = [ pkgs.nh ];

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
