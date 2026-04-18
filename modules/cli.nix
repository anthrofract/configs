{ self, config, ... }:
let
  ids = config.flake.secrets.identities;
in
{
  flake.commonModules.cli =
    { pkgs, ... }:
    {
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
        pkgs.hwatch
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
        pkgs.nushell
        pkgs.openssl
        pkgs.ouch
        pkgs.rage
        pkgs.rclone
        pkgs.ripgrep
        pkgs.sd
        pkgs.starship
        pkgs.tmux
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

  flake.nixosModules.cli =
    { pkgs, ... }:
    {
      imports = [ self.commonModules.cli ];

      # Link nushell to /usr/local/bin to make a single path for nixos and darwin
      system.activationScripts.bin-nu.text = ''
        mkdir -p /usr/local/bin
        ln -sfn ${pkgs.nushell}/bin/nu /usr/local/bin/nu
      '';
    };

  flake.darwinModules.cli =
    { pkgs, ... }:
    {
      imports = [ self.commonModules.cli ];

      # Link nushell to /usr/local/bin to make a single path for nixos and darwin
      # Symlink nushell config to macOS default location so config.nu loads before XDG_CONFIG_HOME is set
      system.activationScripts.postActivation.text = ''
        sudo ln -sfn ${pkgs.nushell}/bin/nu /usr/local/bin/nu
        sudo -u ${ids.personal.userName} mkdir -p "/Users/${ids.personal.userName}/Library/Application Support/nushell"
        sudo -u ${ids.personal.userName} ln -sfn "/Users/${ids.personal.userName}/.config/nushell/config.nu" "/Users/${ids.personal.userName}/Library/Application Support/nushell/config.nu"
      '';
    };
}
