---
paths:
  - "CLAUDE.md"
  - "**/CLAUDE.md"
---

# CLAUDE.md Instructions

Applies when reading, writing or reviewing any `CLAUDE.md`.

A CLAUDE.md carries **grounding context** — what this is, why it's shaped this way, what to watch for. Not a manual, changelog, or mirror of the file tree.

## Progressive disclosure

- **Root file stays thin** — global context only: what the project is, the world around it, top-level layout, conventions that apply everywhere.
- **Detail goes in per-directory `CLAUDE.md`**, loaded when work happens there.
- **Say it once.** Never restate what a descendant covers — point at it.
- **Guidance tied to file types rather than a directory** (e.g. `**/*.sh`) belongs in a path-scoped rule under `.claude/rules/`, not in the root file.

## No coupling to things that drift

Stale grounding misleads. Leave out anything liable to change independently of the file:

- Script, command, tool names; harness or tool limits
- Skill and rule filenames — discoverable at runtime
- Exact counts, versions, page numbers
- Over-specified filename and directory patterns

**Keep** architecture, decisions, business situation and rationale — the grounding earns its place even when it will eventually date.

## Style

Succinct and information-dense, per `writing-documents`. Tables for parallel data. Bold the thing that matters in a bullet. Instructions concrete enough to verify — "use 2-space indentation", not "format code properly".

Stay under 200 lines: the whole file loads every session, and adherence drops as it grows.

## On edits

Sweep the **whole file** for the above, not just lines you touched, and surface significant cuts in your reply.
