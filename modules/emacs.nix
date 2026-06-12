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
              extraPackages = epkgs: [
                (epkgs.treesit-grammars.with-grammars (grammars: [ grammars.tree-sitter-rust ]))
                epkgs.consult
                epkgs.doom-themes
                epkgs.helix
                epkgs.magit
                epkgs.multiple-cursors
                epkgs.orderless
                epkgs.treesit-auto
                epkgs.vertico
              ];
            };
          }
        )
      ];
    };
}
