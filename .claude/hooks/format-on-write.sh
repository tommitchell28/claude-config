#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook: format files after Edit/Write with prettier
# Reads tool input from stdin, formats the affected file, and reports back.

input="$(cat)"

# Extract file_path from tool_input
file_path="$(echo "$input" | jq -r '.tool_input.file_path // empty')"

if [[ -z "$file_path" ]]; then
  exit 0
fi

# Skip if file doesn't exist (e.g. it was deleted)
if [[ ! -f "$file_path" ]]; then
  exit 0
fi

# Capture file content before formatting
before="$(cat "$file_path")"

# Format the file, --ignore-unknown skips non-prettier files silently
npx --yes prettier --write --ignore-unknown "$file_path" > /dev/null 2>&1 || exit 0

after="$(cat "$file_path")"

# Only notify Claude if the file actually changed
if [[ "$before" != "$after" ]]; then
  jq -n --arg file "$file_path" '{additionalContext: ("prettier reformatted " + $file)}'
fi
