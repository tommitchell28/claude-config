<!--
Audit template. Written alongside the report at RUN_DIR/review/audit.md (the AUDIT path from report-paths.sh). This is the reproducibility record: what ran, what each step decided, what was inferred vs given, and which findings survived verification. Fill every <placeholder>; keep it terse.
-->

# Code Review Audit Trail

|              |                                                                         |
| ------------ | ----------------------------------------------------------------------- |
| Generated    | `<ISO 8601 timestamp>`                                                  |
| Branch       | `<branch name>`                                                         |
| Context file | `<path to the review-context file — the exact snapshot every lens saw>` |
| Report       | `<path to the report>`                                                  |

## Run configuration

| Field          | Value                                                                              |
| -------------- | ---------------------------------------------------------------------------------- |
| Tier           | `<lite \| standard \| deep>`                                                       |
| Verify         | `<on \| off (lite) \| off (no-verify)>`                                            |
| Unattended     | `<no \| yes — both confirmation stops skipped; nobody confirmed target or lenses>` |
| Agents         | `<lite: 2 bundles \| standard/deep: 1 per lens; N total>`                          |
| Per-agent read | `<lenses: header shard + all file shards; verifiers: header shard + 1 file shard>` |
| Shard dir      | `<SHARD_DIR path; N per-file shards>`                                              |

## Execution summary

| Step                 | Status                | Details                                                                                                                                                         |
| -------------------- | --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Resolve paths        | `<PASS/FAIL>`         | `<report-paths.sh output>`                                                                                                                                      |
| Resolve changes      | `<PASS/FAIL>`         | `<mode; N files>`                                                                                                                                               |
| Target gate          | `<PASS>`              | `<proceeded as detected \| base changed \| range \| PR/issue corrected/skipped \| unattended: accepted without asking — mode, base, PR, issue; files excluded>` |
| Requirements context | `<PASS/SKIP/FAIL>`    | `<PR and issue numbers, or reason for skip>`                                                                                                                    |
| Discovery            | `<PASS/FAIL>`         | `<N standards found; requirements: given/inferred>`                                                                                                             |
| Lens confirmation    | `<PASS>`              | `<lenses confirmed; any REQUIRED lens dropped \| unattended: lenses run without asking>`                                                                        |
| Shard + launch       | `<PASS/PARTIAL/FAIL>` | `<N shards; M agents ran; any that errored>`                                                                                                                    |
| Verification         | `<PASS/SKIP>`         | `<N in → M upheld (+ deep second-opinion); or reason skipped>`                                                                                                  |
| Report + audit       | `<PASS/FAIL>`         | `<report path>`                                                                                                                                                 |

## Review target

| Field              | Value                        |
| ------------------ | ---------------------------- |
| Mode               | `<MODE from get-changes.sh>` |
| Base branch        | `<base or (none)>`           |
| Merge base         | `<SHA or n/a>`               |
| HEAD               | `<SHA>`                      |
| Working tree dirty | `<yes/no>`                   |

## Discovery result

**Applicable standards found:** `<list each authority discovered and its source path — e.g. CLAUDE.md, a constitution, linter config>`

**Skills applied:** `<the skills each lens actually discovered and loaded — recorded, not prescribed>`

**Requirements:**

- Authoritative: `<list, each with its source: issue / tests added / commit / PR description / spec>`
- Inferred (fenced): `<list, each with what it was inferred from — or "none">`

## Lenses run

| Lens     | Findings raised |
| -------- | --------------- |
| `<lens>` | `<count>`       |

## Verification outcomes

<!-- One row per finding that entered verification. Omit this whole section if verify was skipped
(lite, or no-verify). For deep, note a second-opinion result in the Reason (e.g. "upheld twice"). -->

| Finding         | Lens     | Verdict              | Reason                                   |
| --------------- | -------- | -------------------- | ---------------------------------------- |
| `<short label>` | `<lens>` | `<UPHELD / DROPPED>` | `<why the skeptic upheld or refuted it>` |

## Files processed

<!-- "Examined by" is the real EXAMINED-list union: which lenses actually scrutinised the file.
A changed file no lens examined is recorded as `not examined` — the coverage gap, made visible. -->

| File           | Change | Examined by             | Findings |
| -------------- | ------ | ----------------------- | -------- |
| `path/to/file` | M      | correctness, clean-code | 2        |
| `path/to/miss` | M      | `not examined`          | 0        |
| `path/to/gone` | D      | `skipped (deleted)`     | 0        |

## Warnings and errors

<!-- List anything degraded: a REQUIRED lens the user dropped (with the cost), a changed file no
lens examined, an unattended run on a local-ref base (may be stale), the pull request or issue unreachable, a lens agent that errored, a standard skill not available, scratch
files excluded, an untracked file skipped. "None." if clean. -->

| Type              | Context  | Message     |
| ----------------- | -------- | ----------- |
| `<WARNING/ERROR>` | `<step>` | `<message>` |

## Timing

| Phase               | Duration |
| ------------------- | -------- |
| Resolve + discovery | ~Xs      |
| Lens run            | ~Xs      |
| Verification        | ~Xs      |
| Aggregate + write   | ~Xs      |
| **Total**           | ~Xs      |
