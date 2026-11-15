#!/usr/bin/env bash
# PreToolUse hook: deny Write/Edit/NotebookEdit calls that target the parts of
# ~/.claude deployed from the claude-config repo, and name the repo file to edit.

# -f: the path split in normalise must not glob.
set -euf -o pipefail

show_help() {
  cat <<'HELP'
Usage: block-deployed-config-writes.sh < event.json

PreToolUse hook for Write, Edit and NotebookEdit. Reads the hook event JSON on
stdin. When the target file is a deployed copy under ~/.claude (rules/,
skills/, hooks/, output-styles/, agents/, settings.json or CLAUDE.md) it prints
a "deny" decision naming the file to edit in the claude-config repo. Otherwise
it prints nothing and exits 0.

~/.claude/skills/synced/ (managed by Claude Code) and the rest of ~/.claude
stay writable.

Environment:
  CLAUDE_CONFIG_REPO   Path to the claude-config repo.
                       Default: $HOME/Documents/code/claude-config

Example:
  echo '{"tool_input":{"file_path":"'"$HOME"'/.claude/settings.json"}}' |
    block-deployed-config-writes.sh
HELP
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  show_help
  exit 0
fi

# Collapses '.', '..' and repeated slashes so a roundabout path cannot slip past
# the prefix test. Lexical only: symlinks are not resolved.
normalise() {
  local segments=() segment
  local IFS=/
  for segment in $1; do
    case "${segment}" in
      '' | .) ;;
      ..) [[ ${#segments[@]} -eq 0 ]] || unset "segments[$((${#segments[@]} - 1))]" ;;
      *) segments+=("${segment}") ;;
    esac
  done
  if [[ ${#segments[@]} -eq 0 ]]; then
    printf '/'
    return
  fi
  printf '/%s' "${segments[@]}"
}

# Without jq the event cannot be read. The hook then allows the write and says so:
# blocking every edit on a machine that lacks jq would be worse than the gap.
if ! command -v jq >/dev/null 2>&1; then
  echo "block-deployed-config-writes: jq not found; deployed copies are not protected." >&2
  exit 0
fi

repo="${CLAUDE_CONFIG_REPO:-${HOME}/Documents/code/claude-config}"
deployed="$(normalise "${HOME}/.claude")"

input="$(cat)"
if ! jq -e . >/dev/null 2>&1 <<<"${input}"; then
  echo "block-deployed-config-writes: unreadable hook event; nothing checked." >&2
  exit 0
fi
path="$(jq -r '[.tool_input.file_path, .tool_input.notebook_path]
  | map(select(type == "string" and . != "")) | first // ""' <<<"${input}")"
[[ -n "${path}" ]] || exit 0

tilde='~'
if [[ "${path}" == "${tilde}" || "${path}" == "${tilde}/"* ]]; then
  path="${HOME}${path#"${tilde}"}"
fi
if [[ "${path}" != /* ]]; then
  cwd="$(jq -r '.cwd // empty' <<<"${input}")"
  path="${cwd:-${PWD}}/${path}"
fi
path="$(normalise "${path}")"

# Keep this list in step with sync_dirs and sync_files in setup.sh.
case "${path}" in
  "${deployed}"/skills/synced/*) exit 0 ;;
  "${deployed}"/rules/* | "${deployed}"/skills/* | "${deployed}"/hooks/* | \
    "${deployed}"/output-styles/* | "${deployed}"/agents/* | \
    "${deployed}"/settings.json | "${deployed}"/CLAUDE.md) ;;
  *) exit 0 ;;
esac

source_path="${repo}/.claude${path#"${deployed}"}"
reason="${path} is a deployed copy. The next deploy from the claude-config repo overwrites it, \
so an edit here is lost. Edit ${source_path} instead, then run ${repo}/setup.sh to deploy it."

jq -n --arg reason "${reason}" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
