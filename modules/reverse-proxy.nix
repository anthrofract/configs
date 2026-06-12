{ ... }:
{
  flake.nixosModules.reverse-proxy =
    { config, lib, ... }:
    let
      cfg = config.services.reverse-proxy;

      serviceOpts = {
        options = {
          port = lib.mkOption {
            type = lib.types.port;
            description = "Internal port to proxy to";
          };

          websocketPaths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Paths that should be proxied as websockets";
          };

          hostHeader = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Host header to send to the proxied service";
          };
        };
      };

      serviceLocation = service: {
        proxyPass = "http://127.0.0.1:${toString service.port}/";
        extraConfig = lib.optionalString (service.hostHeader != null) ''
          proxy_set_header Host ${service.hostHeader};
        '';
      };

      serviceVHost = name: service: {
        name = "${name}.${cfg.domain}";
        value = {
          locations = {
            "/" = serviceLocation service;
          }
          // lib.genAttrs service.websocketPaths (_: {
            proxyPass = "http://127.0.0.1:${toString service.port}";
            proxyWebsockets = true;
            extraConfig = lib.optionalString (service.hostHeader != null) ''
              proxy_set_header Host ${service.hostHeader};
            '';
          });
        };
      };
    in
    {
      options.services.reverse-proxy = {
        domain = lib.mkOption {
          type = lib.types.str;
          description = "Domain suffix for reverse-proxied services";
        };

        interface = lib.mkOption {
          type = lib.types.str;
          default = "tailscale0";
          description = "Interface whose IP should be used for service DNS records";
        };

        protocol = lib.mkOption {
          type = lib.types.enum [
            "http"
            "https"
          ];
          default = "http";
          description = "Public protocol for reverse-proxied services";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 80;
          description = "Public port for reverse-proxied services";
        };

        services = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule serviceOpts);
          default = { };
          description = "Reverse-proxied services keyed by subdomain";
        };
      };

      config = {
        services.dnsmasq = {
          enable = true;
          settings = {
            interface = cfg.interface;
            bind-dynamic = true;
            local = "/${cfg.domain}/";
            interface-name = lib.mapAttrsToList (
              name: _: "${name}.${cfg.domain},${cfg.interface}"
            ) cfg.services;
          };
        };

        services.nginx = {
          enable = true;
          recommendedGzipSettings = true;
          recommendedProxySettings = true;
          virtualHosts = {
            default = {
              default = true;
              locations."/".return = "404";
            };
          }
          // lib.mapAttrs' serviceVHost cfg.services;
        };

        networking.firewall.allowedTCPPorts = [ cfg.port ];
        networking.firewall.interfaces.${cfg.interface} = {
          allowedTCPPorts = [ 53 ];
          allowedUDPPorts = [ 53 ];
        };
      };
    };
}
