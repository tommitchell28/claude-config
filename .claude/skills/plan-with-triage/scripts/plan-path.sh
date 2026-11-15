#!/usr/bin/env bash
# Reserve a timestamped plan file and print its path.
set -euo pipefail

usage() {
	cat <<'USAGE'
Usage: plan-path.sh [slug]

Creates .claude/plans/plan-YYYYMMDD-HHMMSS[-slug].md using UTC and prints its path.
Run from the project root. The optional slug uses letters, digits and single hyphens,
converted to lowercase. Fails if the file already exists.
USAGE
}

fail_with_usage() {
	echo "Error: $*" >&2
	usage >&2
	exit 1
}

case "${1:-}" in
-h | --help)
	usage
	exit 0
	;;
esac
[ $# -le 1 ] || fail_with_usage "expected at most one slug"
slug="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
[[ -z "$slug" || "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail_with_usage "invalid slug '$slug'"

mkdir -p .claude/plans
plan_path=".claude/plans/plan-$(date -u +%Y%m%d-%H%M%S)${slug:+-$slug}.md"
(set -o noclobber; : > "$plan_path")
printf '%s\n' "$plan_path"
