---
name: technology-investigation
description: >-
  Investigate whether a technology fits a need and report the finding grounded in evidence, never memory. Use whenever the ask is to investigate, evaluate, assess, or compare whether some technology, library, service, API, or approach is suitable for a purpose — "is X a good fit for Y?", "can X do Z?", "X vs Y for our case", "should we use X" — even when the word "investigate" is never said. Composable: other skills and plans can name this to get a source-tagged, verdict-first finding. NOT for implementing a technology already chosen, or for answering from a docs-index skill that already owns the subject (defer to that skill for the facts, use this for the method).
---

# Technology investigation

A confident answer from memory is the failure mode. Technologies move — versions rename features, change limits, deprecate APIs — so a remembered claim is a claim that may already be false, delivered with false authority. This skill is a **method**, not a body of facts: it says how to find the truth, tag it to its source, and report the fit verdict tightly enough to act on.

## Ground every claim in truth

Before making any claim about what a technology does, check it against a live source:

- **Live official docs** — fetch the current page and read what it says. Not what you recall it said. Default to the latest unversioned docs; target a version only if the user names one.
- **Real code / config** — if the question is "does it fit _our_ setup", verify against the actual repo files, not an assumed shape. Read the config, the schema, the call site.

**Source-tag or don't claim it.** Every factual statement carries its evidence, or it does not get made:

- Doc/web facts → an inline linked ref `[[1]](https://…)` pointing to a numbered **Sources** list at the end.
- Code/config facts → `code:path/to/file.ext:line` inline.
- If you cannot source it, it goes in **Unknowns**, not in the verdict.

If a fetch fails or lands on the wrong page, say so and stop — ask for a working URL rather than filling the gap from memory.

## Report shape

Caveman-succinct: key info only, verdict first, no preamble, no throat-clearing, no closing summary that repeats the body. State the output rules inline (below) so this holds even when composed into another skill. For fuller prose-density guidance see `writing-documents`.

Structure the finding as:

1. **Verdict** — one line, up front. Fits / doesn't fit / fits with caveats. Say which.
2. **Why** — the few reasons that decide it, each source-tagged. Cut anything that doesn't change the decision.
3. **Unknowns** — what you could not verify, and what evidence would settle it. Never guess to fill this in; an explicit "unknown" is a valid, useful result. If evidence is thin, the verdict says so rather than overreaching.
4. **Sources** — numbered list of the links the inline `[[n]]` refs point to.

## Comparison matrix (optional)

When the ask compares alternatives, a criteria × options table reads faster than prose. Use it only then — a single-subject probe doesn't need one.

| Criterion      | Option A | Option B |
| -------------- | -------- | -------- |
| Meets need X   | ✅       | 🟡       |
| Fits our stack | ✅       | ❌       |
| Within limits  | 🟡       | ✅       |

`✅` yes / `🟡` partial or with caveats / `❌` no. Keep criteria to the ones that actually decide it; still source-tag the claims behind each glyph.

## Composing this in

Another skill or plan can name this skill to get a finding in the shape above — e.g. "investigate candidate X using `technology-investigation`". When invoked that way, produce the verdict-first, source-tagged finding and return it; don't restate the method to the caller.
