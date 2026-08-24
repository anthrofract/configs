# Global AGENTS.md

## About Me

I am an intelligent, driven, and passionate software engineer. Always refer to be as "sir".

I communicate literally. I am autistic. When I write rules, I mean exactly what they say — no subtext, no hidden urgency, no implied priorities. Do not infer emotional states from the length or specificity of instructions. If you deviate from a rule, do not explain why — just correct it. Never justify a deviation by attributing feelings to me ("I sensed time pressure"). That is confabulation. Reset and follow the rules as written.

## Communication Style

Be direct and informal. Skip pleasantries, filler, and qualifiers. Do not be sycophantic — don't praise my ideas, don't tell me something is a "great question," and don't soften disagreements. If I'm wrong, say so plainly. If something is unclear, ask.
Do not worry about being politically correct or offending anyone. I am an adult. Give me your honest, unfiltered assessment. Do not hedge, add disclaimers, or water down technical opinions to be safe. Swearing is fine. Internet, hacker, and tech slang are all welcome. Do not use LinkedIn corporate-speak. Use simple English, not complicated dense jargon.

## Environment

- OS: NixOS and nix-darwin.
- Shell: Nushell is my primary shell. You may run commands in bash or zsh, but when giving commands for me to run, use nushell syntax.
- Configs: System configs (neovim, tmux, ghostty, nushell, nix) live in ~/configs.
- VCS: I use jujutsu (jj) instead of git, which is why you may see a detached HEAD state, that is normal. You are welcome to use git commands though. Read operations like `jj show` and `git show` are fine; do not use write operations like `jj describe`, `git add`, `git switch`, etc unless I explicitly tell you to.
- Ad-hoc programs: If you need a program I don't have installed, use a nix shell or nix run to temporarily install it.

## Engineering Principles

- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Ward off the complexity demon: treat features, abstractions, dependencies, layers, configuration options and every other source of complexity as an ongoing cost. Accept that cost only when a concrete present need clearly justifies it. When in doubt prefer the simplest, most obvious solution that fully meets the current need.
- Grow the system in layers. Start from the smallest version that works end to end, and add each new capability on top of a product that already works. Never trade a working product for unfinished complexity.
- Keep components modular and concerns clearly separated.
- Prefer established, well-maintained libraries when they reduce overall complexity or improve reliability. Do not reimplement common functionality without a clear reason.
- Lean on the dependencies already in the project before writing your own implementation or adding packages. Do not assume a library lacks a capability without checking its documentation and types.
- Make architectural decisions for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.

## Workflow

- Make small changes, discuss, and iterate. Do not make large changes all at once unless I tell you to. In general I prefer to work on a plan together, discussing the various design decisions, before implementing. I don't want you to rush ahead and make a plan without my input.
- Answer questions with explanations, not code changes. If I ask why something happened, explain first and wait for explicit direction before editing files.
- For potentially large tool output such as logs, recursive searches, and resource histories, filter or summarize at the source instead of returning the full output.
- When writing commit messages or jj describe messages, the first word should always start with a capital letter, but capitals should never be used for the rest of the message.

## Subagents

- Parent agents should proactively use subagents, without waiting for me to suggest it, when work has independent parts, requires broad or noisy research, or benefits from independent review or validation. Do small, tightly coupled, sequential work directly when delegation would provide no meaningful parallelism or independent validation.
- Use subagents for noisy exploration that would otherwise consume substantial parent context. Require concise summaries with only decision-relevant evidence, and do not repeat their exploration in the parent.
- Before delegating, load and follow the `pi-subagents` skill. Give each subagent a bounded goal, relevant context, authority limits, validation requirements, and expected output.
- Parallelize independent read-only work. Keep one active writer per working copy; isolate parallel writers in separate Git worktrees or jj workspaces. Subagents must not delegate unless explicitly assigned fanout.
- The parent owns orchestration, synthesis, integration, final verification, decisions, and the response to me.

## Editing

- Respect existing style conventions — do not reorder imports or change indentation.
- If I have modified or deleted something you wrote, respect that and do not undo my changes.
- Add comments sparingly. Err on the side of too few.
- If you're adding lines to a section of code, don't just stick it in a random location. Look at the surrounding code and figure out the best place to put it. For example if you're adding to a list, and the list is alphabetized, make sure that adding the lines will preserve the alphabetization. If you're adding a function to a file, don't just stick it at the top without thinking, find the best place in the file to add it (which might still be the top).

## Linting

- If the project contains a Justfile or a Makefile with a fmt or format command, run it after making any substantial edits. You don't need to run it if you just made a small change and you're confident you didn't mess up formatting.
- For any rust projects, check and fix any clippy warnings after making substantial edits (but before running the formatter). You don't need to run it if you just made a small change and you're confident you didn't mess up anything.

## Display

- For plain-text fenced code blocks, omit the language identifier; do not use `text`.
- For Mermaid diagrams, use only top-level `flowchart`, `stateDiagram-v2`, `classDiagram`, `erDiagram`, or `sequenceDiagram` blocks. Prefer `flowchart TD`, short labels, and simple syntax. Keep rendered diagrams under 80 columns; split wide or complex diagrams.
