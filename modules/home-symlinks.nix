# Symlinks all files under ./home into $HOME using home-manager.
# Uses mkOutOfStoreSymlink so the symlinks point to the live configs repo,
# keeping files editable without a rebuild.
{ lib, ... }:
let
  homeDir = ../home;
  relPaths =
    lib.filesystem.listFilesRecursive homeDir
    |> map (path: lib.strings.removePrefix "${toString homeDir}/" (toString path));
in
{
  flake.commonModules.home-symlinks = {
    home-manager.sharedModules = [
      (
        { config, ... }:
        let
          dotfiles = "${config.home.homeDirectory}/configs/home";
        in
        {
          home.file = lib.genAttrs relPaths (path: {
            source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
          });
        }
      )
    ];
  };
}
