{ config, ... }:
let
  id = config.secrets.identities.personal;
in
{
  flake.commonModules.nushell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = [ pkgs.nushell ];

      environment.etc."nu-with-config/nu".source = "${
        config.users.users.${id.userName}.home
      }/bin/nu-with-config/nu";

      home-manager.sharedModules = [
        (
          { config, ... }:
          lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
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
