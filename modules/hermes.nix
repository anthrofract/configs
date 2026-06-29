args@{ inputs, ... }:
{
  flake.nixosModules.hermes =
    { config, pkgs, ... }:
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      services.hermes-agent = {
        enable = true;
        package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
        addToSystemPackages = true;

        container = {
          enable = true;
          hostUsers = [ args.config.secrets.identities.personal.userName ];
        };
        environment = {
          GITHUB_TOKEN = args.config.secrets.tokens.github;
          HERMES_DASHBOARD_FILES_ROOT = "/data/workspace";
        };
        settings.model = {
          provider = "openai-codex";
          default = "gpt-5.4-mini";
        };
      };

      services.reverse-proxy.services.hermes = {
        port = 8083;
        hostHeader = "127.0.0.1:${toString config.services.reverse-proxy.services.hermes.port}";
      };

      systemd.services.hermes-dashboard = {
        description = "Hermes Agent Dashboard";
        after = [
          "docker.service"
          "hermes-agent.service"
          "network-online.target"
          "tailscaled.service"
        ];
        wants = [ "network-online.target" ];
        requires = [ "hermes-agent.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.docker ];

        script = ''
          exec /run/current-system/sw/bin/hermes dashboard \
            --host 127.0.0.1 \
            --port ${toString config.services.reverse-proxy.services.hermes.port} \
            --no-open \
            --insecure
        '';

        serviceConfig = {
          User = args.config.secrets.identities.personal.userName;
          Restart = "always";
          RestartSec = 5;
          WorkingDirectory = config.services.hermes-agent.workingDirectory;
        };

        preStop = ''
          docker exec -i -u hermes hermes-agent \
            /data/current-package/bin/hermes dashboard --stop || true
        '';
      };
    };
}
