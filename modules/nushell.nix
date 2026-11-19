{ ... }:
{
  flake.commonModules.nushell =
    {
      lib,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = [ pkgs.nushell ];

      environment.etc."nu-with-config/nu".source = ../home/bin/nu-with-config/nu;

      home-manager.sharedModules = [
        (
          { config, lib, ... }:
          {
            home.activation.mkNushellAutoloadDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              mkdir -p ${config.home.homeDirectory}/.local/share/nushell/vendor/autoload
            '';
          }
        )

        # Symlink nushell config to macOS default location so config.nu loads before XDG_CONFIG_HOME is set
        (
          { config, ... }:
          lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
            home.file."Library/Application Support/nushell/config.nu" = {
              force = true;
              source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/configs/home/.config/nushell/config.nu";
            };
          }
        )
      ];
    };
}
