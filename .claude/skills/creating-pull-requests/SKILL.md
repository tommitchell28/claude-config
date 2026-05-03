---
name: creating-pull-requests
description: >-
  Creates GitHub pull requests with a body that always links the associated
  issue, so merging the PR auto-closes the issue. Use when the user asks to
  "create a PR", "open a pull request", "push and PR", "raise a PR", or any
  natural phrasing that ends in opening a pull request via the GitHub CLI.
  Owns the full PR-creation flow: gathers context, infers or asks for the
  linked issue, validates it, builds the PR body from a fixed template, and
  invokes `gh pr create`.
---

# Creating Pull Requests

This skill owns the full pull-request creation flow. It replaces any default
PR-creation behaviour. Follow it whenever the next action is opening a GitHub
pull request.

## Important

- The PR body MUST contain a `## Linked issue` section. No exceptions.
- Either link a real issue with `Closes` / `Refs`, or render the section as
  `None`. Never silently omit it.
- Validate every issue reference with `gh issue view` before creating the PR.
  Catching `#86` vs `#68` typos here is the entire point of this skill.

## Step 1: Pre-flight checks

Before doing anything else:

1. Confirm a feature branch is checked out:

   ```bash
   git rev-parse --abbrev-ref HEAD
   ```

   Determine the repo's default branch (usually `main`, sometimes `master`):

   ```bash
   gh repo view --json defaultBranchRef -q .defaultBranchRef.name
   ```

   If the current branch matches the default branch, **abort** and tell the
   user to switch to a feature branch. Do NOT create a branch yourself —
   branch creation is a different workflow.

2. Confirm there is something to PR:

   ```bash
   git status
   git log <default-branch>..HEAD --oneline
   git diff <default-branch>...HEAD
   ```

   If the branch has no commits ahead of the default branch, abort and tell
   the user.

3. Confirm the branch is pushed to the remote and up to date. If unpushed
   commits exist, push with `git push -u origin <branch>` before creating
   the PR.

## Step 2: Identify the linked issue

The PR must reference its issue. Determine the issue number by working
through these sources, in order:

1. **Conversation context.** Scan recent user messages for:
   - Bare issue numbers: `#68`, `issue 68`, `#68 in wagtails`
   - GitHub URLs: `https://github.com/owner/repo/issues/68`
   - Cross-repo references: `owner/repo#68`
   - Phrasing like "work on #68", "fix issue 68", "the bug we discussed"

2. **Branch name heuristic.** Many branches encode the issue (e.g.
   `feat/68-add-login`, `fix-issue-72`). Extract candidate numbers but
   treat them as a hint, not a confirmation.

3. **Ask the user.** If no issue can be inferred with confidence, ask
   explicitly before proceeding:

   > "Which GitHub issue does this PR address? Reply with `#N`,
   > `owner/repo#N`, an issue URL, or `none` if there isn't one."

   Do NOT guess. Do NOT proceed without an answer.

### Cross-repo references

If the issue lives in a different repo than the PR, use `owner/repo#N`
syntax. GitHub renders this as a cross-repo link and auto-closes on merge
when paired with a closing keyword.

Examples:

- Same repo: `Closes #68`
- Cross-repo: `Closes tommitchell28/wagtails-website-v2#68`

## Step 3: Validate the issue exists

Before writing the PR body, run `gh issue view` to confirm every referenced
issue is real:

```bash
# Same repo
gh issue view 68

# Cross-repo
gh issue view 68 --repo tommitchell28/wagtails-website-v2
```

If the command fails (issue does not exist, wrong repo, etc.):

1. Show the user the error.
2. Ask them to confirm the correct issue number / repo.
3. Re-validate.
4. Do NOT create the PR until validation passes.

## Step 4: Choose the closing keyword

For each linked issue, decide between:

- **`Closes #N`** — this PR fully resolves the issue. GitHub will
  auto-close the issue when the PR merges into the default branch. Use this
  whenever the PR ships everything the issue asks for.
- **`Refs #N`** — this PR only partially addresses the issue, or the issue
  should remain open after merge. Creates a link without auto-closing.

If you are uncertain whether the PR fully closes the issue, ask the user:

> "Does this PR fully resolve issue #N, or only part of it? (`Closes` will
> auto-close on merge; `Refs` only links.)"

For multiple issues, emit one keyword per line:

```
Closes #68
Closes #72
Refs #15
```

If there is no associated issue, the section content is the literal word
`None` on its own line. Confirm with the user before using `None` — it
should be a deliberate choice, not the default.

## Step 5: Compose the PR

### Title

- Concise, under 70 characters.
- Use the description/body for detail, not the title.
- Do NOT enforce a particular convention here. The repo's own
  `CLAUDE.md` may mandate Conventional Commits or another style — defer
  to it. In its absence, write a plain imperative summary.

### Body template

The body MUST follow this structure, in this order:

```markdown
## Linked issue

<closing keyword line(s) — `Closes #N`, `Refs #N`, cross-repo, or `None`>

## Summary

- <1-3 bullets describing what the PR changes and why>

## Test plan

- [ ] <verification step>
- [ ] <verification step>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Rules:

- Every section header is present, even when its content is `None`.
- The footer line is mandatory and verbatim.
- The Test plan is a markdown checkbox list, not prose.

## Step 6: Create the PR

Pass the body to `gh pr create` via a heredoc to preserve formatting:

```bash
gh pr create --title "the pr title" --body "$(cat <<'EOF'
## Linked issue

Closes #68

## Summary

- <bullets>

## Test plan

- [ ] <step>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

For in-progress work, add `--draft`:

```bash
gh pr create --draft --title "..." --body "$(cat <<'EOF'
...
EOF
)"
```

Default to ready-for-review. Use `--draft` only when the user asks for it,
or when commits/code clearly indicate work in progress (e.g. "WIP" in
recent commits, failing tests on purpose).

## Step 7: Stop

After `gh pr create` succeeds, print the PR URL and stop.

Do NOT:

- Watch CI status.
- Run a fix loop on red checks.
- Comment on, label, assign, or merge the PR.
- Take any post-creation action.

Those belong to other workflows or to the user.

## Out of scope

This skill does not handle:

- Branch creation (use `/starting-dev` or your project workflow).
- Reviewer / assignee assignment.
- Label application.
- Base-branch overrides — rely on `gh pr create`'s default.
- Detection of an existing PR for the branch — `gh pr create` will error
  clearly if one exists; surface that error to the user.
- `gh` authentication failures — surface `gh`'s error to the user.

## Examples

### Example 1: Same-repo issue inferred from conversation

User earlier said: "let's fix #42, the login bug." Now says: "open a PR".

1. `git rev-parse --abbrev-ref HEAD` → `fix/42-login`. Not the default
   branch — proceed.
2. Issue inferred: `#42`.
3. `gh issue view 42` → exists.
4. Ask the user: "Does this fully resolve #42?" → "yes".
5. Compose PR body with `Closes #42`.
6. `gh pr create` → return URL.

### Example 2: Cross-repo issue

User says: "open a PR in claude-config that closes wagtails-website-v2#68".

1. Pre-flight checks pass.
2. Cross-repo reference: `tommitchell28/wagtails-website-v2#68`.
3. `gh issue view 68 --repo tommitchell28/wagtails-website-v2` → exists.
4. Body: `Closes tommitchell28/wagtails-website-v2#68`.
5. `gh pr create`.

### Example 3: No associated issue

User says: "open a PR for this typo fix".

1. No issue in conversation, no obvious issue in branch name.
2. Ask: "Which GitHub issue does this PR address? Reply with `#N`,
   `owner/repo#N`, an issue URL, or `none`."
3. User: "none".
4. Body's `## Linked issue` section: `None`.
5. `gh pr create`.

### Example 4: Validation catches a typo

User says: "open a PR closing #86" (but the real issue is #68).

1. `gh issue view 86` → 404.
2. Surface the error to the user, ask for the correct number.
3. User: "sorry, #68".
4. `gh issue view 68` → exists. Proceed.

## Common Issues

### `gh: command not found`

Cause: GitHub CLI is not installed.
Solution: Tell the user to install `gh` (https://cli.github.com/) and
authenticate with `gh auth login`. Do not attempt the install yourself.

### `pull request create failed: GraphQL: ... already exists`

Cause: A PR for this branch already exists.
Solution: Surface the error and the existing PR URL (from `gh pr view`)
to the user. Do not force-recreate.

### Issue number ambiguous between same-repo and cross-repo

Cause: User wrote `#68` but the issue lives in another repo.
Solution: If `gh issue view 68` fails in the current repo, ask the user
which repo the issue lives in before falling back to a cross-repo
reference.
