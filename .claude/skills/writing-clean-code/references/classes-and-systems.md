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

Rule of thumb: describe a class in about 25 words without using `and`, `or`, or `but`. A description that needs a conjunction is describing several classes.

```typescript
// Bad - "creates users and sends email and generates reports and validates passwords"
class UserManager {
  createUser() { ... }
  sendEmail() { ... }
  generateReport() { ... }
  validatePassword() { ... }
}

// Good - each class is described without a conjunction
class UserRepository {
  create(user: User) { ... }
  delete(id: string) { ... }
}
class EmailService { send(to: string, template: string) { ... } }
class PasswordValidator { validate(password: string): boolean { ... } }
```

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

```typescript
// Bad - the service is tied to one concrete database
class OrderService {
  private mysqlDatabase = new MySQLDatabase();
  save(order: Order) {
    this.mysqlDatabase.insert(order);
  }
}

// Good - both sides depend on the interface
interface Database {
  insert(data: unknown): void;
}
class OrderService {
  constructor(private database: Database) {}
  save(order: Order) {
    this.database.insert(order);
  }
}
const service = new OrderService(new MySQLDatabase());
const testService = new OrderService(new InMemoryDatabase());
```

## System Design Rules

### Separate Construction from Use

Separate startup (object construction, dependency wiring) from runtime logic:

1. Move all construction to `main` (or a factory, or a container)
2. Design the application assuming dependencies are wired up
3. Have `main` pass all dependencies to the application

```typescript
// Bad - construction mixed into the logic
class Application {
  run() {
    const config = new Config();
    const database = new Database(config.dbUrl);
    const service = new UserService(database);
    service.createUser(userData);
  }
}

// Good - construction at the entry point
// main.ts
const database = new Database(new Config().dbUrl);
const app = new Application(new UserService(database));
app.run();

// Application.ts
class Application {
  constructor(private userService: UserService) {}
  run() {
    this.userService.createUser(userData);
  }
}
```

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

Pass dependencies into a class rather than constructing them inside it. This is the practical mechanism behind the Dependency Inversion Principle and achieves Inversion of Control (IoC).

Benefits:

- Loose coupling: the class does not know which concrete collaborator it has
- Easy testing: inject mocks or in-memory implementations
- Flexible configuration: swap implementations at the entry point without touching the class

```typescript
// Bad - constructs its own collaborators
class ReportGenerator {
  private logger = new FileLogger();
  private dataSource = new DatabaseConnection();
  generate() { ... }
}

// Good - collaborators injected through the constructor
interface Logger {
  log(message: string): void;
}

class ReportGenerator {
  constructor(private logger: Logger, private dataSource: DataSource) {}
  generate() { ... }
}

const generator = new ReportGenerator(new FileLogger(), new DatabaseConnection());
const testGenerator = new ReportGenerator(new MockLogger(), new MockDataSource());
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
