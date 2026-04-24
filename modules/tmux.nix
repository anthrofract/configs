{ ... }:
{
  flake.commonModules.tmux =
    { ... }:
    {
      home-manager.sharedModules = [
        (
          { pkgs, ... }:
          {
            programs.tmux = {
              enable = true;
              package = pkgs.tmux;
              aggressiveResize = true;
              baseIndex = 1;
              escapeTime = 0;
              focusEvents = true;
              historyLimit = 50000;
              keyMode = "vi";
              mouse = true;
              prefix = "`";
              shell = "${pkgs.nushell}/bin/nu";
              terminal = "xterm-ghostty";
              extraConfig = ''
                set-option -g display-time 4000
                set-option -g status-interval 1
                set-option -g detach-on-destroy off
                set-option -g set-titles on
                set-option -g set-titles-string "#S / #W"
                set-option -sa terminal-overrides ",xterm-256color:Tc"
                set-option -ga terminal-features ",xterm-ghostty:extkeys"
                set-option -ga terminal-features "*:hyperlinks"

                set-option -gq allow-passthrough on
                set-option -g extended-keys on
                set-option -g renumber-windows on

                bind-key -n C-1 select-window -t 1
                bind-key -n C-2 select-window -t 2
                bind-key -n C-3 select-window -t 3
                bind-key -n C-4 select-window -t 4
                bind-key -n C-5 select-window -t 5
                bind-key -n C-6 select-window -t 6
                bind-key -n C-7 select-window -t 7
                bind-key -n C-8 select-window -t 8
                bind-key -n C-9 select-window -t 9

                bind-key \\ split-window -h -c "#{pane_current_path}"
                bind-key | split-window -hb -c "#{pane_current_path}"
                bind-key - split-window -v -c "#{pane_current_path}"
                bind-key _ split-window -vb -c "#{pane_current_path}"

                bind-key o display-popup -E "${pkgs.nushell}/bin/nu -l -c 'tms'"
                bind-key a run-shell "${pkgs.nushell}/bin/nu -l -c 'tms ~/scratch'"

                bind-key r source-file ~/.config/tmux/tmux.conf
                bind-key Space switch-client -l
                bind-key e select-layout -E
                bind-key x kill-pane
                bind-key X kill-session

                bind-key -T copy-mode-vi x send -X select-line
                bind-key -T copy-mode-vi WheelUpPane send-keys -X -N 2 scroll-up
                bind-key -T copy-mode-vi WheelDownPane send-keys -X -N 2 scroll-down

                set-option -g status-position bottom
                set-option -g status-style bg="#2f312c",fg="#f1e9d2"

                set-option -g window-status-style bg="#2f312c",fg="#a3a7a1"
                set-option -g window-status-format " #{window_index}:#W#F"

                set-option -g window-status-current-style bg="#2f312c",fg="#f1e9d2"
                set-option -g window-status-current-format " (#W#{?#{==:#F,*},,#F})"

                set-option -g mode-style bg="#f1e9d2",fg="#2f312c",bold
                set-option -g message-style bg="#f1e9d2",fg="#2f312c"
                set-option -g message-command-style bg="#f1e9d2",fg="#2f312c"

                set-option -g pane-active-border-style fg="colour242"
                set-option -g pane-border-style fg="colour242"

                set-option -g status-right-length 50
                set-option -g status-left-length 50
                set-option -g status-left "#[bg=#2f312c,fg=#f1e9d2] [#{session_name}] "
                set-option -g status-right "#H #{?#{==:#{pane_mode},copy-mode},#[bg=#f1e9d2]#[fg=black],}#{?client_prefix,#[bg=green]#[fg=black]  ,  }"
              '';
            };
          }
        )
      ];
    };
}
