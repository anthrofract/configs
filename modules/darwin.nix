{
  self,
  config,
  inputs,
  ...
}:
let
  ids = config.flake.secrets.identities;
in
{
  config.flake.darwinModules.darwin =
    { pkgs, ... }:
    {
      imports = [
        inputs.home-manager.darwinModules.home-manager
        self.commonModules.development
        self.commonModules.env
        self.commonModules.homeSymlinks
        self.commonModules.nixSettings
        self.commonModules.vcs
        self.darwinModules.cli
        self.darwinModules.helium
      ];

      nix.enable = false; # For determinate nix
      nixpkgs.hostPlatform = "aarch64-darwin";

      environment.systemPackages = [
        pkgs.opensc
        pkgs.yubikey-manager
      ];

      services.openssh.enable = true;

      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = true;
          cleanup = "zap";
          upgrade = true;
        };
        casks = [
          "brave-browser"
          "claude-code"
          "cursor"
          "docker-desktop"
          "ghostty"
          "google-chrome"
          "iterm2"
          "karabiner-elements"
          "keepassxc"
          "meetingbar"
          "obsidian"
          "raycast"
          "signal"
          "slack"
          "spotify"
          "syncthing-app"
          "tailscale-app"
          "ungoogled-chromium"
          "zed"
          "zoom"
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
        openssh.authorizedKeys.keys = config.flake.secrets.authorizedKeys;
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
          }
        ];
      };
    };
}
