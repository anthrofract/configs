{ self, inputs, ... }:
{
  flake.commonModules.development =
    { ... }:
    {
      imports = [
        self.commonModules.development-agents
        self.commonModules.development-bitcoin
        self.commonModules.development-direnv
        self.commonModules.development-go
        self.commonModules.development-google-cloud
        self.commonModules.development-kubernetes
        self.commonModules.development-lua
        self.commonModules.development-markdown
        self.commonModules.development-nix
        self.commonModules.development-nodejs
        self.commonModules.development-proto
        self.commonModules.development-python
        self.commonModules.development-rust
        self.commonModules.development-shell
        self.commonModules.development-toml
      ];
    };

  flake.commonModules.development-bitcoin =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.bitcoind
      ];
    };

  flake.commonModules.development-agents =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [ inputs.opencode.overlays.default ];

      environment.systemPackages = [
        (
          (pkgs.opencode.override {
            node_modules = pkgs.opencode.node_modules.override {
              hash = "sha256-1KQFagCMMfSdZJLPAr0b17V66Z2ITcaQis4Pa2jC1hE=";
            };
          }).overrideAttrs
          (old: {
            preBuild = (old.preBuild or "") + ''
              substituteInPlace package.json \
                --replace-fail '"packageManager": "bun@1.3.14"' '"packageManager": "bun@${pkgs.bun.version}"'
            '';
          })
        )
        pkgs.claude-code
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

  flake.commonModules.development-google-cloud =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (pkgs.google-cloud-sdk.withExtraComponents [
          pkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin
        ])
      ];
    };

  flake.commonModules.development-kubernetes =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.kubectl
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

  flake.commonModules.development-nodejs =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.nodejs
        pkgs.pnpm
        pkgs.typescript-language-server
        pkgs.vscode-langservers-extracted
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
      ];
    };

  flake.commonModules.development-rust =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.cargo-binstall
        pkgs.cargo-expand
        pkgs.cargo-nextest
        pkgs.cargo
        pkgs.clippy
        pkgs.rust-analyzer
        pkgs.rustc
        pkgs.rustfmt
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
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

  flake.commonModules.development-toml =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.tombi
      ];
    };
}
