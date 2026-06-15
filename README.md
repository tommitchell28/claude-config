# Claude Config

Source of truth for `~/.claude/` configuration. Tracks settings, plugins config, and custom skills.

## Usage

```bash
./setup.sh
```

Syncs the repo's `.claude/` directory to `~/.claude/` using `rsync -av`, and
merges the repo-root `.mcp.json`'s `mcpServers` into `~/.claude.json` (where
Claude Code reads user-level MCP servers) using `jq`. The existing
`~/.claude.json` is backed up to `~/.claude.json.bak` before it is modified.

To add a user-level MCP server, edit `.mcp.json` in this repo and re-run
`./setup.sh`.
