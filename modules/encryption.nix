{ ... }:
{
  flake.nixosModules.encryption =
    { pkgs, ... }:
    {
      # TODO: switch to sequoia?
      environment.systemPackages = [
        pkgs.ccid
        pkgs.gnupg
        pkgs.opensc
        pkgs.sequoia-chameleon-gnupg
        pkgs.sequoia-sop
        pkgs.sequoia-sq
        pkgs.sequoia-sqv
        pkgs.sequoia-wot
        pkgs.yubikey-manager
      ];

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
