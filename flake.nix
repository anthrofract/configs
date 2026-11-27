{
  description = "Anthrofract's Config Collection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-latest.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    autolith.url = "github:lambda-symbolics/autolith";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dux-shell = {
      url = "github:duxlabs-dev/dux-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dux-calendar = {
      url = "github:duxlabs-dev/dux-calendar";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dux-qt-base.follows = "dux-shell/dux-qt-base";
    };

    dank-calculator = {
      url = "github:rochacbruno/DankCalculator";
      flake = false;
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    xremap = {
      url = "github:xremap/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    majjit = {
      url = "github:anthrofract/majjit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bip39gen = {
      url = "github:anthrofract/bip39gen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nu-scripts = {
      url = "github:nushell/nu_scripts";
      flake = false;
    };

    helium = {
      url = "github:amaanq/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixarr = {
      url = "github:nix-media-server/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports =
        let
          inherit (inputs.nixpkgs) lib;
          nixFilesRecursive =
            dir:
            lib.filesystem.listFilesRecursive dir
            |> lib.filter (path: lib.strings.hasSuffix ".nix" (toString path));
        in
        (lib.mapAttrsToList (name: _: ./hosts/${name}) (lib.filesystem.readDir ./hosts))
        ++ nixFilesRecursive ./config
        ++ nixFilesRecursive ./modules
        ++ nixFilesRecursive ./packages;
    };
}
