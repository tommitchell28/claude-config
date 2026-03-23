# Hook Anti-Patterns

Common mistakes when building Claude Code hooks and how to fix them.

## Table of Contents

- [Infinite Loop](#infinite-loop)
- [Overly Broad Matchers](#overly-broad-matchers)
- [Blocking the Session](#blocking-the-session)
- [Swallowed Errors](#swallowed-errors)
- [Stray Stdout](#stray-stdout)
- [Wrong Event Choice](#wrong-event-choice)
- [Scope Mismatch](#scope-mismatch)
- [Hardcoded Paths](#hardcoded-paths)
- [Missing JSON Merge](#missing-json-merge)
- [Untested Regex](#untested-regex)
- [Shell Profile Pollution](#shell-profile-pollution)

---

## Infinite Loop

**Problem**: Hook triggers an action that re-triggers the same hook.
**Example**: A `PostToolUse` hook on `Write` runs a formatter that writes a file, which fires `PostToolUse` again forever.
**Fix**: Narrow matchers to exclude the hook's own effects. For Stop hooks, check the `stop_hook_active` field and exit 0 if true:

```bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi
```

## Overly Broad Matchers

**Problem**: Empty matcher or permissive regex fires on every occurrence of the event.
**Example**: A `PermissionRequest` hook with `matcher: ""` auto-approves every permission prompt, including file writes and destructive commands.
**Fix**: Always use the narrowest matcher possible. Match specific tool names (`Bash`, `Edit|Write`) rather than wildcards. For PermissionRequest, match the exact tool name you want to auto-approve.

## Blocking the Session

**Problem**: Hook command hangs (network call with no timeout, waiting for interactive input, blocking I/O).
**Example**: A hook runs `curl https://api.example.com/notify` but the server is down. Claude waits 10 minutes (default timeout).
**Fix**: Add timeouts to network calls: `timeout 5 curl ...`. Never use interactive commands (prompts, editors). Set a reasonable `timeout` field on the hook handler. Use `"async": true` for fire-and-forget operations.

## Swallowed Errors

**Problem**: Hook command fails with exit code 1, which is treated as an error (logged but action proceeds). User thinks the hook blocked the action, but it didn't.
**Fix**: Use exit 2 explicitly to block. Exit 1 or other non-zero codes (except 2) are treated as hook errors — the action continues and stderr is only visible in verbose mode (`Ctrl+O`).

| Exit Code | Meaning                                               |
| :-------- | :---------------------------------------------------- |
| 0         | Allow — action proceeds                               |
| 2         | Block — action is prevented, stderr → Claude feedback |
| Other     | Error — action proceeds, stderr logged                |

## Stray Stdout

**Problem**: Hook command prints debug output or warnings to stdout, which gets parsed as JSON. Claude Code fails to parse the mixed output.
**Example**: A hook prints `"Processing..."` before its JSON output. Claude Code sees `Processing...{"decision": "block"}` and fails.
**Fix**: Redirect all non-output text to stderr (`>&2`). Only print valid JSON to stdout when you need decision control. Shell profiles (`~/.zshrc`, `~/.bashrc`) with unconditional `echo` statements also cause this — wrap them in interactive checks:

```bash
# In ~/.zshrc or ~/.bashrc
if [[ $- == *i* ]]; then
  echo "Shell ready"
fi
```

## Wrong Event Choice

**Problem**: Using the wrong event for the desired behavior.

| If you want to...           | Use                              | NOT                                                           |
| :-------------------------- | :------------------------------- | :------------------------------------------------------------ |
| Block a tool before it runs | `PreToolUse`                     | `PostToolUse` (too late)                                      |
| React after a tool finishes | `PostToolUse`                    | `PreToolUse`                                                  |
| Auto-approve a permission   | `PermissionRequest`              | `PreToolUse` (different decision format)                      |
| Block before Claude stops   | `Stop`                           | `SessionEnd` (can't block termination)                        |
| Run on every new session    | `SessionStart` matcher `startup` | `SessionStart` with no matcher (also fires on resume/compact) |
| Re-inject after compaction  | `SessionStart` matcher `compact` | `PostCompact` (no context injection)                          |

**Fix**: Check [event-schema-reference.md](event-schema-reference.md) for when each event fires and what it can control.

## Scope Mismatch

**Problem**: Hook is in the wrong settings file for its purpose.

| If the hook is...                                 | Put it in                                  |
| :------------------------------------------------ | :----------------------------------------- |
| Personal preference (notifications, editor prefs) | `~/.claude/settings.json` (global)         |
| Project standard (formatting, protected files)    | `.claude/settings.json` (committed)        |
| Personal + project-specific (local overrides)     | `.claude/settings.local.json` (gitignored) |

**Fix**: Move the hook to the correct settings file. If a hook is in project settings but only makes sense for you, move it to local or global settings.

## Hardcoded Paths

**Problem**: Hook command uses absolute paths that break on other machines or when the project moves.
**Example**: `"command": "/Users/alice/project/.claude/hooks/lint.sh"` won't work for Bob.
**Fix**: Use `$CLAUDE_PROJECT_DIR` for project-relative paths: `"$CLAUDE_PROJECT_DIR"/.claude/hooks/lint.sh`. For plugin scripts, use `${CLAUDE_PLUGIN_ROOT}`.

## Missing JSON Merge

**Problem**: When adding a hook, the entire settings.json is overwritten, deleting existing permissions, hooks, and other config.
**Fix**: Always read the existing settings file first, parse it, merge the new hook under the correct event key, and write back. Never replace the entire file. If a `hooks` key already exists, add to it. If the event key exists, append to its array.

## Untested Regex

**Problem**: Matcher regex doesn't match what the user expects. Regex is case-sensitive and matches against specific fields.
**Example**: Matcher `"bash"` doesn't match tool name `"Bash"` (case-sensitive).
**Fix**: Test matchers against actual values. Tool names are PascalCase (`Bash`, `Edit`, `Write`, `Read`). MCP tools use `mcp__server__tool` format. Use `/hooks` menu to verify hooks appear under the correct event.

## Shell Profile Pollution

**Problem**: User's `~/.zshrc` or `~/.bashrc` prints text unconditionally. Hook commands inherit this shell, so the profile output prepends to the hook's stdout, breaking JSON parsing.
**Fix**: Wrap echo/print statements in shell profiles with an interactive check:

```bash
if [[ $- == *i* ]]; then
  echo "Welcome message"
fi
```

Hooks run in non-interactive shells, so the `$-` check prevents profile output from contaminating hook output.
