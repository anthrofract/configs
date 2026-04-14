# Symlinks all files under ./home into $HOME using home-manager.
# Uses mkOutOfStoreSymlink so the symlinks point to the live configs repo,
# keeping files editable without a rebuild.
{ lib, ... }:
let
  homeDir = ../home;

  # Recursively collect all file paths under a directory, relative to homeDir.
  collectFiles =
    prefix: dir:
    builtins.readDir dir
    |> lib.mapAttrsToList (
      name: type:
      let
        path = "${prefix}${name}";
      in
      if type == "directory" then collectFiles "${path}/" (dir + "/${name}") else [ path ]
    )
    |> lib.concatLists;

  allFiles = collectFiles "" homeDir;

  mod = {
    home-manager.sharedModules = [
      (
        { config, ... }:
        let
          dotfiles = "${config.home.homeDirectory}/configs/home";
          mkLink = config.lib.file.mkOutOfStoreSymlink;
        in
        {
          # Create a symlink in $HOME for each file, pointing back to the configs repo.
          # Parent directories are created automatically by home-manager.
          home.file =
            allFiles
            |> map (path: {
              name = path;
              value.source = mkLink "${dotfiles}/${path}";
            })
            |> lib.listToAttrs;
        }
      )
    ];
  };
in
{
  flake.nixosModules.homeSymlinks = mod;
  flake.darwinModules.homeSymlinks = mod;
}
