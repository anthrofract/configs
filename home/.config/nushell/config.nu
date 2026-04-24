use std/config *
use std/util "path add"

# Config
$env.config.show_banner = false
$env.config.buffer_editor = 'hx'
$env.config.history = {
  file_format: sqlite
  max_size: 10_000
  sync_on_enter: true
  isolation: false
}
$env.config.menus = [
  {
    name: completion_menu
    only_buffer_difference: false
    marker: ""
    type: {
      layout: ide
      border: false
      correct_cursor_pos: true
      max_completion_height: 25
    }
    style: {
      text: white
      selected_text: green_reverse
      description_text: yellow
      match_text: { attr: u }
      selected_match_text: { attr: ur }
    }
  }
]

# Path
path add "~/.local/bin"
path add "~/bin"
path add "~/.cargo/bin"
path add "~/.npm-global/bin"
if ($nu.os-info.name == "macos") {
    $env.XDG_CONFIG_HOME = $"($nu.home-dir)/.config"
    path add "/nix/var/nix/profiles/default/bin"
    path add "/run/current-system/sw/bin"
    path add "/usr/local/bin"
    path add $"($nu.home-dir)/.local/share/mise/shims"
    path add $"($nu.home-dir)/.nix-profile/bin"
    path add $"/etc/profiles/per-user/($env.user)/bin"
    path add "/opt/homebrew/bin/"
}

# Env vars
$env.EDITOR = $env.config.buffer_editor
$env.VISUAL = $env.config.buffer_editor
$env.PAGER = 'bat --plain'
$env.FZF_DEFAULT_OPTS = "--pointer='>' --gutter=' ' --color=bg+:#30363F,fg+:white,gutter:-1,hl:#C98E56,hl+:#C98E56,pointer:#C98E56"
$env.LESS = '--mouse --wheel-lines=1'
if (which gpgconf | is-not-empty) {
    $env.SSH_AUTH_SOCK = (gpgconf --list-dirs agent-ssh-socket | str trim)
}

def --wrapped bat-pager [...args] {
  with-env { BAT_PAGER: 'less -R' } {
    bat --plain --paging=always ...$args
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

# Need to run like this so opencode gets the proper PATH
def --wrapped opencode-wrapped [...passed_args] {
    let path_string = $env.PATH | str join (char esep)
    let args = if ($passed_args | is-empty) {
        "--port"
    } else {
        $passed_args | str join ' '
    }
    bash -i -c $"export PATH='($path_string)'; exec opencode ($args)"
}

def copy-last-command [] {
    history | last 2 | get 0.command | c
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

    # Must spawn as background task to avoid opencode stealing focus
    job spawn {
        # Window 2, majjit and opencode
        tmux new-window
        tmux send-keys "oc" Enter
        tmux split-window -hb
        tmux send-keys "mj" Enter

        # Window 3, two shells
        tmux new-window
        tmux split-window -h

        # Window 1, helix with two windows
        tmux select-window -t 1
        tmux send-keys "hx" Enter
        tmux send-keys " wv"
    } | ignore
}

alias bp = bat-pager
alias cat = bat --plain --paging=never
alias clc = copy-last-command
alias ff = fastfetch
alias ghb = gh browse
alias ghpr = gh pr view --web (jbr)
alias ghprnd = gh pr new --web --draft --head (jbr)
alias ghrpn = gh pr new --web --head (jbr)
alias jbr = jj log -r "heads(::@ & bookmarks())" --no-graph -T 'bookmarks.map(|b| b.name())'
alias jclone = jj git clone --colocate
alias jnM = jj-fetch-new-trunk
alias lt = lsd --color always -A --date relative --group-directories-first --tree
alias lt2 = lsd --color always -A --date relative --group-directories-first --tree --depth 2
alias lt3 = lsd --color always -A --date relative --group-directories-first --tree --depth 3
alias m = just-make
alias mj = ~/projects/majjit/target/release/majjit
alias ns = nix-shell --command nu
alias nsc = nix develop ~/configs/shells/rust-c --command nu
alias oc = opencode-wrapped
alias sha = hash sha256
alias t = tmux-dev-layout
alias x = hx

# Direnv
$env.config.hooks.env_change.PWD = $env.config.hooks.env_change.PWD? | default []
$env.config.hooks.env_change.PWD ++= [{||
  if (which direnv | is-empty) {
    # If direnv isn't installed, do nothing
    return
  }
  direnv export json | from json | default {} | load-env
  # If direnv changes the PATH, it will become a string and we need to re-convert it to a list
  $env.PATH = do (env-conversions).path.from_string $env.PATH
}]

# Zoxide
zoxide init nushell | save -f ($nu.data-dir | path join "vendor/autoload/zoxide.nu")

# Carapace
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
carapace _carapace nushell | save -f ($nu.data-dir | path join "vendor/autoload/carapace.nu")

# Prompt
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
$env.TRANSIENT_PROMPT_COMMAND = {||
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
