{ self, inputs, ... }:
{
  flake.commonModules.development =
    { ... }:
    {
      imports = [
        self.commonModules.developmentAgents
        self.commonModules.developmentBase
        self.commonModules.developmentBitcoin
        self.commonModules.developmentDirenv
        self.commonModules.developmentGo
        self.commonModules.developmentGoogleCloud
        self.commonModules.developmentKubernetes
        self.commonModules.developmentLua
        self.commonModules.developmentMarkdown
        self.commonModules.developmentNix
        self.commonModules.developmentNodejs
        self.commonModules.developmentProto
        self.commonModules.developmentPython
        self.commonModules.developmentRust
        self.commonModules.developmentShell
        self.commonModules.developmentToml
      ];
    };

  flake.commonModules.developmentBase =
    { ... }:
    {
      nixpkgs.overlays = [ inputs.opencode.overlays.default ];
    };

  flake.commonModules.developmentBitcoin =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.bitcoind
      ];
    };

  flake.commonModules.developmentAgents =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.claude-code
        pkgs.opencode
      ];
    };

  flake.commonModules.developmentDirenv =
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

  flake.commonModules.developmentGo =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.go
        pkgs.golangci-lint
        pkgs.golangci-lint-langserver
        pkgs.gopls
      ];
    };

  flake.commonModules.developmentGoogleCloud =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (pkgs.google-cloud-sdk.withExtraComponents [
          pkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin
        ])
      ];
    };

  flake.commonModules.developmentKubernetes =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.kubectl
      ];
    };

  flake.commonModules.developmentLua =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.lua-language-server
        pkgs.stylua
      ];
    };

  flake.commonModules.developmentMarkdown =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.marksman
      ];
    };

  flake.commonModules.developmentNix =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.nixd
        pkgs.nixfmt
      ];
    };

  flake.commonModules.developmentNodejs =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.nodejs
        pkgs.pnpm
        pkgs.typescript-language-server
        pkgs.vscode-langservers-extracted
      ];
    };

  flake.commonModules.developmentProto =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.buf
      ];
    };

  flake.commonModules.developmentPython =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.black
        pkgs.poetry
        pkgs.python3
        pkgs.ty
      ];
    };

  flake.commonModules.developmentRust =
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

  flake.commonModules.developmentShell =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.bash-language-server
        pkgs.shellcheck
        pkgs.shfmt
      ];
    };

  flake.commonModules.developmentToml =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.tombi
      ];
    };
}
