# Jargon ban-list

The words Claude reaches for when a plain one would do. The **canonical data lives in `jargon-banlist.json`** — this file is the human-readable companion; edit the JSON, not a copy here.

Every voice surface points at that data: the `plain-voice` output style and `writing-documents` rule 8 carry a short curated subset; the `check-jargon` hook reads `autoMatched[].pattern` from the JSON and greps it against prose it has just written.

## Why these are banned

The complaint isn't that the words are made-up — `footgun`, `idempotent`, `circuit breaker` are real industry terms that predate the models. It's **overuse and performativity**: reaching for the clever term when a plain one carries the same meaning, and coining undefined concepts. Judgement still applies — a term genuinely used for its real technical meaning (an actual electrical `circuit breaker`, the `Gate` class in the code) is fine.

## Shape of the data

`jargon-banlist.json` has two lists:

- **`autoMatched`** — `{ avoid, prefer, pattern }` entries. `pattern` is a case-insensitive extended-regex the hook greps for; keep it tight to avoid false hits. These are the terms flagged automatically.
- **`judgementCalls`** — `{ term, note }` entries too context-dependent to grep without firing on legitimate use (e.g. `spine`/`seams`/`gate`, invented acronyms, undefined concepts). The hook leaves them alone; the same rule applies when writing.

Add a term by adding an entry to the right list in the JSON — every surface picks it up from there.
