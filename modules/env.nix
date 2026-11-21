{ config, ... }:
{
  flake.commonModules.env =
    host@{ ... }:
    {
      age.secrets.github-token = {
        file = ../secrets/github-token.age;
        owner = config.secrets.identities.personal.userName;
      };
      age.secrets.grafana-token = {
        file = ../secrets/grafana-token.age;
        owner = config.secrets.identities.personal.userName;
      };
      age.secrets.keenable-api-key = {
        file = ../secrets/keenable-api-key.age;
        owner = config.secrets.identities.personal.userName;
      };

      home-manager.sharedModules = [
        {
          programs.nushell.extraEnv = ''
            $env.GITHUB_TOKEN = open --raw "${host.config.age.secrets.github-token.path}"
            $env.GRAFANA_TOKEN = open --raw "${host.config.age.secrets.grafana-token.path}"
            $env.KEENABLE_API_KEY = open --raw "${host.config.age.secrets.keenable-api-key.path}"
            $env.NIX_CONFIG = $"access-tokens = github.com=($env.GITHUB_TOKEN)"
          '';
        }
      ];
    };
}
