---
name: writing-clean-code
description: >-
  Enforces clean code principles (based on Robert C. Martin's Clean Code) as a
  system-wide standard. Automatically applied when Claude writes new code,
  modifies existing code, or reviews code quality -- no user invocation needed.
  Covers naming, functions, comments, formatting, error handling, classes,
  testing, and code smells.
user-invocable: false
---

# Writing Clean Code

These are hard rules to follow when writing or reviewing any code. Based on
Robert C. Martin's "Clean Code: A Handbook of Agile Software Craftsmanship".

## Important

- These rules apply to ALL code written or reviewed -- no exceptions
- Code should be written as if maintained by someone else, because it will be
- Clean code reduces cognitive load, making it easier to debug, extend, and refactor

## Core Principles

### Naming

- Use intention-revealing names -- the name alone should explain purpose
- Avoid disinformation, mental mapping, and encodings (no Hungarian notation, no `I` prefix on interfaces)
- Use pronounceable, searchable names
- Prefix booleans with `is`, `has`, or `can` -- avoid negatives (`isReady = false` not `isNotReady = true`)
- Classes: noun or noun phrase. Functions: verb or verb phrase
- Constants: ALL_UPPERCASE_WITH_UNDERSCORES
- Use solution domain names (technical terms) and problem domain names (business terms) appropriately

For detailed naming rules and examples, see [references/naming.md](references/naming.md).

### Functions

- Keep functions small -- each does one thing well
- Minimize arguments (0 is best, never more than 3). Use objects to group related args
- No boolean arguments -- split into two functions instead
- No side effects -- function name must describe everything it does
- Don't mutate input arguments (no output arguments)
- Command Query Separation: functions either DO something or ANSWER something, not both
- Extract try-catch block bodies into separate functions

For detailed function rules and examples, see [references/functions-and-comments.md](references/functions-and-comments.md).

### Comments

- Default: don't write comments. Code should be self-explanatory
- Acceptable comments: legal, explanation of intent, clarification of obscure APIs, warnings, TODOs with ticket references, API documentation
- Bad comments: redundant, misleading, mandated docblocks, commented-out code

For detailed comment guidance, see [references/functions-and-comments.md](references/functions-and-comments.md).

### Formatting

- Use blank lines to separate different concepts (imports, property groups, methods)
- Keep related concepts vertically close together
- Variable declarations near their usage
- Caller functions above callee functions
- Group conceptually related code together

### Error Handling

- Use exceptions, not error codes
- Start with try-catch-finally blocks
- Add context to exceptions -- include the intent of the failed operation
- Use the Special Case Pattern to avoid null checks
- Never return null -- throw exceptions or use Special Case objects
- Never pass null as an argument

For detailed error handling rules and examples, see [references/error-handling.md](references/error-handling.md).

### Classes and Objects

- Classes should be small in responsibilities, not just lines
- Single Responsibility Principle: one reason to change
- Open-Closed Principle: open for extension, closed for modification
- Dependency Inversion: depend on abstractions, not concrete implementations
- High cohesion: methods should use most of the class's instance variables
- No public instance variables
- Follow the Law of Demeter: don't reach through objects (`customer.transferMoney(amount)` not `customer.getWallet().debit(amount)`)

For detailed class, object, and system design rules, see [references/classes-and-systems.md](references/classes-and-systems.md).

### Testing

- Test code has the same quality standards as production code
- One concept per test, single assertion where possible
- Keep test setup separate from assertions
- F.I.R.S.T: Fast, Independent, Repeatable, Self-Validating, Timely

For detailed testing rules and TDD guidance, see [references/testing.md](references/testing.md).

### Code Smells

When writing or reviewing code, watch for and eliminate code smells including: duplication, ambiguous names, magic numbers, feature envy, negative conditionals, too many arguments, boolean arguments, and commented-out code.

For the full code smell catalog, see [references/code-smells.md](references/code-smells.md).

## Reference Files

Consult these detailed guides when writing or reviewing code:

- [references/naming.md](references/naming.md) - Naming conventions for variables, functions, classes, constants
- [references/functions-and-comments.md](references/functions-and-comments.md) - Function design and comment guidelines
- [references/classes-and-systems.md](references/classes-and-systems.md) - OOP design, SOLID principles, architecture
- [references/error-handling.md](references/error-handling.md) - Exception handling and null safety patterns
- [references/testing.md](references/testing.md) - Unit testing and TDD practices
- [references/code-smells.md](references/code-smells.md) - Anti-patterns to identify and eliminate

## Performance Notes

- Apply these rules consistently -- they are not optional
- Quality and readability are more important than brevity
- When reviewing code, flag every violation with a specific rule reference
