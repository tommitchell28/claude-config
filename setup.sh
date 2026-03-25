#!/bin/bash
# Sync claude config from this repo to ~/.claude

show_help() {
  cat <<'HELP'
Usage: setup.sh [-h|--help]

Syncs hooks/, skills/, settings.json, and CLAUDE.md from this repo's
.claude/ directory to ~/.claude/ using rsync. Other files in ~/.claude/
are left untouched.

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

# Copy individual files
for sync_file in "${sync_files[@]}"; do
  source="${repo_claude}/${sync_file}"
  if [[ ! -f "${source}" ]]; then
    continue
  fi
  cp -v "${source}" "${dest_claude}/${sync_file}"
done

echo ""
echo "Sync complete."
