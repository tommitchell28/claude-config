#!/bin/bash
# Sync claude config from this repo to ~/.claude

show_help() {
  cat <<'HELP'
Usage: setup.sh [-h|--help]

Syncs hooks/, skills/, settings.json, and CLAUDE.md from this repo's
.claude/ directory to ~/.claude/ using rsync. Other files in ~/.claude/
are left untouched.

Also merges the repo-root .mcp.json's "mcpServers" into ~/.claude.json
(user-level MCP config), backing up that file to ~/.claude.json.bak first.
Requires jq.

If the destination already contains files that would be overwritten,
you will be shown what exists and prompted before continuing.

Warns if the repo's .claude/ contains directories not in the sync list.

Examples:
  ./setup.sh          # sync config to ~/.claude/
  ./setup.sh --help   # show this help
HELP
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  show_help
  exit 0
fi

repo_dir="$(cd "$(dirname "$0")" && pwd)"
repo_claude="${repo_dir}/.claude"
dest_claude="${HOME}/.claude"

sync_dirs=("hooks" "skills")
sync_files=("settings.json" "CLAUDE.md")

# .mcp.json lives at the repo root (not in .claude/). Its "mcpServers" key is
# merged into ~/.claude.json, where Claude Code reads user-level MCP servers.
mcp_source="${repo_dir}/.mcp.json"
claude_json="${HOME}/.claude.json"

# Warn about directories in repo .claude/ that won't be synced
for entry in "${repo_claude}"/*/; do
  [[ -d "${entry}" ]] || continue
  dirname="$(basename "${entry}")"
  found=false
  for sync_dir in "${sync_dirs[@]}"; do
    if [[ "${dirname}" == "${sync_dir}" ]]; then
      found=true
      break
    fi
  done
  if [[ "${found}" == false ]]; then
    echo "WARNING: repo .claude/${dirname}/ exists but is not in the sync list — it will NOT be synced."
  fi
done

# Check for existing files in destination
existing_files=()
for sync_dir in "${sync_dirs[@]}"; do
  target="${dest_claude}/${sync_dir}"
  if [[ -d "${target}" ]]; then
    while IFS= read -r file; do
      existing_files+=("${file}")
    done < <(find "${target}" -type f | sort)
  fi
done
for sync_file in "${sync_files[@]}"; do
  target="${dest_claude}/${sync_file}"
  if [[ -f "${target}" ]]; then
    existing_files+=("${target}")
  fi
done

if [[ ${#existing_files[@]} -gt 0 ]]; then
  echo "The following files already exist in the destination:"
  echo ""
  for file in "${existing_files[@]}"; do
    echo "  ${file}"
  done
  echo ""
  read -r -p "Continue and overwrite? [y/N] " answer
  if [[ "${answer}" != [yY] ]]; then
    echo "Aborted."
    exit 1
  fi
  echo ""
fi

# Sync each directory
mkdir -p "${dest_claude}"
for sync_dir in "${sync_dirs[@]}"; do
  source="${repo_claude}/${sync_dir}"
  if [[ ! -d "${source}" ]]; then
    continue
  fi
  target="${dest_claude}/${sync_dir}"
  rm -rf "${target}"
  mkdir -p "${target}"
  rsync -av "${source}/" "${target}/"
done

# Copy individual files to ~/.claude/, rewriting paths as needed.
#
# The repo's settings.json uses $CLAUDE_PROJECT_DIR to reference hook scripts
# (e.g. "$CLAUDE_PROJECT_DIR/.claude/hooks/status-line.sh"). This works when
# Claude Code loads the file as project-level config, because it sets that
# env var to the project root.
#
# However, when we copy settings.json to ~/.claude/ for global use,
# $CLAUDE_PROJECT_DIR won't be set (it's only defined per-project). So we
# rewrite those paths to use $HOME instead, since setup.sh has already synced
# the hooks/ directory to ~/.claude/hooks/.
#
# Example: "$CLAUDE_PROJECT_DIR/.claude/hooks/foo.sh" -> "$HOME/.claude/hooks/foo.sh"
for sync_file in "${sync_files[@]}"; do
  source="${repo_claude}/${sync_file}"
  if [[ ! -f "${source}" ]]; then
    continue
  fi
  sed 's|\$CLAUDE_PROJECT_DIR/\.claude/hooks/|\$HOME/.claude/hooks/|g' \
    "${source}" > "${dest_claude}/${sync_file}"
  echo "'${source}' -> '${dest_claude}/${sync_file}'"
done

# Merge MCP server definitions into ~/.claude.json (user-level config).
#
# User-scoped MCP servers live under the "mcpServers" key of ~/.claude.json, a
# large stateful file managed by Claude Code. We must NOT overwrite it, so we
# merge our declarative .mcp.json into it with jq — preserving every other key
# and any servers already defined there. A timestamp-free .bak is written first.
if [[ -f "${mcp_source}" ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "WARNING: jq not found — skipping MCP sync into ${claude_json}."
  else
    [[ -f "${claude_json}" ]] || echo '{}' > "${claude_json}"
    cp "${claude_json}" "${claude_json}.bak"
    tmp="$(mktemp)"
    jq --slurpfile mcp "${mcp_source}" \
      '.mcpServers = ((.mcpServers // {}) + ($mcp[0].mcpServers // {}))' \
      "${claude_json}" > "${tmp}" && mv "${tmp}" "${claude_json}"
    echo "merged '${mcp_source}' mcpServers -> '${claude_json}' (backup: ${claude_json}.bak)"
  fi
fi

echo ""
echo "Sync complete."
