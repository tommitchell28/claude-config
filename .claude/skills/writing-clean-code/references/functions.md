# Functions

Functions should be small and do one thing well.

## Contents

- [Small](#small)
- [Single Responsibility](#single-responsibility)
- [Descriptive Name](#descriptive-name)
- [Number of Arguments](#number-of-arguments)
- [Reducing Arguments](#reducing-arguments)
- [Boolean Arguments](#boolean-arguments)
- [No Side Effects](#no-side-effects)
- [Avoid Output Arguments](#avoid-output-arguments)
- [Command Query Separation](#command-query-separation)
- [Extract Try-Catch Blocks](#extract-try-catch-blocks)

## Small

Functions should not be long. Keep each function easy to read and understand. When a function has labelled sections, those sections are usually functions waiting to be named.

```javascript
// Bad - one function doing validation, calculation, saving, notification
function processOrder(order) {
  // 50+ lines...
}

// Good - each step named and small
function processOrder(order) {
  validateOrder(order);
  const total = calculateTotal(order);
  saveOrder(order, total);
  notifyCustomer(order);
}
```

## Single Responsibility

Functions should do one thing, do it well, and do it only. "One thing" means one level of abstraction: mixing high-level orchestration with low-level detail shows a function does more than one thing.

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

## Descriptive Name

The name should leave no surprises when reading the body. Longer names are acceptable when needed for clarity.

```javascript
// Bad - vague
function process(data) { ... }

// Good - the name predicts the body
function calculateShippingCost(order) { ... }
```

## Number of Arguments

Fewer is better. 0 is ideal, never exceed 3.

Reasons:

- Ease of understanding
- Reduction of test permutations

## Reducing Arguments

Use an object to wrap related arguments:

```javascript
// Bad
function createUser(name, email, age, role, department) { ... }

// Good
function createUser(userDetails) { ... }
```

## Boolean Arguments

Boolean arguments indicate a function does more than one thing. Split into two functions instead.

```javascript
// Bad
function render(isMobile) { ... }

// Good
function renderDesktop() { ... }
function renderMobile() { ... }
```

### Naming an Unavoidable Boolean at the Call Site

Prefer splitting, as above. Some callees take a boolean and are not yours to split: a framework or external API, a constructor whose flag is part of one object's state, or a test helper that configures a mock. There, a bare `true`/`false` at the call site is a magic literal: the reader has to open the callee to learn what it means.

Bind it to a named local (or constant) so the argument documents itself.

```javascript
// Bad - what does `false` mean here?
mockSearch(resources, false);

// Good - the name states what the flag means
const hasMoreResults = false;
mockSearch(resources, hasMoreResults);
```

Name it after the parameter's meaning, not its value: `hasMoreResults`, never `flagFalse`. Match the callee's parameter name where one exists.

See also "No bare literal arguments" in [naming.md](naming.md#no-bare-literal-arguments).

## No Side Effects

A side-effect is hidden behaviour the function name doesn't indicate. Everything a function does must be reflected in its name.

```javascript
// Bad - validating also initializes a session
function validatePassword(password) {
  if (isValid(password)) {
    Session.initialize();
    return true;
  }
  return false;
}

// Good - does only what it says
function validatePassword(password) {
  return isValid(password);
}
```

## Avoid Output Arguments

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

## Command Query Separation

Functions should either DO something or ANSWER something, never both.

```typescript
// Bad - What does the return value mean?
function set(key: string, value: string): boolean;
if (set('isUser', false)) { ... }

// Good - separate command and query
function set(key: string, value: string): void;
function has(key: string): boolean;
```

## Extract Try-Catch Blocks

Error handling is one thing; the happy path is another. Extract the bodies of try-catch blocks into their own functions:

```javascript
// Bad - happy path and error handling interleaved
function processFile(path) {
  try {
    const data = readFile(path);
    const parsed = parseData(data);
    saveResult(transform(parsed));
  } catch (error) {
    logError(error);
    notifyAdmin(error);
    throw error;
  }
}

// Good - each concern named
function processFile(path) {
  try {
    doProcessFile(path);
  } catch (error) {
    handleProcessingError(error);
  }
}
```
