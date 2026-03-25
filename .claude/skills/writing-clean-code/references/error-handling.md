# Error Handling

## Contents

- [General Rules](#general-rules)
- [Special Case Pattern](#special-case-pattern)

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

### Tailor Exceptions to Callers

Design exceptions for how callers will use them. Ask: Will this be useful? Will it make sense?

### Don't Return Null

Returning null forces callers to check for it and risks null pointer exceptions.

Instead:

- Throw an exception
- Use a Special Case object

### Don't Pass Null

Passing null mandates null checks inside the function and is unreadable. What does passing null mean?

## Special Case Pattern

The Special Case Pattern implicitly handles exceptional cases by returning objects that adhere to the same interface as normal-case objects but with simplified behaviour.

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

// Caller must check for null everywhere
const plan = customer.getPlan();
if (plan) {
  console.log(plan.getMonthlyRate());
} else {
  console.log("No plan");
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
