{
  inputs,
  lib,
  moduleLocation,
  ...
}:
let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.options) mkOption;
  inherit (lib.types) deferredModule lazyAttrsOf;

  wrap =
    kind: class: name: module:
    {
      _file = "${toString moduleLocation}#${kind}.${name}";
      key = "${toString moduleLocation}#${kind}.${name}";
      imports = [ module ];
    }
    // lib.optionalAttrs (class != null) { _class = class; };

  mkModulesOption =
    kind: class: description:
    mkOption {
      type = lazyAttrsOf deferredModule;
      default = { };
      apply = mapAttrs (wrap kind class);
      inherit description;
    };
in
{
  disabledModules = [ "${inputs.flake-parts}/modules/nixosModules.nix" ];

  options.flake.nixosModules = mkModulesOption "nixosModules" "nixos" "NixOS modules.";
  options.flake.darwinModules = mkModulesOption "darwinModules" "darwin" "Darwin modules.";
  options.flake.commonModules =
    mkModulesOption "commonModules" null
      "Modules shared between NixOS and Darwin.";
}
