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

# Defs
def la [...pattern] {
    let pattern = if ($pattern | is-empty) { 
        ["."] 
    } else { 
        $pattern | each { |p| $p | path expand }
    }
    ls -la ...$pattern | sort-by type name
}

def lad [...pattern] {
    let pattern = if ($pattern | is-empty) { 
        ["."] 
    } else { 
        $pattern | each { |p| $p | path expand }
    }
    ls -ladt ...$pattern | sort-by type name
}

def clc [] {
    history | last 2 | get 0.command | cb
}

# Need to run like this so opencode gets the proper PATH
def --wrapped oc [...passed_args] {
    let path_string = $env.PATH | str join (char esep)
    let args = if ($passed_args | is-empty) {
        "--port"
    } else {
        $passed_args | str join ' '
    }
    zsh -i -c $"export PATH='($path_string)'; exec opencode ($args)"
}

def --wrapped m [...args] {
    if ("Justfile" | path exists) {
        just ...$args
    } else {
        make ...$args
    }
}

def po [] { poweroff; tmux kill-server }

# Set up tmux layout
def tl [] {
    if ($env.TMUX? | is-empty) {
        print "Error: You must be inside a tmux session to run this."
        return
    }

    print "Setting up tmux layout..."

    # Must spawn as background task to avoid opencode stealing focus
    job spawn {
        tmux new-window
        tmux send-keys "jjd" Enter
        tmux split-window -h

        tmux select-window -t 1
        tmux send-keys "oc" Enter
        tmux split-window -h
        tmux send-keys "x" Enter

        tmux select-pane -t 1
        # Wait for opencode to finish loading to avoid it stealing focus
        sleep 1sec
        tmux select-pane -t 2
    } | ignore
}

def --wrapped less [...args] {
  with-env { BAT_PAGER: 'less -R' } {
    bat --plain --paging=always ...$args
  }
}

# Aliases
alias cat = bat --plain --paging=never
alias ff = fastfetch
alias ll = lsd --color always -1 --group-directories-first
alias lla = lsd --color always -lA --date relative --group-directories-first --git
alias lt = lsd --color always -A --date relative --group-directories-first --tree
alias lt2 = lsd --color always -A --date relative --group-directories-first --tree --depth 2
alias lt3 = lsd --color always -A --date relative --group-directories-first --tree --depth 3
alias jjd = ~/projects/jjdag/target/release/jjdag
alias ns = nix-shell --command /usr/local/bin/nu
alias nsc = nix develop ~/configs/shells/rust-c --command nu
alias sha = hash sha256
alias t = tms ~/scratch
alias v = nvim
alias vc = nvim --clean
alias x = hx
alias wat = hwatch --interval 2 --differences=word --color --exec nu --login -c
alias wat1 = hwatch --interval 1 --differences=word --color --exec nu --login -c
alias wat10 = hwatch --interval 10 --differences=word --color --exec nu --login -c
alias wat5 = hwatch --interval 5 --differences=word --color --exec nu --login -c
alias valhalla = mosh valhalla
alias asgard = mosh asgard
alias work-mbp = mosh work-mbp
alias nidavellir = mosh nidavellir

# Jj defs
def ji [] {
    jj git init --colocate
    jj bookmark create master
}

def jnM [] { jj git fetch; jj new 'trunk()' }

# Jj aliases
alias j = jj status
alias ja = jj abandon
alias jab = jj abandon -r @-
alias jb = jj bookmark
alias jbr = jj log -r "heads(::@ & bookmarks())" --no-graph -T 'bookmarks.map(|b| b.name())'
alias jbc = jj bookmark create
alias jbl = jj bookmark list
alias jbmt = jj bookmark move --from 'heads(::@- & bookmarks())' --to @
alias jbs = jj bookmark set
alias jc = jj commit
alias jclone = jj git clone --colocate
alias jcm = jj commit -m
alias jd = jj diff
alias jdb = jd -r @-
alias jdr = jj describe
alias jdrb = jj describe -r @-
alias jdrm = jj describe -m
alias jdrmb = jj describe -r @- -m
alias je = jj edit
alias jeb = jj edit @-
alias jef = jj edit --ignore-immutable
alias jf = jj git fetch
alias jg = jj git
alias jjs = jj --stat
alias jl = jj log --revisions 'all()' --limit 10
alias jla = jj log --revisions 'all()'
alias jlas = jj log --revisions 'all()' --stat
alias jls = jj log --revisions 'all()' --limit 10 --stat
alias jn = jj new
alias jnb = jj new --insert-before @ --no-edit
alias jnm = jj new 'trunk()'
alias jp = jj git push
alias jrm = jj rebase -s @ -d 'trunk()'
alias js = jj squash
alias jsf = jj squash --ignore-immutable
alias jsi = jj squash --interactive
alias ju = jj undo

# Github aliases
alias pr = gh pr view --web (jbr)
alias prnew = gh pr new --head (jbr)
alias prnewdraft = gh pr new --draft --head (jbr)
alias prchecks = gh pr checks --web (jbr)
alias prready = gh pr ready (jbr)
alias prdraft = gh pr ready --undo (jbr)
alias predit = gh pr edit (jbr)
alias prcomment = gh pr comment (jbr)
alias prreview = gh pr review (jbr)
alias browse = gh browse
alias browseb = gh browse --branch (jbr)
alias repo = gh repo view --web

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

# Create vendor autoload directory
let autoload = ($nu.data-dir | path join "vendor/autoload")
if not ($autoload | path exists) { mkdir $autoload }

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
