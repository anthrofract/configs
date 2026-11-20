{ self, ... }:
{
  flake.commonModules.cli =
    { pkgs, ... }:
    {
      imports = [
        self.commonModules.neovim
        self.commonModules.nushell
        self.commonModules.tmux
      ];

      environment.systemPackages = [
        pkgs.bc
        pkgs.btop
        pkgs.difftastic
        pkgs.fastfetch
        pkgs.fd
        pkgs.gnumake
        pkgs.inetutils
        pkgs.jc
        pkgs.jq
        pkgs.just
        pkgs.lazyjournal
        pkgs.less
        pkgs.lsd
        pkgs.lsof
        pkgs.moreutils
        pkgs.openssl
        pkgs.ouch
        pkgs.rclone
        pkgs.ripgrep
        pkgs.sd
        pkgs.tokei
        pkgs.tree-sitter
        pkgs.unzip
        pkgs.usbutils
        pkgs.uutils-coreutils-noprefix
        pkgs.watchman
        pkgs.wget
        pkgs.wireguard-tools
      ];

      home-manager.sharedModules = [
        (
          { ... }:
          {
            programs.bat = {
              enable = true;
              config.theme = "Visual Studio Dark+";
            };

            programs.helix.enable = true;

            programs.fzf = {
              enable = true;
              enableNushellIntegration = false;
              defaultOptions = [
                "--pointer='>'"
                "--gutter=' '"
              ];
              colors = {
                "bg+" = "#30363F";
                "fg+" = "white";
                gutter = "-1";
                hl = "#C98E56";
                "hl+" = "#C98E56";
                pointer = "#C98E56";
              };
            };
          }
        )
      ];
    };
}
