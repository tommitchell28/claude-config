# Claude Config

Source of truth for `~/.claude/` configuration: settings, skills, hooks, rules, output styles and agents. Edit here, then deploy; a file edited directly in `~/.claude/` is overwritten by the next deploy.

## Layout

| Path                          | Deployed | Holds                                                              |
| ----------------------------- | -------- | ------------------------------------------------------------------ |
| `.claude/skills/`             | yes      | Skills, one directory each with a `SKILL.md`                       |
| `.claude/hooks/`              | yes      | Hook scripts that `settings.json` points at                        |
| `.claude/rules/`              | yes      | Rules loaded in every project, some scoped by `paths:` frontmatter |
| `.claude/output-styles/`      | yes      | Output styles; `plain-voice` is the default                        |
| `.claude/agents/`             | yes      | Sub-agent definitions                                              |
| `.claude/settings.json`       | yes      | User settings; hook paths are rewritten to `$HOME` on deploy       |
| `.claude/CLAUDE.md`           | yes      | Instructions loaded in every session                               |
| `.mcp.json`                   | merged   | MCP servers, merged into `~/.claude.json`                          |
| `.claude/plans/`              | no       | Plan files for work on this repo                                   |
| `.claude/code-reviews/`       | no       | Output of the `reviewing-code` skill; gitignored                   |
| `.claude/settings.local.json` | no       | Settings for this repo only                                        |

## Usage

```bash
./setup.sh --dry-run   # preview: changes nothing
./setup.sh             # deploy to ~/.claude/ after a confirmation prompt
```

`setup.sh` copies the deployed directories with `rsync` and never deletes anything in `~/.claude/`.

- **Dry run.** `--dry-run` shows what would be copied, the diffs below, the orphan report and what the MCP merge would do.
- **Diffs.** Before `settings.json` and `CLAUDE.md` are written, the script prints a diff between the deployed copy and the copy about to replace it.
- **Orphan report.** Files under the deployed directories that are no longer in this repo are listed, never deleted; remove them by hand. `~/.claude/skills/synced/` belongs to Claude Code and is left out of the report.
- **MCP servers.** The `mcpServers` in `.mcp.json` are merged into `~/.claude.json` with `jq`, after backing that file up to `~/.claude.json.bak`. To add a user-level MCP server, edit `.mcp.json` and re-run `./setup.sh`.

## Changes Made on the Machine

`/config`, `/effort` and similar commands write to the deployed `~/.claude/settings.json`, not to this repo. The next deploy overwrites them, so copy any such change back into `.claude/settings.json` here. The diff that `setup.sh` prints shows what would be lost.

## Write Protection

The `block-deployed-config-writes.sh` hook stops Claude from editing the deployed copies under `~/.claude/` and names the file in this repo to edit instead. It finds this repo through the `CLAUDE_CONFIG_REPO` environment variable, which defaults to `$HOME/Documents/code/claude-config`; set it if the repo is cloned somewhere else.
