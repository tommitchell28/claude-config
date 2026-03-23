# Hook Event Schema Reference

Compact reference for all 22 Claude Code hook events. For each event: when it fires, what the matcher filters, key input fields, and decision control.

## Table of Contents

- [Hook Configuration Structure](#hook-configuration-structure)
- [Hook Types](#hook-types)
- [Event Reference](#event-reference)
  - [SessionStart](#sessionstart)
  - [UserPromptSubmit](#userpromptsubmit)
  - [PreToolUse](#pretooluse)
  - [PermissionRequest](#permissionrequest)
  - [PostToolUse](#posttooluse)
  - [PostToolUseFailure](#posttoolusefailure)
  - [Notification](#notification)
  - [SubagentStart](#subagentstart)
  - [SubagentStop](#subagentstop)
  - [Stop](#stop)
  - [StopFailure](#stopfailure)
  - [TeammateIdle](#teammateidle)
  - [TaskCompleted](#taskcompleted)
  - [InstructionsLoaded](#instructionsloaded)
  - [ConfigChange](#configchange)
  - [WorktreeCreate](#worktreecreate)
  - [WorktreeRemove](#worktreeremove)
  - [PreCompact](#precompact)
  - [PostCompact](#postcompact)
  - [Elicitation](#elicitation)
  - [ElicitationResult](#elicitationresult)
  - [SessionEnd](#sessionend)
- [Matcher Syntax](#matcher-syntax)
- [Decision Control Summary](#decision-control-summary)

## Hook Configuration Structure

Hooks live in settings JSON files under the `hooks` key:

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "regex_pattern",
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

## Hook Types

| Type      | Field                                                        | Description                                                  | Default Timeout |
| :-------- | :----------------------------------------------------------- | :----------------------------------------------------------- | :-------------- |
| `command` | `command` (string)                                           | Shell command. Input on stdin, output on stdout/stderr       | 600s            |
| `http`    | `url` (string), `headers` (object), `allowedEnvVars` (array) | POST JSON to URL. Response body = output                     | 30s             |
| `prompt`  | `prompt` (string), `model` (string, optional)                | Single-turn LLM evaluation. Returns `{ok, reason}`           | 30s             |
| `agent`   | `prompt` (string), `model` (string, optional)                | Multi-turn subagent with tool access. Returns `{ok, reason}` | 60s             |

Common fields on all handlers: `type` (required), `timeout` (seconds), `statusMessage` (spinner text), `once` (bool, skills only).

## Event Reference

### SessionStart

**Fires when**: A session begins or resumes.
**Matcher filters**: How the session started.
**Matcher values**: `startup`, `resume`, `clear`, `compact`
**Key input fields**: `source` (string)
**Decision control**: Stdout text is added to Claude's context. No blocking.

### UserPromptSubmit

**Fires when**: User submits a prompt, before Claude processes it.
**Matcher**: No matcher support — always fires.
**Key input fields**: `prompt` (string)
**Decision control**: Exit 0 + stdout text = added to context. Exit 2 = blocks the prompt. JSON output: `additionalContext` (string).

### PreToolUse

**Fires when**: Before a tool call executes.
**Matcher filters**: Tool name.
**Matcher values**: `Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Agent`, `mcp__server__tool`, regex patterns like `Edit|Write`
**Key input fields**: `tool_name` (string), `tool_input` (object)
**Decision control**: Exit 0 = allow, exit 2 = block (stderr → Claude feedback). JSON: `hookSpecificOutput.permissionDecision` = `allow` / `deny` / `ask`. Also: `permissionDecisionReason`, `updatedInput`, `additionalContext`.

### PermissionRequest

**Fires when**: A permission dialog is about to appear.
**Matcher filters**: Tool name.
**Matcher values**: Same as PreToolUse.
**Key input fields**: `tool_name`, `tool_input`, `permission_mode`, `permission_suggestions`
**Decision control**: JSON: `hookSpecificOutput.decision.behavior` = `allow` / `deny`. For allow: `updatedInput`, `updatedPermissions`. For deny: `message`, `interrupt` (bool).

### PostToolUse

**Fires when**: After a tool call succeeds.
**Matcher filters**: Tool name.
**Matcher values**: Same as PreToolUse.
**Key input fields**: `tool_name`, `tool_input`, `tool_response`, `tool_use_id`
**Decision control**: JSON: `decision` = `block` + `reason`. Also: `additionalContext`, `updatedMCPToolOutput`.

### PostToolUseFailure

**Fires when**: After a tool call fails.
**Matcher filters**: Tool name.
**Key input fields**: `tool_name`, `tool_input`, `tool_use_id`, `error` (string), `is_interrupt` (bool)
**Decision control**: JSON: `additionalContext` only. Cannot block.

### Notification

**Fires when**: Claude Code sends a notification.
**Matcher filters**: Notification type.
**Matcher values**: `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`
**Key input fields**: `message`, `title`, `notification_type`
**Decision control**: `additionalContext` only. Cannot block.

### SubagentStart

**Fires when**: A subagent is spawned.
**Matcher filters**: Agent type.
**Matcher values**: `Bash`, `Explore`, `Plan`, or custom agent names
**Key input fields**: `agent_id`, `agent_type`
**Decision control**: `additionalContext` (added to subagent context). Cannot block.

### SubagentStop

**Fires when**: A subagent finishes.
**Matcher filters**: Agent type.
**Matcher values**: Same as SubagentStart.
**Key input fields**: `agent_id`, `agent_type`, `agent_transcript_path`, `last_assistant_message`
**Decision control**: Same as Stop — `decision: "block"` + `reason`.

### Stop

**Fires when**: Claude finishes responding. Does not fire on user interrupts.
**Matcher**: No matcher support — always fires.
**Key input fields**: `stop_hook_active` (bool), `last_assistant_message`
**Decision control**: JSON: `decision` = `block` + `reason` (tells Claude to continue). IMPORTANT: Check `stop_hook_active` — if true, exit 0 to avoid infinite loops.

### StopFailure

**Fires when**: Turn ends due to an API error.
**Matcher filters**: Error type.
**Matcher values**: `rate_limit`, `authentication_failed`, `billing_error`, `invalid_request`, `server_error`, `max_output_tokens`, `unknown`
**Key input fields**: `error`, `error_details`, `last_assistant_message`
**Decision control**: None. Output and exit code are ignored. Notification/logging only.

### TeammateIdle

**Fires when**: An agent team teammate is about to go idle.
**Matcher**: No matcher support — always fires.
**Key input fields**: `teammate_name`, `team_name`
**Decision control**: Exit 2 = teammate continues (stderr → feedback). JSON: `{continue: false, stopReason: "..."}` = stops teammate.

### TaskCompleted

**Fires when**: A task is being marked as completed.
**Matcher**: No matcher support — always fires.
**Key input fields**: `task_id`, `task_subject`, `task_description`, `teammate_name`, `team_name`
**Decision control**: Exit 2 = task NOT marked complete (stderr → feedback). JSON: `{continue: false, stopReason: "..."}` = stops teammate.

### InstructionsLoaded

**Fires when**: A CLAUDE.md or `.claude/rules/*.md` file is loaded.
**Matcher filters**: Load reason.
**Matcher values**: `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact`
**Key input fields**: Load context details.
**Decision control**: None documented.

### ConfigChange

**Fires when**: A configuration file changes during a session.
**Matcher filters**: Configuration source.
**Matcher values**: `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills`
**Key input fields**: `source`, `file_path`
**Decision control**: JSON: `decision` = `block` + `reason`. Note: `policy_settings` changes cannot be blocked.

### WorktreeCreate

**Fires when**: A worktree is being created via `--worktree` or `isolation: "worktree"`.
**Matcher**: No matcher support — always fires.
**Key input fields**: `name` (slug identifier)
**Decision control**: Command must print absolute path to created worktree on stdout. Only `type: "command"` supported.

### WorktreeRemove

**Fires when**: A worktree is being removed.
**Matcher**: No matcher support — always fires.
**Key input fields**: `worktree_path` (absolute path)
**Decision control**: None. Only `type: "command"` supported.

### PreCompact

**Fires when**: Before context compaction.
**Matcher filters**: Compaction trigger.
**Matcher values**: `manual`, `auto`
**Key input fields**: `trigger`, `custom_instructions`
**Decision control**: None documented.

### PostCompact

**Fires when**: After context compaction completes.
**Matcher filters**: Compaction trigger.
**Matcher values**: `manual`, `auto`
**Key input fields**: `trigger`, `compact_summary`
**Decision control**: None. Cannot affect compaction result.

### Elicitation

**Fires when**: An MCP server requests user input during a tool call.
**Matcher filters**: MCP server name.
**Key input fields**: `mcp_server_name`, `message`, `mode` (`form` or `url`), `requested_schema` or `url`
**Decision control**: JSON: `hookSpecificOutput.action` = `accept` / `decline` / `cancel`. For accept: `content` (object with form values).

### ElicitationResult

**Fires when**: After user responds to an MCP elicitation, before response is sent to server.
**Matcher filters**: MCP server name.
**Key input fields**: `mcp_server_name`, `action`, `content`
**Decision control**: Can modify action and content before sending to server.

### SessionEnd

**Fires when**: A session terminates.
**Matcher filters**: Exit reason.
**Matcher values**: `clear`, `resume`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other`
**Key input fields**: `reason`
**Decision control**: None. Cannot block termination. Default timeout: 1.5s (override with `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS`).

## Matcher Syntax

- Matchers are **regex patterns** matched against event-specific fields
- Case-sensitive
- Use `|` for alternation: `Edit|Write`
- Use `.*` for wildcards: `mcp__github__.*`
- Empty string `""`, `"*"`, or omitting `matcher` = match all occurrences
- MCP tool naming: `mcp__<server>__<tool>` (e.g., `mcp__github__search_repositories`)

## Decision Control Summary

| Method                              | Meaning                                                     |
| :---------------------------------- | :---------------------------------------------------------- |
| Exit 0                              | Allow the action. Stdout added to context (for some events) |
| Exit 2                              | Block the action. Stderr → feedback to Claude               |
| Other exit codes                    | Error logged, action proceeds                               |
| JSON `permissionDecision: "allow"`  | PreToolUse: skip permission prompt (deny rules still apply) |
| JSON `permissionDecision: "deny"`   | PreToolUse: cancel tool call, reason → Claude               |
| JSON `permissionDecision: "ask"`    | PreToolUse: show permission prompt as normal                |
| JSON `decision: "block"` + `reason` | PostToolUse/Stop/ConfigChange: block with feedback          |
| JSON `decision.behavior: "allow"`   | PermissionRequest: grant permission                         |
| JSON `decision.behavior: "deny"`    | PermissionRequest: deny permission                          |
| Prompt/Agent `ok: true`             | Allow                                                       |
| Prompt/Agent `ok: false` + `reason` | Block with feedback                                         |
