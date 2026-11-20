{ ... }:
{
  flake.commonModules.nushell =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.nushell ];

      environment.etc."nu-with-config/nu".source = pkgs.writers.writeNu "nu-with-config" ''
        def --wrapped main [...args] {
          exec ${lib.getExe pkgs.nushell} --config $nu.config-path ...$args
        }
      '';

      home-manager.sharedModules = [
        (
          { lib, pkgs, ... }:
          {
            programs.nushell = {
              enable = true;
              loadSessionVariables = true;

              settings = {
                show_banner = false;
                buffer_editor = "nvim";
                history = {
                  file_format = "sqlite";
                  max_size = 10000;
                  sync_on_enter = true;
                  isolation = false;
                };
                menus = [
                  {
                    name = "completion_menu";
                    only_buffer_difference = false;
                    marker = "";
                    type = {
                      layout = "ide";
                      border = false;
                      correct_cursor_pos = true;
                      max_completion_height = 25;
                    };
                    style = {
                      text = "white";
                      selected_text = "green_reverse";
                      description_text = "yellow";
                      match_text.attr = "u";
                      selected_match_text.attr = "ur";
                    };
                  }
                ];
              };

              environmentVariables = {
                CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
                SSH_AUTH_SOCK = lib.hm.nushell.mkNushellInline "^${lib.getExe' pkgs.gnupg "gpgconf"} --list-dirs agent-ssh-socket | str trim";

                TRANSIENT_PROMPT_COMMAND = lib.hm.nushell.mkNushellInline ''
                  {||
                    let dir = if $env.PWD == $nu.home-dir {
                      '~'
                    } else if ($env.PWD | str starts-with $"($nu.home-dir)/") {
                      $env.PWD | str replace $nu.home-dir '~'
                    } else {
                      $env.PWD
                    }

                    let time = date now | format date '%I:%M%P '

                    let duration = if ($env.CMD_DURATION_MS | into float) > 1000.0 {
                      $" (($env.CMD_DURATION_MS | into float) / 1000.0 | math floor)s"
                    } else { "" }

                    let path_color = (if (is-admin) { ansi red_bold } else { ansi blue })
                    let separator_color = (if (is-admin) { ansi red_bold } else { ansi blue })
                    let duration_color = ansi yellow
                    let character_color = ansi yellow
                    let time_color = ansi dark_gray

                    let path_segment = $"($time_color)($time)($path_color)($dir)($duration_color)($duration)($character_color) ❯ "

                    $path_segment | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"
                  }
                '';
              };

              extraConfig = ''
                def --wrapped bat-pager [...args] {
                  with-env { BAT_PAGER: 'less -R' } {
                    bat --number --paging=always ...$args
                  }
                }

                def --wrapped just-make [...args] {
                  if ("Justfile" | path exists) {
                    just ...$args
                  } else {
                    make ...$args
                  }
                }

                def --wrapped la [...args] {
                  let paths = if ($args | is-empty) { ["."] } else { $args | each {|arg| $arg | path expand } }
                  ls --all ...$paths | sort-by type name
                }

                def --wrapped lad [...args] {
                  let paths = if ($args | is-empty) { ["."] } else { $args | each {|arg| $arg | path expand } }
                  ls --all --du --long --threads ...$paths | sort-by type name
                }

                def --wrapped lade [...args] {
                  lad ...$args | sort-by type name | explore
                }

                def copy-last-command [] {
                  history | last 2 | get 0.command | c
                }

                def jbr [] {
                  jj log -r "heads(::@ & bookmarks())" --no-graph -T 'bookmarks.map(|b| b.name())'
                }

                def jj-init [] {
                  jj git init --colocate
                  jj bookmark create master
                }

                def jj-fetch-new-trunk [] { jj git fetch; jj new 'trunk()' }

                def tmux-dev-layout [] {
                  if ($env.TMUX? | is-empty) {
                    print "Error: You must be inside a tmux session to run this."
                    return
                  }

                  print "Setting up tmux layout."

                  # Must spawn as background task to avoid the new window stealing focus
                  job spawn {
                    # Window 1, nvim with two windows
                    tmux send-keys "nvim" Enter
                    sleep 50ms
                    tmux send-keys " wv"

                    # Window 2, majjit and a directory listing
                    tmux new-window
                    tmux send-keys "mj" Enter
                    tmux split-window -h
                    tmux send-keys "omp" Enter

                    # Window 3, two shells
                    tmux new-window
                    tmux split-window -h

                    tmux select-window -t 2
                  } | ignore
                }
              '';

              shellAliases = {
                cat = "bat --plain --paging=never";
                clc = "copy-last-command";
                ff = "fastfetch";
                ghb = "gh browse";
                ghpr = "gh pr view (jbr)";
                ghprn = "gh pr new --head (jbr)";
                ghprnd = "gh pr new --draft --head (jbr)";
                jclone = "jj git clone --colocate";
                jnM = "jj-fetch-new-trunk";
                kp = "unlock-keepass ~/keepass/main.kdbx ~/.local/share/keepass/unlock-keepass-password.asc";
                less = "bat-pager";
                lt = "lsd --color always -A --date relative --group-directories-first --tree";
                lt2 = "lsd --color always -A --date relative --group-directories-first --tree --depth 2";
                lt3 = "lsd --color always -A --date relative --group-directories-first --tree --depth 3";
                m = "just-make";
                mj = "~/projects/majjit/target/release/majjit";
                ns = "nix-shell --command nu";
                nsc = "nix develop ~/configs/home/shells/rust-c --command nu";
                p = "omp";
                sha = "hash sha256";
                t = "tmux-dev-layout";
                v = "nvim";
                x = "hx";
              };
            };

            programs.carapace.enable = true;
            programs.starship.enable = true;
            programs.zoxide.enable = true;

            home.sessionPath = [
              "$HOME/.local/bin"
              "$HOME/bin"
              "$HOME/.cargo/bin"
              "$HOME/.npm-global/bin"
            ]
            ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin "/opt/homebrew/bin";

            home.sessionVariables = {
              PAGER = "bat --plain";
              LESS = "--mouse --wheel-lines=1";
            };
          }
        )
      ];
    };
}
