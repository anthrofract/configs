{ self, ... }:
{
  flake.commonModules.cli =
    { pkgs, ... }:
    {
      imports = [
        self.commonModules.nushell
        self.commonModules.tmux
      ];

      environment.systemPackages = [
        pkgs.asciinema
        pkgs.bc
        pkgs.btop
        pkgs.carapace
        pkgs.difftastic
        pkgs.fastfetch
        pkgs.fd
        pkgs.fzf
        pkgs.gh
        pkgs.gnumake
        pkgs.gnupg
        pkgs.inetutils
        pkgs.jc
        pkgs.jq
        pkgs.just
        pkgs.lazyjournal
        pkgs.less
        pkgs.lsd
        pkgs.lsof
        pkgs.moreutils
        pkgs.mosh
        pkgs.neovim
        pkgs.nh
        pkgs.openssl
        pkgs.ouch
        pkgs.rage
        pkgs.rclone
        pkgs.ripgrep
        pkgs.sd
        pkgs.starship
        pkgs.tokei
        pkgs.tree-sitter
        pkgs.unzip
        pkgs.usbutils
        pkgs.uutils-coreutils-noprefix
        pkgs.wget
        pkgs.wireguard-tools
        pkgs.yazi
        pkgs.zoxide
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
          }
        )
      ];
    };
}
