---
name: crafting-hooks
description: >-
  Guides creation, review, debugging, and modification of Claude Code hooks in
  settings.json. Use when user asks to "create a hook", "add a hook", "debug a
  hook", "fix a hook", "review my hooks", "modify a hook", "set up notifications",
  "block tool use", "auto-approve", or works with hook configuration. Handles
  requirements interview, hook design, settings.json editing, and troubleshooting.
---

# Crafting Hooks

This skill guides the full lifecycle of Claude Code hooks — event-driven
automations configured in settings.json. It covers creation, review, debugging,
and modification.

## Mode Detection

Determine which mode to use based on user input and `$ARGUMENTS`:

**Create Mode** — if any of these are true:

- User says "create", "add", "new", "set up", or "make"
- User describes desired behavior without referencing an existing hook
- User asks "how do I" or "I want to" followed by automation behavior

**Review Mode** — if any of these are true:

- User says "review", "check", "audit", "list", or "show my hooks"
- User asks about current hook configuration

**Debug Mode** — if any of these are true:

- User says "debug", "fix", "not working", "not firing", "broken", or "infinite loop"
- User describes a hook that misbehaves or doesn't trigger

**Modify Mode** — if any of these are true:

- User says "change", "modify", "update", "remove", or "delete"
- User references a specific existing hook to alter

If ambiguous, ask: "Would you like to create a new hook, review existing hooks, debug a problem, or modify a hook?"

---

## Create Mode

### Step 1: Requirements Interview

CRITICAL: Do NOT design or write any hook until requirements are fully understood.

Ask the user all of these questions in a single numbered list:

1. **What should happen?** Describe the behavior you want. (e.g., "notify me when Claude edits a file", "block writes to the production directory")
2. **When should it trigger?** Which lifecycle event? If unsure, describe the moment it should fire and I'll identify the right event. For browsing events, see [references/event-schema-reference.md](references/event-schema-reference.md).
3. **Scope**: Should this apply to all your projects (global), just this project (shared with team), or only for you in this project (local)?
   - Global: `~/.claude/settings.json`
   - Project: `.claude/settings.json` (committed to repo)
   - Local: `.claude/settings.local.json` (gitignored)
4. **Filtering**: Should it fire for all occurrences of that event, or only specific ones? (e.g., only for `Write` tool, only for `.env` files, only on `startup`)
5. **Action or observation?** Should the hook just observe and log (exit 0), or should it be able to block/modify behavior? (exit 2 to block, JSON output to modify)
6. **Hook type**: Which handler type?
   - Shell command (default) — runs a command, reads stdin, writes stdout
   - HTTP — POSTs event data to a URL
   - Prompt — asks an LLM model for a yes/no decision
   - Agent — spawns a subagent that can use tools to verify conditions

After receiving answers:

- Summarize your understanding in 2-3 sentences
- Ask: "Does this capture what you need, or should I adjust anything?"
- Only proceed once confirmed

### Step 2: Design the Hook

Using the interview answers and [references/event-schema-reference.md](references/event-schema-reference.md):

1. **Identify the event**: Match the user's "when" to one of the 22 hook events
2. **Draft the matcher**: Determine the regex pattern for the event's matcher field. Use the narrowest match possible. If no filtering needed, omit the matcher
3. **Choose the handler type**: Based on question 6. For command hooks, draft the shell command. For scripts longer than one line, recommend a separate `.sh` file
4. **Determine decision behavior**: Based on question 5. Map to the correct exit code or JSON output format for the chosen event
5. **Check for anti-patterns**: Review [references/anti-patterns.md](references/anti-patterns.md) — especially infinite loops for Stop hooks, overly broad matchers for PermissionRequest hooks, and stray stdout
6. **Check for similar recipes**: See if [references/hook-recipes.md](references/hook-recipes.md) has a ready-made example similar to the user's request. Adapt rather than reinvent

Present the complete hook configuration as JSON:

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "pattern",
        "hooks": [
          {
            "type": "command",
            "command": "your-command-here"
          }
        ]
      }
    ]
  }
}
```

If the hook uses a script file, also present the script content and where to save it (e.g., `.claude/hooks/script-name.sh`).

Ask: "Does this look right? I'll add it to your settings file once confirmed."

### Step 3: Write to Settings File

1. Read the target settings file (based on scope from interview)
2. If the file exists, parse the existing JSON
3. If a `hooks` key exists, merge the new hook into it:
   - If the event key already exists, append to its array
   - If the event key doesn't exist, add it
4. If no `hooks` key exists, create it
5. Preserve ALL existing settings (permissions, autoMemoryEnabled, etc.)
6. Show the user the complete updated JSON before writing
7. Write the file
8. If a script file is needed, write it and run `chmod +x` on it

If the user has a `setup.sh` or sync mechanism, remind them: "Run `./setup.sh` to deploy to `~/.claude/` if you use one."

### Step 4: Verify

Suggest verification steps:

1. **Syntax check**: Confirm the JSON is valid and the hook appears under the correct event
2. **Manual test**: For command hooks, test the command standalone:
   ```
   echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | ./your-hook.sh
   echo $?
   ```
3. **Live test**: Describe what action would trigger the hook and what the expected behavior is
4. **Check /hooks**: Type `/hooks` in Claude Code to browse configured hooks and verify yours appears

---

## Review Mode

### Step 1: Read Existing Hooks

1. Read all three settings files that may contain hooks:
   - `~/.claude/settings.json` (global)
   - `.claude/settings.json` (project)
   - `.claude/settings.local.json` (local)
2. Parse the `hooks` key from each
3. Present a summary:

| #   | Event      | Matcher     | Type    | Command/URL/Prompt | Scope   |
| --- | ---------- | ----------- | ------- | ------------------ | ------- |
| 1   | PreToolUse | Edit\|Write | command | protect-files.sh   | project |
| ... |            |             |         |                    |         |

If no hooks are found, say so and offer to create one.

### Step 2: Analyze

For each hook, check against [references/anti-patterns.md](references/anti-patterns.md):

- **Safety**: Is the command safe? No infinite loops, no blocking I/O, no missing timeouts?
- **Matchers**: Are matchers correctly scoped? Not too broad (especially PermissionRequest), not too narrow?
- **Hook type**: Is the type appropriate? (command for simple tasks, prompt/agent for judgment calls)
- **Decision codes**: Are exit codes used correctly? (0=allow, 2=block, not 1)
- **Scope**: Is the hook in the right settings file for its purpose?
- **Paths**: Using `$CLAUDE_PROJECT_DIR` instead of hardcoded absolute paths?

### Step 3: Report

Present findings by severity:

**Critical** — Issues that would prevent the hook from working or cause harm:

- Infinite loop potential
- Overly broad PermissionRequest matchers
- Wrong exit codes

**Warning** — Issues that degrade quality:

- Hardcoded paths
- Missing timeouts on network calls
- Scope mismatch

**Suggestion** — Improvements:

- Could use a narrower matcher
- Consider async for fire-and-forget hooks
- Script could be more robust

For each Critical or Warning issue, provide the specific fix as JSON or script change.

---

## Debug Mode

### Step 1: Gather Symptoms

Ask the user:

1. Which hook is misbehaving? (describe the expected behavior if you can't name it)
2. What actually happens? (nothing fires, wrong behavior, error message, infinite loop)
3. When did it last work, if ever?

### Step 2: Systematic Diagnosis

Walk through this checklist in order. Stop at the first failure found:

1. **Hook exists?** Read the settings file and confirm the hook is present under the correct event key. Check all three settings files — the hook may be in a different scope than expected.

2. **Correct event?** Verify the event name matches when the behavior should trigger. Common confusions:
   - `PreToolUse` (before execution) vs `PostToolUse` (after execution)
   - `Stop` (Claude finishes) vs `SessionEnd` (session terminates)
   - `UserPromptSubmit` (before processing) vs `Stop` (after responding)
     See the confusion table in [references/anti-patterns.md](references/anti-patterns.md) under "Wrong Event Choice."

3. **Matcher matches?** If matchers are defined, verify the regex matches the actual input value. Test: tool names are PascalCase (`Bash`, not `bash`). MCP tools are `mcp__server__tool`. Check `/hooks` to see if the hook appears under the expected event.

4. **Command works standalone?** Run the hook command manually with sample JSON input:

   ```bash
   echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | ./your-hook.sh
   echo $?
   ```

   Check for: file permissions (`chmod +x`), missing shebang line, PATH issues, missing dependencies (`jq`, etc.), absolute path problems.

5. **Exit code correct?** If the hook should block, verify it exits with code 2 (not 1). Exit 1 = error (logged, action proceeds). Exit 2 = block. Run the command and check `echo $?`.

6. **Infinite loop?** If the hook fires repeatedly or Claude never stops:
   - For Stop hooks: check `stop_hook_active` field and exit 0 if true
   - For PostToolUse hooks: check if the hook's own action triggers the same event
   - Solution: add narrower matchers or guard conditions

7. **JSON output valid?** If the hook outputs JSON for decision control:
   - Verify it's valid JSON (no stray text before/after)
   - Check for shell profile pollution (`~/.zshrc` printing text)
   - Verify the JSON structure matches the event's expected format

8. **Scope conflict?** Check if a managed policy or higher-priority settings file overrides or conflicts with the hook. Check if `disableAllHooks: true` is set in any settings file.

### Step 3: Fix

1. Propose the specific fix based on diagnosis
2. Show the before/after diff
3. Apply after user confirmation

---

## Modify Mode

### Step 1: Identify the Hook

1. Read all settings files containing hooks
2. List hooks with index numbers (same table as Review Mode)
3. Ask: "Which hook do you want to modify? (by number or description)"

### Step 2: Determine Change

Ask what to change:

- **Matcher**: Add, remove, or adjust the regex pattern
- **Command/URL/Prompt**: Change what the hook does
- **Hook type**: Switch between command/http/prompt/agent
- **Event**: Move the hook to a different event
- **Scope**: Move between global/project/local settings files
- **Decision behavior**: Change from observe to block or vice versa
- **Delete**: Remove the hook entirely

### Step 3: Apply

1. Show the before/after JSON diff
2. Apply after user confirmation
3. If moving scope: remove from old settings file, add to new settings file (two file edits)
4. If deleting: remove the hook entry; if it was the last hook under that event, remove the event key; if it was the last event, remove the `hooks` key
5. Remind about `./setup.sh` sync if applicable

---

## Important Rules

These rules apply across all modes:

1. **Always read before writing**: Never write to a settings file without reading it first. Parse the existing JSON and merge changes.
2. **Preserve existing config**: Never overwrite the entire file. The settings file contains permissions, autoMemoryEnabled, and other keys that must be preserved.
3. **Show diffs**: Always show the user the exact JSON that will be written before writing.
4. **Use environment variables for paths**: Prefer `$CLAUDE_PROJECT_DIR` over absolute paths in hook commands.
5. **Test matchers mentally**: Before writing a matcher, ask: "Would this regex match X? Would it also match Y that we DON'T want?"
6. **Check for infinite loops**: Any hook that can trigger its own event is a potential loop. Add guards.
7. **Remind about sync**: If the user has `setup.sh` or a similar sync script, remind them to run it after changes.
8. **Consult references**: When unsure about an event's schema, matchers, or decision format, check [references/event-schema-reference.md](references/event-schema-reference.md). When looking for examples, check [references/hook-recipes.md](references/hook-recipes.md). When reviewing for issues, check [references/anti-patterns.md](references/anti-patterns.md).
