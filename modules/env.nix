# Env vars for nushell, read from agenix-decrypted secrets in ../secrets.
{ self, ... }:
{
  flake.commonModules.env = {
    imports = [ self.commonModules.agenix ];

    home-manager.sharedModules = [
      (
        { config, ... }:
        {
          age.secrets.github-token.file = ../secrets/github-token.age;
          age.secrets.grafana-token.file = ../secrets/grafana-token.age;

          programs.nushell.extraEnv = ''
            $env.GITHUB_TOKEN = open --raw "${config.age.secrets.github-token.path}"
            $env.GRAFANA_TOKEN = open --raw "${config.age.secrets.grafana-token.path}"
            $env.NIX_CONFIG = $"access-tokens = github.com=($env.GITHUB_TOKEN)"
          '';
        }
      )
    ];
  };
}
