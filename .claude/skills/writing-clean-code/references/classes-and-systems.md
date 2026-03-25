# Classes, Objects, and Systems

## Contents

- [Objects vs Data Structures](#objects-vs-data-structures)
- [Class Rules](#class-rules)
- [System Design Rules](#system-design-rules)
- [Boundaries](#boundaries)

## Objects vs Data Structures

**Objects**: Hide data behind abstractions, expose functions that operate on that data.

**Data Structures**: Expose data, have no meaningful functions.

### Law of Demeter

A piece of code should not know about the internals of the objects it uses:

- Each unit should only have limited knowledge about closely-related units
- Only talk to immediate friends, not strangers

```javascript
// Bad - reaching through objects
class Bank {
  transferMoney(customer, amount) {
    customer.getWallet().debit(amount);
  }
}

// Good - tell, don't ask
class Bank {
  transferMoney(customer, amount) {
    customer.transferMoney(amount);
  }
}
```

The Law of Demeter does not apply when accessing data structures, as their data is meant to be exposed.

### Data Transfer Objects (DTOs)

DTOs are data structures with public properties and no functions. Used for serializing object state for communication (e.g., over a network).

## Class Rules

### Organisation

Top to bottom:

1. Public static constants
2. Private static variables
3. Private instance variables
4. Public methods
5. Private methods

### No Public Instance Variables

Reasons:

- Loss of control over how values change
- Breaks encapsulation
- Creates tight coupling

### Small

Small in responsibilities, not just lines of code.

### Clear Name

The name should clearly indicate responsibilities. Avoid vague names like `Manager` or `Processor`.

Rule of thumb: describe a class in about 25 words without using `if`, `and`, `or`, or `but`.

### Single Responsibility Principle (SRP)

A class should have only one reason to change.

### High Cohesion

Methods should use most/all of a class's instance variables. Low cohesion indicates a class should be split.

### Open-Closed Principle (OCP)

Open for extension, closed for modification. New functionality should be added without modifying existing code.

### Dependency Inversion Principle (DIP)

High-level classes should not depend on low-level classes. Both should depend on abstractions (interfaces or abstract classes).

Benefits:

- Decoupling: swap implementations seamlessly
- Testability: mock dependencies easily

## System Design Rules

### Separate Construction from Use

Separate startup (object construction, dependency wiring) from runtime logic:

1. Move all construction to `main`
2. Design the application assuming dependencies are wired up
3. Have `main` pass all dependencies to the application

### Abstract Factory Pattern

Provides an interface for creating families of related objects without specifying concrete classes.

```java
// Abstract Factory
public interface GUIFactory {
    Button createButton();
    Checkbox createCheckbox();
}

// Concrete Factory
public class WindowsFactory implements GUIFactory {
    public Button createButton() {
        return new WindowsButton();
    }
    public Checkbox createCheckbox() {
        return new WindowsCheckbox();
    }
}

// Client Code - depends on abstractions only
public class Application {
    private GUIFactory factory;
    private Button button;

    public Application(GUIFactory factory) {
        this.factory = factory;
        this.button = factory.createButton();
    }

    public void render() {
        button.render();
    }
}
```

### Dependency Injection

Delegate object creation rather than constructing directly. Achieves Inversion of Control (IoC).

```typescript
// Bad - no DI, tightly coupled
class App {
  run() {
    console.log("App is running");
  }
}

// Good - DI via constructor
interface Logger {
  log(message: string): void;
}

class ConsoleLogger implements Logger {
  log(message: string) {
    console.log(message);
  }
}

class App {
  private logger: Logger;

  constructor(logger: Logger) {
    this.logger = logger;
  }

  run() {
    this.logger.log("App is running");
  }
}
```

## Boundaries

A boundary is where two different pieces of code meet: between applications, microservices, layers, or third-party code.

### Use Interfaces

- Abstracts away implementation complexity
- Enables loose coupling and easy swapping of implementations

### Use Generic Data

Data crossing a boundary should be in its simplest, most generic form.

### No Data Leaks

Data crossing a boundary must not reveal the underlying implementation.
