{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );
    in
    {
      devShells = forAllSystems (
        { pkgs }:
        {
          default = (pkgs.mkShell.override { stdenv = pkgs.llvmPackages.stdenv; }) {
            nativeBuildInputs = [
              pkgs.cargo-binstall
              pkgs.cargo-nextest
              pkgs.cargo
              pkgs.clippy
              pkgs.cmake
              pkgs.lld
              pkgs.openssl
              pkgs.pkg-config
              pkgs.rust-analyzer
              pkgs.rustc
              pkgs.rustfmt
            ];
            BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/${pkgs.lib.getVersion pkgs.clang}/include";
            LD_LIBRARY_PATH = "${pkgs.llvmPackages.stdenv.cc.cc.lib}/lib";
            LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
            NIX_CFLAGS_COMPILE = "-Wno-error=int-conversion";
            CXXFLAGS = "-include cstdint";
            RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
            RUSTFLAGS = "-Clink-self-contained=no";
          };
        }
      );
    };
}
