---
name: orchestrate-ticket
description: Run one issue unattended as an orchestrator, from reading it to an open pull request. Subagents build and verify; the main session briefs and judges. Stops at the pull request.
argument-hint: "[issue-number]"
disable-model-invocation: true
---

# orchestrate-ticket

Take issue `$ARGUMENTS` from reading it to an open pull request, **unattended**, as an **orchestrator**.

- **Unattended:** ask the user nothing.
  - Make each decision the user would have been asked for.
  - Record it in the notes file, and show it in the pull request.
- **The repo's rules win.**
  - This skill fixes the sequence.
  - Checks, review tier and what a pull request shows come from the repo's `CLAUDE.md` files and the issue.
  - The defaults below apply where the repo is silent.
- **One run per checkout.** A second run at the same time needs its own worktree, since both switch branches and commit.
- **Stop early only for a deliberate blocker:** a hook or guardrail that cannot be satisfied, or access that was withheld. Say what is done and what is not.

## Steps

### 1. Load `delegating-work`

It sets how every subagent below is briefed, which model it runs on, and what it reports.

### 2. Read the requirements

Read the issue yourself (`gh issue view`, or as the repo's issue tracker document says), and every document it names.

- **If the working tree has uncommitted changes, stop** and report them. They are someone's work.
- **Create a branch** off the up-to-date default branch, named for the issue.
- **Start the notes file** with the acceptance criteria.

Done when every acceptance criterion is listed with how it will be measured.

### 3. Scout

Launch read-only agents in parallel, before any edit:

- **A map of the code** for each area the issue touches.
- **The state before the change,** in whatever form the issue's checks will compare against, kept where no later step writes.
- **Open issues** that already cover something this run might raise.

Done when the map, the state before and the list of open issues are in the notes file.

### 4. Split

Cut the work into slices from the issue and the scouts' reports. One builder can finish and report on one slice. Shared pieces come first.

Done when the notes file lists the slices in order, each with the acceptance criteria it carries.

### 5. Build

Run the slices in order, one builder at a time. Judge each report before starting the next slice:

- Does it meet the acceptance criteria its slice carries?
- Does each departure from a default come with evidence you have looked at?

Done when every slice is built, its report judged, and its commits are on the branch.

### 6. Verify independently

An agent that built nothing measures every acceptance criterion and reports pass or fail with the measurement. A failure goes back to its builder, and the verifier measures again. After two rounds of fixing, a criterion that still fails is recorded as a gap.

Done when every criterion passes, or is in the notes file as a gap with its reason.

### 7. Run the repo's checks

Have an agent run the repo's full check command and report the failures; a builder fixes them. Where the repo names no single command, run its tests, linter and type check.

Done when the checks pass, or each remaining failure is shown to fail on the default branch too and is raised as out of scope.

### 8. Write the lessons down

A lesson is anything this run learned that the next run would need: a tool's quirk, a rule that was missing, a step that failed and how it was worked round.

- **A lesson about the repo or its tools** goes into the document that describes that tool or step, where the next reader doing it would meet it, committed on this branch. These edits are part of the ticket, so the repo's rule for out-of-scope findings leaves them alone.
- **A lesson about this skill or `delegating-work`** goes under a "Lessons for the skills" heading in the pull request body and the closing message. The skills themselves are the user's to change.
- **A lesson learned later,** during the review, is written down the same way before the pull request opens.

Done when each lesson is committed, or listed for the pull request body.

### 9. Review

Run the `reviewing-code` skill with `unattended`, at the tier the repo's rules give this change (`standard` where the repo has no tiers). Skip this step where the repo's rules say the change needs no review. Run the review once.

- **Supply the issue.** No pull request exists yet, so the review detects no requirements. At its requirements step, pass issue `$ARGUMENTS` to `requirements-context.sh append` with `--issue`, and say in the pull request that the issue was supplied.
- **Fix each finding,** by delegation, unless you can give a concrete reason it is wrong or out of scope.
- **Keep a list** of the findings you dispute, each with that reason, and of any fix that changes scope or behaviour.
- **Repeat steps 6 and 7** for whatever the fixes touched.

Done when every finding is fixed or on the disputed list, and steps 6 and 7 pass again.

### 10. Open the pull request

Use the `creating-pull-requests` skill. Give it issue `$ARGUMENTS` with the closing keyword `Closes`, and tell it the run is unattended, so it asks nothing. Write the body from the notes file, with these as sections after its Summary:

- **What the issue or the repo's documents say a pull request shows.**
- **Each decision made in the user's place,** with where it is recorded.
- **Gaps:** criteria not met, and cases no rule covered.
- **Disputed review findings,** each with the reason.
- **Out-of-scope findings** and the issue raised for each.
- **Lessons for the skills.**

Done when `gh pr view` shows the pull request with each item above in its body.

### 11. Stop

Merging is the user's. The closing message gives:

- the pull request link;
- the decisions that departed from the issue's defaults or from earlier decisions;
- the issues opened;
- the lessons for the skills;
- anything left undone.

## Throughout

- **Out-of-scope findings are raised, and left unfixed.**
  - Follow the repo's rule for raising them; where it has none, list them in the pull request.
  - Check the scouts' list of open issues first, and add to an existing issue where one covers the finding.
- **Hooks run on every commit.** When a hook changes files, stage them and commit again.

## When Something Goes Wrong

| Situation                                                    | What to do                                                                                        |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| No issue number was given, no issue matches, or two match    | Stop and say so                                                                                   |
| The review refuses to run on a dirty tree                    | The tree was clean at step 2, so the files are this run's: commit or remove them, and re-run      |
| A shared tool is held by another session (a browser profile) | Work round it, and record the way round as a lesson in step 8                                     |
| A subagent broke a rule its brief stated                     | Undo what can be undone, and name it in the pull request                                          |
| A repo document says to ask the user                         | Take the option that leaves the user's files and processes untouched, and record it as a decision |
