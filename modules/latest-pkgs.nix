{ inputs, ... }:
{
  flake.commonModules.latest-pkgs =
    { pkgs, ... }:
    let
      latestPkgs = import inputs.nixpkgs-latest {
        inherit (pkgs.stdenv.hostPlatform) system;
        config = pkgs.config;
      };
    in
    {
      _module.args = { inherit latestPkgs; };
      home-manager.extraSpecialArgs = { inherit latestPkgs; };
    };
}
