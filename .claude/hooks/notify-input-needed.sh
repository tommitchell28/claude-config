#!/usr/bin/env bash
set -euo pipefail

# Notification hook: desktop notification when a Claude Code session needs input.
# Reads the Notification hook event JSON from stdin and raises a GNOME popup.

print_help() {
  cat <<'EOF'
Usage: notify-input-needed.sh [-h|--help]

Claude Code Notification hook. Reads the hook event JSON on stdin and shows
a persistent GNOME desktop notification (via notify-send) titled with the
session's working-directory basename, so parallel sessions are
distinguishable.

Expected stdin fields: cwd, message (both optional — fallbacks apply).

Example:
  echo '{"cwd":"/path/to/project","message":"Claude needs your permission"}' \
    | notify-input-needed.sh
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_help
  exit 0
fi

input="$(cat)"

project="$(basename "$(echo "$input" | jq -r '.cwd // empty')")"
message="$(echo "$input" | jq -r '.message // "Claude needs your input"')"

# A failed notification must never disrupt the session
notify-send --urgency=critical --app-name="Claude Code" \
  "Claude Code — ${project:-unknown}" "${message}" || true
