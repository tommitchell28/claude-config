---
name: crafting-skills
description: >-
  Guides creation and review of Claude Code skills (SKILL.md packages).
  Use when user asks to "create a skill", "build a skill", "write a skill",
  "review a skill", "improve a skill", "check my skill", "audit a skill",
  "design a skill", or works with SKILL.md files. Handles requirements
  interview, drafting, quality review via sub-agent, and iterative refinement.
---

# Crafting Skills

This skill guides the full lifecycle of creating or reviewing a Claude Code skill.
It follows a write-then-review workflow with genuine separation between drafting
and quality review.

## Mode Detection

Determine which mode to use based on user input and `$ARGUMENTS`:

**Review Mode** -- if any of these are true:

- `$ARGUMENTS` contains a file path to an existing SKILL.md
- User says "review", "improve", "check", "audit", or "fix"
- User references an existing skill by name

If Review Mode, skip to the **Review Mode** section below.

**Create Mode** -- if any of these are true:

- User says "create", "build", "new", "write", or "make"
- No existing skill is referenced

If Create Mode, continue to **Requirements Interview** below.

If ambiguous, ask: "Would you like to create a new skill or review an existing one?"

---

## Create Mode

### Step 1: Requirements Interview

CRITICAL: Do NOT draft anything until requirements are fully understood.

Ask the user all of these questions in a single numbered list:

1. **Purpose**: What problem does this skill solve? What should it help the user do?
2. **Use cases**: Give me 2-3 concrete examples of when someone would use this skill. What would they type or say to trigger it?
3. **Category**: Which best describes this skill?
   - Document & Asset Creation (generating documents, code, designs)
   - Workflow Automation (multi-step processes, coordination)
   - MCP Enhancement (workflow guidance for an MCP server)
4. **Tools needed**: Does it need specific tools? (MCP servers, scripts, built-in tools like Bash/Read/Grep)
5. **Freedom level**: Should instructions be prescriptive (exact steps, low flexibility) or flexible (general guidance, Claude adapts to context)?
6. **Supporting files**: Will it need reference files, scripts, templates, or assets beyond the main SKILL.md?

After receiving answers:

- Summarize your understanding back to the user in 3-4 sentences
- Ask: "Does this capture what you need, or should I adjust anything?"
- If anything is unclear, ask follow-up questions. Do not assume.
- Only proceed to drafting once the user confirms

### Step 2: Drafting

#### Step 2a: Draft the Frontmatter

Read [references/description-guide.md](references/description-guide.md) for the description formula and examples.

Draft the YAML frontmatter:

```yaml
---
name: <skill-name>
description: <description>
---
```

**Name rules:**

- Kebab-case only (lowercase letters, numbers, hyphens)
- Max 64 characters
- Must NOT contain "claude" or "anthropic" (reserved)
- Should match the folder name
- Prefer gerund form (e.g., `processing-pdfs`, `analyzing-spreadsheets`)

**Description rules:**

- Follow the formula: [What it does] + [When to use it] + [Key capabilities]
- Include specific trigger phrases users would actually say
- Write in third person
- Under 1024 characters
- No XML angle brackets

**Optional frontmatter fields** -- add only if needed:

- `disable-model-invocation: true` -- for skills the user should trigger manually (deploys, sends, destructive actions)
- `user-invocable: false` -- for background knowledge Claude should use but users shouldn't invoke directly
- `allowed-tools` -- to restrict which tools Claude can use
- `context: fork` -- to run in a sub-agent
- `agent` -- which sub-agent type to use with `context: fork`
- `model` -- override the model
- `effort` -- override effort level

#### Step 2b: Draft the Instructions Body

Structure the instructions with clear sections:

```markdown
# Skill Name

## Instructions

### Step 1: [First Major Step]

Clear explanation of what happens.

### Step 2: [Second Major Step]

Clear explanation of what happens.

## Examples

### Example 1: [Common scenario]

User says: "..."
Actions:

1. ...
2. ...
   Result: ...

## Common Issues

### [Error or edge case]

Cause: [Why it happens]
Solution: [How to fix it]
```

**Instruction quality rules:**

- Be specific and actionable. Not "validate the data" but "Run `python scripts/validate.py --input {filename}` to check data format"
- Include error handling for likely failure scenarios
- Put critical instructions near the top or under `## Important` headers
- Use consistent terminology throughout
- Only add context Claude does not already know

#### Step 2c: Draft Reference Files (if needed)

Only create reference files if:

- The SKILL.md body would exceed ~300 lines without them
- The content is genuinely reference material (checklists, API docs, lookup tables, many examples)

For each reference file:

- Place in a `references/` subdirectory
- Name descriptively (e.g., `api-patterns.md`, not `doc2.md`)
- Link from SKILL.md with context: "For rate limiting guidance, see [references/api-patterns.md](references/api-patterns.md)"
- Keep references one level deep (no subdirectories within references/)

#### Step 2d: Present the Draft

Present the complete draft to the user:

1. Show the full SKILL.md content
2. Show each reference file's content
3. Show the planned directory structure:
   ```
   .claude/skills/<skill-name>/
   ├── SKILL.md
   └── references/  (if applicable)
       └── ...
   ```

Then say: "I'll now run a quality review on this draft to check for issues."

Proceed to **Quality Review**.

---

## Review Mode

### Step 1: Read the Existing Skill

1. Read the existing SKILL.md file (from the path provided or by searching for it)
2. List the directory contents to find any reference files
3. Read all reference files

### Step 2: Understand the Problem

Ask the user: "What issues are you experiencing with this skill? Select all that apply, or say 'general review' for a full quality check:"

- Skill doesn't trigger when it should (under-triggering)
- Skill triggers on unrelated queries (over-triggering)
- Claude doesn't follow the instructions correctly
- Inconsistent results across uses
- General quality review

Wait for the user's response. Pass their specific concerns to the Quality Review sub-agent as additional context so it can prioritize those areas in its assessment.

Proceed to **Quality Review**.

---

## Quality Review

This is the core review mechanism. It uses a forked Explore sub-agent to review the skill with fresh context -- genuinely separate "eyes" that haven't seen the drafting reasoning.

### Launch the Review Sub-Agent

Spawn a forked Explore sub-agent with the following instructions:

> You are reviewing a Claude Code skill for quality. Read these files:
>
> 1. The skill being reviewed: [path to the SKILL.md]
> 2. Quality checklist: [path to references/quality-checklist.md in the crafting-skills directory]
> 3. Anti-patterns: [path to references/anti-patterns.md in the crafting-skills directory]
>
> Also read any reference files in the skill's directory.
>
> Evaluate the skill against every item in the quality checklist. For each item, report PASS or FAIL with a one-line explanation.
>
> Then check the anti-patterns file and flag any matches.
>
> Return a structured report:
>
> **Overall Assessment**: Good / Needs Work / Major Issues
>
> **Checklist Results**:
>
> - [item]: PASS/FAIL - [explanation]
> - ...
>
> **Issues Found** (numbered, by severity):
>
> - Critical: [issues that would prevent the skill from working]
> - Warning: [issues that degrade quality or cause problems]
> - Suggestion: [improvements that would enhance the skill]
>
> **Recommended Fixes**:
> For each issue, provide a specific fix (not "improve the description" but the actual improved description text).
>
> **Triggering Assessment**:
>
> - Phrases that WOULD trigger this skill: [list 3-5]
> - Phrases that SHOULD trigger but might NOT: [list any]
> - Phrases that SHOULD NOT trigger but MIGHT: [list any]

### Present the Review Results

After the sub-agent returns:

1. Present findings organized by severity (Critical first, then Warning, then Suggestion)
2. For each Critical or Warning issue, show the recommended fix
3. Ask the user: "Which fixes would you like me to apply?"

---

## Refinement Loop

After the user selects fixes to apply:

1. Apply the accepted fixes to the skill content
2. Present the updated version
3. If there were any Critical issues, re-run the Quality Review on the updated version
4. Cap at 2 total review cycles to avoid infinite loops
5. Once no Critical issues remain (or user explicitly approves), proceed to Finalization

---

## Finalization

1. Present the final version of all files (SKILL.md + any reference files)

2. Create the files on disk:
   - Create the skill directory at `.claude/skills/<skill-name>/`
   - Create `references/` subdirectory if needed
   - Write all files

3. Remind the user to test:
   - **Trigger test**: Ask Claude 2-3 queries that should activate the skill. Verify it loads.
   - **Negative test**: Ask Claude something unrelated. Verify the skill does NOT load.
   - **Functional test**: Actually use the skill for its intended purpose. Does it work correctly?
   - **Iterate**: If triggering is off, adjust the description. If instructions aren't followed, make them more specific or prominent.

4. If the user has a `setup.sh` or similar sync mechanism, remind them to sync:
   - "Run your setup/sync script to deploy the skill to `~/.claude/` if you use one."
