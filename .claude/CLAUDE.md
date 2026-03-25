# Rules

## CRITICAL: The `claude-config` repo is the source of truth

**ALL new files (skills, hooks, scripts, config) MUST be created inside the `claude-config` repo, NEVER directly in `~/.claude/`.**

The `~/.claude/` directory is a deployment target -- it is populated by `setup.sh` syncing FROM `claude-config`. Writing files directly to `~/.claude/` means they will be overwritten on the next sync and lost. If you create a file in `~/.claude/` instead of `claude-config`, you have made a mistake. There are no exceptions to this rule.

- New skills go in `.claude/skills/<skill-name>/` in `claude-config`
- New hooks go in `.claude/hooks/` in `claude-config`
- Config changes go in `.claude/` in `claude-config`
- `setup.sh` handles deployment to `~/.claude/`

## Plans

### CRITICAL: Requirements first, implementation second

**Do NOT jump into technical details or implementation plans until requirements are fully understood.**

In plan mode, your first priority is to interview me. Ask questions, probe for ambiguities, and keep asking until you are 100% certain of what I need. Do not move on to designing a solution until every requirement is nailed down and there is nothing left to clarify. If in doubt, ask — do not assume.

This is non-negotiable. A technically perfect plan that solves the wrong problem is worthless.

### Plan content

Plans must be fully self-contained and standalone — assume context will be cleared and someone else may review.

- Include all gathered context, decisions, and rationale in the plan itself
- Don't abbreviate or assume the reader knows the background
