{ config, inputs, ... }:
let
  ids = config.secrets.identities;
in
{
  flake.commonModules.vcs =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.git
        inputs.majjit.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      home-manager.sharedModules = [
        (
          { config, ... }:
          {
            home.file.".config/git/ignore-work".text = ''
              .direnv
              .envrc
              AGENTS-GI.md
              PLAN.md
            '';

            # One SSH alias per GitHub identity, so each identity gets its own shared connection
            programs.ssh.settings = {
              github-personal = {
                HostName = "github.com";
                IdentityFile = "~/.ssh/${ids.personal.sshKey}";
                IdentitiesOnly = "yes";
              };
              github-work = {
                HostName = "github.com";
                IdentityFile = "~/.ssh/${ids.work.sshKey}";
                IdentitiesOnly = "yes";
              };
            };

            # Git
            programs.git = {
              enable = true;
              settings = {
                user = {
                  name = ids.personal.name;
                  email = ids.personal.email;
                };
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
                    url."git@github-work:".insteadOf = "git@github.com:";
                    core.excludesFile = "~/.config/git/ignore-work";
                  };
                }
                # Git uses the first of equally long insteadOf matches, so this must follow the work include
                { contents.url."git@github-personal:".insteadOf = "git@github.com:"; }
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
}
