{ ... }:
{
  flake.nixosModules.sunshine =
    { pkgs, ... }:
    {
      # Sunshine game streaming server
      services.sunshine = {
        enable = true;
        package = pkgs.sunshine.override { cudaSupport = true; };
        autoStart = false;
        capSysAdmin = true;
        openFirewall = true;
      };
    };
}
