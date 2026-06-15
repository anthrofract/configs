{ lib, ... }:
let
  version = "mainnet-v1.72.5";

  platforms = {
    x86_64-linux = {
      suffix = "ubuntu-x86_64";
      hash = "sha256-5XKBbP1+2bfwTQ2W0mz2Q3kiBfYIAGnnptASDkayzsU=";
    };
    aarch64-darwin = {
      suffix = "macos-arm64";
      hash = "sha256-YkxCdSaLbCbOb473bqBErfb6N8teWSKg1VpRdjIvT28=";
    };
  };
in
{
  flake.commonModules.development-sui =
    { pkgs, ... }:
    let
      platform = platforms.${pkgs.stdenv.hostPlatform.system};

      sui-bin = pkgs.stdenvNoCC.mkDerivation {
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

      prettier-move = pkgs.stdenv.mkDerivation rec {
        pname = "prettier-plugin-move";
        version = "0.3.5";

        src = pkgs.fetchFromGitHub {
          owner = "MystenLabs";
          repo = "sui";
          rev = "8c1a5dbc40b12b91e5ce79f8f0e259c69f63269c";
          hash = "sha256-38XMYt492bo/LFNCZrjOmmTUlrvtqsA4N8OqOUD+HvA=";
        };

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
    in
    {
      environment.systemPackages = [
        sui-bin
        pkgs.prettier
        prettier-move
      ];
    };
}
