# Unit Testing

## Contents

- [Test Driven Development](#test-driven-development)
- [General Rules](#general-rules)
- [Tom's Review Standards](#toms-review-standards)

## Test Driven Development

### Summary

TDD emphasizes writing tests before production code. Iteratively: write a failing test, implement code to pass it, refactor.

### Benefits

- **Bug Prevention**: Issues identified early
- **Simplified Debugging**: Small changes between clean states make diagnosis easy
- **Self-documenting Tests**: The test suite describes all behaviour
- **Ease of Refactoring**: Full test coverage makes refactoring safe

### Three Laws of TDD

1. You may not write production code until you have written a failing unit test
2. You may not write more of a unit test than is sufficient to fail (not compiling counts as failing)
3. You may not write more production code than is sufficient to pass the currently failing test

## General Rules

### Test Code === Production Code

Test code is just as important as production code. All clean code practices apply equally to tests.

### One Concept per Test

Each test covers one concept, asserted as strictly as the data allows: the whole object, every field. The limit is on concepts, not on the number of assertions -- a test that checks one field of a returned object and ignores the rest passes on a malformed result.

```typescript
// Bad - one field checked, the rest could be anything
test("getUser_whenUserExists_returnsUser", () => {
  const user = getUser("42");
  expect(user.id).toBe("42");
});

// Good - one concept, the whole object asserted
test("getUser_whenUserExists_returnsUser", () => {
  const user = getUser("42");
  expect(user).toStrictEqual({ id: "42", name: "Ada", roles: ["admin"] });
});
```

### Keep Setup Separate

Separate test setup (mocks, stubs, environment config) from the tests themselves.

Benefits:

- Readability
- Extensibility -- adding tests becomes trivial
- Small, focused tests -- easy to see what is being tested

### F.I.R.S.T Principles

- **Fast**: Tests should run quickly
- **Independent**: Tests must not depend on each other
- **Repeatable**: Tests must work in any environment
- **Self-Validating**: Tests pass or fail -- no manual inspection needed
- **Timely**: Tests written just before the production code that makes them pass

## Tom's Review Standards

Each standard keeps the shape Standard / Why / Example (the example is optional).

### Scenario-revealing test names

**Standard:** Name tests `method_scenario_expectedOutcome`. **Why:** The name should tell you what broke without reading the body. **Example:** `listUsers_whenDirectoryEmpty_returnsEmptyList()`

### Assert as strictly as the data allows

**Standard:** Assert the whole object and every field of a validated structure, reject anything malformed, and dedupe at every level rather than just the outermost. **Why:** A lenient assertion passes on malformed input, so what it "validates" can ship broken. **Example:** strict deserialization that rejects unknown keys over lenient parsing that nulls them; assert a value is non-blank, not merely non-null.

### Cover the inverse case

**Standard:** Add the negative or inverse test alongside the happy path. **Why:** Testing only the positive path leaves half the behaviour unverified.

### Assert interactions, not side effects, when mocking

**Standard:** With the data layer or other dependencies mocked, assert whether the dependency was invoked rather than on downstream side effects. **Why:** A "no query issued" check is meaningless when the data layer is mocked -- the actual contract is that the call happened.

### Keep the suite lean

**Standard:** Remove low-value or convoluted tests, collapse overlapping ones, and don't write integration tests for services that are not part of the public API. **Why:** Redundant tests cost maintenance without adding coverage. **Example:** A test that wraps a plain write in elaborate setup but asserts nothing adds ceremony, not coverage -- delete it or give it an assertion.

### Share test setup

**Standard:** Extract shared setup -- mocks, data-layer stubs, component creation -- into helpers reused across suites. **Why:** Duplicated setup drifts between suites.

### Control async timing in tests

**Standard:** Resolve promises deliberately so intermediate states can be asserted. **Why:** A fire-and-forget `await` skips straight past the transitions worth testing. **Example:** `Promise.withResolvers` to assert loading `true` → `false`.
