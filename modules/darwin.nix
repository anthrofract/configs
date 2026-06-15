{
  self,
  config,
  inputs,
  ...
}:
let
  ids = config.secrets.identities;
in
{
  config.flake.darwinModules.darwin =
    { pkgs, ... }:
    let
      latestPkgs = import inputs.nixpkgs-latest {
        inherit (pkgs.stdenv.hostPlatform) system;
        config = pkgs.config;
      };
    in
    {
      imports = [
        inputs.home-manager.darwinModules.home-manager
        self.commonModules.cli
        self.commonModules.development
        self.commonModules.env
        self.commonModules.ghostty
        self.commonModules.home-symlinks
        self.commonModules.vcs
        self.darwinModules.helium
        self.darwinModules.nix-settings
      ];

      nix.enable = false; # For determinate nix
      nixpkgs.hostPlatform = "aarch64-darwin";

      environment.systemPackages = [
        latestPkgs.zed-editor
        pkgs.google-chrome
        pkgs.keepassxc
        pkgs.meetingbar
        pkgs.obsidian
        pkgs.opensc
        pkgs.raycast
        pkgs.signal-desktop
        pkgs.spotify
        pkgs.tart
        pkgs.yubikey-manager
        pkgs.zoom-us
      ];

      environment.variables = {
        LANG = "en_US.UTF-8";
        LC_CTYPE = "en_US.UTF-8";
      };

      services.openssh = {
        enable = true;
        extraConfig = ''
          AcceptEnv TERMINFO
        '';
      };

      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = true;
          cleanup = "zap";
          upgrade = true;
          extraFlags = [ "--force-cleanup" ];
        };
        casks = [
          "docker-desktop"
          "karabiner-elements"
          "slack"
          "syncthing-app"
          "tailscale-app"
        ];
      };

      system.defaults.NSGlobalDomain.NSAutomaticWindowAnimationsEnabled = false;
      system.defaults.NSGlobalDomain.NSWindowShouldDragOnGesture = true;
      system.defaults.controlcenter.Bluetooth = true;
      system.defaults.controlcenter.Sound = true;
      system.defaults.dock.autohide = true;
      system.defaults.dock.expose-group-apps = true;
      system.defaults.dock.orientation = "right";
      system.defaults.dock.show-recents = false;
      system.defaults.finder.AppleShowAllExtensions = true;
      system.defaults.finder.AppleShowAllFiles = true;
      system.defaults.finder.FXRemoveOldTrashItems = true;
      system.defaults.finder._FXShowPosixPathInTitle = true;
      system.defaults.finder._FXSortFoldersFirst = true;
      system.defaults.spaces.spans-displays = true;
      system.keyboard.enableKeyMapping = true;
      system.keyboard.remapCapsLockToEscape = true;

      launchd.daemons.limit-maxfiles = {
        serviceConfig = {
          Label = "limit.maxfiles";
          ProgramArguments = [
            "/bin/launchctl"
            "limit"
            "maxfiles"
            "524288"
            "524288"
          ];
          RunAtLoad = true;
        };
      };

      system.primaryUser = ids.personal.userName;
      users.users.${ids.personal.userName} = {
        home = "/Users/${ids.personal.userName}";
        openssh.authorizedKeys.keys = config.secrets.authorizedKeys;
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs; };
        users.${ids.personal.userName} = { };
        sharedModules = [
          {
            home.username = ids.personal.userName;
            home.homeDirectory = "/Users/${ids.personal.userName}";
            programs.home-manager.enable = true;
            programs.ghostty.settings.font-size = 16;
          }
        ];
      };
    };
}
