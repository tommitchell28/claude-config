# Unit Testing

## Contents

- [Test Driven Development](#test-driven-development)
- [General Rules](#general-rules)

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

### Single Concept per Test

Each test should test one thing. Often this means a single assertion per test, though not always.

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
