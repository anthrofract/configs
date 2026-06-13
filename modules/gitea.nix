{ ... }:
{
  flake.nixosModules.gitea =
    { config, ... }:
    {
      services.gitea = {
        enable = true;
        settings = {
          server = {
            HTTP_ADDR = "127.0.0.1";
            HTTP_PORT = config.services.reverse-proxy.services.gitea.port;
            ROOT_URL = "${config.services.reverse-proxy.protocol}://gitea.${config.services.reverse-proxy.domain}/";
          };
        };
      };

      services.reverse-proxy.services.gitea.port = 8082;
    };
}
