{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, fenix, ... }:
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
            rust-toolchain = fenix.packages.${system}.stable.withComponents [
              "cargo"
              "clippy"
              "rust-analyzer"
              "rust-src"
              "rustc"
              "rustfmt"
            ];
          }
        );
    in
    {
      devShells = forAllSystems (
        { pkgs, rust-toolchain }:
        {
          default = (pkgs.mkShell.override { stdenv = pkgs.llvmPackages.stdenv; }) {
            nativeBuildInputs = [
              rust-toolchain
              pkgs.cargo-binstall
              pkgs.cargo-nextest
              pkgs.cmake
              pkgs.lld
              pkgs.openssl
              pkgs.pkg-config
            ];
            BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/${pkgs.lib.getVersion pkgs.clang}/include";
            LD_LIBRARY_PATH = "${pkgs.llvmPackages.stdenv.cc.cc.lib}/lib";
            LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
            NIX_CFLAGS_COMPILE = "-Wno-error=int-conversion";
            CXXFLAGS = "-include cstdint";
            RUSTFLAGS = "-Clink-self-contained=no";
          };
        }
      );
    };
}
