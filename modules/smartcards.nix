{ ... }:
{
  flake.nixosModules.smartcards =
    { pkgs, ... }:
    {
      # TODO: switch to sequoia?
      environment.systemPackages = [
        pkgs.ccid
        pkgs.gnupg
        pkgs.opensc
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
