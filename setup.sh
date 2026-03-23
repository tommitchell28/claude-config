#!/bin/bash
# Sync claude config from this repo to ~/.claude

show_help() {
  cat <<'HELP'
Usage: setup.sh [-h|--help]

Syncs the .claude/ directory from this repo to ~/.claude/ using rsync.
This overwrites existing files in ~/.claude/ with the repo versions.

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

mkdir -p "${HOME}/.claude"
rsync -av "${repo_dir}/.claude/" "${HOME}/.claude/"
