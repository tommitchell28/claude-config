#!/usr/bin/env bash
# Print the audit date, revision, working-tree status and file list of a repository.
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: discover.sh [-h|--help] [repository-directory]

Prints the directory, audit date (UTC), git revision, working-tree status and
the list of files to inspect for a dependency audit. Defaults to the current
directory. Secret and state files (.env, secrets/, Terraform state and
variables) are left out of the list.

Example:
  bash discover.sh ~/code/my-service
USAGE
}

if [ "$#" -gt 1 ]; then
    usage >&2
    exit 2
fi
case "${1:-}" in
-h | --help)
    usage
    exit 0
    ;;
esac

print_paths() {
    local path
    while IFS= read -r -d '' path; do
        case "/$path" in
            */.env|*/.env.*|*/secrets/*|*/.terraform/*|*.tfstate|*.tfstate.*|*.tfvars|*.tfvars.json) continue ;;
        esac
        if [ -f "$path" ] && [ ! -L "$path" ]; then
            printf '%q\n' "${path#./}"
        fi
    done
}

cd -- "${1:-.}"
printf 'Directory: %s\nAudit date (UTC): %s\n' "$PWD" "$(date -u +%F)"

if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true ]; then
    printf 'Revision: %s\n' "$(git rev-parse --verify HEAD 2>/dev/null || printf 'unborn')"
    if [ -n "$(git status --porcelain -- .)" ]; then
        echo 'Working tree: changed (check individual files before citing a commit)'
    else
        echo 'Working tree: clean'
    fi
    echo 'Files (tracked and non-ignored untracked; submodules not traversed):'
    git ls-files --cached --others --exclude-standard -z -- . | print_paths | LC_ALL=C sort -u
else
    echo 'Revision: unavailable'
    echo 'Files (filesystem listing; VCS, secret and common generated directories excluded):'
    find . -type d \( -name .git -o -name .hg -o -name .svn -o -name secrets \
        -o -name .terraform -o -name node_modules -o -name .venv \) -prune \
        -o -type f -print0 | print_paths | LC_ALL=C sort -u
fi
