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
                version = "19.1.0";
                src = old.src.override {
                  tag = "v${finalAttrs.version}";
                  hash = "sha256-aBhxgL3d4R3a7Prfu/iZWyUgfCqId4XBiI2Aye1JxR0=";
                };
                cargoDeps = final.rustPlatform.fetchCargoVendor {
                  inherit (finalAttrs) src;
                  hash = "sha256-RD+qnzGe0Wu6dQDs2L1HbPkZW5OB5UpmGKaAFZWin4g=";
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
