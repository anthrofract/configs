{ lib, self, ... }:
let
  version = "mainnet-v1.73.2";

  platforms = {
    x86_64-linux = {
      suffix = "ubuntu-x86_64";
      hash = "sha256-EYlODmXWywbPH6JD3+IYvUQT6nZ3YAo7D3yniGOkqeA=";
    };
    aarch64-darwin = {
      suffix = "macos-arm64";
      hash = "sha256-x7vqeZYTyQ9FqvBZqRos9fAHuGOPpFUi+qPh3MRtuW0=";
    };
  };
in
{
  perSystem =
    { pkgs, system, ... }:
    let
      platform = platforms.${system};
      suiSrc = pkgs.fetchFromGitHub {
        owner = "MystenLabs";
        repo = "sui";
        rev = version;
        hash = "sha256-RFIx0uyS+HJ5yZggQ+PZ7sYoSD5tVNnyD9BaDiT71Oo=";
      };
    in
    {
      packages.sui-bin = pkgs.stdenvNoCC.mkDerivation {
        pname = "sui-bin";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/MystenLabs/sui/releases/download/${version}/sui-${version}-${platform.suffix}.tgz";
          inherit (platform) hash;
        };

        sourceRoot = ".";

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          for binary in *; do
            if [ -f "$binary" ] && [ -x "$binary" ]; then
              install -Dm755 "$binary" "$out/bin/$binary"
            fi
          done

          runHook postInstall
        '';

        meta = {
          description = "Sui blockchain command line tools";
          homepage = "https://github.com/MystenLabs/sui";
          license = lib.licenses.asl20;
          platforms = builtins.attrNames platforms;
        };
      };

      packages.prettier-plugin-move = pkgs.stdenv.mkDerivation rec {
        pname = "prettier-plugin-move";
        version = "0.3.5";
        src = suiSrc;
        sourceRoot = src.name;
        pluginPath = "external-crates/move/tooling/prettier-move";
        pnpmWorkspaces = [ "@mysten/prettier-plugin-move" ];

        pnpmDeps = pkgs.fetchPnpmDeps {
          inherit
            pname
            version
            src
            sourceRoot
            pnpmWorkspaces
            ;
          pnpm = pkgs.pnpm_10;
          hash = "sha256-w05dSVSWLAd4hz0rJET4SGz6RMAnV6VDU4nqNPQhSbE=";
          fetcherVersion = 4;
        };

        nativeBuildInputs = [
          pkgs.makeWrapper
          pkgs.nodejs
          pkgs.pnpm_10
          pkgs.pnpmConfigHook
        ];

        buildPhase = ''
          runHook preBuild

          pushd $pluginPath
          pnpm build
          popd

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib/prettier-plugin-move $out/bin
          pushd $pluginPath
          cp -R bin out package.json tree-sitter-move.wasm $out/lib/prettier-plugin-move/
          mkdir -p $out/lib/prettier-plugin-move/node_modules
          cp -RL node_modules/{prettier,web-tree-sitter} $out/lib/prettier-plugin-move/node_modules/
          popd
          makeWrapper ${pkgs.nodejs}/bin/node $out/bin/prettier-move \
            --add-flags "$out/lib/prettier-plugin-move/bin/prettier-move.js" \
            --prefix PATH : ${lib.makeBinPath [ pkgs.prettier ]}

          runHook postInstall
        '';

        meta = {
          description = "Move plugin for Prettier";
          homepage = "https://github.com/MystenLabs/sui/tree/main/external-crates/move/tooling/prettier-move";
          license = lib.licenses.asl20;
          mainProgram = "prettier-move";
        };
      };

      packages.tree-sitter-move = pkgs.tree-sitter.buildGrammar {
        language = "move";
        inherit version;
        src = suiSrc;
        location = "external-crates/move/tooling/tree-sitter";

        meta = {
          description = "Tree-sitter grammar for Move";
          homepage = "https://github.com/MystenLabs/sui/tree/main/external-crates/move/tooling/tree-sitter";
          license = lib.licenses.asl20;
        };
      };
    };

  flake.commonModules.neovim-langs-move =
    { ... }:
    {
      home-manager.sharedModules = [
        (
          { config, pkgs, ... }:
          let
            suiPackages = self.packages.${pkgs.stdenv.hostPlatform.system};
          in
          {
            programs.nixvim = {
              filetype.extension.move = "move";

              plugins = {
                lsp.postConfig = ''
                  vim.lsp.config("move_analyzer", {
                    cmd = { "${suiPackages.sui-bin}/bin/move-analyzer" },
                    filetypes = { "move" },
                    root_markers = { "Move.toml", ".git" },
                  })
                  vim.lsp.enable("move_analyzer")
                '';

                conform-nvim.settings = {
                  formatters_by_ft.move = [ "prettier_move" ];
                  formatters.prettier_move = {
                    command = "${suiPackages.prettier-plugin-move}/bin/prettier-move";
                    stdin = false;
                    args = [
                      "--use-tabs"
                      "false"
                      "--tab-width"
                      "4"
                      "-w"
                      "$FILENAME"
                    ];
                  };
                };

                treesitter = {
                  grammarPackages = config.programs.nixvim.plugins.treesitter.package.allGrammars ++ [
                    suiPackages.tree-sitter-move
                  ];
                  languageRegister.move = "move";
                };
              };

              extraPlugins = [
                suiPackages.tree-sitter-move
              ];
            };
          }
        )
      ];
    };
}
