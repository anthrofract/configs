{
  description = "Anthrofract's Config Collection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
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

    opencode = {
      url = "github:anomalyco/opencode/v1.14.22";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:amaanq/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
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
          nixFilesRecursive =
            dir:
            builtins.readDir dir
            |> builtins.mapAttrs (
              name: type:
              let
                path = dir + "/${name}";
              in
              if type == "directory" then
                nixFilesRecursive path
              else if builtins.match ".*\\.nix" name != null then
                [ path ]
              else
                [ ]
            )
            |> builtins.attrValues
            |> builtins.concatLists;
        in
        (builtins.readDir ./hosts |> builtins.attrNames |> map (name: ./hosts/${name}))
        ++ nixFilesRecursive ./config
        ++ nixFilesRecursive ./modules
        ++ nixFilesRecursive ./packages;
    };
}
