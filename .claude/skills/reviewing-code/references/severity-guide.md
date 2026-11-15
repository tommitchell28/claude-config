# Severity Guide

How every lens classifies a finding — three tiers, one bar each. When a finding could sit in two tiers, take the higher only if its failure is real and reachable; otherwise the lower.

Each finding leads with one plain-language **`CONTEXT`** line — what the code does and why the issue bites — for a reader who doesn't know the code. That one field is plain English; `ISSUE` and `SUGGESTION` stay terse. Severity is unaffected by the wording.

## BLOCKER — must fix before merge

The change is unsafe to ship as-is.

- **Security**
  - Injection (SQL/command/path), XSS, CSRF, SSRF.
  - Hardcoded credentials or secrets.
  - Missing authentication or authorisation.
  - Missing object/field permission checks.
  - Sensitive data in logs or responses.
- **Data loss / corruption**
  - A destructive operation without a guard.
  - A missing rollback on failure.
  - A race that can corrupt state.
  - A cascade delete without a safeguard.
- **Breaking change**
  - Removing or renaming a public/exported API without deprecation.
  - An incompatible signature or serialised-shape change.
  - Breaking an existing integration or contract.
- **Certain failure**
  - A bug wrong in every case.
  - An infinite loop or deadlock.
  - A resource limit the code will always hit.
- **Boundary break** — a boundary broken in a way that breaks or precludes a real consumer.
  - A lower, more general layer importing an upper, more specific layer's types (dependency direction inverted).
  - A shared service/data layer reshaped around one caller's use case, so another existing caller breaks or can no longer use it.

## CRITICAL — should fix

Wrong or fragile, but not an immediate ship-stopper.

- **Bug**
  - A logic error in some cases.
  - An off-by-one.
  - An unhandled null where one can occur.
  - Exception handling that swallows the error.
- **Standards violation with teeth** — breaks a rule the repo actually enforces (see _Applicable standards_ under the review-context file's Discovery section) in a way that bites, not cosmetics.
- **Missing error handling**
  - No handling for an expected failure.
  - An unvalidated required input.
  - A silent failure that hides a problem.
- **Performance**
  - An N+1 or a query/IO call in a loop.
  - Unbounded growth.
  - A missing filter on a large dataset, where scale makes it real.
- **Boundary leak** — a caller's specific context encoded into a lower, more general layer (a caller-named parameter, an entrypoint's use case in a data method), coupling that layer to one caller. CRITICAL when a plausible near-term consumer would be blocked or burdened by it; drop to NORMAL when no realistic second consumer would care.
- **Test coverage** — tests are the behavioural spec; judge them for happy path, unhappy/error path, and edge cases.
  - New production code with no happy-path test, or a changed behaviour whose test wasn't updated, is CRITICAL.
  - A new source file with no test for its main path is CRITICAL, not NORMAL.
  - A missing _low-value_ test is not a finding — don't demand exhaustive coverage.

## NORMAL — worth raising

Correct and safe, but the next reader pays for it.

- **Naming & clarity**
  - A name that misleads or forces a lookup.
  - A magic literal.
  - A bare boolean/positional argument.
  - A double-negative condition.
- **Structure**
  - A function doing several things.
  - A misplaced responsibility.
  - Duplication that will drift.
  - Dead or unused code.
  - A needless dependency.
  - A concern placed one layer lower than it belongs, or a caller-flavoured name in a shared layer, where no current or near-term consumer is harmed.
- **Comments & docs** — default to zero comments; prefer clearer names and structure. Flag:
  - A comment that restates what the code already says.
  - A point-in-time note ("not yet used") that goes stale with the next change.
  - A spec-key reference ("FR2 …", "SC-005:") that goes stale and forces a lookup.
  - A comment far longer than the point needs.
  - Narration of the _how_, a docblock on a private method, or commented-out code.
- **Testing gaps** — an uncovered edge case or error path.
  - A missing edge-case test signals the edge wasn't considered — raise it as a question.
  - An assertion weaker than the data allows, a test that asserts nothing, or redundant low-value test bloat.

## Decision order

1. Data loss or security breach? → **BLOCKER**
2. Breaks an existing contract, inverts a layer boundary a real consumer depends on, or always fails? → **BLOCKER**
3. Wrong in some case, violates an enforced standard with real consequence, or leaks a caller's context into a layer a near-term consumer needs clean? → **CRITICAL**
4. Slower or more fragile at scale? → **CRITICAL**
5. Style, clarity, a misplaced concern, or a minor gap? → **NORMAL**
6. None of these? → **don't report it.**

Report only real, reachable problems with a concrete fix. A hypothetical that can't occur, an intentional deletion, or working code that meets every applicable standard is not a finding.

## The inferred-requirement fence

Requirements come in two kinds (_Requirements_ under the review-context file's Discovery section labels each):

- **Authoritative** — a requirement stated in the linked issue or the pull request description, a linked spec, the tests added in this change, a commit message. Review hard against these; a genuine violation carries its natural severity, up to BLOCKER.
- **Inferred** — a requirement the discovery step _guessed_ from surrounding code or convention because authoritative sources were thin.

A finding whose only basis is an **inferred** requirement is **fenced**:

- **Cap it at NORMAL** — never a standalone BLOCKER or CRITICAL.
- **Label it** — state that it rests on an inferred requirement and name what the inference came from.
- **Frame it as a question** — "Was X intended? If so, …"; the author, not the reviewer, holds the real requirement.

If the same issue also breaks an authoritative source or a real correctness/security rule, drop the fence and report it at its true severity on _that_ basis — the fence only governs findings that rest on an inference alone.
