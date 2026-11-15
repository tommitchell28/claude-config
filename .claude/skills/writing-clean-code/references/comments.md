# Comments

When a comment earns its place, and, far more often, when it doesn't.

## Contents

- [Default: Don't Write Comments](#default-dont-write-comments)
- [The Test](#the-test)
- [Comments That Pass the Test](#comments-that-pass-the-test)
- [Comments to Delete](#comments-to-delete)
- [Tom's Review Standards](#toms-review-standards)

## Default: Don't Write Comments

Code should be self-explanatory. Comments become outdated quickly. Instead of a comment, use a well-named function or variable.

```javascript
// Bad - a comment props up unclear code
// Check if employee is eligible for benefits
if (employee.type === 'FT' && employee.tenure > 1) { ... }

// Good - a well-named method needs no comment
if (employee.isEligibleForBenefits()) { ... }
```

## The Test

Before adding any comment, it must pass this test:

> Would a competent engineer reading this code be surprised, or make a wrong change, without it?

If the answer is no, delete the comment and improve the code instead. Most comments fail. When in doubt, omit.

The bar is this high because comments carry ongoing risk:

1. **They go stale**: code changes, comments often don't
2. **They mislead**: a stale comment is worse than none, because the reader trusts it
3. **They mask unclear code**: if a comment is needed to explain it, the code wants rewriting

## Comments That Pass the Test

Keep these terse. Each is the exception, not the norm.

**Legal**: Copyright and license statements, where the project requires them.

**Explanation of Intent (a genuine why)**: A non-obvious tradeoff, workaround, or constraint that a reader would otherwise undo.

```javascript
// Insertion sort: the array is almost always nearly sorted, so this is O(n) in practice.
insertionSort(events);
```

```javascript
// Process in 200-record chunks: the bulk endpoint rejects larger batches.
for (const chunk of partition(records, 200)) { ... }
```

```javascript
// response.status is 0 when offline (browser quirk), not an error.
if (response.status === 0) {
  handleOffline();
}
```

**Clarification**: Readable representations of obscure arguments/return types from unmodifiable code (third-party, standard library).

**Warning of Consequences**: Safety warnings about non-trivial consequences of running particular code.

**TODO Comments**: Only with a reference to scheduled work (an issue number). Never orphaned TODOs: they have no owner and no end.

```javascript
// TODO(#123): Optimize this query for large datasets
```

**API Documentation**: Docblocks for external-facing interfaces, where consumers benefit from documented parameters and behaviour.

```typescript
/**
 * Calculates the total price including tax.
 * @param taxRate - Tax rate as decimal (e.g., 0.1 for 10%)
 */
function calculateTotal(items: Item[], taxRate: number): number { ... }
```

## Comments to Delete

These are the comments that show up in practice. Recognise and remove them.

### Narration and Section Headers

The most common kind: a comment that announces what the next line or block does. The code already says it.

```javascript
// Bad
function saveOrder(order) {
  // Validate the inputs
  if (!order.id) throw new Error("id required");
  // Build the query
  const query = buildQuery(order);
  // Now save the record
  return db.save(query);
}

// Good - the names already say all of this
function saveOrder(order) {
  requireId(order);
  return db.save(buildQuery(order));
}
```

### Docblocks on Private Methods

A docblock that adds nothing over the signature is noise, doubly so on a non-public method. The same goes for mandated docblocks on functions and properties that don't need them.

```typescript
// Bad - restates the name, on a private helper
/**
 * Gets the active accounts
 * @returns the active accounts
 */
private getActiveAccounts() { ... }

// Good
private getActiveAccounts() { ... }
```

### A "Why" That Is Really a "What"

The why exception is narrow. A comment dressed up as intent but only restating the mechanics still fails the test.

```javascript
// Bad - "why"-shaped, but it only says what the line does
// Loop through users to find the admin
const admin = users.find((u) => u.isAdmin);

// Good - a real why: surprising, would be changed incorrectly otherwise
// Linear scan, not a Map: this list is never larger than ~5 and rebuilt every render.
const admin = users.find((u) => u.isAdmin);
```

Two guards catch the comments that most look like a valid "why":

- If the reason is the called function's reason for existing, it belongs on that function, not at the call site. A comment above a call to a well-named helper is almost always narration, even when it reads like intent.
- A real "why" names something a reader could plausibly undo: a tradeoff, a limit, a quirk. If nobody would change the line without it, omit it.

```typescript
// Bad - "why"-shaped, but splitIntoChunks already says what, and the reason
// (the column's maximum length) belongs on that helper, not at every call site.
// Breaking down parameters into smaller chunks to prevent size-related issues
// in the parameter column of the job record.
const chunks = splitIntoChunks(payload);

// Good - the name carries it; no comment.
const chunks = splitIntoChunks(payload);
```

### Comments Inherited by Cloning

Copying a class or method as a template does not carry its comments with it. Re-run the test on every comment in code you clone or mirror: a comment that was marginal in the original is still marginal in the copy, and most should not survive the move.

An instruction to copy a template "verbatim" (in a plan, issue, or request) applies to the code structure, not its comments. After cloning, do a separate pass over every inherited comment and delete the ones that restate the code.

### Misleading Comments

Comments that are wrong, hard to understand, or have drifted from the code. The most dangerous kind.

```javascript
// Returns the user's full name  (WRONG - actually returns email)
function getUserIdentifier(user) {
  return user.email;
}
```

### Commented-Out Code

Delete it. Version control has the history.

```javascript
// Bad
function process(data) {
  // const oldResult = legacyProcess(data);
  return newProcess(data);
}
```

### Journal Comments

Don't track changes in comments. That is what version control is for.

```javascript
// Bad
// 2024-01-15: Added validation
// 2024-02-20: Fixed bug in validation
function validate() { ... }
```

### Noise Comments

Comments that state the obvious or are no longer relevant.

```typescript
// Bad
// Default constructor
constructor() {}

// The day of the month
private dayOfMonth: number;
```

## Tom's Review Standards

Documentation and comments. Each standard keeps the shape Standard / Why / Example (the example is optional).

### Comment the what and why, not the how

**Standard:** Doc comments state the high-level what and why; they don't narrate the implementation step by step. Trim verbose ones across the whole change. **Why:** Implementation-narrating comments rot the moment the code changes and bury the intent the comment exists to convey.

### Describe concepts durably

**Standard:** Describe what an entity is for, in terms that stay true as it grows; leave out today's contents and transient state. **Why:** A description tied to current contents goes stale on the next extension. **Example:** Drop "Installs empty" from a package description.

### Delete zero-information documentation

**Standard:** Remove READMEs, Javadoc, and comments that restate what the code already says -- including acceptance-criteria references in tests. **Why:** They still have to be read and maintained, and acceptance-criteria references go stale the moment the story closes.
