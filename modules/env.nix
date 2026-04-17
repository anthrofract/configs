{ config, ... }:
let
  tokens = config.flake.secrets.tokens;

  # Env vars made available in every shell.
  # POSIX shells pick them up via ~/.nix-profile/etc/profile.d/hm-session-vars.sh.
  # Nushell doesn't source POSIX profile scripts, so we also create a nu autoload file.
  vars = {
    GITHUB_TOKEN = tokens.github;
    GRAFANA_TOKEN = tokens.grafana;
  };

  nuAutoload =
    vars
    |> builtins.attrNames
    |> map (name: ''
      $env.${name} = "${vars.${name}}"
    '')
    |> builtins.concatStringsSep "";

  mod = {
    home-manager.sharedModules = [
      {
        home.sessionVariables = vars;
        xdg.dataFile."nushell/vendor/autoload/secrets.nu".text = nuAutoload;
      }
    ];
  };
in
{
  flake.nixosModules.env = mod;
  flake.darwinModules.env = mod;
}
