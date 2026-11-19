# Claude Config

Source of truth for `~/.claude/` configuration: settings, skills, hooks, rules, output styles and agents. Edit here, then deploy; a file edited directly in `~/.claude/` is overwritten by the next deploy.

## Layout

| Path                          | Deployed | Holds                                                                     |
| ----------------------------- | -------- | ------------------------------------------------------------------------- |
| `.claude/skills/`             | yes      | Skills, one directory each with a `SKILL.md`                              |
| `.claude/hooks/`              | yes      | Hook scripts that `settings.json` points at                               |
| `.claude/rules/`              | yes      | Rules loaded in every project, some scoped by `paths:` frontmatter        |
| `.claude/output-styles/`      | yes      | Output styles; `plain-voice` is the default                               |
| `.claude/agents/`             | yes      | Sub-agent definitions                                                     |
| `.claude/settings.json`       | yes      | User settings; hook paths are rewritten to `$HOME` on deploy              |
| `.claude/CLAUDE.md`           | yes      | Instructions loaded in every session                                      |
| `.mcp.json`                   | merged   | MCP servers, merged into `~/.claude.json`                                 |
| `third-party-skills.json`     | fetched  | Skills fetched from other git repos (see Third-Party Skills)              |
| `scripts/`                    | no       | Scripts `setup.sh` calls                                                  |
| `.third-party/`               | no       | Clones of upstream repos and the skill copies built from them; gitignored |
| `.claude/plans/`              | no       | Plan files for work on this repo                                          |
| `.claude/code-reviews/`       | no       | Output of the `reviewing-code` skill; gitignored                          |
| `.claude/settings.local.json` | no       | Settings for this repo only                                               |

## Usage

```bash
./setup.sh --dry-run   # preview: changes nothing
./setup.sh             # deploy to ~/.claude/ after a confirmation prompt
```

`setup.sh` copies the deployed directories with `rsync` and never deletes anything in `~/.claude/`.

- **Dry run.** `--dry-run` still fetches third-party skills, which writes only to `.third-party/`. It previews, without writing to `~/.claude/`:
  - the files that would be copied
  - the diffs below
  - the third-party skill changes
  - the orphan report
  - what the MCP merge would do
- **Diffs.** Before `settings.json` and `CLAUDE.md` are written, the script prints a diff between the deployed copy and the copy about to replace it.
- **Orphan report.**
  - Lists files under the deployed directories that are no longer in this repo or the third-party manifest.
  - Never deletes them; remove them by hand.
  - Leaves out `~/.claude/skills/synced/`, which belongs to Claude Code.
- **MCP servers.** The `mcpServers` in `.mcp.json` are merged into `~/.claude.json` with `jq`, after backing that file up to `~/.claude.json.bak`.
  - To add a user-level MCP server, edit `.mcp.json` and re-run `./setup.sh`.

## Third-Party Skills

`setup.sh` fetches the skills named in `third-party-skills.json` and deploys each source as a plugin under `~/.claude/skills/<plugin>/`. Claude Code lists a plugin's skills as `<plugin>:<skill>`, so they cannot clash with the skills in this repo. The file holds a `sources` array; each entry looks like:

```json
{
  "plugin": "mattpocock",
  "repo": "https://github.com/mattpocock/skills.git",
  "ref": "main",
  "skills": ["skills/engineering/tdd"],
  "rewrites": [{ "from": "code-review", "to": "reviewing-code" }]
}
```

| Field      | Holds                                                                                                     |
| ---------- | --------------------------------------------------------------------------------------------------------- |
| `plugin`   | Plugin name and deployed directory; must not match a directory in `.claude/skills/`                       |
| `repo`     | Git URL of the upstream repo                                                                              |
| `ref`      | Branch or tag to fetch                                                                                    |
| `skills`   | Upstream paths of the skill directories to install                                                        |
| `rewrites` | Optional whole-word replacements applied to the installed copies, e.g. to point at a skill from this repo |

- **Add a skill.** Add its upstream path to `skills`, or add an entry for another repo, then run `./setup.sh`.
  - Also add any skill the new one calls through the Skill tool.
- **Update.** Every run fetches the latest commit of `ref`; there is no pinning.
  - Before the confirmation prompt, the script prints the upstream commit and the files that differ from the deployed copies.
- **Remove a skill.** Delete it from `skills` and run `./setup.sh`; the orphan report then lists the deployed copy, which you delete by hand.
- **Reload.** A running session picks up the change after `/reload-plugins` or a restart.

| Situation                                          | Result                                                                                        |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Fetch fails, or `git`, `jq` or `perl` is missing   | The rest of the config is deployed; third-party skills already in `~/.claude/` are left alone |
| Manifest is invalid, e.g. a clashing `plugin` name | The run stops before writing anything                                                         |
| A rewrite's `from` matches nothing                 | A warning is printed, usually because upstream changed its wording                            |

## Changes Made on the Machine

`/config`, `/effort` and similar commands write to the deployed `~/.claude/settings.json`, not to this repo. The next deploy overwrites them, so copy any such change back into `.claude/settings.json` here. The diff that `setup.sh` prints shows what would be lost.

## Write Protection

The `block-deployed-config-writes.sh` hook stops Claude from editing the deployed copies under `~/.claude/` and names the file in this repo to edit instead; for a third-party skill that file is `third-party-skills.json`. It finds this repo through the `CLAUDE_CONFIG_REPO` environment variable, which defaults to `$HOME/Documents/code/claude-config`; set it if the repo is cloned somewhere else.
