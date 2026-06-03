#!/usr/bin/env bash
set -euo pipefail

# Notification hook: desktop notification when a Claude Code session needs input.
# Reads the Notification hook event JSON from stdin and raises a GNOME popup.

print_help() {
  cat <<'EOF'
Usage: notify-input-needed.sh [-h|--help]

Claude Code Notification hook. Reads the hook event JSON on stdin and shows
a persistent GNOME desktop notification (via notify-send) identifying the
session by working-directory basename, git branch, prompt type, and a short
session id, so parallel sessions (e.g. worktrees of the same repo) are
distinguishable.

Expected stdin fields: cwd, message, notification_type, session_id
(all optional — fallbacks apply).

Example:
  echo '{"cwd":"/path/to/project","message":"Claude needs your permission","notification_type":"permission_prompt","session_id":"abc123"}' \
    | notify-input-needed.sh
EOF
}

prompt_type_label() {
  case "$1" in
    permission_prompt) echo "Permission needed" ;;
    idle_prompt) echo "Waiting for input" ;;
    elicitation_dialog) echo "Question for you" ;;
    *) echo "Needs attention" ;;
  esac
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_help
  exit 0
fi

input="$(cat)"

cwd="$(echo "$input" | jq -r '.cwd // empty')"
message="$(echo "$input" | jq -r '.message // "Claude needs your input"')"
notification_type="$(echo "$input" | jq -r '.notification_type // empty')"
session_id="$(echo "$input" | jq -r '.session_id // empty')"

project="$(basename "${cwd:-unknown}")"
branch=""
if [[ -n "$cwd" ]]; then
  branch="$(git -C "$cwd" branch --show-current 2>/dev/null || true)"
fi
type_label="$(prompt_type_label "$notification_type")"

title="${project}${branch:+ (${branch})} — ${type_label}"
body="${message}${session_id:+ [session ${session_id:0:6}]}"

# Normal urgency auto-dismisses after ~5s on GNOME (critical would persist
# until manually closed). A failed notification must never disrupt the session.
notify-send --urgency=normal --expire-time=5000 --app-name="Claude Code" \
  "${title}" "${body}" || true
