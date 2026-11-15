---
name: mermaid-diagrams
description: Tom's standard for writing Mermaid diagrams — the right diagram type, a fixed node shape per component type, tiers grouped in subgraphs, labelled edges, and syntax that renders first time in VSCode and GitHub. Use whenever you write or edit a Mermaid diagram, in any file or in chat — "draw/create/generate a diagram", "mermaid", an architecture, infrastructure, system, flow, data-flow or sequence diagram, or a design doc or README that would carry one — even when the word "mermaid" is never said. NOT for colours, themes, `%%{init}%%` blocks or `classDef` fills (Tom handles those), and NOT for exporting diagrams to images.
---

# Mermaid Diagrams (Tom)

A diagram should show the real mechanism at a glance and render first time in every viewer Tom uses.

## Pick the Type

| Type                | Fits                                                             |
| ------------------- | ---------------------------------------------------------------- |
| `flowchart`         | components and the calls between them; infra; decision flows     |
| `sequenceDiagram`   | ordered interactions over time between a few parties             |
| `erDiagram`         | data models and their relationships                              |
| `stateDiagram-v2`   | lifecycles — the states one thing moves through                  |
| `architecture-beta` | only when asked; see the optional tier in `references/shapes.md` |

If the reader's question is "what talks to what", it is a flowchart; if it is "what happens in which order", it is a sequence.

## Flowcharts and Infra

- **Shapes carry meaning.** Give each component type its fixed shape from `references/shapes.md` — a database is always a cylinder, a queue always the asymmetric flag — so the reader learns the vocabulary once.
- **A diamond is a decision only.** A load balancer, gateway or router is a service rectangle; a diamond implies a yes/no branch the reader will look for.
- **Group tiers in subgraphs** (Client, Edge, Services, Data, External) so the layout reads as layers. The grouping is for structure; leave fills and colours out.
- **Arrows follow the call or data direction** — from caller to callee, or producer to consumer. A two-way arrow hides which side starts the exchange.
- **Label edges with what flows**: protocol, event or payload (`HTTPS`, `order.created`, `SQL`). Leave an edge unlabelled only when the label adds nothing.
- **Order elements logically** — (a) before (b), left to right, top to bottom.
- **Mermaid lays sibling subgraphs out in reverse declaration order**, so declare the one you want on the right (or bottom) first.

## Sequence Diagrams

- `actor` for people, `participant` for systems.
- `alt`/`else` for branches, `opt` for an optional step.
- Activation bars (`+`/`-`) only where they show something the arrows don't, such as a call that stays open across others.

## Syntax That Breaks Rendering

- **Quote labels containing `()`, `[]`, `{}`, `:` or `#`**: `api["Orders API (v2)"]`.
  - Unquoted, these characters are parsed as shape or link syntax.
- **Never use lowercase `end` as a node id or bare label.**
  - The parser reads it as the `end` keyword and the diagram breaks.
  - Use `End`, `done` or a quoted label instead.
- **An id starting with `o` or `x` straight after a link becomes a circle or cross edge.**
  - `A---ops` draws a circle-ended link to a node called `ps`.
  - Add a space (`A --- ops`) or capitalise.
- Keep node ids short and meaningful (`orders`, `ordersDb`) and put the display text in the label.

## Portable First

Write classic `flowchart` and `sequenceDiagram` syntax by default — it renders in every target viewer:

- VSCode markdown preview (built-in Mermaid support, currently Mermaid 11.x).
- GitHub, whose Mermaid version lags.

Use the optional tier — named `@{ shape: … }` shapes, `architecture-beta`, icons — only when Tom asks for it, and say which renderer version it needs.

## References

Read `references/shapes.md` before drawing any flowchart or infra diagram. It holds:

- the component→shape table;
- one infra and one sequence example in portable syntax;
- the optional, renderer-dependent tier.
