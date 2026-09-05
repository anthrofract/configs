---
name: create-pr
description: Create a GitHub pull request when explicitly requested, using jj bookmarks and the gh CLI.
---

# Create PR

A request to create a PR explicitly authorizes `jj git fetch`, `jj bookmark create`, targeted `jj git push`, `gh pr create`, and `gh stack link` without further confirmation, satisfying the global AGENTS.md permission requirement. It does not authorize commit rewrites, checkout changes, unrelated bookmark moves, or file edits.

## Resolve scope

1. Use the supplied jj change or commit as the PR tip, defaulting to `@`. Resolve it to a single commit ID (`<tip>`); do not substitute a different revision if it is empty or undescribed.
2. Read the `origin` URL from `jj git remote list` to identify `<owner>/<repo>`.
3. Use the requested base branch, or discover the repository's default branch (such as `main` or `master`):

   ```bash
   gh repo view <owner>/<repo> --json defaultBranchRef --jq '.defaultBranchRef.name'
   ```

4. Run `jj git fetch` and resolve the base's `origin` bookmark. Check for a parent PR as described below, then inspect the commits and diff above the effective base. Use only this PR's layer for its title, description, commit count, and Linear ticket selection.
5. Retrieve associated Linear tickets with `get_issue` for their suggested branch names and URLs.

## Find a parent PR

Walk the tip's ancestors back toward the requested or default base, excluding the tip and commits already reachable from that base. List bookmarks in this range:

```bash
jj bookmark list --revision '(<base>@origin..<tip>) ~ <tip>'
```

For each bookmarked ancestor, check for an open PR (including drafts):

```bash
gh pr list --repo <owner>/<repo> --state open --head <ancestor-branch> --json number,url,headRefName,headRefOid,baseRefName
```

Use the nearest ancestor with an open PR as the parent; skip bookmarks without one. Confirm its `headRefOid` matches the ancestor commit. If competing ancestry paths or mismatched PR heads make the parent ambiguous, stop rather than guess. With a parent, use its head branch as `<base>` for the new PR; otherwise keep the original base.

For a parent PR, check existing GitHub stacks before creating the new PR:

```bash
gh api --paginate repos/<owner>/<repo>/stacks
```

If the parent belongs to a stack, it must be that stack's top PR before appending. Otherwise, retain the ancestor PR URLs in bottom-to-top order to create a stack after publishing. Confirm they already form a base-to-head chain; stop if linking would retarget existing PRs.

## Choose and push a bookmark

Run `jj bookmark list --revision <tip>`, then use the first applicable option:

1. **Existing bookmark at the tip:** reuse and push it.

   ```bash
   jj git push --bookmark <branch>
   ```

2. **Associated Linear ticket:** create a bookmark using its exact suggested branch name, then push it.

   ```bash
   jj bookmark create <linear-branch> --revision <tip>
   jj git push --bookmark <linear-branch>
   ```

3. **Otherwise:** let jj create and push a bookmark.

   ```bash
   jj git push --change <tip>
   ```

   Read the generated bookmark name from the push output.

If multiple bookmarks or tickets fit, use the request and context to choose; ask only if still ambiguous. Do not move an ancestor's bookmark or overwrite an existing local or remote bookmark pointing elsewhere. Push only the selected bookmark, preserve jj's safety checks, and stop if the push fails.

## Create the PR

- **Title:** for a single-commit PR, use the commit description's first line verbatim. For multiple commits, write a concise title covering the whole change.
- **Description:** a concise Markdown bullet list explaining what changed and why, with relevant context such as Linear tickets, Slack discussions, documentation links, or logs. No headings, checklists, boilerplate, or invented context. Do not use `--fill`.

After a successful push, create the PR with an explicit repository, head bookmark, and base branch. `--repo` supports jj workspaces without `.git`; `--head` avoids detached-HEAD discovery.

```bash
gh pr create --repo <owner>/<repo> --head <branch> --base <base> --title "$title" --body "$body"
```

Replace placeholders with resolved values and set `title` and `body` to the prepared text. Add `--draft` only when requested.

## Link the stack

If there is a parent PR, link the newly created PR using GitHub's `gh stack link` extension command—not `gh pr stack`. Use PR URLs so the extension does not push branches itself. `GH_REPO` supplies the repository explicitly because this command has no `--repo` flag.

For an existing stack:

```bash
GH_REPO=<owner>/<repo> gh stack link <stack-number> <new-pr-url>
```

Otherwise, pass all ancestor PR URLs followed by the new PR URL, ordered bottom to top:

```bash
GH_REPO=<owner>/<repo> gh stack link --base <bottom-pr-base> <ancestor-pr-url> <new-pr-url>
```

Add further ancestor PR URLs between the shown arguments as needed. `<bottom-pr-base>` is the existing base branch of the bottom PR, not the new PR's parent branch.

Return the created PR's URL. Report creation or linking failures accurately, including whether the branch was pushed and the PR was created.
