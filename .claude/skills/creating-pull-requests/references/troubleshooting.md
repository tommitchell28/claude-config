# Troubleshooting

Common errors and edge cases when running the `creating-pull-requests`
skill.

## `gh: command not found`

**Cause:** GitHub CLI is not installed.

**Fix:** Tell the user to install `gh` (https://cli.github.com/) and
authenticate with `gh auth login`. Do not attempt the install yourself.

## `gh auth status` reports "not logged in"

**Cause:** `gh` is installed but not authenticated.

**Fix:** Tell the user to run `gh auth login` and re-run the request.
Do not store or generate credentials.

## `pull request create failed: GraphQL: ... already exists`

**Cause:** A PR for this branch already exists.

**Fix:** Run `gh pr view` to fetch the existing PR's URL and surface
both the error and the URL to the user. Do not force-recreate.

## `gh issue view <N>` returns 404

**Cause:** The issue number does not exist in the current repo (or
typo).

**Fix:**

1. Show the user the error.
2. Ask which repo the issue lives in. It may need a `--repo owner/repo`
   flag for cross-repo references.
3. Re-validate before creating the PR.

## Branch not pushed to remote

**Cause:** `gh pr create` requires the branch to exist on the remote.

**Fix:** Run `git push -u origin <branch>` before invoking
`gh pr create`. Surface any push errors to the user (e.g. permission
denied, non-fast-forward).

## On the default branch

**Cause:** `git rev-parse --abbrev-ref HEAD` returns `main` (or whatever
the repo's default branch is).

**Fix:** Abort. Tell the user to switch to a feature branch. Do NOT
create a branch yourself — that belongs to a different workflow.

## Issue number ambiguous between same-repo and cross-repo

**Cause:** User wrote `#68` but the issue lives in another repo.

**Fix:** If `gh issue view 68` fails in the current repo, ask the user
which repo the issue lives in before falling back to a cross-repo
reference.

## User wants a base branch other than the repo default

**Cause:** Out of scope for this skill.

**Fix:** Tell the user to create the PR manually with
`gh pr create --base <branch>` or to change the base after creation in
the GitHub UI.
