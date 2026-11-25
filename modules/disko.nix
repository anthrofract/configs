{ inputs, ... }:
{
  # Single disk with an ESP, ext4 root, and swap partition. Hosts set the disk's
  # `device` and pin each partition's `uuid`, so disko mounts by PARTUUID.
  flake.nixosModules.disko-ext4 = {
    imports = [ inputs.disko.nixosModules.disko ];

    disko.devices.disk.main = {
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };
          swap = {
            size = "9G";
            content.type = "swap";
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
