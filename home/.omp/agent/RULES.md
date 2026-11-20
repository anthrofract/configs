# Global rules

## Environment

- OS: NixOS and nix-darwin. Use `nix shell` or `nix run` for programs that are not installed.
- VCS: Use jj. Read-only Git operations are allowed, but prefer jj equivalents. A detached HEAD is normal in my jj workspaces. Never run Git commands that mutate repository state, directly or through helpers. jj commands that change repository state, such as `jj new`, `jj commit`, `jj squash`, `jj rebase`, `jj abandon`, bookmark changes, and `jj git push`, require my explicit permission or a skill that authorizes them.

## Workflow

- Prefer the simplest solution that fully meets the current need; require concrete justification for added complexity.
- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Before adding a dependency or implementing functionality yourself, check whether existing dependencies provide it. Consult their documentation and types rather than assuming they lack a capability. Prefer maintained libraries when they reduce overall complexity.
- Scale research, planning, delegation, and validation to the task's scope and risk. Stop once the request is complete and necessary checks pass.
- Edit documentation (such as READMEs) only when the intended audience needs the information; avoid edits that merely record work done or add irrelevant detail. Read the rest of the document before editing so additions fit its purpose, structure, tone, and level of detail.
- Keep repository artifacts grounded in the final requirements, not the conversation that produced them. Remove rejected approaches without leaving commentary, tests, names, or other residue merely documenting their rejection. Retain negative constraints only when they serve an independent correctness or maintenance purpose.
- Filter or summarize large tool output at the source rather than returning it in full.
