{ config, lib, ... }:
let
  id = config.secrets.identities.personal;
  devices = config.machines |> lib.filterAttrs (_: machine: machine.syncthing.id != null);
  devicesSharing =
    folder:
    devices |> lib.filterAttrs (_: machine: lib.elem folder machine.syncthing.folders) |> lib.attrNames;
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
          devices = devices |> lib.mapAttrs (_: machine: { inherit (machine.syncthing) id addresses; });
          folders = {
            "notes" = {
              path = "/home/${id.userName}/notes";
              devices = devicesSharing "notes";
              versioning = {
                type = "staggered";
                params = {
                  cleanInterval = "3600"; # 1 hour
                  maxAge = "31536000"; # 365 days
                };
              };
            };
            "pictures" = {
              path = "/home/${id.userName}/Pictures";
              devices = devicesSharing "pictures";
              versioning = {
                type = "trashcan";
                params = {
                  cleanoutDays = "30";
                };
              };
            };
            "keepass" = {
              path = "/home/${id.userName}/keepass";
              devices = devicesSharing "keepass";
              versioning = {
                type = "staggered";
                params = {
                  cleanInterval = "3600"; # 1 hour
                  maxAge = "31536000"; # 365 days
                };
              };
            };
            "emulation" = {
              path = "/home/${id.userName}/Emulation";
              devices = devicesSharing "emulation";
              type = "sendreceive";
              versioning = {
                type = "staggered";
                params = {
                  cleanInterval = "3600"; # 1 hour
                  maxAge = "2592000"; # 30 days
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
