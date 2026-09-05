---
name: address-feedback
description: Address feedback on a GitHub pull request when the user asks to implement or act on PR feedback. Do not use for reviewing code or checking whether previous feedback has already been addressed.
---

# Address Feedback

Use this skill when the user asks to address feedback on a PR. Implement valid feedback and prepare replies; do not merely assess whether feedback has already been addressed.

## Resolve the PR

1. Use the PR specified by the user. If none is explicitly provided, infer it from recent conversation history when the target is clear; do not inspect repository state merely to rediscover that PR. Otherwise, use read-only jj commands to inspect the current change and its ancestor chain for existing bookmarks, and query GitHub for their associated PRs using the `gh` CLI. Select the most recent PR associated with a bookmark in that chain. Do not substitute an unrelated repository PR. If no matching PR exists, or competing matches leave the target ambiguous, ask the user for the target.
2. Determine the repository from the remote URL and use explicit repository arguments with `gh`; the workspace may not have a `.git` directory.
3. Retrieve the latest PR metadata, description, comments, and complete review threads, including replies and resolution state, directly from GitHub. Paginate results so feedback is not silently omitted. Read linked requirements when needed to establish intent.
4. Compare the PR's current head and base with the local code using read-only commands. Preserve existing user changes. If the working copy does not contain the PR code needed to make the fixes safely, explain the mismatch and ask for the necessary repository operation rather than changing revisions yourself.

## Validate and implement

- Identify actionable feedback in unresolved comment threads, accounting for subsequent replies, clarifications, and changes. Verify against the current code whether a change is still needed. Include actionable standalone PR comments as well.
- Thoroughly check each claim against source before editing. Trace relevant callers, consumers, invariants, guards, and dependency behavior. Establish the actual trigger and consequence for bug reports, or the concrete benefit and consistency with repository conventions for proposed improvements. Do not accept feedback merely because a reviewer asserted it.
- If the feedback is valid and still applies, implement the smallest complete change addressing its root cause. Update affected callers and documentation as appropriate, reuse existing patterns, and preserve unrelated work. If several threads describe the same issue, make one coherent fix and account for each thread in the replies.
- If feedback is incorrect, already addressed, superseded, or conflicts with established requirements, do not make an unnecessary change. Explain the reason with concrete evidence. If a requirement is genuinely ambiguous, ask rather than inventing intent.
- Verify implemented changes with focused checks appropriate to the affected behavior and follow the repository's validation and formatting instructions. Unlike a read-only code review, this workflow implements changes and should exercise them. Report exactly what was verified and any remaining limits.

## Replies and permissions

1. For every thread containing feedback, provide its link and a short, paste-ready reply:
   - If fixed, explain how the change addresses the concern and mention relevant verification where useful.
   - If no change was made, explain why, supported by the code or requirements.
   - If blocked or only partially addressed, state what remains and what is needed to finish.
2. Keep replies concise, conversational, and specific. Do not claim local fixes have been committed, pushed, or published.
3. Do not post replies unless explicitly asked. When asked, post each reply to its corresponding thread or comment using the `gh` CLI. Do not resolve threads unless explicitly asked; addressing feedback does not authorize thread resolution.
4. Do not run any jj command that modifies repository state unless specifically asked. This includes `jj git fetch`, `jj new`, `jj describe`, bookmark creation or movement, rebasing, and `jj git push`. The request to address feedback authorizes source edits, not these repository operations. Read-only jj inspection is allowed. Do not use Git or another tool to bypass this restriction.
