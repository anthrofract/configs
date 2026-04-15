{ inputs, ... }:
let
  mod =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system}.stable.withComponents [
          "cargo"
          "clippy"
          "rust-analyzer"
          "rust-src"
          "rustc"
          "rustfmt"
        ])
        (pkgs.google-cloud-sdk.withExtraComponents [
          pkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin
        ])
        inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
        pkgs.bash-language-server
        pkgs.bitcoind
        pkgs.black
        pkgs.buf
        pkgs.cargo-binstall
        pkgs.cargo-nextest
        pkgs.claude-code
        pkgs.go
        pkgs.golangci-lint
        pkgs.golangci-lint-langserver
        pkgs.gopls
        pkgs.kubectl
        pkgs.lua-language-server
        pkgs.marksman
        pkgs.nixd
        pkgs.nixfmt
        pkgs.nodejs
        pkgs.pnpm
        pkgs.poetry
        pkgs.python3
        pkgs.shellcheck
        pkgs.shfmt
        pkgs.stylua
        pkgs.tombi
        pkgs.ty
        pkgs.typescript-language-server
        pkgs.vscode-langservers-extracted
      ];
    };
in
{
  flake.nixosModules.development =
    { ... }:
    {
      imports = [ mod ];

      home-manager.sharedModules = [
        {
          programs.direnv = {
            enable = true;
            nix-direnv.enable = true;
            config.global.hide_env_diff = true;
          };
        }
      ];
    };

  flake.darwinModules.development = mod;
}
