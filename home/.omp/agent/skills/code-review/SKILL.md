---
name: code-review
description: Review branches, commit ranges, and GitHub pull requests. Use when the user asks for a code review or PR review.
---

# Code Review

Run this workflow directly. Do not invoke OMP's built-in `/review` workflow.

1. Identify the changes the user asked to review:
   - For a branch, review its diff from where it branches off main or its parent branch.
   - For two branches separated by `...`, review the diff between them.
   - For a GitHub PR, review the PR branch against its base branch. Read the PR through `pr://<owner>/<repo>/<number>` and its diff through `pr://<owner>/<repo>/<number>/diff/all` when useful. You may be in a jj workspace without a `.git` dir, so use jj commands, not git commands, and be sure to pass owner and repo in the pr read tool call, don't do just `pr://<number>`.
2. Once the diff is identified, use `jj git fetch` to fetch the latest repository state, then `jj new` to create a new change on top of the branch or commit being reviewed. This makes the local repository state match the changes under review so the user can inspect it in their editor. Leave the working copy there after the review.
3. Read the changes and analyze them within the larger context of the repository, not in isolation. Look around the rest of the repository for context and review the changes as a whole, not commit by commit.
4. Before reviewing the code, give the user a thorough and detailed summary of the changes. Do not assume the user is familiar with the affected parts of the codebase or the concepts involved.
5. After the summary, review the changes thoroughly but concisely. Always include file paths and line numbers when discussing specific code. Look for potential bugs, security issues, missing test coverage, bad styling, opportunities to deduplicate or simplify code, incorrect documentation, and anything else actionable. Do not focus on backward compatibility or fallbacks. Do not mention code that is fine or issues that are trivial. The main goal is to suggest actionable improvements.
6. Verify every finding before reporting it: trace the affected code path end to end, inspect called dependency implementations when behavior depends on them, and confirm each premise against source. Do not infer behavior from names, types, constructors, or unused fields; report an issue only when you can explain the concrete path to incorrect behavior.
7. For each finding, give a short description that a person unfamiliar with the changed code could understand. Then write a short comment about the finding that could be added to a PR review. Do not post comments to the PR unless the user asks. Each comment must identify the triggering condition, concrete consequence, line number, and suggested fix, using simple, concise, conversational language that does not sound like LLM output.

Do not run tests during a code review; CI covers them. If the user asks to post the comments, use the `gh` CLI to post all comments to GitHub in a single review.
