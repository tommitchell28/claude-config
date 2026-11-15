---
name: architecture-design
description: Layer generality and boundary discipline for a change spanning layers (entrypoint → service → data). Use whenever code crosses layers — a new endpoint calling a service, a service calling a repository or client, a flag or parameter threaded down more than one layer, a shared module gaining a caller-specific branch — or when reviewing such a change, even when nobody says "architecture" or "boundaries"; and when deciding where logic should live or a lower layer risks being shaped around one caller's concern ("cross-domain context pollution"). NOT for picking a system-wide architecture style or infra topology.
---

# Architecture Design

**Core rule: the lower a component sits, the more general it must stay.** A change enters at an entrypoint and flows down to data. Each layer down serves more callers, so must know less about any one of them.

## Layer generality

| Layer      | Serves              |
| ---------- | ------------------- |
| Entrypoint | one use case        |
| Service    | several entrypoints |
| Data       | every service       |

A component built to serve caller Y must not be shaped so it precludes serving caller Z.

## The anti-pattern: cross-domain context pollution

- A caller's context — its use case, vocabulary, edge cases — leaks into a layer whose world shouldn't hold it.
- Code still compiles and the feature still works, so nothing flags it.
- But the boundary is broken: the next caller can't reuse the layer, or inherits the first caller's baggage.
- AI-assisted dev invites it — the whole slice sits in context at once, so threading the caller's concern straight down is frictionless.

## Tells — a boundary break until proven otherwise

- Service parameter named for one caller (`isFromAdminPage`), not in the service's own terms.
- Data method encoding an entrypoint's use case — only makes sense if you know which screen called it.
- Lower layer importing an upper layer's types (a service importing a controller's request DTO).
- A flag threaded down just so a deep layer behaves differently for one caller.
- A general layer's tests that only make sense via the one feature that prompted them.

## Also check

- **Dependency direction** — deps point toward the general; a lower layer never imports an upper one's types. Wrong-way import = broken boundary.
- **Cohesion vs coupling** — threading a caller's concern down raises coupling and drops cohesion at once.
- **Abstraction fit** — right generality, not most. Under-general = one caller baked in; over-general = params for callers that don't exist (gold-plating).
- **Placement** — put each concern at the altitude that owns it; caller-specific stays up top, genuinely shared descends.

## Future-consumers test

Barometer: _realistically, what other consumers might this serve, and how well would this design serve them?_

- Several, each having to work around this one caller's shape → too caller-specific; fix now, while it's cheap.
- Only ever this caller, plausibly → a tight, specific design is correct; don't abstract for ghosts.
- A known-upcoming caller (on the roadmap) → design for it now, and name it so the generality is justified.

## Applying it

- Map the layers the change touches before writing any of them.
- Name each lower layer in its own terms — can't name a service method without naming the screen that calls it? Responsibility is misplaced.
- Trace each downward call: does this layer now know something about its caller it shouldn't?
- State any break concretely — the leaking concern, the layer, the consequence (which future caller it blocks). A data layer importing entrypoint types can be a blocker.
- Ground it or drop it — "feels coupled" is not a finding.
