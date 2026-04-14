# Global AGENTS.md

Always refer to me as "boss". I am a software engineer.

The configs for my system are in the repo at `~/configs`. These include config files for helix, tmux, ghostty, and nushell.

I run NixOS and nix darwin, the configs for that are in `~/configs`. If you need to run a program I don't have installed, you can always use a nix shell to temporarily install the program.

My primary shell is nushell. It's ok if you want to run commands in bash or zsh, but if you are giving commands for me to run, I prefer if you use nushell syntax.

I primarily use the jujutsu vcs system instead of git. So if you see git in a detached head state, that is why. Use jj commands over git commands when possible. It is fine to run "read" vcs operations like `jj show`, but please do not use "write" vcs operations like `jj describe` unless I explicitly tell you to.

When we work together on a problem, I prefer if we make small changes at a time, discuss it, and iterate from there, instead of making large changes all at once.

When editing files, please respect the existing style conventions. For example do not reorder imports or change indentation. If you see I have modified or deleted something you have written, respect that, and do not undo my changes. Please add comments sparingly, err on the side of too few comments over too many.

Answer questions with explanations, not code changes. If I ask why something happened, explain first and wait for explicit direction before editing files.
