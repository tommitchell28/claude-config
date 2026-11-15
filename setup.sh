#!/bin/bash
# Sync claude config from this repo to ~/.claude without deleting anything there.
set -euo pipefail

show_help() {
  cat <<'HELP'
Usage: setup.sh [--dry-run] [-h|--help]

Copies hooks/, skills/, rules/, output-styles/ and agents/ plus settings.json
and CLAUDE.md from this repo's .claude/ directory to ~/.claude/.

Nothing in ~/.claude/ is ever deleted. Files under those directories that are
no longer in the repo are reported so you can remove them by hand;
~/.claude/skills/synced/ belongs to Claude Code and is never reported.

For settings.json and CLAUDE.md a diff between the deployed copy and the copy
about to be written is printed first, so changes made on the machine (through
/config or /effort, say) are visible before they are overwritten.

Also merges the repo-root .mcp.json's "mcpServers" into ~/.claude.json
(user-level MCP config), backing up that file to ~/.claude.json.bak first.
Requires rsync; the MCP merge requires jq.

Stops before writing anything if a destination path clashes with the repo
layout (a file or symlink where the repo has a directory, or the reverse).

Warns if the repo's .claude/ contains directories not in the sync list
(plans/ and code-reviews/ are known repo-only directories).

Options:
  --dry-run    Change nothing. Show what would be copied, the diffs, the
               orphan report and what the MCP merge would do.
  -h, --help   Show this help.

A real run asks for confirmation before it writes anything.

Examples:
  ./setup.sh --dry-run   # preview
  ./setup.sh             # sync config to ~/.claude/
HELP
}

dry_run=false
for argument in "$@"; do
  case "${argument}" in
    -h | --help)
      show_help
      exit 0
      ;;
    --dry-run)
      dry_run=true
      ;;
    *)
      echo "Unknown argument: ${argument}" >&2
      echo "Run 'setup.sh --help' for usage." >&2
      exit 2
      ;;
  esac
done

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_claude="${repo_dir}/.claude"
dest_claude="${HOME}/.claude"

# Keep in step with the paths .claude/hooks/block-deployed-config-writes.sh protects.
sync_dirs=("hooks" "skills" "rules" "output-styles" "agents")
sync_files=("settings.json" "CLAUDE.md")
repo_only_dirs=("plans" "code-reviews")

# .mcp.json lives at the repo root (not in .claude/). Its "mcpServers" key is
# merged into ~/.claude.json, where Claude Code reads user-level MCP servers.
mcp_source="${repo_dir}/.mcp.json"
claude_json="${HOME}/.claude.json"

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

contains() {
  local wanted="$1"
  shift
  local candidate
  for candidate in "$@"; do
    [[ "${candidate}" == "${wanted}" ]] && return 0
  done
  return 1
}

warn_about_unsynced_dirs() {
  local entry name
  for entry in "${repo_claude}"/*/; do
    [[ -d "${entry}" ]] || continue
    name="$(basename "${entry}")"
    contains "${name}" "${sync_dirs[@]}" && continue
    contains "${name}" "${repo_only_dirs[@]}" && continue
    echo "WARNING: repo .claude/${name}/ exists but is not in the sync list — it will NOT be synced."
  done
}

# Claude Code sets $CLAUDE_PROJECT_DIR only per project, so hook paths written
# against it in the repo must point at $HOME in the deployed copy.
render_for_deploy() {
  local source="$1" rendered="$2"
  # shellcheck disable=SC2016 # the literal variable names are what is rewritten
  sed 's|\$CLAUDE_PROJECT_DIR/\.claude/hooks/|\$HOME/.claude/hooks/|g' \
    "${source}" >"${rendered}"
}

render_files() {
  local sync_file
  for sync_file in "${sync_files[@]}"; do
    [[ -f "${repo_claude}/${sync_file}" ]] || continue
    render_for_deploy "${repo_claude}/${sync_file}" "${work_dir}/${sync_file}"
  done
}

show_file_diffs() {
  local sync_file deployed
  for sync_file in "${sync_files[@]}"; do
    [[ -f "${work_dir}/${sync_file}" ]] || continue
    deployed="${dest_claude}/${sync_file}"
    echo "--- ${sync_file}: deployed copy vs copy to be written"
    if [[ ! -f "${deployed}" ]]; then
      echo "  (not deployed yet; the file will be created)"
    elif diff -u "${deployed}" "${work_dir}/${sync_file}"; then
      echo "  (no differences)"
    fi
    echo ""
  done
}

# rsync never gets --delete here: the destination holds content this repo does
# not own (skills/synced/ is managed by Claude Code).
copy_dirs() {
  local rsync_options=(-a --itemize-changes)
  if [[ "${dry_run}" == true ]]; then
    rsync_options+=(--dry-run)
  fi
  local sync_dir source
  for sync_dir in "${sync_dirs[@]}"; do
    source="${repo_claude}/${sync_dir}"
    [[ -d "${source}" ]] || continue
    echo "--- ${sync_dir}/ -> ${dest_claude}/${sync_dir}/"
    if [[ "${dry_run}" == true && ! -d "${dest_claude}/${sync_dir}" ]]; then
      echo "  (destination does not exist; every file below would be created)"
      (cd "${source}" && find . -type f | sort | sed 's|^\./|  |')
      continue
    fi
    mkdir -p "${dest_claude}/${sync_dir}"
    rsync "${rsync_options[@]}" "${source}/" "${dest_claude}/${sync_dir}/"
  done
  echo ""
}

copy_files() {
  local sync_file
  for sync_file in "${sync_files[@]}"; do
    [[ -f "${work_dir}/${sync_file}" ]] || continue
    cp "${work_dir}/${sync_file}" "${dest_claude}/${sync_file}"
    echo "'${repo_claude}/${sync_file}' -> '${dest_claude}/${sync_file}'"
  done
  echo ""
}

report_orphans() {
  echo "--- Files under ${dest_claude} that are no longer in this repo"
  echo "    (reported only; nothing is deleted)"
  local found=false sync_dir source target path
  local -a orphan_options
  for sync_dir in "${sync_dirs[@]}"; do
    source="${repo_claude}/${sync_dir}"
    target="${dest_claude}/${sync_dir}"
    [[ -d "${source}" && -d "${target}" ]] || continue
    orphan_options=(-a --dry-run --delete --itemize-changes)
    if [[ "${sync_dir}" == "skills" ]]; then
      orphan_options+=(--exclude=/synced/)
    fi
    while IFS= read -r path; do
      echo "  ${target}/${path}"
      found=true
    done < <(rsync "${orphan_options[@]}" "${source}/" "${target}/" |
      sed -n 's/^\*deleting  *//p')
  done
  if [[ "${found}" == false ]]; then
    echo "  (none found)"
  fi
  echo ""
}

# ~/.claude.json is a large stateful file managed by Claude Code, so the repo's
# servers are merged into it rather than the file being replaced.
merge_mcp_servers() {
  [[ -f "${mcp_source}" ]] || return 0
  echo "--- MCP servers: ${mcp_source} -> ${claude_json}"
  if ! command -v jq >/dev/null 2>&1; then
    echo "WARNING: jq not found — skipping MCP sync into ${claude_json}."
    return 0
  fi

  local current="${work_dir}/claude.json.current"
  local merged="${work_dir}/claude.json.merged"
  if [[ -s "${claude_json}" ]]; then
    cp "${claude_json}" "${current}"
  else
    echo '{}' >"${current}"
  fi
  if ! jq -e '(.mcpServers // {}) | type == "object"' "${mcp_source}" >/dev/null 2>&1; then
    echo "WARNING: ${mcp_source} is not valid JSON with an mcpServers object — skipping MCP sync."
    return 0
  fi
  if ! jq -e 'type == "object" and ((.mcpServers // {}) | type == "object")' "${current}" >/dev/null 2>&1; then
    echo "WARNING: ${claude_json} is not a valid JSON object — skipping MCP sync and leaving it untouched."
    return 0
  fi
  jq --slurpfile mcp "${mcp_source}" \
    '.mcpServers = ((.mcpServers // {}) + ($mcp[0].mcpServers // {}))' \
    "${current}" >"${merged}"

  local server_names
  server_names="$(jq -r '(.mcpServers // {}) | keys | join(", ")' "${mcp_source}")"
  if [[ "$(jq -S . "${current}")" == "$(jq -S . "${merged}")" ]]; then
    echo "  mcpServers already up to date (${server_names}); nothing to merge."
    return 0
  fi
  if [[ "${dry_run}" == true ]]; then
    echo "  would merge mcpServers (${server_names}) into ${claude_json}, backing up any existing file to ${claude_json}.bak"
    return 0
  fi
  if [[ -f "${claude_json}" ]]; then
    cp "${claude_json}" "${claude_json}.bak"
    cp "${merged}" "${claude_json}"
    echo "  merged mcpServers (${server_names}); backup: ${claude_json}.bak"
  else
    (umask 077 && cp "${merged}" "${claude_json}")
    echo "  created ${claude_json} with mcpServers (${server_names})"
  fi
}

# rsync replaces a destination file or symlink that sits where the repo has a
# directory (and the reverse), which would delete content this repo does not
# own. Such clashes stop the run before anything is written.
list_type_conflicts() {
  local sync_dir source target relative
  for sync_dir in "${sync_dirs[@]}"; do
    source="${repo_claude}/${sync_dir}"
    target="${dest_claude}/${sync_dir}"
    [[ -d "${source}" ]] || continue
    while IFS= read -r -d '' relative; do
      relative="${relative#.}"
      # A symlinked top-level directory is followed by rsync, not replaced.
      if [[ -n "${relative}" && -L "${target}${relative}" ]] ||
        [[ -e "${target}${relative}" && ! -d "${target}${relative}" ]]; then
        echo "  ${target}${relative} (the repo has a directory here)"
      fi
    done < <(cd "${source}" && find . -type d -print0)
    while IFS= read -r -d '' relative; do
      relative="${relative#.}"
      if [[ -L "${target}${relative}" ]]; then
        echo "  ${target}${relative} (a symlink; the repo has a file here)"
      elif [[ -d "${target}${relative}" ]]; then
        echo "  ${target}${relative} (the repo has a file here)"
      fi
    done < <(cd "${source}" && find . -type f -print0)
  done
  local sync_file
  for sync_file in "${sync_files[@]}"; do
    if [[ -f "${repo_claude}/${sync_file}" && -d "${dest_claude}/${sync_file}" ]]; then
      echo "  ${dest_claude}/${sync_file} (the repo has a file here)"
    fi
  done
  if [[ -e "${dest_claude}" && ! -d "${dest_claude}" ]]; then
    echo "  ${dest_claude} (must be a directory)"
  fi
}

abort_on_type_conflicts() {
  local conflicts
  conflicts="$(list_type_conflicts)"
  [[ -n "${conflicts}" ]] || return 0
  echo "Error: these destination paths clash with the repo layout; deploying would replace them." >&2
  echo "${conflicts}" >&2
  echo "Move them out of the way and run again. Nothing was changed." >&2
  exit 1
}

confirm_or_abort() {
  local answer=""
  read -r -p "Write these changes to ${dest_claude}? [y/N] " answer || true
  if [[ "${answer}" != [yY] ]]; then
    echo "Aborted."
    exit 1
  fi
  echo ""
}

if [[ ! -d "${repo_claude}" ]]; then
  echo "Error: ${repo_claude} not found." >&2
  exit 1
fi
if ! command -v rsync >/dev/null 2>&1; then
  echo "Error: rsync is required." >&2
  exit 1
fi

warn_about_unsynced_dirs
abort_on_type_conflicts
render_files
show_file_diffs

if [[ "${dry_run}" == true ]]; then
  echo "Dry run: nothing will be changed."
  echo ""
  copy_dirs
  report_orphans
  merge_mcp_servers
  echo ""
  echo "Dry run complete; nothing was changed."
  exit 0
fi

confirm_or_abort
mkdir -p "${dest_claude}"
copy_dirs
copy_files
report_orphans
merge_mcp_servers
echo ""
echo "Sync complete."
