---
name: simplify-response
description: Re-express Claude's previous answer in plain, unjargonated terms on demand. Use when Tom asks to simplify, de-jargon, plain-English, un-fancy, or rephrase the last response — "say that plainly", "too academic, redo it", "cut the jargon", "/simplify-response". Rewrites the prior message; does NOT re-run the work behind it. NOT for shortening a doc file (use writing-documents) or a PR description (use creating-pull-requests).
---

# Simplify response (Tom)

Rewrite Claude's **previous message** in plain words a colleague would use — same content, same structure, jargon and academic register stripped out. This is the on-demand counterpart to the always-on `plain-voice` output style: you reach for it when a specific answer came out too dense.

## What it operates on

The immediately prior assistant message, unless Tom points at a different one. Rewrite the text; do not redo the underlying task, re-run tools, or change any technical claim, number, name, command, or conclusion.

## How to rewrite

1. Keep every point, caveat, example, and piece of technical substance — this is a re-wording, not a cut.
2. If it also needs shortening, say so and apply `writing-documents` density on top.
3. Replace house jargon with the plain alternative in [`references/jargon-banlist.md`](references/jargon-banlist.md) — `load-bearing` → say what it carries, `blast radius` → "what this affects", `bespoke` → "custom", `X lives in Y` → "X is in Y", and so on.
4. Leave a term only when it's genuinely the technical name for the thing.
5. Unstack metaphors and expand anything a fresh reader couldn't define; coin no acronyms.
6. Adopt the `plain-voice` persona: a tired senior engineer answering a colleague — direct, no performance, no throat-clearing.
7. Preserve verbatim: code, identifiers, file paths, commands, URLs, error messages, numbers, units.

## Avoid the rebound trap

Don't quote the old jargon back to explain what you're fixing — restating the bad phrasing at length only reinforces it. Produce the clean rewrite and stop; a one-line note on what changed is enough if anything.

## Output

Return only the rewritten answer, in the same shape (headings, lists, code blocks) as the original. No preamble, no diff of old-vs-new beyond that optional one-liner.
