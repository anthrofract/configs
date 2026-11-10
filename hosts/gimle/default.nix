{
  config,
  self,
  inputs,
  ...
}:
let
  userName = config.secrets.identities.personal.userName;
in
{
  flake = {
    nixosConfigurations.gimle = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.gimle-configuration
      ];
    };

    nixosModules.gimle-configuration =
      { modulesPath, pkgs, ... }:
      {
        imports = [
          "${modulesPath}/profiles/minimal.nix"
          "${modulesPath}/installer/cd-dvd/iso-image.nix"
          self.nixosModules.home-manager
          self.nixosModules.plasma
          self.nixosModules.fonts
          self.nixosModules.xremap
          self.nixosModules.encryption
          self.commonModules.latest-pkgs
          self.commonModules.ghostty
          self.commonModules.cli
        ];

        networking.hostName = "gimle";
        system.stateVersion = "26.11";
        time.timeZone = "UTC";

        # Disable networking
        networking = {
          useDHCP = false;
          dhcpcd.enable = false;
          networkmanager.enable = false;
          wireless.enable = false;
          wireless.iwd.enable = false;
          useNetworkd = true;
          enableIPv6 = false;
          nftables = {
            enable = true;
            tables.gimle-offline = {
              family = "inet";
              content = ''
                chain output {
                  type filter hook output priority filter; policy drop;
                  oifname "lo" accept
                }
              '';
            };
          };
        };
        systemd.network = {
          wait-online.enable = false;
          networks."10-always-down" = {
            matchConfig.Type = "!loopback";
            linkConfig.ActivationPolicy = "always-down";
            networkConfig = {
              DHCP = "no";
              LinkLocalAddressing = "no";
              IPv6AcceptRA = false;
            };
          };
        };
        services.resolved.enable = false;
        services.geoclue2.enable = false;
        services.fwupd.enable = false;
        boot.initrd.network.enable = false;
        boot.initrd.systemd.network.enable = false;
        boot.kernelParams = [
          "ipv6.disable=1"
          # Block radio/audio core modules, including dependency loads.
          "module_blacklist=cfg80211,bluetooth,snd,soundcore"
        ];

        # Disable Bluetooth
        hardware.bluetooth.enable = false;

        # Disable audio
        hardware.alsa.enable = false;
        services.pipewire.enable = false;
        services.pulseaudio.enable = false;

        # Live image and portable hardware support
        hardware.enableAllHardware = true;

        isoImage.makeBiosBootable = true;
        isoImage.makeEfiBootable = true;
        isoImage.makeUsbBootable = true;
        isoImage.appendToMenuLabel = " Gimle Live";
        isoImage.edition = "gimle";
        system.disableInstallerTools = true;

        # Desktop and input
        services.displayManager = {
          sddm.enable = true;
          autoLogin = {
            enable = true;
            user = userName;
          };
        };
        environment.systemPackages = [
          pkgs.wl-clipboard-rs
          pkgs.keepassxc
          pkgs.sparrow
        ];

        # Live user
        users.users.${userName} = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          shell = pkgs.nushell;
        };
        environment.shells = [ pkgs.nushell ];
        services.getty.autologinUser = userName;
        security.sudo.wheelNeedsPassword = false;

        # Home files
        home-manager.users.${userName} =
          { config, lib, ... }:
          {
            programs.nixvim.plugins.lsp.enable = lib.mkForce false;
            programs.ghostty.settings.initial-command = "${pkgs.nushell}/bin/nu -il -c \"tms ~/scratch\"";
            programs.plasma.kscreenlocker = {
              autoLock = false;
              lockOnResume = false;
              passwordRequired = false;
            };
            programs.plasma.taskbarLaunchers = [
              "applications:com.mitchellh.ghostty.desktop"
              "applications:org.keepassxc.KeePassXC.desktop"
              "applications:org.kde.dolphin.desktop"
            ];

            home.username = userName;
            home.homeDirectory = "/home/${userName}";
            home.stateVersion = "26.11";
            home.preferXdgDirectories = true;
            xdg.userDirs = {
              enable = true;
              createDirectories = true;
              projects = "${config.home.homeDirectory}/scratch";
            };
            home.file = {
              "bin/c".source = ../../home/bin/c;
              "bin/tms".source = ../../home/bin/tms;
              ".config/helix".source = ../../home/.config/helix;
              ".config/nushell/config.nu".source = ../../home/.config/nushell/config.nu;
              ".config/starship.toml".source = ../../home/.config/starship.toml;
            };
            home.activation.mkDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              mkdir -p ${config.home.homeDirectory}/.local/share/nushell/vendor/autoload
              mkdir -p ${config.home.homeDirectory}/scratch
            '';
          };
      };
  };
}
