{ ... }:
{
  flake.nixosModules.flatpak =
    { config, ... }:
    {
      services.flatpak.enable = true;

      # Adding the remote downloads its definition, so it waits for the network instead of
      # running during activation, where a network restart would fail the switch
      systemd.services.flatpak-repo = {
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        path = [ config.services.flatpak.package ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          if ! flatpak remotes --system --columns=name | grep -qx flathub; then
            flatpak remote-add --system flathub https://flathub.org/repo/flathub.flatpakrepo
          fi
        '';
      };
    };
}
