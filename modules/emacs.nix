{ ... }:
{
  flake.nixosModules.emacs =
    { ... }:
    {
      home-manager.sharedModules = [
        (
          { pkgs, ... }:
          {
            programs.emacs = {
              enable = true;
              package = pkgs.emacs-pgtk;
              extraPackages =
                epkgs:
                let
                  majutsu = epkgs.trivialBuild {
                    pname = "majutsu";
                    version = "0.6.0";
                    src = pkgs.fetchFromGitHub {
                      owner = "0WD0";
                      repo = "majutsu";
                      rev = "v0.6.0";
                      sha256 = "1b840z3p10jyh8d6kmj7syad7308qr9p09gsci4gmha0iw3adnx5";
                    };
                    packageRequires = [
                      epkgs.magit
                      epkgs.transient
                    ];
                  };
                in
                [
                  (epkgs.treesit-grammars.with-grammars (grammars: [ grammars.tree-sitter-rust ]))
                  epkgs.consult
                  epkgs.doom-themes
                  epkgs.helix
                  epkgs.multiple-cursors
                  epkgs.orderless
                  epkgs.treesit-auto
                  epkgs.vertico
                  majutsu
                ];
            };
          }
        )
      ];
    };
}
