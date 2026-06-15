# Claude Config

Source of truth for `~/.claude/` configuration. Tracks settings, plugins config, and custom skills.

## Usage

```bash
./setup.sh
```

Syncs the repo's `.claude/` directory to `~/.claude/` using `rsync -av`, and
copies the repo-root `.mcp.json` to `~/.mcp.json`.
