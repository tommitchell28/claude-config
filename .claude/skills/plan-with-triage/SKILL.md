---
name: plan-with-triage
description: Triage an input (issue, code-review comments, bug report, free-form request, anything else) and produce a standalone plan-of-action file. Use when the user asks to "triage", "plan this work", "scope this out", or invokes `/plan-with-triage`. The plan describes WHAT to deliver and a HIGH-LEVEL HOW, naming relevant skills/agents rather than concrete commands.
---

# plan-with-triage

Three phases: **triage**, **write the plan**, then **resolve open questions**.

## Phase 1 — Triage

Reach shared understanding of:

- The deliverable
- Scope (in / out)
- Constraints, dependencies, unknowns
- High-level approach

To get there, grill the user relentlessly — resolve each branch of the decision tree one question at a time, using `AskUserQuestion` and leading with your recommended answer. Where a question can be answered by exploring the codebase, do that instead of asking.

## Phase 2 — Write the plan

1. Run `bash "${CLAUDE_SKILL_DIR}/scripts/plan-path.sh" [slug]` from the project root, omitting `[slug]` or replacing it with a short issue number or label.
2. Use the printed path: `.claude/plans/plan-YYYYMMDD-HHMMSS[-slug].md` (UTC), reserved by the script.
3. Fill that file using [`templates/plan.md`](templates/plan.md); keep the same path when updating the plan.

Keep the plan succinct and high information-density: no filler, no walls of text.

For the Approach section, pick relevant skills/agents from this session's available toolkit and reference them by name. Do not invent helpers.

## Phase 3 — Resolve open questions

If the plan has any entries under **Open questions / assumptions**, keep grilling the user on them — one question at a time, via `AskUserQuestion` — and update the plan as each is settled. Repeat until either:

- no open questions/assumptions remain, or
- the user confirms they are happy to leave the remaining ones outstanding.

Only then is the plan done.

## Rules

- **Standalone**: a fresh agent with no prior context must be able to pick it up.
- **High-level how**: name the helper, not the invocation (e.g. "run the affected tests", not `npm test -- foo.test.ts`).
