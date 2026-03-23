# Writing Effective Descriptions

The `description` field is how Claude decides whether to load your skill. Get this right.

## Formula

```
[What it does] + [When to use it] + [Key capabilities]
```

## Rules

- Write in third person ("Processes PDF files..." not "I help you process PDFs")
- Under 1024 characters
- No XML angle brackets (< >)
- Include specific phrases users would actually say
- Mention relevant file types if applicable

## Good Examples

```yaml
# Specific, includes trigger phrases
description: >-
  Analyzes Figma design files and generates developer handoff documentation.
  Use when user uploads .fig files, asks for "design specs", "component
  documentation", or "design-to-code handoff".
```

```yaml
# Includes trigger phrases and scope
description: >-
  Manages Linear project workflows including sprint planning, task creation,
  and status tracking. Use when user mentions "sprint", "Linear tasks",
  "project planning", or asks to "create tickets".
```

```yaml
# Clear value proposition
description: >-
  End-to-end customer onboarding workflow for PayFlow. Handles account
  creation, payment setup, and subscription management. Use when user says
  "onboard new customer", "set up subscription", or "create PayFlow account".
```

## Bad Examples

```yaml
# Too vague -- no trigger phrases, no specifics
description: Helps with projects.
```

```yaml
# Missing triggers -- says what but not when
description: Creates sophisticated multi-page documentation systems.
```

```yaml
# Too technical, no user triggers
description: Implements the Project entity model with hierarchical relationships.
```

## Negative Triggers

When your skill has a narrow scope, add negative triggers to prevent over-triggering:

```yaml
description: >-
  Advanced data analysis for CSV files. Use for statistical modeling,
  regression, clustering. Do NOT use for simple data exploration
  (use data-viz skill instead).
```

## Testing Your Description

Ask Claude: "When would you use the [skill name] skill?"

Claude will quote the description back. If the answer doesn't match your intent, revise. Adjust based on:

- **Under-triggering**: Add more detail, synonyms, and trigger phrases
- **Over-triggering**: Be more specific, add negative triggers, clarify scope
