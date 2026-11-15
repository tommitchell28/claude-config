---
paths:
  - "CLAUDE.md"
  - "**/CLAUDE.md"
  - "**/CLAUDE.local.md"
  - "**/MEMORY.md"
  - "**/.claude/rules/**/*.md"
---

# Claude Memory Guidelines

Anything touching Claude Code's memory system — `CLAUDE.md`, `CLAUDE.local.md`, `.claude/rules/`, auto memory — follows the official reference:

<https://code.claude.com/docs/en/memory.md>

Read it before changing how memory or rules files are structured, scoped or loaded. It's the authority on frontmatter fields, glob semantics, load order and precedence — don't work from assumptions.

See also `claude-md-instructions` for the house style on top of the docs.
