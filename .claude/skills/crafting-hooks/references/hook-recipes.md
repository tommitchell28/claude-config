# Hook Recipes

Ready-to-use hook configurations. Copy the JSON block into your settings file and adjust as needed.

## Table of Contents

- [Notification Hooks](#notification-hooks)
  - [Desktop notification when Claude needs input](#desktop-notification-when-claude-needs-input)
  - [Desktop notification on errors](#desktop-notification-on-errors)
- [Safety Hooks](#safety-hooks)
  - [Block edits to protected files](#block-edits-to-protected-files)
  - [Block destructive shell commands](#block-destructive-shell-commands)
  - [Auto-approve ExitPlanMode](#auto-approve-exitplanmode)
- [Automation Hooks](#automation-hooks)
  - [Auto-format with Prettier after edits](#auto-format-with-prettier-after-edits)
  - [Re-inject context after compaction](#re-inject-context-after-compaction)
  - [Inject project context on session start](#inject-project-context-on-session-start)
- [Audit Hooks](#audit-hooks)
  - [Log all Bash commands](#log-all-bash-commands)
  - [Audit configuration changes](#audit-configuration-changes)
- [LLM Hooks](#llm-hooks)
  - [Prompt-based completion check](#prompt-based-completion-check)
  - [Agent-based test verification](#agent-based-test-verification)
- [HTTP Hooks](#http-hooks)
  - [POST tool use to logging service](#post-tool-use-to-logging-service)

---

## Notification Hooks

### Desktop notification when Claude needs input

Fires when Claude is waiting for your input or permission approval. Uses Linux `notify-send`.

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code' 'Claude Code needs your attention'"
          }
        ]
      }
    ]
  }
}
```

macOS alternative: replace command with `osascript -e 'display notification "Claude Code needs your attention" with title "Claude Code"'`

### Desktop notification on errors

Fires when a turn ends due to an API error (rate limit, auth failure, etc.).

```json
{
  "hooks": {
    "StopFailure": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '\"Claude Code error: \" + .error' | xargs notify-send 'Claude Code Error'"
          }
        ]
      }
    ]
  }
}
```

---

## Safety Hooks

### Block edits to protected files

Prevents Claude from modifying `.env`, lock files, or `.git/` contents. Uses a separate script for maintainability.

**Script** (save to `.claude/hooks/protect-files.sh`, then `chmod +x`):

```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

PROTECTED_PATTERNS=(".env" "package-lock.json" ".git/")

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH matches protected pattern '$pattern'" >&2
    exit 2
  fi
done

exit 0
```

**Hook config**:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-files.sh"
          }
        ]
      }
    ]
  }
}
```

### Block destructive shell commands

Blocks `rm -rf`, `DROP TABLE`, and other destructive patterns before they execute.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.command' | grep -qiE '(rm\\s+-rf\\s+/|DROP\\s+TABLE|mkfs|dd\\s+if=)' && { echo 'Blocked: destructive command detected' >&2; exit 2; } || exit 0"
          }
        ]
      }
    ]
  }
}
```

### Auto-approve ExitPlanMode

Skips the permission dialog when Claude exits plan mode, so you aren't prompted every time.

```json
{
  "hooks": {
    "PermissionRequest": [
      {
        "matcher": "ExitPlanMode",
        "hooks": [
          {
            "type": "command",
            "command": "echo '{\"hookSpecificOutput\": {\"hookEventName\": \"PermissionRequest\", \"decision\": {\"behavior\": \"allow\"}}}'"
          }
        ]
      }
    ]
  }
}
```

Keep matchers narrow. Matching `.*` or `""` on PermissionRequest would auto-approve everything.

---

## Automation Hooks

### Auto-format with Prettier after edits

Runs Prettier on every file Claude edits or creates.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

The `|| true` prevents formatter errors from disrupting Claude's flow.

### Re-inject context after compaction

When context compaction drops important details, re-inject them. Fires after every auto or manual compaction.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Reminder: use Bun, not npm. Run bun test before committing. Current sprint: auth refactor.'"
          }
        ]
      }
    ]
  }
}
```

Stdout is injected into Claude's context. Replace the `echo` with any command that produces dynamic output (e.g., `git log --oneline -5`).

### Inject project context on session start

Add project-specific context at the beginning of every new session.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "echo \"Project: $(basename $CLAUDE_PROJECT_DIR). Branch: $(git -C $CLAUDE_PROJECT_DIR branch --show-current). Last commit: $(git -C $CLAUDE_PROJECT_DIR log --oneline -1)\""
          }
        ]
      }
    ]
  }
}
```

---

## Audit Hooks

### Log all Bash commands

Appends every Bash command Claude runs to a log file.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.command' >> ~/.claude/command-log.txt"
          }
        ]
      }
    ]
  }
}
```

### Audit configuration changes

Logs when any settings or skills file changes during a session.

```json
{
  "hooks": {
    "ConfigChange": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "jq -c '{timestamp: now | todate, source: .source, file: .file_path}' >> ~/claude-config-audit.log"
          }
        ]
      }
    ]
  }
}
```

---

## LLM Hooks

### Prompt-based completion check

Asks a fast model whether all tasks are complete before letting Claude stop. If not, Claude continues working.

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if all tasks are complete. If not, respond with {\"ok\": false, \"reason\": \"what remains to be done\"}."
          }
        ]
      }
    ]
  }
}
```

IMPORTANT: the Stop event has no matcher. Check `stop_hook_active` in command hooks to avoid infinite loops (prompt/agent hooks handle this automatically).

### Agent-based test verification

Spawns a subagent to run tests and verify they pass before Claude stops.

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify that all unit tests pass. Run the test suite and check the results. $ARGUMENTS",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

Use `type: "prompt"` when the hook input alone is enough to decide. Use `type: "agent"` when you need to inspect files or run commands.

---

## HTTP Hooks

### POST tool use to logging service

Sends every tool use event to an HTTP endpoint for external logging.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "http",
            "url": "http://localhost:8080/hooks/tool-use",
            "headers": {
              "Authorization": "Bearer $MY_TOKEN"
            },
            "allowedEnvVars": ["MY_TOKEN"]
          }
        ]
      }
    ]
  }
}
```

Header values support `$VAR_NAME` interpolation, but only for variables listed in `allowedEnvVars`. The endpoint receives the same JSON a command hook would get on stdin. Return a 2xx response with JSON body for decision control.
