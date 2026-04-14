{ config, ... }:
let
  id = config.flake.secrets.identities.personal;
in
{
  flake.nixosModules.gaming =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        gamescopeSession.enable = true;
        protontricks.enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };
      hardware.steam-hardware.enable = true;

      services.udev.packages = [ pkgs.game-devices-udev-rules ];

      programs.gamescope = {
        enable = true;
        capSysNice = true;
      };

      programs.gamemode.enable = true;

      # Allow SteamVR to run properly
      system.activationScripts.steamvr-capset.text = ''
        ${pkgs.libcap}/bin/setcap CAP_SYS_NICE+ep /home/${id.userName}/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher 2>/dev/null || true
      '';

      home-manager.sharedModules = [
        (
          { pkgs, ... }:
          {
            home.packages = [
              (pkgs.prismlauncher.override { jdks = [ pkgs.zulu25 ]; })
              pkgs.limo
            ];
          }
        )
      ];
    };
}
