# Rules

## CRITICAL: The `claude-config` repo is the source of truth

**ALL new files (skills, hooks, rules, output styles, agents, scripts, config) MUST be created inside the `claude-config` repo, NEVER directly in `~/.claude/`.**

The `~/.claude/` directory is a deployment target -- it is populated by `setup.sh` syncing FROM `claude-config`. Writing files directly to `~/.claude/` means they will be overwritten on the next sync and lost. If you create a file in `~/.claude/` instead of `claude-config`, you have made a mistake. There are no exceptions to this rule.

- New skills go in `.claude/skills/<skill-name>/` in `claude-config`
- New hooks go in `.claude/hooks/` in `claude-config`
- New rules go in `.claude/rules/` in `claude-config`
- New output styles go in `.claude/output-styles/` in `claude-config`
- New agents go in `.claude/agents/` in `claude-config`
- Config changes go in `.claude/` in `claude-config`
- `setup.sh` handles deployment to `~/.claude/`

## CRITICAL: Small atomic commits as you go

**Do NOT batch all changes into a single commit at the end of a task. Commit early and commit often.**

- Make small, focused commits after each logical unit of work (e.g., a single file change, a single feature addition, a bug fix, a refactor step)
- Each commit must represent one coherent change — not a mix of unrelated modifications
- Commit immediately after completing each step, not at the end of the task
- Never accumulate uncommitted work across multiple steps
- Use **conventional commit** format for all commit messages: `type(scope): description`
  - Types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `build`, `ci`, `perf`
  - Scope is optional but encouraged (e.g., `feat(auth): add login endpoint`)
  - Description must be lowercase, imperative mood, no period at the end

This is non-negotiable. Large "dump everything" commits are unacceptable.

## Response Verbosity

Be concise: lead with the answer, cut preamble and filler, keep it scannable.

Length is a cost, not evidence of effort.

- Deliverables (docs, reports, plans):
  - Match length to the task.
  - Omit filler sections, closing summaries that repeat the body, and headings for show.
  - Defer to `writing-documents` for Markdown density.
- Narration:
  - Use one sentence before the first tool call.
  - Give a short update when you find something important, change direction, or have been working a while without saying anything — not after every tool call.
  - Lead the closing message with the outcome, then only what changes the reader's next move.

## Skill Announcement

Announce which `.claude/skills/` skill(s) you're using — brief inline mention at the start of the response. Skip when no specific skill applies.

## Code Review

Every code review goes through the `reviewing-code` skill. Do not use the built-in `/code-review` unless Tom asks for it by name.

## Delegation

For the main session only. A subagent does its own task itself.

- On long work with several parts, keep the main session's context for decisions: subagents read, build and check, and report back briefly.
- Before delegating building or verification to a subagent, load the `delegating-work` skill.
- When a tracked issue spans several areas and would not fit one context, suggest `/orchestrate-ticket <issue>` in one sentence, then carry on as asked. Only Tom starts it.

## Plans

### CRITICAL: Requirements first, implementation second

**Do NOT jump into technical details or implementation plans until requirements are fully understood.**

In plan mode, your first priority is to interview me. Ask questions, probe for ambiguities, and keep asking until you are 100% certain of what I need. Do not move on to designing a solution until every requirement is nailed down and there is nothing left to clarify. If in doubt, ask — do not assume.

This is non-negotiable. A technically perfect plan that solves the wrong problem is worthless.

### Planning workflow

- In plan mode, follow the `plan-with-triage` skill — it owns the questioning standard and the plan-file format.
- When a change spans layers (entrypoint → service → data), or the question is where a piece of logic belongs, consult the `architecture-design` skill.

### Plan content

Plans must be fully self-contained and standalone — assume context will be cleared and someone else may review.

- Include all gathered context, decisions, and rationale in the plan itself
- Don't abbreviate or assume the reader knows the background
