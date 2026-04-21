{ inputs, lib, ... }:
let
  inherit (lib.attrsets) hasAttr optionalAttrs;
in
{
  perSystem =
    { self', system, ... }:
    optionalAttrs (hasAttr system inputs.zmk-nix.packages) {
      packages.lily58-firmware = inputs.zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
        name = "lily58-firmware";

        src = ./.;

        board = "nice_nano@2.0.0//zmk";
        shield = "lily58_%PART% nice_view_adapter nice_view";

        extraCmakeFlags = [
          "-DCONFIG_ZMK_DISPLAY=y"
          "-DCONFIG_ZMK_MOUSE=y"
        ];

        zephyrDepsHash = "sha256-yZd+C2k9Kb1TKzXS6rR3/Jcs3UAGeKmq0YwdylODRgs=";

        meta = {
          description = "ZMK firmware for Lily58";
          license = lib.licenses.mit;
          platforms = lib.platforms.all;
        };
      };

      packages.lily58-flash = inputs.zmk-nix.packages.${system}.flash.override {
        firmware = self'.packages.lily58-firmware;
      };

      packages.lily58-update = inputs.zmk-nix.packages.${system}.update;
    };
}
