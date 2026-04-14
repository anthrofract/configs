{ config, ... }:
let
  id = config.flake.secrets.identities.personal;
  hosts = config.flake.secrets.hosts;
in
{
  flake.nixosModules.syncthing =
    { ... }:
    {
      # Syncthing
      services.syncthing = {
        enable = true;
        overrideDevices = true;
        overrideFolders = true;
        user = id.userName;
        dataDir = "/home/${id.userName}";
        configDir = "/home/${id.userName}/.config/syncthing";
        openDefaultPorts = true;
        settings = {
          devices = {
            "valhalla" = {
              id = hosts.valhalla.syncthingId;
              addresses = [ "tcp://valhalla" ];
            };
            "asgard" = {
              id = hosts.asgard.syncthingId;
              addresses = [ "tcp://asgard" ];
            };
            "nidavellir" = {
              id = hosts.nidavellir.syncthingId;
              addresses = [ "tcp://nidavellir" ];
            };
            "zfold7" = {
              id = hosts.zfold7.syncthingId;
              addresses = [ "tcp://zfold7" ];
            };
            "work-mbp" = {
              id = hosts.work-mbp.syncthingId;
              addresses = [ "tcp://work-mbp" ];
            };
          };
          folders = {
            "notes" = {
              path = "/home/${id.userName}/notes";
              devices = [
                "valhalla"
                "asgard"
                "nidavellir"
                "zfold7"
                "work-mbp"
              ];
              versioning = {
                type = "staggered";
                params = {
                  cleanInterval = "3600";
                  maxAge = "31536000";
                };
              };
            };
            "pictures" = {
              path = "/home/${id.userName}/Pictures";
              devices = [
                "valhalla"
                "asgard"
                "nidavellir"
                "zfold7"
                "work-mbp"
              ];
              versioning = {
                type = "trashcan";
                params = {
                  cleanoutDays = "30";
                };
              };
            };
            "keepass" = {
              path = "/home/${id.userName}/keepass";
              devices = [
                "valhalla"
                "asgard"
                "nidavellir"
                "zfold7"
                "work-mbp"
              ];
              versioning = {
                type = "staggered";
                params = {
                  cleanInterval = "3600";
                  maxAge = "31536000";
                };
              };
            };
          };
        };
      };

      home-manager.sharedModules = [
        (
          { ... }:
          {
            services.syncthing.tray.enable = true;
          }
        )
      ];
    };
}
