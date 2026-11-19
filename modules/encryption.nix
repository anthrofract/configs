{ self, config, ... }:
{
  flake.commonModules.encryption =
    { pkgs, ... }:
    {
      # TODO: switch to sequoia?
      environment.systemPackages = [
        pkgs.gnupg
        pkgs.openpgp-card-tools
        pkgs.opensc
        pkgs.rage
        pkgs.sequoia-chameleon-gnupg
        pkgs.sequoia-sop
        pkgs.sequoia-sq
        pkgs.sequoia-sqv
        pkgs.yubikey-manager
      ];

      home-manager.sharedModules = [
        {
          home.file."gpg-pubkey.asc".text = config.secrets.gpgPublicKey;
        }
      ];
    };

  flake.nixosModules.encryption =
    { pkgs, ... }:
    {
      imports = [ self.commonModules.encryption ];

      environment.systemPackages = [ pkgs.ccid ];

      services.pcscd.enable = true;
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
      environment.etc."gnupg/scdaemon.conf".text = ''
        disable-ccid
      '';
    };
}
