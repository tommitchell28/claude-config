---
name: creating-pull-requests
description: >-
  Creates GitHub pull requests with a body that always links the associated
  issue, so merging the PR auto-closes the issue. Use when the user asks to
  "create a PR", "open a pull request", "raise a PR", "submit a PR", "make
  a PR", "push and PR", or any natural phrasing that ends in opening a pull
  request via the GitHub CLI. Owns the full PR-creation flow: gathers
  context, infers or asks for the linked issue, validates it, builds the PR
  body from a fixed template, and invokes `gh pr create`.
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
   gh repo view --json defaultBranchRef -q .defaultBranchRef.name
   ```

   If the current branch matches the default branch, **abort** and tell the
   user to switch to a feature branch. Do NOT create a branch yourself —
   branch creation is a different workflow.

2. Confirm there is something to PR:

   ```bash
   git log <default-branch>..HEAD --oneline
   git diff <default-branch>...HEAD
   ```

   Abort if the branch has no commits ahead of the default branch.

3. Confirm the branch is pushed. If unpushed commits exist, run
   `git push -u origin <branch>` before continuing.

## Step 2: Identify the linked issue

Determine the issue number by working through these sources, in order:

1. **Conversation context.** Scan recent user messages for `#N`, GitHub
   issue URLs, `owner/repo#N` cross-repo refs, and phrasing like "fix
   #68", "the bug we discussed".
2. **Branch name.** Many branches encode the issue (e.g.
   `feat/68-add-login`). Treat as a hint, not a confirmation.
3. **Commit messages.** Run `git log <default-branch>..HEAD --oneline`
   and look for `#N` references. Treat as a hint, not a confirmation.
4. **Ask the user.** If no issue can be inferred with confidence:

   > "Which GitHub issue does this PR address? Reply with `#N`,
   > `owner/repo#N`, an issue URL, or `none` if there isn't one."

   Do NOT guess. Do NOT proceed without an answer.

For issues in another repo, use `owner/repo#N` syntax — GitHub renders the
cross-repo link and auto-closes on merge when paired with a closing
keyword.

## Step 3: Validate the issue exists

Run `gh issue view` to confirm every referenced issue is real:

```bash
gh issue view 68                    # same repo
gh issue view 68 --repo owner/repo  # cross-repo
```

If validation fails, surface the error, ask the user to confirm the
correct issue number / repo, and re-validate. Do NOT create the PR until
validation passes.

## Step 4: Choose the closing keyword

For each linked issue:

- **`Closes #N`** — this PR fully resolves the issue. GitHub auto-closes
  the issue on merge into the default branch.
- **`Refs #N`** — partial fix or the issue should remain open. Links
  without auto-closing.

If uncertain whether the PR fully closes the issue, ask the user:

> "Does this PR fully resolve issue #N, or only part of it? (`Closes`
> will auto-close on merge; `Refs` only links.)"

For multiple issues, emit one keyword per line.

If there is no associated issue, the section content is the literal word
`None` on its own line. Before using `None`, ask:

> "This PR has no linked issue. Confirm you want to open it with
> `## Linked issue` set to `None`?"

User must explicitly confirm. `None` is a deliberate choice, not the
default.

## Step 5: Compose the PR body

The body must follow the template in
[templates/pr-body.md](templates/pr-body.md). It defines
the four required sections (`## Linked issue`, `## Summary`, `## Test
plan`, footer), the multi-issue and cross-repo rules, and the
`gh pr create --body "$(cat <<'EOF' ... EOF)"` heredoc invocation pattern.

### Title

- Concise, under 70 characters.
- Use the description/body for detail, not the title.
- Do NOT enforce a particular convention. The repo's own `CLAUDE.md` may
  mandate Conventional Commits or another style — defer to it. In its
  absence, write a plain imperative summary.

## Step 6: Create the PR

Invoke `gh pr create` per the template's heredoc pattern.

Default to ready-for-review. Use `--draft` only when:

- The user explicitly asks for a draft.
- Recent commit messages contain `WIP`, `TODO`, or `in progress`.
- Tests are intentionally skipped or failing.
- The diff contains obvious debug code (`console.log`, `dbg!`, etc.) the
  user has not removed.

## Step 7: Stop

After `gh pr create` succeeds, print the PR URL and stop.

Do NOT watch CI, run a fix loop, comment, label, assign, or merge — those
belong to other workflows or to the user.

## Out of scope

This skill does not handle: branch creation, reviewer/assignee assignment,
labels, base-branch overrides, detection of an existing PR for the branch,
or `gh` authentication failures. Surface any `gh` errors verbatim to the
user.

## Bundled files

Read these as needed during the workflow:

- [templates/pr-body.md](templates/pr-body.md) — PR body template,
  multi-issue and cross-repo rules, heredoc invocation pattern. Open
  before composing the body in Step 5.
- [references/examples.md](references/examples.md) — six walked-through
  scenarios. Skim if the situation looks unusual (cross-repo, no issue,
  partial closure, multi-issue).
- [references/troubleshooting.md](references/troubleshooting.md) — common
  errors. Open if any `git` or `gh` command fails.
