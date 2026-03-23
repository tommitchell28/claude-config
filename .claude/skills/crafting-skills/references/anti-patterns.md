# Anti-Patterns

Common mistakes in skill creation and how to fix them.

## Contents
- [Too Verbose](#too-verbose)
- [Too Many Options](#too-many-options)
- [Missing Error Handling](#missing-error-handling)
- [Vague Instructions](#vague-instructions)
- [XML Tags in Frontmatter](#xml-tags-in-frontmatter)
- [Wrong File Naming](#wrong-file-naming)
- [README.md in Skill Folder](#readmemd-in-skill-folder)
- [Deeply Nested References](#deeply-nested-references)
- [Windows-Style Paths](#windows-style-paths)
- [Buried Critical Instructions](#buried-critical-instructions)
- [No Trigger Phrases in Description](#no-trigger-phrases-in-description)
- [Model Laziness](#model-laziness)

## Too Verbose

**Problem**: Explaining things Claude already knows (what PDFs are, how libraries work).

**Fix**: Only add context Claude does not have natively. Challenge each paragraph: "Does Claude really need this?"

Bad: "PDF (Portable Document Format) files are a common file format that contains text, images..."
Good: "Use pdfplumber for text extraction:" followed by a code snippet.

## Too Many Options

**Problem**: Presenting 5+ approaches without clear decision criteria.

**Fix**: Provide a default approach with an escape hatch for specific situations.

Bad: "You can use pypdf, or pdfplumber, or PyMuPDF, or pdf2image, or..."
Good: "Use pdfplumber for text extraction. For scanned PDFs requiring OCR, use pdf2image with pytesseract instead."

## Missing Error Handling

**Problem**: No guidance on what to do when things fail.

**Fix**: Add "If X fails..." sections for likely failure scenarios.

## Vague Instructions

**Problem**: Instructions that sound reasonable but give no actionable guidance.

Bad: "Validate the data before proceeding."
Good: "Run `python scripts/validate.py --input {filename}` to check data format. Common issues: missing required fields (add them to the CSV), invalid date formats (use YYYY-MM-DD)."

## XML Tags in Frontmatter

**Problem**: Using angle brackets (< >) anywhere in YAML frontmatter.

**Why**: Frontmatter appears in Claude's system prompt. XML tags could cause injection issues.

**Fix**: Remove all angle brackets from name, description, and any other frontmatter fields.

## Wrong File Naming

**Problem**: File not named exactly `SKILL.md` (case-sensitive).

Common mistakes: `SKILL.MD`, `skill.md`, `Skill.md`, `SKILL.markdown`

**Fix**: Must be exactly `SKILL.md`. Verify with `ls -la`.

## README.md in Skill Folder

**Problem**: Adding README.md alongside SKILL.md inside the skill directory.

**Fix**: All documentation goes in SKILL.md or references/. README.md is only for the repo root (for human visitors on GitHub), not inside the skill folder.

## Deeply Nested References

**Problem**: References pointing to references pointing to more files.

Bad: SKILL.md -> advanced.md -> details.md -> "here's the actual information"

**Fix**: All reference files link directly from SKILL.md (one level deep). Claude may only partially read deeply nested files.

## Windows-Style Paths

**Problem**: Using backslashes in file paths.

Bad: `scripts\helper.py`, `reference\guide.md`
Good: `scripts/helper.py`, `reference/guide.md`

**Fix**: Always use forward slashes. They work on all platforms.

## Buried Critical Instructions

**Problem**: Important rules placed at the bottom or in the middle of long text blocks.

**Fix**: Put critical instructions near the top. Use `## Important` or `## Critical` headers. Repeat key rules if needed.

## No Trigger Phrases in Description

**Problem**: Description says what the skill does but not what the user would say to invoke it.

Bad: "Processes documents" -- Claude doesn't know when to activate this.
Good: "Processes PDF legal documents for contract review. Use when user asks to 'review a contract', 'extract clauses', or uploads a PDF for legal analysis."

**Fix**: Always include "Use when user says..." or "Use when user asks to..." phrases.

## Model Laziness

**Problem**: Claude skips validation steps or takes shortcuts.

**Fix**: Add explicit encouragement in a Performance Notes section:

```
## Performance Notes
- Take your time to do this thoroughly
- Quality is more important than speed
- Do not skip validation steps
```
