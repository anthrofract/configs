# Global AGENTS.md

## Communication Style

- Be direct and concise. Use plain English.
- Disagree plainly when I'm wrong.
- Ask when uncertainty would materially change the result; otherwise use repository conventions and reasonable defaults.
- Answer questions with explanations. Do not edit files unless I explicitly ask you to.
- End long responses with a brief summary of the key takeaways, decisions, and any next steps.

## Environment

- OS: NixOS and nix-darwin.
- Shell: Use Nushell syntax for commands you give me to run. You may use bash for your own tool calls.
- Configs: System configs (neovim, tmux, ghostty, nushell, nix, omp) live in ~/configs.
- VCS: Prefer jj over git. A detached HEAD is normal in my jj workspaces. Read-only commands are allowed; commands that modify repository state require my explicit permission.
- Ad-hoc programs: Use `nix shell` or `nix run` for programs that are not installed.
- Agent harness: omp (oh my pi)

## Workflow

- Prefer the simplest solution that fully meets the current need; require concrete justification for added complexity.
- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Before adding a dependency or implementing functionality yourself, check whether existing dependencies provide it. Consult their documentation and types rather than assuming they lack a capability. Prefer maintained libraries when they reduce overall complexity.
- Make small changes and iterate. Discuss plans and design decisions with me before substantial implementation unless I explicitly authorize proceeding.
- Scale research, planning, delegation, and validation to the task's scope and risk. Stop once the request is complete and necessary checks pass.
- Filter or summarize large tool output at the source rather than returning it in full.
- For commit and `jj describe` messages, capitalize the first letter and use lowercase everywhere else.
- After substantial edits, run the project's `fmt` or `format` recipe from its Justfile or Makefile, if available. Skip formatting for small changes only when confident formatting is unaffected.
- After substantial Rust edits, run Clippy and fix its warnings before formatting. Skip Clippy for small changes only when confident they introduce no warnings.
