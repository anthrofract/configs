# Root is a RAID0 array across both NVMe disks, and /boot is on a USB stick.
# The /data RAID10 array lives in default.nix so a reinstall never formats it,
# and the USB drive the NAS firmware needs to boot is deliberately not declared.
let
  rootArrayUuid = "9f0dbc9c:bbb7a7e2:647ec043:e3336262";
in
{
  disko.devices = {
    disk = {
      boot = {
        type = "disk";
        device = "/dev/disk/by-id/usb-USB_SanDisk_3.2Gen1_040121643dddcf51133ea8fb5a43a5ed7ee9f6d2f4d99c568bb85b9406f83435e405000000000000000000007f462f9eff1e061891558107c7ad79d1-0:0";
        content = {
          type = "gpt";
          partitions.ESP = {
            uuid = "fe0be450-b89a-4814-8727-058c88a17513";
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
        };
      };

      root0 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_2TB_S6S2NS0W508564B";
        content = {
          type = "mdraid";
          name = "root";
        };
      };

      root1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_2TB_S59CNM0W440978L";
        content = {
          type = "mdraid";
          name = "root";
        };
      };
    };

    mdadm.root = {
      type = "mdadm";
      level = 0;
      extraArgs = [ "--uuid=${rootArrayUuid}" ];
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
        # /dev/md/<name> depends on the array's homehost, so mount by array UUID instead
        device = "/dev/disk/by-id/md-uuid-${rootArrayUuid}";
      };
    };
  };
}
