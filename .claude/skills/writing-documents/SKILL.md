---
name: writing-documents
description: Tom's standard for writing and editing markdown documents — succinct, high information density, no filler or walls of text. Use whenever creating or editing any .md file (CLAUDE.md, plan files, technical docs, READMEs, design docs), or when invoked via /writing-documents. NOT for PR descriptions (use creating-pull-requests) or code comments (use writing-clean-code).
---

# Writing Documents (Tom)

Every markdown doc Tom owns should carry maximum information per word and be scannable at a glance.

## Core Principle

Cut words and walls of text — never useful information.

- If content is useful, keep it: examples, the "why", caveats, orienting context for newcomers all stay.
- "Useful" is judged against the doc's purpose and altitude (see rule 9): detail below that altitude is noise, not substance.
- The enemy is verbosity (too many words for the point) and walls of text (unbroken prose blocks) — not length itself.
- Tighten _how_ something is said and _how_ it's laid out; do not drop _what_ it says to hit brevity.

## Scope

| Surface                                                         | Owner                    |
| --------------------------------------------------------------- | ------------------------ |
| `*.md` files (CLAUDE.md, plans, READMEs, technical/design docs) | **this skill**           |
| PR titles & descriptions                                        | `creating-pull-requests` |
| Code & doc comments                                             | `writing-clean-code`     |

When a project's own `CLAUDE.md` or conventions conflict with these rules, the project wins — note the tension rather than overriding silently.

## Rules

Self-checkable. Apply to everything you write in an in-scope doc.

1. **Delete filler.** Cut or rewrite throat-clearing and padding:
   - Drop: `just`, `simply`, `very`, `really`, `quite`, `basically`, `actually`, `it's worth noting that`, `please note`, `as you can see`, `it should be noted`, `in this section/document we will…`.
   - Drop marketing adjectives: `powerful`, `seamless`, `robust`, `cutting-edge`.
   - Rewrite: `in order to`→`to`, `leverage`/`utilize`→`use`, `facilitate`→`help`/`let`, `a number of`→`several`/a count.
2. **No walls of text.** A paragraph over ~3 sentences becomes a list. Lead with the conclusion, then support it.
   - **Bullets carry the points; prose only introduces.** A section may open with a sentence or two of prose to summarise or orient — but the actual points belong in bullets, not in more prose.
   - **One clause per bullet.** Each bullet makes a single point in one sentence or clause. Several sentences packed into one bullet defeats the scannability that made it a bullet — split them.
   - **Parallel items become sub-bullets.** Options (a) and (b), or several alternatives, each get their own nested bullet under the line that introduces them, never a semicolon-chain in one bullet.
3. **One line per paragraph — never hard-wrap prose.** Write each paragraph, list item, table row and heading as a single unbroken line, however long, and let the reader's viewer wrap it. No manual newlines at 80/100/120 columns. A newline inside a paragraph is a markdown authoring error, not formatting: it defeats soft wrap at the reader's width, and makes every later edit rewrap the whole block, so diffs touch lines that did not change. Applies to new docs and to any hard-wrapped doc you edit — unwrap the paragraphs you touch. Exceptions: fenced code blocks, and the rare deliberate hard break (`\` or two trailing spaces).
4. **Story-lists.** Order list items so each builds on the last — the list reads as a progression, not a random bag.
5. **Tables for reference/comparison.** Parallel or structured data goes in a table, not repeated prose.
6. **Say it once.** Don't restate the heading in the first sentence; don't add a summary that repeats the body.
7. **Keep the substance.** Never drop an example, rationale, caveat, or needed context to shorten — tighten its wording instead.
8. **Plain words over jargon.** Test: could a competent mid-level engineer understand it? Foundational concepts you genuinely can't avoid (OAuth, webhook, mTLS) stay — but otherwise prefer a few plain words over a single jargon term. When an acronym or jargon term is unavoidable, spell it out and gloss it on first use, e.g. "iPaaS (Integration Platform as a Service) — a hosted service that copies data between apps". Avoid house jargon in particular — `load-bearing`, `blast radius`, `bespoke`, `fan out`, `X lives in Y` and the like; the full list with plain alternatives is `references/jargon-banlist.md` in the `simplify-response` skill, and the `plain-voice` output style owns the always-on version of this rule.
9. **Match detail to the doc's purpose (altitude).** Include what serves the doc's job; cut detail below its altitude. A high-level planning doc doesn't need secret var names, `file:line` cites, or exact counts — that's noise there, even though it'd be substance in an implementation note. Ask "what is this doc _for_?" and keep to that grain.
10. **Present the current state, not the doc's history.** A living doc accretes reconciliation notes, corrections, and before/after counts that record how it evolved — cut them; state the fact as it stands now, once, where it belongs.
    - Test: does the phrase describe the subject _as it is now_ (keep) or the _process that produced the doc_ (cut)?
    - Keep confidence caveats about the current fact (`inferred`, `unconfirmed`, `pending confirm`); cut narration of how it got here (`reconciled from the first count of 13`, `the first pass missed X`, `reclassified out`).
    - A redundant "corrections" or "changelog" section goes entirely once its facts are folded in place.
11. **Headings are names, not claims.** Title Case, a short noun phrase (`Verdict`, `Platform Today`, `Open Questions`), never a sentence. The claim the heading would have made becomes the first sentence beneath it.
12. **Inline text explains itself.** No source-tag legends, abbreviation keys, or codes (`SRC`, `TBC`) the reader must look up; say the source or caveat in words where it applies, or link it.
13. **Diagrams carry the mechanism; prose supports.**
    - Where a diagram exists, the text beneath it is a few bullets of what the picture cannot show, not a re-narration.
    - Draw Mermaid diagrams to the `mermaid-diagrams` standard — diagram type, node shapes, subgraph grouping, layout order and syntax.

## On Edits

When editing any in-scope doc, also tighten existing fluff across the whole file, not only your own additions.

- Apply the trims as part of the change.
- Then **surface significant cuts** in your reply as a short list — what was removed or collapsed, and where — so nothing vanishes silently.

Example reply tail:

> Done. Added the Config section. Also trimmed for density:
>
> - removed 2-sentence preamble (§1)
> - cut "Overview" para that restated the title
> - collapsed 3 bullets → 1 table row

## Before / After

- **Filler:**
  - Before: "It's worth noting that this module, which is quite powerful, can be used to simply transform the data in order to prepare it for export."
  - After: "Transforms data for export."
- **Wall of text → story-list:**
  - Before: "First you install the dependencies, and then once that is done you need to configure the environment variables, after which you can finally run the build, and then the tests."
  - After:
    1. Install dependencies.
    2. Set environment variables.
    3. Run the build.
    4. Run the tests.
- **Multi-sentence bullet → one clause each:**
  - Before: "- It caches rendered pages for an hour per region, and editors can purge a page from the admin screen, so no deploy is needed to fix a typo."
  - After:
    - Caches rendered pages for an hour, per region.
    - Editors can purge a page from the admin screen; fixing a typo needs no deploy.
- **Hard-wrapped → one line:**
  - Before (newlines inserted at ~90 columns):

    ```
    Companion to `check-backups.sh`. Everything below was derived from the repo and the
    backup tool's own documentation (`docs/vendor/backup-tool.md`) — the script's job is to confirm
    or refute it against the staging database.
    ```

  - After: that same paragraph on one line.

- **Jargon → plain words (+ defined acronym):**
  - Before: "An embedded iPaaS that runs connectors to normalise SaaS data."
  - After: "An **iPaaS** (Integration Platform as a Service) — a hosted service that connects to a customer's apps and copies their data out on a schedule."
- **Doc history → current state (but keep the confidence caveat):**
  - Before: "12 scheduled jobs — 9 nightly + 3 weekly, reconciled from the first count of 13."
  - After: "12 scheduled jobs — 9 nightly + 3 weekly." — the `reconciled from the first count of 13` is how the number was reached, not what it is now.
  - Still kept: "The invoice export — counted in the 9, pending confirmation that it runs in production." That's the current fact's solidity, not the doc's edit history.

## `/writing-documents [path]`

Run a density pass on a doc on demand.

- With a path: apply the rules above to that file.
- No path: apply them to the markdown doc you just produced or most recently touched.
- Either way, surface significant cuts as above.

## Independent Review

Once you have finished writing or editing an in-scope doc this turn, spawn an independent reviewer before you finish, so a clean context catches what you, focused on content, missed.

1. Spawn the `document-reviewer` agent via the `Agent` tool, passing the doc's absolute path. It reviews read-only against this standard and returns a findings list (location, rule, problem, suggestion) — it never edits the file.
2. Apply each finding in the main context, where the informational context lives. **Reject any suggestion that would lose information** — the reviewer flags verbosity, not substance; you own the content and have final say.
3. Then run the self-check below and surface significant cuts as usual.

Skip the reviewer only for a trivial one-line edit where a full review is disproportionate.

## Self-Check

Re-read the Rules above against your draft — they are written to be checked off directly. On edits, confirm significant cuts are surfaced in your reply.
