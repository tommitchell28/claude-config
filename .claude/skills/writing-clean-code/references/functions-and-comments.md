# Functions and Comments

## Contents

- [Function Rules](#function-rules)
- [Comment Rules](#comment-rules)

## Function Rules

### Small

Functions should not be long. Keep each function easy to read and understand.

### Single Responsibility

Functions should do one thing, do it well, and do it only.

Error handling functions should only do error handling:

```javascript
function runProcess() {
  try {
    run();
  } catch (error) {
    processError(error);
  } finally {
    notifyEnd();
  }
}
```

### Descriptive Name

The name should leave no surprises when reading the body. Longer names are acceptable when needed for clarity.

### Number of Arguments

Fewer is better. 0 is ideal, never exceed 3.

Reasons:

- Ease of understanding
- Reduction of test permutations

### Reducing Arguments

Use an object to wrap related arguments:

```javascript
// Bad
function createUser(name, email, age, role, department) { ... }

// Good
function createUser(userDetails) { ... }
```

### Boolean Arguments

Boolean arguments indicate a function does more than one thing. Split into two functions instead.

```javascript
// Bad
function render(isMobile) { ... }

// Good
function renderDesktop() { ... }
function renderMobile() { ... }
```

### No Side Effects

A side-effect is hidden behaviour the function name doesn't indicate. Everything a function does must be reflected in its name.

### Avoid Output Arguments

Don't mutate input arguments. Output arguments hurt readability, create surprises, and make testing harder.

```javascript
// Bad - mutates input
function squareAndStore(arr) {
  for (let i = 0; i < arr.length; i++) {
    arr[i] = arr[i] * arr[i];
  }
}

// Good - returns new data
function square(arr) {
  return arr.map((x) => x * x);
}
```

Exception: mutating large data structures may be necessary for performance.

### Command Query Separation

Functions should either DO something or ANSWER something, never both.

```typescript
// Bad - What does the return value mean?
function set(key: string, value: string): boolean;
if (set('isUser', false)) { ... }

// Good - separate command and query
function set(key: string, value: string): void;
function has(key: string): boolean;
```

### Extract Try-Catch Blocks

Extract the bodies of try-catch blocks into their own functions:

```javascript
// Good
try {
  foo();
} catch (error) {
  processError(error);
}
```

## Comment Rules

### Default: Don't Write Comments

Code should be self-explanatory. Comments become outdated quickly. Instead of a comment, use a well-named function or variable.

### Acceptable Comments

**Legal**: Copyright and license statements required by enterprise software.

**Explanation of Intent**: Why a decision was made, when not obvious from code alone.

**Clarification**: Readable representations of obscure arguments/return types from unmodifiable code (third-party, standard library).

**Warning of Consequences**: Safety warnings about non-trivial consequences of running particular code.

**TODO Comments**: Only with a reference to scheduled work (e.g., a Jira ticket). Never orphaned TODOs.

**API Documentation**: Docblocks for external-facing interfaces to document behaviour and contract.

### Bad Comments

- **Nonsensical/misleading**: Difficult to understand or inaccurate
- **Redundant**: No longer relevant or stating the obvious
- **Mandated docblocks**: Docblocks on functions/properties that don't need them
- **Commented-out code**: Delete it. Version control exists for a reason
