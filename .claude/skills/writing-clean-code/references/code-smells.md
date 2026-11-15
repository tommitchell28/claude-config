# Code Smells

A code smell is a surface-level indication that usually corresponds to a deeper problem. Not an error, but a sign that good practices and design principles have been violated.

## Contents

- [Structural Issues](#structural-issues)
- [Naming and Syntax](#naming-and-syntax)
- [Abstraction and Encapsulation](#abstraction-and-encapsulation)
- [Responsibility and Cohesion](#responsibility-and-cohesion)
- [Compliance and Overrides](#compliance-and-overrides)
- [Comments](#comments)
- [Environment](#environment)
- [Functions](#functions)
- [Surprise](#surprise)

## Structural Issues

- **Code Duplication**: Repeating the same code in multiple places
- **Redundant Coupling**: Unnecessary dependencies between classes or modules
- **Large Vertical Separation**: Related code should be close together
- **Clutter**: Default constructors, redundant comments, and other noise

## Naming and Syntax

- **Ambiguous Names**: Names that don't convey purpose or functionality
- **Magic Numbers/Strings**: Unnamed constants that lack context
- **Not Following Standard Conventions**: Naming conventions, file structures, established best practices
- **Negative Conditionals**: Adds mental overhead and verbosity

```javascript
// Good
if (shouldFoo()) { ... }

// Bad
if (!shouldNotFoo()) { ... }
```

## Abstraction and Encapsulation

- **Implementation Code at the Wrong Level of Abstraction**: Code too low-level or too high-level for its context
- **Feature Envy**: Methods more interested in a different class than their own
- **if/else or switch over Polymorphism**: Using conditionals instead of leveraging polymorphism
- **Un-encapsulated Conditionals**: Conditional logic that should be wrapped in a function

## Responsibility and Cohesion

- **Misplaced Responsibility**: Code that doesn't belong in its current location, violating SRP
- **Lack of Consideration of Edge Cases**: Not handling special cases that might not be immediately obvious
- **Implicit Not-Found Handling**: A lookup whose missing-record behaviour is undocumented, or that makes absent look the same as empty (see [error-handling.md](error-handling.md#not-found-contract))
- **Masked Broken State**: Defensive defaults around a condition that should never occur, hiding the bug instead of failing

## Compliance and Overrides

- **Overriding Rules**: Disabling linters, compilers, or other rules -- indicates a workaround or misunderstanding
- **Inconsistency**: Inconsistent code styles or practices across the codebase

## Comments

- **Needless/Obsolete Information**: Comments that no longer serve a purpose
- **Poorly-Written**: Comments that confuse more than they clarify
- **Narration and Journal Comments**: Comments that announce what the next line does or track change history
- **Commented-Out Code**: Old code that's been commented out rather than removed

See [comments.md](comments.md) for the full list of comments to delete.

## Environment

- **Building the Environment is Not Easy**: Requires multiple steps to set up
- **Running All Tests Requires Multiple Steps**: Hinders test-driven development

## Functions

- **Too Many Arguments**: Hard to understand and use
- **Output Arguments**: Modify external variables, harder to reason about
- **Boolean Arguments**: Make function behaviour less clear. Split the function; where the callee is not yours to split, name the literal at the call site (see [functions.md](functions.md#boolean-arguments))
- **Unused Functions**: No longer called from anywhere -- delete them, along with unused classes and parameters (see [structure.md](structure.md))

## Surprise

- **Unexpected Function Behaviour**: A function's implementation should not be surprising. If it does something unanticipated, something is wrong
