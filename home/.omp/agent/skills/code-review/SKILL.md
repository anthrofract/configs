---
name: code-review
description: Review branches, commit ranges, and GitHub pull requests when explicitly requested with a target, or check whether feedback from a previous review has been addressed. Do not use for routine checks of work in progress, analysis of existing code, or general feedback.
---

# Code Review

For an initial review, use this skill only when both conditions are met:
- The user explicitly asks for a code review.
- The user specifies the branch, commit range, or PR to review.

Do not treat implementation checks, debugging, code explanations, or general requests to inspect or improve code as code-review requests. If the user asks for a code review without a target, ask for the target before starting this workflow. Do not infer one from the current workspace.

After performing a review, also use this skill when the user asks whether its issues or comments have been addressed. Reuse the previously reviewed target unless the user specifies another; follow "Check whether feedback was addressed" below.

Run this workflow directly rather than through OMP's built-in `/review` command, but use OMP's `reviewer` subagents as described under "Analysis".

## Scope and checkout

1. Identify the requested branch, commit range, or GitHub PR. For PRs, read `pr://<owner>/<repo>/<number>` and, when useful, `pr://<owner>/<repo>/<number>/diff/all`. Always include owner and repo.
2. Use jj for repository operations; the workspace may not have a `.git` directory. Fetch with `jj git fetch` before resolving the exact base and head revisions:
   - For a branch, compare its merge base with main or its parent branch to its head.
   - For `A...B`, compare the merge base of A and B to B, not the two branch tips.
   - For a commit range, resolve the requested endpoints.
   - For a PR, compare its merge base with the PR's base branch to the PR head.
   Use the resolved revisions for both analysis and checkout throughout the review.
3. Run `jj new` on the resolved head so the user can inspect the reviewed code in their editor. Leave the working copy there afterward. This skill explicitly authorizes `jj git fetch` and `jj new` for reviews; other VCS writes still require explicit permission. Preserve existing work and stop if checkout would overwrite local changes.

## Analysis

- After checkout, run a first bug-finding pass with OMP's `reviewer` agent using the `task` tool, setting `agent: "reviewer"` in every `tasks[]` item. Use 1 reviewer for small diffs. For large diffs, spawn several in parallel and assign files by locality: same module or related functionality together, tests with their implementation. Give each reviewer the resolved base and head revisions, the intended behavior from the PR description or requirements, and its assigned files. Tell it to read the diff with `jj diff --git --from <base> --to <head>` instead of `git diff` or `gh pr diff`, and that the working copy is checked out at the reviewed head, so it may read local files for context, including unchanged callers and consumers.
- Treat reviewer findings as leads, not results. Verify each one using the standards below before reporting it, and drop any that fail. Reviewers only look for correctness bugs, so do the full analysis below yourself as well.
- Analyze the complete diff in repository context before writing the summary and findings. Review the changes as a whole, not commit by commit.
- Establish the intended behavior from the PR description, linked requirements, and repository contracts. Check whether the implementation satisfies them. Distinguish explicit requirements from your own assumptions.
- When a contract changes, inspect its callers, consumers, and producers—including unchanged code. Check that they agree on inputs, outputs, errors, and lifecycle behavior.
- Look for bugs, security issues, meaningful test-coverage gaps, concrete simplifications or deduplication opportunities, violations of established repository conventions, and incorrect documentation. Report only issues introduced or materially worsened by the changes. Do not focus on backward compatibility or fallbacks.
- Verify every finding against source. For correctness findings, trace the trigger and concrete failure path end to end, inspecting dependency implementations when behavior depends on them. Do not infer behavior from names, types, constructors, or unused fields alone.
- Before reporting a finding, look for guards, invariants, caller guarantees, or dependency behavior that would make it invalid. Compare with the base revision to establish that the changes introduced or worsened the issue.
- For maintainability or documentation findings, identify the concrete cost or mismatch. Do not report speculative concerns, personal style preferences, trivial issues, or code that is fine.
- Read relevant tests. Report a coverage gap only when you can name a concrete behavior at risk and a plausible regression the missing test would catch. Do not request tests merely because code changed.
- Do not run tests during a code review. Disclose verification limits; do not claim CI coverage or success without evidence.

## Output

Order findings by impact and distinguish correctness or security issues from optional maintainability improvements. Consolidate findings with the same root cause unless they require different fixes. If there are no actionable findings, say so without inventing suggestions.

1. Start with a summary, followed by findings. Write the summary for a reader who knows the language but not this area of the codebase. This section is an exception to any general instruction to be terse: use full sentences and define terms instead of assuming context. Cover, in order:
   - **Purpose**: the problem or requirement the change addresses and why it matters, from the PR description or linked issues. Say so if the motivation is unclear.
   - **Background**: the subsystems, data flow, and domain concepts needed to understand the change. Explain what each relevant component is responsible for and how it relates to the others before describing what changed. Define project-specific terms and abbreviations on first use.
   - **What changed**: walk through the change by behavior or data flow, not file by file. Describe behavior before and after, including changes to public interfaces, configuration, or data formats. Use file paths to point the reader at code; do not rely on them as the explanation.
   - **Where to look**: the parts that carry the most risk or need the most careful reading, and why.

   Scale the length to the change: a few sentences for trivial changes, several paragraphs for changes that span subsystems. Use a short mermaid diagram when a flow or interaction among several components is easier to see than to read.
2. For each finding:
   - Explain the issue briefly for a reader unfamiliar with the changed code.
   - Provide a paste-ready PR comment stating the trigger or relevant context, concrete consequence, and suggested fix.
   - Include the relevant file path and line number in both.

   Use plain, concise, conversational language.
3. Do not post comments unless the user asks. When asked, use the `gh` CLI to post all comments to GitHub in a single review.
4. If the user asks to approve the PR, just approve it without comment, unless otherwise specified.

## Check whether feedback was addressed

1. Refresh the review target rather than relying on the previous checkout or cached PR information. Run `jj git fetch` again, retrieve the latest PR metadata, comments, and complete review threads including replies and resolution state with the `gh` CLI, and resolve the current base and head. Run `jj new` again on the resolved current head, following the same working-copy safeguards as the initial review. This follow-up explicitly authorizes both commands.
2. Evaluate each feedback item against the latest code and discussion using the analysis standards above. Trace whether the original failure or concern is actually addressed; a reply claiming a fix, an outdated diff anchor, or a resolved thread alone is not proof. Include previous findings that were never posted, but do not create threads for them.
3. Resolve each unresolved PR review thread whose feedback is fully addressed, using the `gh` CLI. This follow-up explicitly authorizes resolving addressed threads without further confirmation. Leave partially addressed, unaddressed, or unverifiable threads unresolved. Confirm resolution succeeded before reporting a thread as resolved.
4. Summarize which items are addressed with brief supporting evidence and links to the relevant threads or current code. For each item that remains unaddressed, briefly explain why and provide a paste-ready reply explaining the remaining issue and what needs to change. State any verification limits rather than guessing.
5. Do not post replies unless explicitly requested. If requested, post them as replies to their corresponding PR comment threads, not as a new review or unrelated top-level comments.
