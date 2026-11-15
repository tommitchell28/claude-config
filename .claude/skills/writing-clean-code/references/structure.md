# Structure and Design

Where code goes, what gets defined once, and what should not land at all. For class-level design (SOLID, dependency injection, boundaries) see [classes-and-systems.md](classes-and-systems.md).

## Tom's Review Standards

Each standard keeps the shape Standard / Why / Example (the example is optional).

### Single source of truth for shared contracts

**Standard:** Define a shared shape, constant, or contract once and reference it; point back to it with a class-level comment rather than duplicating it. **Why:** Duplicated contracts drift apart silently.

### Sweep the fix across the whole change

**Standard:** When one line needs a fix, apply the same rule everywhere it's relevant in the change. **Why:** A fix applied to one instance but not its siblings leaves the codebase inconsistent and the review incomplete.

### Put code where its role is obvious

**Standard:** Code and metadata belong in the module that owns them, and within a module the location should reveal the role. **Why:** Location is a signal readers rely on -- a factory sitting among test classes reads as a test that never runs. **Example:** New library metadata goes in the new library, not the host app; test utilities go in `test/utils/`, not beside real test classes.

### Don't land unused code

**Standard:** Delete classes, methods, and parameters nothing calls, and sweep the change for others; challenge speculative parameters no caller passes. **Why:** Unused code is unverified code that still costs maintenance and implies a contract that doesn't exist.

### Time-box workarounds explicitly

**Standard:** Take the minimal reversible workaround, state in the PR that it is temporary, and name the real fix as the immediate next priority. Prefer deferring a new dependency over baking one in to unblock. **Why:** An unlabelled workaround becomes permanent.
