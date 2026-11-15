<!--
Report template. Written to RUN_DIR/review/report.md (the REPORT path from report-paths.sh). Fill every <placeholder>; delete sections marked optional when they don't apply. Findings are numbered CONTINUOUSLY across severity sections, starting at 1 in the highest-severity section that has any — e.g. 2 BLOCKER (1,2), 0 CRITICAL (omitted), 3 NORMAL (3,4,5). Omit any severity section with no findings.
-->

# Code Review Report

|                   |                                                                 |
| ----------------- | --------------------------------------------------------------- |
| Generated         | `<ISO 8601 timestamp>`                                          |
| Branch            | `<branch name>`                                                 |
| Review target     | `<MODE from get-changes.sh>` — `<merge-base or HEAD short SHA>` |
| Requirements      | `<authoritative \| inferred \| none>`                           |
| Standards applied | `<skills/standards the lenses discovered and applied>`          |
| Lenses            | `<comma-separated lenses run>`                                  |
| Tier              | `<lite \| standard \| deep>`                                    |
| Verification      | `<on \| skipped (lite) \| skipped (no-verify)>`                 |

## Summary

| Metric         | Count |
| -------------- | ----- |
| Files reviewed | X     |
| BLOCKER        | X     |
| CRITICAL       | X     |
| NORMAL         | X     |

<!--
COVERAGE — include only when something went unexamined; omit the block entirely when coverage
was complete. Name each required lens the user dropped (with the concrete cost) and any changed
file no lens examined. This is the honest "what this review did NOT look at" line.
-->

> **Coverage:** `<e.g. test-quality not run — 3 new source files landed untested; src/legacy/foo.ts changed but not individually examined by any lens.>`

<!-- OPTIONAL — include only when Step 3 appended a Requirements context (a pull request, a linked issue, or both). Drop the row that does not apply. -->

## Requirements context

|              |                                   |
| ------------ | --------------------------------- |
| Pull request | [#<N> <PR title>](<PR URL>)       |
| Issue        | [#<N> <issue title>](<issue URL>) |

**Requirements alignment:** `<one paragraph: do the changes satisfy what the pull request and issue ask for? flag anything unrelated to them, or a stated requirement that appears unmet.>`

---

## Findings

<!-- Group by severity, highest first. Omit a section with no findings. Each finding: -->

<!--
Each finding leads with one plain-language Context line, then terse bullets. The header
folds in file:LINE, lens, and confidence. Context is one plain sentence — what the code does and
why the issue bites — so a reader who doesn't know the code can judge the finding without
reverse-engineering it. Issue and Fix stay terse: bullet lists, one idea per bullet, consequence
folded into an Issue bullet. A finding raised by two lenses lists both after the first `·` (e.g.
`· correctness, test-quality`). The trailing `· <confidence>` is the lens's own high/medium/low,
corrected down by the verify pass if overstated — it lets the author triage a wall of findings
(chase the high-confidence ones first).
-->

### BLOCKER

#### 1. `path/to/file:XX` · `<correctness \| clean-code \| security \| contracts \| requirements-alignment \| test-quality \| design>` · `<high \| medium \| low>`

**Context:** `<one plain sentence: what this code does and why the issue matters>`

**Issue:**

- `<what's wrong>`
- `<consequence, concretely>`

**Fix:**

- `<specific, actionable fix>`

---

### CRITICAL

#### 2. `path/to/file:XX-YY` · `<lens>` · `<confidence>`

**Context:** `<one plain sentence>`

**Issue:**

- `<…>`
- `<…>`

**Fix:**

- `<…>`

---

### NORMAL

<!--
For a finding that rests on an INFERRED requirement, keep the fence visible: cap at NORMAL,
say so in a bullet, and frame it as a question. Example body:

**Context:** `<what the code does and why the inferred contract might matter>`

**Issue:**

- (inferred requirement) Should `foo` also handle the empty-list case?
- Inferred from the sibling handlers in `bar.ts`, which all guard it; no AC or test pins it down.

**Fix:**

- Confirm the intended contract; if empty is valid input, add the guard and a test.
-->

#### 3. `path/to/file:XX` · `<lens>` · `<confidence>`

**Context:** `<one plain sentence>`

**Issue:**

- `<…>`
- `<…>`

**Fix:**

- `<…>`

---

## Files reviewed

<!--
Built from the union of every lens's EXAMINED list — real coverage, not assumed. "Examined by"
names the lenses that actually scrutinised the file. A changed file no lens examined is called out
explicitly ("(not examined)"), never implied as reviewed. Deleted files are skipped by design.
-->

| File           | Change   | Examined by             | Issues |
| -------------- | -------- | ----------------------- | ------ |
| `path/to/file` | modified | correctness, clean-code | 2      |
| `path/to/new`  | added    | correctness, security   | 0      |
| `path/to/miss` | modified | **(not examined)**      | 0      |
| `path/to/gone` | deleted  | (skipped — deleted)     | 0      |

<!--
NO-ISSUES VARIANT — replace the Findings section with this when nothing survived verification:

## No issues found

No issues found. The change meets every applicable standard and requirement reviewed.

**Files reviewed:** X · **Lenses:** `<list>` · **Standards:** `<list>`
-->
