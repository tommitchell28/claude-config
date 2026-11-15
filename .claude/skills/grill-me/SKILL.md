---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time, using the `AskUserQuestion` tool for each question so the user can select from structured options. Always include your recommended answer as the first option, labelled with "(Recommended)". Provide 2-4 distinct options per question; the tool automatically offers an "Other" escape hatch for free-form answers.

If a question can be answered by exploring the codebase, explore the codebase instead.
