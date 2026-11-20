# Registry of every device. Host files register their NixOS or Darwin module here;
# private values (Syncthing IDs, real host names, devices without Nix) are set in config/secrets.nix.
{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib.attrsets) filterAttrs mapAttrs' nameValuePair;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    deferredModule
    lazyAttrsOf
    listOf
    nullOr
    str
    submodule
    ;

  configurationsOf =
    class: build:
    config.machines
    |> filterAttrs (_: machine: machine.${class} != null)
    |> mapAttrs' (_: machine: nameValuePair machine.hostName (build machine));
in
{
  options.machines = mkOption {
    type = lazyAttrsOf (
      submodule (
        { name, ... }:
        {
          options = {
            hostName = mkOption {
              type = str;
              default = name;
              description = "Host name reported by `hostname`, used as the configuration name.";
            };

            nixos = mkOption {
              type = nullOr deferredModule;
              default = null;
              description = "NixOS configuration of this machine.";
            };

            darwin = mkOption {
              type = nullOr deferredModule;
              default = null;
              description = "nix-darwin configuration of this machine.";
            };

            syncthing.id = mkOption {
              type = nullOr str;
              default = null;
              description = "Syncthing device ID.";
            };

            syncthing.addresses = mkOption {
              type = listOf str;
              default = [ "tcp://${name}" ];
              description = "Syncthing addresses of this device.";
            };

            syncthing.folders = mkOption {
              type = listOf str;
              default = [ ];
              description = "Syncthing folders shared with this device.";
            };
          };
        }
      )
    );
    default = { };
    description = "Every device: NixOS and Darwin hosts plus devices that don't run Nix.";
  };

  config.flake.nixosConfigurations = configurationsOf "nixos" (
    machine:
    inputs.nixpkgs.lib.nixosSystem {
      modules = [
        machine.nixos
        { networking.hostName = machine.hostName; }
      ];
    }
  );

  config.flake.darwinConfigurations = configurationsOf "darwin" (
    machine:
    inputs.nix-darwin.lib.darwinSystem {
      modules = [ machine.darwin ];
    }
  );
}
