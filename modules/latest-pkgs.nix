{ inputs, ... }:
{
  flake.commonModules.latest-pkgs =
    { pkgs, ... }:
    let
      latestPkgs = import inputs.nixpkgs-latest {
        inherit (pkgs.stdenv.hostPlatform) system;
        config = pkgs.config;
        overlays = [
          (final: prev: {
            omp = prev.omp.overrideAttrs (
              finalAttrs: old: {
                version = "19.1.1";
                src = old.src.override {
                  tag = "v${finalAttrs.version}";
                  hash = "sha256-NcYk0wu54+NmwsumDgRgDrsh5ZlbaQ2NJHgS90cxskw=";
                };
                cargoDeps = final.rustPlatform.fetchCargoVendor {
                  inherit (finalAttrs) src;
                  hash = "sha256-i3KsqsSJHAGbamHfsF/FVdvXkXN9B/qoKcgAjz9TJ9I=";
                };
                node_modules = old.node_modules.overrideAttrs {
                  outputHash = "sha256-vaHHl+2xGbMCJcV5PGhYx0EbMBJ6BdCwYt3OWXEB9Ls=";
                };
              }
            );
          })
        ];
      };
    in
    {
      _module.args = { inherit latestPkgs; };
      home-manager.extraSpecialArgs = { inherit latestPkgs; };
    };
}
