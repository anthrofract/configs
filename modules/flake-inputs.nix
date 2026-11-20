{
  inputs,
  lib,
  self,
  ...
}:
let
  # Every flake input, including inputs of inputs, named like `nixvim.flake-parts`.
  # `self` is left out so the repo source, which includes the decrypted secrets, isn't kept or deployed.
  flakeInputs =
    let
      collect =
        prefix: nodes:
        nodes
        |> lib.mapAttrsToList (
          name: input:
          [
            {
              name = "${prefix}${name}";
              path = input.outPath;
            }
          ]
          ++ collect "${prefix}${name}." (input.inputs or { })
        )
        |> lib.concatLists;
    in
    collect "" (removeAttrs inputs [ "self" ]);
in
{
  flake.commonModules.flake-inputs =
    { pkgs, ... }:
    {
      # Linking every input into the system keeps their sources from being garbage collected.
      environment.etc."nix/flake-inputs".source = pkgs.linkFarm "flake-inputs" flakeInputs;
    };

  flake.nixosModules.flake-inputs =
    { config, ... }:
    {
      imports = [ self.commonModules.flake-inputs ];

      # Pin every flake input in the registry and NIX_PATH, e.g. `nix shell nixpkgs-latest#foo`.
      # NixOS already pins nixpkgs itself, and `self` would pull the repo source into the system.
      nix.registry =
        removeAttrs inputs [
          "self"
          "nixpkgs"
        ]
        |> lib.filterAttrs (_: input: input._type or null == "flake")
        |> lib.mapAttrs (_: flake: { inherit flake; });
      nix.nixPath = config.nix.registry |> lib.attrNames |> map (name: "${name}=flake:${name}");
    };
}
