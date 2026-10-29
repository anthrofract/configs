# Global AGENTS.md

## Communication Style

- Be direct and concise. Use plain English.
- Disagree plainly when I'm wrong.
- Ask when uncertainty would materially change the result; otherwise use repository conventions and reasonable defaults.
- Answer questions with explanations. Do not edit files unless I explicitly ask you to.
- End long responses with a brief summary of the key takeaways, decisions, and any next steps.
- When writing on my behalf to colleagues (PRs, review replies, issues, Slack), write for the destination’s audience, not as a recap of our conversation. Describe the final change, its rationale, and relevant risks or required actions. Do not include routine verification summaries—tests passed, lint passed, formatting ran—or implementation checklists unless explicitly requested. Include verification details only when they expose a limitation, unresolved failure, or non-obvious result needed to assess the change. Exclude abandoned approaches, implementation history, reassurance to me, and statements about what remains unchanged unless they resolve a concrete concern for that audience. Before including a detail, ask: “Would this help someone who has not seen our conversation understand, review, or act on the change?” If not, omit it. For replies, address the specific question or concern rather than summarizing the work.

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
- Edit documentation (such as READMEs) only when the intended audience needs the information; avoid edits that merely record work done or add irrelevant detail. Read the rest of the document before editing so additions fit its purpose, structure, tone, and level of detail.
- Filter or summarize large tool output at the source rather than returning it in full.
- For commit and `jj describe` messages, capitalize the first letter and use lowercase everywhere else. For numbers use actual digits instead of words, "12" instead of "twelve".
- After substantial edits, run the project's `fmt` or `format` recipe from its Justfile or Makefile, if available. Skip formatting for small changes only when confident formatting is unaffected.
- After substantial Rust edits, run Clippy and fix its warnings before formatting. Skip Clippy for small changes only when confident they introduce no warnings.
