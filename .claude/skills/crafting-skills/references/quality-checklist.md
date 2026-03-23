# Quality Checklist

Use this checklist to evaluate a skill. For each item, assess PASS or FAIL.

## Structure

- [ ] Folder named in kebab-case (no spaces, underscores, or capitals)
- [ ] File is exactly `SKILL.md` (case-sensitive -- not SKILL.MD, skill.md, etc.)
- [ ] YAML frontmatter has opening and closing `---` delimiters
- [ ] No `README.md` inside the skill folder (all docs go in SKILL.md or references/)
- [ ] Reference files are one level deep (no `references/subfolder/file.md`)

## Frontmatter

- [ ] `name` field present
- [ ] `name` is kebab-case only (lowercase letters, numbers, hyphens)
- [ ] `name` is max 64 characters
- [ ] `name` does not contain "claude" or "anthropic" (reserved)
- [ ] `name` matches the folder name
- [ ] `description` field present and non-empty
- [ ] `description` is under 1024 characters
- [ ] `description` includes WHAT the skill does
- [ ] `description` includes WHEN to use it (trigger conditions)
- [ ] `description` includes specific trigger phrases users would actually say
- [ ] `description` is written in third person (not "I can help you" or "You can use this")
- [ ] No XML angle brackets (< >) anywhere in frontmatter
- [ ] Optional fields (`context`, `agent`, `allowed-tools`, `model`, `effort`) used correctly if present

## Instructions

- [ ] Instructions are specific and actionable (not "validate the data" but "Run `python scripts/validate.py --input {filename}`")
- [ ] Error handling included for likely failure scenarios
- [ ] Examples provided for common use cases
- [ ] References to bundled files use correct relative paths (forward slashes only)
- [ ] Total SKILL.md is under 500 lines (including frontmatter)
- [ ] Critical instructions placed near the top or under ## Important / ## Critical headers
- [ ] No ambiguous language ("make sure things work properly" vs specific checks)
- [ ] Consistent terminology throughout (pick one term, use it everywhere)

## Progressive Disclosure

- [ ] SKILL.md is focused on workflow and core instructions
- [ ] Detailed reference material (lookup tables, long examples, API docs) moved to separate files
- [ ] Reference files are clearly linked from SKILL.md with context on what they contain and when to read them
- [ ] Each reference file has a table of contents if over 100 lines

## Triggering Quality

- [ ] Description would trigger on obvious, direct requests
- [ ] Description would trigger on paraphrased/indirect requests
- [ ] Description would NOT trigger on unrelated topics
- [ ] If scope is narrow, description includes negative triggers ("Do NOT use for...")
