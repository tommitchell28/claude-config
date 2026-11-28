#!/usr/bin/env bash
# Create one timestamped directory for a review and print its artifact paths.
set -euo pipefail

readonly REVIEWS_SUBDIR=".claude/code-reviews"

usage() {
	cat <<'USAGE'
Usage: report-paths.sh [slug]

Creates .claude/code-reviews/review-YYYYMMDD-HHMMSS[-slug]/ using UTC and prints:
  RUN_DIR=<run directory>
  CONTEXT_FILE=<run directory>/context.md
  SHARD_DIR=<run directory>/context-shards
  REPORT=<run directory>/review/report.md
  AUDIT=<run directory>/review/audit.md

Paths are relative to the reviewed repo's root. In a linked worktree, the run directory goes
under the main worktree's .claude/code-reviews/ instead and the paths are absolute, so the
review outlives the worktree. The optional slug is a short label such as
pr-12 or issue-7: letters, digits and single hyphens, converted to lowercase. Fails if the run exists.
USAGE
}

fail_with_usage() {
	echo "Error: $*" >&2
	usage >&2
	exit 1
}

parse_args() {
	case "${1:-}" in
	-h | --help)
		usage
		exit 0
		;;
	esac
	[ $# -le 1 ] || fail_with_usage "expected at most one slug"
	slug="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
	[[ -z "$slug" || "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail_with_usage "invalid slug '$slug'"
}

# Print the main worktree's path when the current directory is a linked worktree, else nothing.
main_worktree_if_linked() {
	local git_dir common_dir
	git_dir="$(git rev-parse --path-format=absolute --git-dir 2>/dev/null)" || return 0
	common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
	[ "$git_dir" != "$common_dir" ] || return 0
	git worktree list --porcelain | sed -n '1s/^worktree //p'
}

output_dir() {
	local main_worktree
	main_worktree="$(main_worktree_if_linked)"
	if [ -n "$main_worktree" ]; then
		echo "$main_worktree/$REVIEWS_SUBDIR"
	else
		echo "$REVIEWS_SUBDIR"
	fi
}

main() {
	parse_args "$@"
	local reviews_dir run_dir
	reviews_dir="$(output_dir)"
	mkdir -p "$reviews_dir"
	run_dir="$reviews_dir/review-$(date -u +%Y%m%d-%H%M%S)${slug:+-$slug}"
	mkdir "$run_dir"
	mkdir "$run_dir/context-shards" "$run_dir/review"
	printf 'RUN_DIR=%s\nCONTEXT_FILE=%s/context.md\nSHARD_DIR=%s/context-shards\nREPORT=%s/review/report.md\nAUDIT=%s/review/audit.md\n' \
		"$run_dir" "$run_dir" "$run_dir" "$run_dir" "$run_dir"
}

main "$@"
