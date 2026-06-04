{ ... }:
{
  flake.commonModules.nushell =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.nushell ];

      home-manager.sharedModules = [
        (
          { config, ... }:
          lib.mkIf pkgs.stdenv.isDarwin {
            # Symlink nushell config to macOS default location so config.nu loads before XDG_CONFIG_HOME is set
            home.file."Library/Application Support/nushell/config.nu" = {
              force = true;
              source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/configs/home/.config/nushell/config.nu";
            };
          }
        )
      ];
    };
}
