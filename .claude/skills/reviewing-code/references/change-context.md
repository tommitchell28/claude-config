# Change-Context Scripts

The scripts under `scripts/` turn "a code change" into one shared snapshot, so every agent in a review reads the same diff the same way. Call them as shown; never re-derive a diff with git by hand.

| Script                    | Job                                                                                                                      | Output                                                                             |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------- |
| `report-paths.sh`         | Create one timestamped run directory under `.claude/code-reviews/`.                                                      | `RUN_DIR`, `CONTEXT_FILE`, `SHARD_DIR`, `REPORT` and `AUDIT` as `KEY=VALUE` lines. |
| `get-changes.sh`          | Resolve the change and write the context file (metadata, name-status, full unified diff). Diff goes to the file only.    | Compact `KEY=VALUE` summary plus the name-status list on stdout.                   |
| `requirements-context.sh` | Find the branch's GitHub pull request and linked issue (`detect`), and append their text to the context file (`append`). | `PR_NUMBER`, `ISSUE_REF`, `REQ_SLUG` and `REQ_STATUS` lines; never fails a review. |
| `shard-context.sh`        | Split a context file into a header shard (everything but the diff) plus one diff shard per changed file.                 | Manifest: `HEADER=<path>` then one `SHARD<TAB><file><TAB><shard>` line per file.   |

Every script answers `--help`. `CONTEXT_SCRIPTS` below is this skill's `scripts/` directory.

## `get-changes.sh` — Pick the Change

```bash
# Auto-detect from the checked-out state: branch, working-tree, last-commit, initial-commit or unborn-branch.
"$CONTEXT_SCRIPTS/get-changes.sh" "$CONTEXT"                         # optional 2nd arg overrides the base branch
"$CONTEXT_SCRIPTS/get-changes.sh" "$CONTEXT" --exclude TODO.md --exclude 'docs/*'   # leave paths out (tracked and untracked)

# Explicit range: diff a PR while another branch (e.g. main) is checked out.
git fetch origin "$BASE_BRANCH" "$HEAD_BRANCH"                        # fetched branches resolve only as origin/<branch>
"$CONTEXT_SCRIPTS/get-changes.sh" "$CONTEXT" --range "origin/$BASE_BRANCH..origin/$HEAD_BRANCH"   # or SHAs
```

- Auto-detect is for reviewing what is checked out; `--range` is for a PR's `base..head` from any checkout.
- Both write the same file shape.
- The range path diffs exactly `merge-base(base,head)..head` and ignores the working tree.
- Read the printed `MODE`, `BASE`, `HEAD`, `FILE_COUNT` and the name-status; `FILE_COUNT=0` means nothing to work on.
- `--exclude <pathspec>` (repeatable) drops matching paths from the change — the way to honour "that file isn't part of this" when the user says so.
- `BASE_IS_LOCAL=yes` means the detected base is not a remote-tracking ref and may be stale (the file's metadata carries the same warning); suggest `git fetch` in that case.
- Untracked files in the context file's own directory are never counted as part of the change, so earlier context files, shards and reports stay out of the diff.

## `requirements-context.sh` — the Pull Request and Issue

```bash
"$CONTEXT_SCRIPTS/requirements-context.sh" detect                                  # current branch
"$CONTEXT_SCRIPTS/requirements-context.sh" append "$CONTEXT" --pr 12 --issue 7     # either flag alone is fine
```

- `detect` finds the open pull request for the current branch, then its linked issue: the PR's closing references first, else the first `Closes`/`Fixes`/`Resolves`/`Refs #N` in the PR body.
- An issue in another repository comes back as its URL; `--issue` takes a number or a URL.
- `append` adds a `## Requirements context` section holding each title, URL and body, all quoted; an empty `--pr` or `--issue` value is ignored.
- Confirm what `detect` found with the user before running `append`.
- When `gh` is missing or not logged in, the repository has no remote, or nothing is found, the script prints `REQ_STATUS=SKIP: <reason>` and exits 0.

## `shard-context.sh` — Slice One Context Into Per-File Shards

```bash
"$CONTEXT_SCRIPTS/shard-context.sh" "$CONTEXT" "$SHARD_DIR"           # prints HEADER= then SHARD lines
```

- Run it **after** every appended section (requirements context, discovered standards, requirements) is in the context file, so the header shard carries the full shared context.
- Writes `$SHARD_DIR/header.md` and `$SHARD_DIR/files/NNN_<path>.diff`, removing earlier shards first; the diff bytes are copied exactly as `get-changes.sh` wrote them.
- Give each agent only what it needs: an agent judging one file reads the header plus that file's shard; an agent covering the whole change reads the header plus every shard the manifest lists.

## Context File Shape

`get-changes.sh` writes `# Change context` with three sections — `## Metadata` (table), `## Changed files` (name-status in a code fence) and `## Unified diff` (a `diff` fence). Later sections are appended after the diff; `shard-context.sh` keeps them in the header shard and out of the per-file shards.
