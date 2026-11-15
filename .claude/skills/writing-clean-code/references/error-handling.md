# Error Handling

## Contents

- [General Rules](#general-rules)
- [Not-Found Contract](#not-found-contract)
- [Special Case Pattern](#special-case-pattern)
- [Tom's Review Standards](#toms-review-standards)

## General Rules

### Exceptions Over Error Codes

Error codes violate Command Query Separation, force immediate handling, and create heavy nesting.

```javascript
// Bad - error codes
if (foo(bar) === ERROR_CODES.OK) {
    if (baz(bar) === ERROR_CODES.OK) {
        ...
    } else {
        logError('error in baz');
    }
} else {
    logError('error in foo');
}

// Good - exceptions
try {
    foo(bar);
    baz(bar);
    ...
} catch (error) {
    logError(error);
}
```

### Begin with Try-Catch-Finally

When writing code that could throw, start with try-catch-finally:

- The unhappy path is considered alongside the happy path
- Error handling is immediately separated (Separation of Concerns)

### Add Context to Exceptions

Exceptions must contain enough information to determine the source and location of the error. Error messages should describe the intent of the failed operation.

```javascript
// Bad
throw new Error("Failed");

// Good - operation, identifiers, and cause
throw new Error(
  `Failed to save order ${orderId} for customer ${customerId}: ${originalError.message}`,
);
```

### Tailor Exceptions to Callers

Design exceptions for how callers will use them. Ask: Will this be useful? Will it make sense?

### Fail Fast

Validate inputs early and throw immediately with a message that says what failed and why. Failing at the entry point is far cheaper to diagnose than failing 50 lines deep with a cryptic error.

```typescript
// Bad - fails deep, with a confusing message
function processPayment(amount, account) {
  // ...50 lines...
  database.save(amount); // "Cannot save NaN"
}

// Good - fail at the door
function processPayment(amount, account) {
  if (typeof amount !== "number" || isNaN(amount)) {
    throw new Error(`Invalid amount: ${amount}`);
  }
  if (!account?.id) throw new Error("Account with ID required");
  // processing...
}
```

Failing fast also means not hiding a state that should never occur behind a default. See [Fail fast; don't mask broken state](#fail-fast-dont-mask-broken-state).

### Handle Errors at the Right Level

Catch an error only at the level that has enough context to act on it. Below that level, let it propagate: a catch that only logs and swallows hides failures.

```typescript
// Bad - catches too early, can't do anything useful
function saveUser(user) {
  try {
    database.save(user);
  } catch (error) {
    console.log("Error");
  }
}

// Good - propagate; the entry point decides
function saveUser(user) {
  database.save(user);
}

async function handleCreateUser(request, response) {
  try {
    const user = createUser(request.body);
    saveUser(user);
    response.status(201).json(user);
  } catch (error) {
    if (error instanceof ValidationError) {
      response.status(400).json({ error: error.message });
    } else {
      logError(error);
      response.status(500).json({ error: "Internal error" });
    }
  }
}
```

### Don't Pass Null

Passing null mandates null checks inside the function and is unreadable. What does passing null mean? Use a default parameter or require the value.

## Not-Found Contract

Decide and document what a function does when the thing it looks for is missing. Absent must be distinguishable from empty.

- Returning `null` (or an Optional, where the language has one) for a missing record is acceptable when that is the documented contract
- Throw when absence is exceptional and the caller cannot continue
- Do not return `null` where an empty collection is the right answer
- Use a [Special Case object](#special-case-pattern) only when "nothing here" has a sensible default behaviour -- not to disguise a missing record as an empty one

```typescript
/** Returns the user with this id, or null when no such user exists. */
function findUser(id: string): User | null {
  const user = userById.get(id);
  const isUserMissing = user === undefined;
  return isUserMissing ? null : user;
}

// Absence is exceptional here - throw
function getUser(id: string): User {
  const user = findUser(id);
  if (user === null) throw new UserNotFoundError(id);
  return user;
}

// Collections - empty, not null
function findUsers(criteria: Criteria): User[] {
  return database.query(criteria) ?? [];
}
```

## Special Case Pattern

The Special Case Pattern handles a "nothing here" case by returning an object that adheres to the same interface as normal-case objects but with simplified behaviour. Use it when the absent case has a sensible default behaviour that every caller wants.

Benefits:

- Fewer conditional checks (better readability)
- Leverages polymorphism for extensibility

### Without Special Case Pattern

```typescript
class Plan {
  getMonthlyRate(): number {
    return 100;
  }
}

class Customer {
  private hasPlan: boolean;

  constructor(hasPlan: boolean) {
    this.hasPlan = hasPlan;
  }

  getPlan(): Plan | null {
    return this.hasPlan ? new Plan() : null;
  }
}

// Every caller repeats the same check to get the same default
const plan = customer.getPlan();
if (plan) {
  console.log(plan.getMonthlyRate());
} else {
  console.log(0);
}
```

### With Special Case Pattern

```typescript
class Plan {
  getMonthlyRate(): number {
    return 100;
  }
}

class NullPlan extends Plan {
  getMonthlyRate(): number {
    return 0;
  }
}

class Customer {
  private hasPlan: boolean;

  constructor(hasPlan: boolean) {
    this.hasPlan = hasPlan;
  }

  getPlan(): Plan {
    return this.hasPlan ? new Plan() : new NullPlan();
  }
}

// No null checks needed
console.log(customer.getPlan().getMonthlyRate());
```

## Tom's Review Standards

Error handling and edge cases. Each standard keeps the shape Standard / Why / Example (the example is optional).

### Handle "not found" as its own case

**Standard:** Explicitly handle the missing-record case, decide its contract (e.g. return `null` rather than an empty object), document that contract, and express the condition with a named boolean. **Why:** Callers need to treat "absent" differently from "empty"; leaving it implicit causes silent mishandling downstream.

### Fail fast; don't mask broken state

**Standard:** Don't wrap conditions that should never legitimately occur in defensive code -- let them blow up. **Why:** Masking a genuinely-broken state hides bugs and produces confusing downstream behaviour instead of a clear failure. **Example:** A missing required config value should throw, not be silently defaulted by optional chaining.
