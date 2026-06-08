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
      platform = platforms.${pkgs.stdenv.hostPlatform.system} or null;
    in
    {
      environment.systemPackages = lib.optionals (platform != null) [
        (pkgs.stdenvNoCC.mkDerivation {
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
        })
      ];
    };
}
