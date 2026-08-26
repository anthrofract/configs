{ self, inputs, ... }:
{
  flake.commonModules.development =
    { ... }:
    {
      imports = [
        self.commonModules.development-agents
        self.commonModules.development-bitcoin
        self.commonModules.development-direnv
        self.commonModules.development-github
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
        self.commonModules.development-shell
        self.commonModules.development-sui
        self.commonModules.development-toml
      ];
    };

  flake.commonModules.development-agents =
    { latestPkgs, pkgs, ... }:
    {
      environment.systemPackages = [
        (inputs.omp.packages.${pkgs.stdenv.hostPlatform.system}.omp.override {
          withWaylandScreencast = pkgs.stdenv.hostPlatform.isLinux;
        })
        latestPkgs.claude-code
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

  flake.commonModules.development-github =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.gh
      ];

      home-manager.sharedModules = [
        {
          xdg.dataFile."gh/extensions/gh-stack".source = "${pkgs.gh-stack}/bin";
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
    {
      environment.systemPackages = [
        pkgs.cargo-binstall
        pkgs.cargo-expand
        pkgs.cargo-nextest
        pkgs.rustup
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.gcc
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
