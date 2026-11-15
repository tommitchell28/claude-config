---
name: writing-clean-code
description: >-
  Clean code standards (based on Robert C. Martin's Clean Code) together with
  Tom's personal coding and code-review standards, distilled from his own
  pull-request review comments. Automatically applied when Claude writes new
  code, modifies existing code, reviews code quality, critiques a diff, or
  prepares changes for review -- no user invocation needed. Covers naming,
  functions, comments, formatting, structure, error handling, classes, testing,
  and code smells, so that code and review feedback match the standards Tom
  holds others to.
user-invocable: false
---

# Writing Clean Code

The rules to follow when writing or reviewing any code. Two sources, merged:

- Robert C. Martin's "Clean Code: A Handbook of Agile Software Craftsmanship"
- Tom's own review standards, each recorded as **Standard / Why / Example** (see [Tom's Review Standards](#toms-review-standards))

## Important

- These rules apply to all code written or reviewed
- Project conventions (`CLAUDE.md`, linters, existing code) win on conflict -- note the tension rather than overriding silently
- Raise each point by leading with the why, not the rule
- No recorded standard for an area? Fall back to general good practice; never invent a "Tom standard"
- Code should be written as if maintained by someone else, because it will be
- Readability comes first: code is read far more often than it is written

## Core Principles

### Naming

- Use intention-revealing names -- the name alone should explain purpose
- Avoid disinformation, mental mapping, and encodings (no Hungarian notation, no `I` prefix on interfaces)
- Use pronounceable, searchable names; only universally understood abbreviations
- Plural nouns for collections (`activeUsers`), singular for one item (`activeUser`), `SingularNounByKey` for lookup maps (`userById`)
- Avoid generic names (`data`, `item`, `temp`) -- add the context that says which one (`sourceAccount`, `targetAccount`)
- Prefix booleans with `is`, `has`, `can`, or `should` -- avoid negatives (`isReady = false` not `isNotReady = true`)
- Classes: noun or noun phrase. Functions: verb or verb phrase
- Constants: ALL_UPPERCASE_WITH_UNDERSCORES
- Use solution domain names (technical terms) and problem domain names (business terms) appropriately
- Match the naming convention already established in the module

For detailed naming rules and examples, see [references/naming.md](references/naming.md).

### Functions

- Keep functions small -- each does one thing well
- Minimize arguments (0 is best, never more than 3). Use objects to group related args
- No boolean arguments -- split into two functions instead
- When the callee is not yours to split, bind the literal to a named local so the call documents itself (`const hasMoreResults = false; mockSearch(resources, hasMoreResults);`)
- No side effects -- function name must describe everything it does
- Don't mutate input arguments (no output arguments)
- Command Query Separation: functions either DO something or ANSWER something, not both
- Extract try-catch block bodies into separate functions

For detailed function rules and examples, see [references/functions.md](references/functions.md).

### Comments

- Default: don't write comments. Code should be self-explanatory
- Before adding any comment, apply the test: would a competent engineer reading this code be surprised, or make a wrong change, without it? If not, delete it and improve the code
- Comments that pass: legal notices a project requires, a genuine why (a tradeoff, workaround, or constraint someone might otherwise undo), clarification of obscure APIs, warnings, TODOs with an issue reference (`// TODO(#123): ...`), docblocks on public APIs
- Comments to delete: narration, section headers, docblocks on private methods, a "why" that is really a "what", comments inherited by cloning a file, misleading comments, commented-out code, journal and noise comments
- Doc comments state the what and why, never the how

For detailed comment guidance, see [references/comments.md](references/comments.md).

### Formatting

- Use blank lines to separate different concepts (imports, property groups, methods)
- Keep related concepts vertically close together
- Variable declarations near their usage
- Caller functions above callee functions
- Group conceptually related code together

### Structure

- Define a shared shape, constant, or contract once and reference it
- When one line needs a fix, apply the same fix everywhere it is relevant in the change
- Put code in the module that owns it, where its location shows its role
- Don't land unused code
- Label workarounds as temporary and name the real fix

For the full standards, see [references/structure.md](references/structure.md).

### Error Handling

- Use exceptions, not error codes
- Start with try-catch-finally blocks
- Add context to exceptions -- include the intent of the failed operation
- Fail fast: validate early and throw with a clear message; don't wrap conditions that should never occur in defensive code
- Handle errors at the level that has the context to act; let them propagate until then
- Decide and document the not-found contract. Absent must be distinguishable from empty. Returning `null` for a missing record is acceptable when that is the documented contract; do not return `null` where an empty collection is the right answer
- Use the Special Case Pattern when "nothing here" has a sensible default behaviour
- Never pass null as an argument

For detailed error handling rules and examples, see [references/error-handling.md](references/error-handling.md).

### Classes and Objects

- Classes should be small in responsibilities, not just lines -- describable in about 25 words without "and", "or", or "but"
- Single Responsibility Principle: one reason to change
- Open-Closed Principle: open for extension, closed for modification
- Dependency Inversion: depend on abstractions, not concrete implementations
- Inject dependencies rather than constructing them inside the class; keep construction separate from use
- High cohesion: methods should use most of the class's instance variables
- No public instance variables
- Follow the Law of Demeter: don't reach through objects (`customer.transferMoney(amount)` not `customer.getWallet().debit(amount)`)
- Objects hide data behind behaviour; data structures expose data and have no behaviour -- don't mix the two
- At a boundary, depend on an interface, pass generic data, and leak no implementation detail

For detailed class, object, system design, and boundary rules, see [references/classes-and-systems.md](references/classes-and-systems.md).

### Testing

- Test code has the same quality standards as production code
- One concept per test, asserted as strictly as the data allows (whole object, every field)
- Name tests `method_scenario_expectedOutcome`
- Cover the inverse case alongside the happy path
- Keep test setup separate from assertions, and share it across suites
- F.I.R.S.T: Fast, Independent, Repeatable, Self-Validating, Timely

For detailed testing rules and TDD guidance, see [references/testing.md](references/testing.md).

### Code Smells

When writing or reviewing code, watch for and eliminate code smells including: duplication, ambiguous names, magic numbers, feature envy, negative conditionals, too many arguments, boolean arguments, and commented-out code.

For the full code smell catalog, see [references/code-smells.md](references/code-smells.md).

## Tom's Review Standards

20 standards Tom holds others to in review. Each is recorded in its reference file under a "Tom's Review Standards" heading, in the shape **Standard / Why / Example**.

| Area           | Standards                                                                                                                                                                                                               | File                                                                               |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Naming         | Intention-revealing names; No bare literal arguments; Match the established convention                                                                                                                                  | [references/naming.md](references/naming.md#toms-review-standards)                 |
| Structure      | Single source of truth for shared contracts; Sweep the fix across the whole change; Put code where its role is obvious; Don't land unused code; Time-box workarounds explicitly                                         | [references/structure.md](references/structure.md#toms-review-standards)           |
| Error handling | Handle "not found" as its own case; Fail fast; don't mask broken state                                                                                                                                                  | [references/error-handling.md](references/error-handling.md#toms-review-standards) |
| Testing        | Scenario-revealing test names; Assert as strictly as the data allows; Cover the inverse case; Assert interactions, not side effects, when mocking; Keep the suite lean; Share test setup; Control async timing in tests | [references/testing.md](references/testing.md#toms-review-standards)               |
| Documentation  | Comment the what and why, not the how; Describe concepts durably; Delete zero-information documentation                                                                                                                 | [references/comments.md](references/comments.md#toms-review-standards)             |

## Reference Files

Consult these detailed guides when writing or reviewing code:

- [references/naming.md](references/naming.md) - Naming conventions for variables, functions, classes, constants
- [references/functions.md](references/functions.md) - Function design
- [references/comments.md](references/comments.md) - When a comment earns its place, and the comments to delete
- [references/structure.md](references/structure.md) - Where code goes, shared contracts, unused code, workarounds
- [references/classes-and-systems.md](references/classes-and-systems.md) - OOP design, SOLID principles, architecture, boundaries
- [references/error-handling.md](references/error-handling.md) - Exception handling, not-found contracts, null safety
- [references/testing.md](references/testing.md) - Unit testing and TDD practices
- [references/code-smells.md](references/code-smells.md) - Anti-patterns to identify and eliminate

## Performance Notes

- Apply these rules consistently -- they are not optional
- Quality and readability are more important than brevity
- When reviewing code, flag every violation with a specific rule reference and the reason behind it
