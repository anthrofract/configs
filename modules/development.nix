{ self, ... }:
{
  flake.commonModules.development =
    { ... }:
    {
      imports = [
        self.commonModules.development-agents
        self.commonModules.development-bitcoin
        self.commonModules.development-direnv
        self.commonModules.development-go
        # self.commonModules.development-haskell
        self.commonModules.development-infra
        self.commonModules.development-js
        self.commonModules.development-lua
        self.commonModules.development-markdown
        self.commonModules.development-nix
        self.commonModules.development-proto
        self.commonModules.development-python
        self.commonModules.development-rust
        self.commonModules.development-services
        self.commonModules.development-shell
        self.commonModules.development-sui
        self.commonModules.development-toml
      ];
    };

  flake.commonModules.development-agents =
    { pkgs, latestPkgs, ... }:
    {
      environment.systemPackages = [
        latestPkgs.claude-code
        latestPkgs.codex
        latestPkgs.omp
        latestPkgs.opencode
      ];

      home-manager.sharedModules = [
        {
          home.file.".omp/agent/agents/reviewer-secondary.md".source =
            pkgs.runCommand "reviewer-secondary.md" { }
              ''
                substitute \
                  ${latestPkgs.omp}/lib/omp/packages/coding-agent/src/prompts/agents/reviewer.md \
                  "$out" \
                  --replace-fail 'name: reviewer' 'name: reviewer-secondary' \
                  --replace-fail 'model: "@slow"' 'model: anthropic/claude-opus-5-5:high'
              '';
        }
      ];
    };

  flake.commonModules.development-bitcoin =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.bitcoind
      ];
    };

  flake.commonModules.development-direnv =
    { ... }:
    {
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

  flake.commonModules.development-go =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.go
        pkgs.golangci-lint
        pkgs.golangci-lint-langserver
        pkgs.gopls
      ];
    };

  flake.commonModules.development-haskell =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.cabal-install
        pkgs.ghc
        pkgs.haskell-language-server
        pkgs.hlint
        pkgs.ormolu
        pkgs.stack
      ];
    };

  flake.commonModules.development-infra =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (pkgs.google-cloud-sdk.withExtraComponents [
          pkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin
        ])
        pkgs.awscli2
        pkgs.kubectl
        pkgs.pulumi-bin
      ];
    };

  flake.commonModules.development-js =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.nodejs
        pkgs.pnpm
        pkgs.prettier
        pkgs.typescript-language-server
        pkgs.vscode-langservers-extracted
      ];
    };

  flake.commonModules.development-lua =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.lua-language-server
        pkgs.stylua
      ];
    };

  flake.commonModules.development-markdown =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.marksman
      ];
    };

  flake.commonModules.development-nix =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.nixd
        pkgs.nixfmt
        pkgs.nix-prefetch
      ];
    };

  flake.commonModules.development-proto =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.buf
      ];
    };

  flake.commonModules.development-python =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.black
        pkgs.poetry
        pkgs.python3
        pkgs.ty
        pkgs.uv
      ];
    };

  flake.commonModules.development-rust =
    { lib, pkgs, ... }:
    let
      rustup = pkgs.rustup.overrideAttrs (_: {
        # Keep downloaded toolchains unpatched; NixOS runs them through nix-ld.
        patches = [ ];
      });
    in
    {
      environment.systemPackages = [
        pkgs.cargo-binstall
        pkgs.cargo-expand
        pkgs.cargo-nextest
        rustup
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.gcc
      ];
    };

  flake.commonModules.development-services =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.gh
        pkgs.gws
      ];

      home-manager.sharedModules = [
        {
          xdg.dataFile."gh/extensions/gh-stack".source = "${pkgs.gh-stack}/bin";
        }
      ];
    };

  flake.commonModules.development-shell =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.bash-language-server
        pkgs.shellcheck
        pkgs.shfmt
      ];
    };

  flake.commonModules.development-sui =
    { pkgs, ... }:
    let
      packages = self.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      environment.systemPackages = [
        packages.prettier-plugin-move
        packages.sui-bin
      ];
    };

  flake.commonModules.development-toml =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.tombi
      ];
    };
}
