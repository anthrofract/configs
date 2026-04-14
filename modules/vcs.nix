{ config, ... }:
let
  ids = config.flake.secrets.identities;
  mod =
    { ... }:
    {
      home-manager.sharedModules = [
        (
          { config, pkgs, ... }:
          {
            home.file.".config/git/ignore-work".text = ''
              .direnv
              .envrc
              AGENTS-GI.md
              PLAN.md
            '';

            # Git
            programs.git = {
              enable = true;
              settings = {
                user = {
                  name = ids.personal.name;
                  email = ids.personal.email;
                };
                core.sshCommand = "ssh -i ~/.ssh/${ids.personal.sshKey} -o IdentitiesOnly=yes";
                push.autoSetupRemote = true;
                pull.rebase = true;
              };
              includes = [
                {
                  condition = "gitdir:${config.home.homeDirectory}/work/";
                  contents = {
                    user = {
                      name = ids.work.name;
                      email = ids.work.email;
                    };
                    core.sshCommand = "ssh -i ~/.ssh/${ids.work.sshKey} -o IdentitiesOnly=yes";
                    core.excludesFile = "~/.config/git/ignore-work";
                  };
                }
              ];
              ignores = [
                ".direnv"
                "AGENTS-GI.md"
                "PLAN.md"
              ];
              signing.format = null;
            };

            # Jj
            programs.jujutsu = {
              enable = true;
              ediff = false;
              settings = {
                user = {
                  name = ids.personal.name;
                  email = ids.personal.email;
                };
                ui = {
                  default-command = "log";
                  diff-formatter = [
                    "difft"
                    "--color=always"
                    "$left"
                    "$right"
                  ];
                };
                "--scope" = [
                  {
                    "--when" = {
                      repositories = [ "~/work" ];
                    };
                    user = {
                      name = ids.work.name;
                      email = ids.work.email;
                    };
                  }
                ];
                templates = {
                  log_node = ''
                    coalesce(
                      if(!self, label("elided", "~")),
                      label(
                        separate(" ",
                          if(current_working_copy, "working_copy"),
                          if(immutable, "immutable"),
                          if(conflict, "conflict"),
                        ),
                        coalesce(
                          if(current_working_copy, "@"),
                          if(root, "┴"),
                          if(immutable, "●"),
                          if(conflict, "⊗"),
                          "○",
                        )
                      )
                    )
                  '';
                  op_log_node = ''if(current_operation, "@", "○")'';
                };
              };
            };
          }
        )
      ];
    };
in
{
  flake.nixosModules.vcs = mod;
  flake.darwinModules.vcs = mod;
}
