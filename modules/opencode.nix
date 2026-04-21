{ inputs, ... }:
let
  opencodeNodeModules =
    {
      lib,
      stdenvNoCC,
      bun,
      opencodeSrc,
      rev ?
        if opencodeSrc ? shortRev then
          opencodeSrc.shortRev
        else if opencodeSrc ? rev then
          opencodeSrc.rev
        else
          "dirty",
      hash,
    }:
    let
      packageJson = lib.pipe (opencodeSrc + "/packages/opencode/package.json") [
        builtins.readFile
        builtins.fromJSON
      ];
      platform = stdenvNoCC.hostPlatform;
      bunCpu = if platform.isAarch64 then "arm64" else "x64";
      bunOs = if platform.isLinux then "linux" else "darwin";
    in
    stdenvNoCC.mkDerivation {
      pname = "opencode-node_modules";
      version = "${packageJson.version}+${lib.replaceString "-" "." rev}";

      src = lib.sources.cleanSource opencodeSrc;

      impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
        "GIT_PROXY_COMMAND"
        "SOCKS_SERVER"
      ];

      nativeBuildInputs = [ bun ];

      dontConfigure = true;

      buildPhase = ''
        runHook preBuild
        export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
        bun install \
          --cpu="${bunCpu}" \
          --os="${bunOs}" \
          --filter './' \
          --filter './packages/opencode' \
          --filter './packages/desktop' \
          --filter './packages/app' \
          --filter './packages/shared' \
          --frozen-lockfile \
          --ignore-scripts \
          --no-progress
        bun --bun ${opencodeSrc + "/nix/scripts/canonicalize-node-modules.ts"}
        bun --bun ${opencodeSrc + "/nix/scripts/normalize-bun-binaries.ts"}
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        find . -type d -name node_modules -exec cp -R --parents {} $out \;
        runHook postInstall
      '';

      dontFixup = true;

      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
      outputHash = hash;

      meta.platforms = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    };
in
{
  flake.commonModules.development-opencode =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        inputs.opencode.overlays.default
        (final: prev: {
          opencode = prev.opencode.override {
            node_modules = final.callPackage opencodeNodeModules {
              opencodeSrc = inputs.opencode;
              hash =
                if final.stdenv.hostPlatform.isDarwin then
                  "sha256-t16bjKN5f/GCRmIyjv9/RG7PsYLQjUxeAvqo3uG0l9c="
                else
                  "sha256-JjkS8fpYXHCs1h3nGtc8tdSXEMnp6o9aKvsbBx2gvVY=";
            };
          };
        })
      ];

      environment.systemPackages = [
        pkgs.opencode
      ];
    };
}
