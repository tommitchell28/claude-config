---
name: delegating-work
description: How to delegate to subagents so the main session's context is spent on decisions - what a brief contains, which model does which kind of work, what a report holds, how to run several agents. Use before briefing a subagent to build, verify or gather facts, when acting as an orchestrator on long work, or when writing a plan or skill that briefs subagents.
---

# Delegating Work

The main session is the **orchestrator**: it reads the requirements, splits the work, writes each brief, judges each report and makes the decisions. Subagents read, build and check. The orchestrator's context is what runs out, so it holds conclusions and leaves file contents with the subagents.

## The Orchestrator's Own Work

- **Reads the requirements:** the issue or request, and the documents it names.
- **Asks for conclusions:** a subagent reads the code, the diff or the long output and reports what the orchestrator needs in order to decide.
- **Looks at evidence only to decide:** a screenshot, a failing output or one function, when:
  - a subagent proposes departing from a default;
  - two options are close;
  - a verifier raises a doubt.
- **Reads in full what sets rules for later work:** a design document or a set of standards a subagent drafted. The orchestrator answers for it.
- **Works directly when that is cheaper:** a handful of tool calls, or a lookup whose target is known, costs less than a brief and a report.

## Model by Kind of Work

Pass `model` on every Agent call. An agent without one inherits the orchestrator's model.

| Work                                                                                                            | Model    |
| --------------------------------------------------------------------------------------------------------------- | -------- |
| Building, design choices, fixing what checks, verification or review find, writing documents that set rules     | `opus`   |
| Scouting, fact gathering, running checks and reporting failures, captures, independent verification, git chores | `sonnet` |

- **Fable is for the orchestrator.** A subagent runs on Fable only when the user asks for it.
- **A `fork` inherits the orchestrator's model and whole context.** Use one for a short side task only.

## Agent Type

- **`general-purpose` for any agent that writes, commits or must follow the repo's rules.** It is given the same `CLAUDE.md` files as the orchestrator.
- **`Explore` for locating code.** It cannot edit files and starts with no `CLAUDE.md`, so its brief states any rule it needs, such as a privacy rule.

## The Brief

A subagent knows the brief and the `CLAUDE.md` files, and nothing else from the conversation. A brief states:

- **The goal and where it fits:** the issue, this agent's part of it, and what is already done or ruled out.
- **Where to start:** file paths and document sections by name. Point at them; the agent reads them itself.
- **What done means:** a condition the agent can check, such as "every acceptance criterion measured, with the number".
- **Its limits:** what to leave alone, whether it may commit, whether it is read-only.
- **The two or three rules that matter most for this job,** restated even though `CLAUDE.md` has them.
  - An agent that commits is told the commit rules, and that a hook failure means stop and report.
  - The remaining repo rules are left to `CLAUDE.md`.
- **The report wanted:** its shape and a word limit, as below.
- **For a reviewer or verifier, the work and the requirement only.** An agent handed a conclusion returns it confirmed. Tell a verifier to be sceptical and to measure.

## The Report

- **Ask for:**
  - what changed: files, one line each;
  - what was decided and why;
  - what failed or was left undone;
  - open questions;
  - anything noticed outside the task.
- **Set a limit,** 300 to 400 words, with no file contents and no diffs.
- **A report is a claim:** a mistake arrives in the same confident tone as a finding.
- **Reports come back as text.** A subagent is told to return findings and not to write report files, so the orchestrator writes any file that has to exist.

## Running Several Agents

- **One editing agent at a time in a working tree:** they share the tree, and commit hooks stash it.
- **Read-only agents run in parallel,** launched in one message.
- **Scout before building.** A read-only pass maps the files and records the state before any edit: captures, test counts, whatever the work will later be compared against.
- **A builder commits as it goes,** in small commits, when commits are allowed, and lists them in its report.
- **A failure goes back to the agent that built it,** by SendMessage, while it still holds the context. A new slice gets a new agent.
- **Check in on an agent that has been silent for 15 minutes.** A background agent reports only when it stops, so a stuck one looks the same as a busy one.
  - Keep a 15-minute timer running while any agent is out: a background `sleep 900`, which wakes the orchestrator when it ends. Start another each time one fires.
  - When it fires, look for progress first: new commits, or changed files in the agent's tree.
  - An agent with no progress gets a SendMessage asking where it is. A read-only agent that is still researching is told to stop and report what it has.
  - A brief for research or review states a time or lookup budget, so the agent stops without being asked.
- **Verify independently, and again after every round of fixes.** An agent that did not do the work measures it against the requirement. A fix made for a review finding can introduce a new fault, and only a second measurement finds it.

## The Notes File

Keep one notes file in the scratchpad and give its path in every builder's brief, as working notes to append to. Each builder appends its decisions, departures from defaults, and gaps. Where a builder's report shows it did not, append them from the report yourself. The pull request body and the closing message are written from this file, since the orchestrator's own memory of early work may have been compacted away.
