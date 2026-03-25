# Naming Rules and Patterns

## Contents

- [General Rules](#general-rules)
- [Naming Patterns](#naming-patterns)

## General Rules

### Use Intention-Revealing Names

Choose names that clearly express the intention behind the variable, method, or class.

```python
# Bad
x = 42

# Good
age = 42
```

### Avoid Disinformation

Don't use names that could be misleading or suggest a wrong type. Avoid `l` or `O` as variable names (confused with `1` and `0`).

```python
# Bad
l = 1

# Good
length = 1
```

### Make Meaningful Distinctions

Avoid names that are easy to misspell or sound similar but have different meanings.

```python
# Bad
def control(): pass
def controller(): pass
class UserManager(): pass
class UserManagement(): pass

# Good
def user_control(): pass
def system_controller(): pass
class UserServices(): pass
class UserAdministration(): pass
```

### Use Pronounceable Names

```python
# Bad
cstmrId = 1

# Good
customer_id = 1
```

### Boolean Variables

Prefix booleans with `is`, `has`, `can`, or similar.

```java
// Bad
boolean done;
boolean p;

// Good
boolean isDone;
boolean hasPermission;
```

### Use Searchable Names

Names should be unique enough that a codebase search returns only relevant instances. Single-letter names are only acceptable as local variables in short functions.

```java
// Bad
int s;

// Good
int speed;
```

### Avoid Encodings

No Hungarian notation. No `I` prefix on interfaces. Consumers needn't know whether they're dealing with an interface or concrete class.

```java
// Bad
interface IShape { ... }
String strName = "John";
int iAge = 25;

// Good
interface Shape { ... }
String name = "John";
int age = 25;
```

### Avoid Mental Mapping

Don't make the reader translate. Abbreviations must be universally understood (e.g., `HTTP`, `ID`).

### Don't Be Cute

No clever or humorous names. Say what you mean, mean what you say.

### Use Solution Domain Names

Use commonly-known technical terminology: algorithm names, pattern names, math terms.

```javascript
// Bad
function doStuff() { ... }
const users = [...];
class Processor { ... }

// Good
function quickSort() { ... }
const userQueue = [...];
class AbstractFactory { ... }
```

### Use Problem Domain Names

Use terminology from the real-life area the software relates to.

```javascript
// Bad
function calculate() { ... }

// Good
function calculateMortgage() { ... }
```

### Add Meaningful Context

Names should live within a well-named class, function, or namespace to provide full meaning.

```javascript
// Bad
const duration = 5;
function validate() { ... }
function onClick() { ... }

// Good
const durationDays = 5;
function validateUserInput() { ... }
function onLoginButtonClick() { ... }
```

### Don't Add Gratuitous Context

Don't add unnecessary context. Utility functions should be named generically, not tied to their initial consumer.

```javascript
// Bad - tied to OrderProcessor context
function removeDuplicateProductIds(allProductIds) {
  return [...new Set(allProductIds)];
}

// Good - generic, reusable
function getUniqueElements(elements) {
  return [...new Set(elements)];
}
```

## Naming Patterns

### Classes

Use a noun or noun phrase. Two patterns:

**Thing** (entities, concepts, data structures):

- Problem domain: `User`, `Account`, `Order`
- Solution domain: `LinkedList`, `DatabaseConnection`, `HttpRequest`, `Configuration`, `Logger`

**Do-er** (actions, behaviors, responsibilities):

- Problem domain: `PaymentProcessor`, `EmailSender`, `AuthenticationManager`, `OrderValidator`, `ReportGenerator`
- Software constructs: `Controller`, `Service`, `Factory`, `Strategy`

Avoid vague names like `Data`, `Info`, `Manager`, `Processor`.

### Functions

Use a verb or verb phrase.

- Accessors: prefix with `get`
- Mutators: prefix with `set`
- Predicates: prefix with `is`/`has`/`can`

```javascript
function isReady() { ... }
function hasProperty() { ... }
function canEdit() { ... }
```

**Overloaded constructors** -- use static factory methods:

```javascript
// Bad
const foo1 = new Foo({ bar: true });
const foo2 = new Foo({ baz: true });

// Good
const foo1 = Foo.withBar(true);
const foo2 = Foo.withBaz(true);
```

### Boolean Variables/Properties

Prefix with `is`, `has`, or `can`. Avoid negatives.

```javascript
// Bad
const isNotReady = true;
if (isNotReady) { ... }

// Good
const isReady = false;
if (!isReady) { ... }
```

### Constants

All uppercase with underscores:

```javascript
const MAX_COUNT = 10;
```

### Enums

Singular name for the type, all caps for members:

```javascript
enum Outcome {
    SUCCESS,
    ERROR
}
```
