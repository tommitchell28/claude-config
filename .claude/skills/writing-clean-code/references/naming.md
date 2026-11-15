# Naming Rules and Patterns

## Contents

- [General Rules](#general-rules)
- [Naming Patterns](#naming-patterns)
- [Tom's Review Standards](#toms-review-standards)

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

Names should sit within a well-named class, function, or namespace to provide full meaning.

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

### Collections and Items

Use plural nouns for variables holding multiple items, singular nouns for a single item. The reader learns the cardinality from the name alone.

```javascript
// Collections - plural
const newUsers = [];
const activeAccounts = fetchActiveAccounts();

// Single items - singular
const newUser = createUser(data);
const activeAccount = activeAccounts[0];

// In loops, the element is singular
for (const user of users) { ... }
```

### Lookup Maps and Dictionaries

Name dictionary-style lookups `SingularNounByKey`. The suffix tells the reader that this is a lookup structure, what the key is, and what it contains.

```javascript
const userById = new Map(); // userById.get(userId)
const accountByName = new Map(); // accountByName.get(accountName)

const configByEnvironment = {
  development: devConfig,
  production: prodConfig,
}; // configByEnvironment[environment]
```

### Avoid Generic Names

Avoid names that carry no information beyond the type: `data`, `item`, `temp`, or a name that only echoes the class name or its plural. Add the context that distinguishes this value.

```javascript
// Bad - too generic
const data = getUser(id);
const items = getAllUsers();
const temp = new Account();

// Good - the name states which one and why
const currentUser = getUser(id);
const activeUsers = getAllUsers().filter((u) => u.isActive);
const targetAccount = findAccount(criteria);
```

### Contextual Naming

Add context to tell similar variables apart -- by purpose, by state, or by scope.

```javascript
// By purpose
const sourceAccount = getAccount(sourceId);
const targetAccount = getAccount(targetId);

// By state
const originalData = fetchData();
const transformedData = transform(originalData);

// By scope
const globalConfig = loadGlobalConfig();
const userConfig = loadUserConfig(userId);
const mergedConfig = merge(globalConfig, userConfig);
```

### Abbreviations

Only common, universally understood abbreviations are acceptable -- they read as words in their own right:

```javascript
const id = record.id;
const url = "https://...";
const idx = 0; // index
const config = loadConfig(); // configuration
const params = getParams(); // parameters
const res = await fetch(url); // response
```

Avoid the ones that save a few characters at the cost of clarity:

```javascript
const usr = getUser(id); // use: user
const acct = getAccount(id); // use: account
const amt = 100; // use: amount
const qty = 5; // use: quantity
const dt = new Date(); // use: date
const val = getValue(); // use: value
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

### Files

Follow the project's existing convention. Where none exists:

| Language   | Convention            | Example               |
| ---------- | --------------------- | --------------------- |
| TypeScript | camelCase             | `userService.ts`      |
| Test files | Match source + suffix | `userService.test.ts` |

## Tom's Review Standards

Naming and readability. Each standard keeps the shape Standard / Why / Example (the example is optional).

### Intention-revealing names

**Standard:** Name things for what they actually are, and rename when a name is vague or stale -- including purging dead terminology from every mention. **Why:** Names are the primary documentation; a name implying the wrong thing misleads every future reader. **Example:** `getMostRecentNavState`, not a position-based name, when the selection is by time.

### No bare literal arguments

**Standard:** Assign literal arguments to a named variable, or extract a well-named method, instead of passing bare booleans and magic values. **Why:** `someCall(false)` forces the reader to open the callee to learn what it means. **Example:** `const isDryRun = false;`

### Match the established convention

**Standard:** Use the naming convention already established in the module rather than introducing a second style alongside it. **Why:** A mixed convention forces every future reader and author to guess which applies.
