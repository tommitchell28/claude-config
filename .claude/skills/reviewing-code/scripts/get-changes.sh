#!/usr/bin/env bash
# Resolve a code change into a self-contained context file — metadata, changed-file
# name-status, and the full unified diff — and print a compact summary to stdout.
# The diff is written only to the file, so a caller never loads it into its own context.
set -euo pipefail

# Shared state, filled by parse_args and the resolve_* functions, read by the writers.
context_file="" base_override="" range_spec="" excludes=() pathspec=()
context_path="" repo_root="" branch_name=""
mode="" base_branch="" base_is_local="" merge_base="" head_sha="" dirty=""
untracked="" include_untracked="" diff_args=() name_status="" file_count=""

usage() {
	cat <<'USAGE'
Usage:
  get-changes.sh <context-file> [base-branch] [--exclude <pathspec>]...
  get-changes.sh <context-file> --range <base>..<head> [--exclude <pathspec>]...

Writes a self-contained change-context file (metadata + name-status + full unified diff)
and prints a compact summary to stdout. The diff goes only to the file. Untracked files in
the context file's own directory are never counted as part of the change.

Auto-detect (default) picks the change from the checked-out state:
  branch          HEAD has diverged from the base branch  -> merge-base..HEAD
  working-tree    uncommitted or untracked work           -> HEAD..worktree (untracked included)
  last-commit     clean tree, no divergence               -> HEAD~1..HEAD
  initial-commit  HEAD has no parent                      -> empty tree..HEAD
  unborn-branch   no commit yet and a clean tree          -> nothing to diff

Arguments:
  <context-file>          Path to write; its directory is created if absent.
  [base-branch]           Auto-detect only: override the detected base (e.g. origin/main).
  --range <base>..<head>  Diff merge-base(base,head)..head (base itself when they share no
                          history); the working tree is ignored. Endpoints are SHAs or refs;
                          a fetched branch name is also tried as origin/<name>.
  --exclude <pathspec>    Leave matching paths out of the change (tracked and untracked);
                          repeatable. Repo-root-relative git pathspec, e.g. TODO.md, 'docs/*'.
USAGE
}

fail() {
	echo "Error: $*" >&2
	exit 1
}

fail_with_usage() {
	echo "Error: $*" >&2
	usage >&2
	exit 1
}

parse_args() {
	while [ $# -gt 0 ]; do
		case "$1" in
		-h | --help)
			usage
			exit 0
			;;
		--exclude)
			[ $# -ge 2 ] || fail_with_usage "--exclude needs a pathspec"
			excludes+=("$2")
			shift 2
			;;
		--exclude=*)
			excludes+=("${1#--exclude=}")
			shift
			;;
		--range)
			[ $# -ge 2 ] || fail_with_usage "--range needs a value: <base>..<head>"
			range_spec="$2"
			shift 2
			;;
		--range=*)
			range_spec="${1#--range=}"
			shift
			;;
		-*)
			fail_with_usage "unknown option '$1'"
			;;
		*)
			assign_positional "$1"
			shift
			;;
		esac
	done
	[ -n "$context_file" ] || fail_with_usage "missing <context-file> argument"
	if [ -n "$range_spec" ] && [ -n "$base_override" ]; then
		fail_with_usage "--range and a base-branch positional are mutually exclusive"
	fi
	build_pathspec
}

# Empty when nothing is excluded, so git sees no pathspec at all. Bash 3.2 rejects an empty
# array expansion under set -u, hence the ${pathspec[@]+...} form at every use.
build_pathspec() {
	pathspec=()
	[ "${#excludes[@]}" -gt 0 ] || return 0
	pathspec=(-- ':/')
	local pattern
	for pattern in "${excludes[@]}"; do
		pathspec+=(":(top,exclude)$pattern")
	done
}

assign_positional() {
	if [ -z "$context_file" ]; then
		context_file="$1"
	elif [ -z "$base_override" ]; then
		base_override="$1"
	else
		fail_with_usage "unexpected argument '$1'"
	fi
}

require_git_repo() {
	git rev-parse --git-dir >/dev/null 2>&1 || fail "not inside a git repository"
}

absolute_path() {
	local dir
	dir="$(dirname "$1")"
	mkdir -p "$dir"
	echo "$(cd "$dir" && pwd -P)/$(basename "$1")"
}

current_branch_name() {
	git symbolic-ref --quiet --short HEAD 2>/dev/null ||
		git rev-parse --abbrev-ref HEAD 2>/dev/null ||
		echo '(unknown)'
}

validate_range_spec() {
	case "$range_spec" in
	*..*) ;;
	*) fail "--range expects <base>..<head>, got '$range_spec'" ;;
	esac
	if [ -z "${range_spec%%..*}" ] || [ -z "${range_spec##*..}" ]; then
		fail "--range needs both endpoints: <base>..<head>"
	fi
}

# A SHA or ref as given, else the remote-tracking form of a branch that was fetched but never
# checked out (git fetch origin X updates only refs/remotes/origin/X).
resolve_endpoint() {
	local endpoint="$1" candidate
	for candidate in "$endpoint" "origin/$endpoint"; do
		if git rev-parse --verify --quiet "$candidate^{commit}" >/dev/null; then
			printf '%s' "$candidate"
			return
		fi
	done
	fail "cannot resolve '$endpoint' — fetch it first and pass a SHA or a remote-tracking ref such as origin/<branch>"
}

resolve_range_target() {
	validate_range_spec
	local range_base range_head
	range_base="$(resolve_endpoint "${range_spec%%..*}")" || exit 1
	range_head="$(resolve_endpoint "${range_spec##*..}")" || exit 1
	mode="range"
	base_branch="$range_base"
	base_is_local="no"
	merge_base="$(git merge-base "$range_base" "$range_head" 2>/dev/null || git rev-parse "$range_base^{commit}")"
	head_sha="$(git rev-parse "$range_head^{commit}")"
	dirty="no"
	untracked=""
	include_untracked="no"
	diff_args=("$merge_base" "$head_sha")
}

resolve_auto_target() {
	head_sha="$(git rev-parse --verify --quiet HEAD || true)"
	base_branch="$(detect_base_branch)"
	base_is_local="$(base_ref_is_local_only "$base_branch")"
	untracked="$(list_untracked_files)"
	merge_base=""
	if [ -n "$base_branch" ] && [ -n "$head_sha" ]; then
		merge_base="$(git merge-base HEAD "$base_branch" 2>/dev/null || true)"
	fi
	select_auto_mode
}

detect_base_branch() {
	if [ -n "$base_override" ]; then
		git rev-parse --verify --quiet "$base_override^{commit}" >/dev/null ||
			fail "cannot resolve base branch '$base_override'"
		printf '%s' "$base_override"
		return
	fi
	local candidates=()
	local origin_head
	origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
	if [ -n "$origin_head" ]; then
		candidates+=("$origin_head")
	fi
	candidates+=(origin/main main origin/master master origin/develop develop)
	local candidate
	for candidate in "${candidates[@]}"; do
		if git rev-parse --verify --quiet "$candidate" >/dev/null; then
			printf '%s' "$candidate"
			return
		fi
	done
}

# A local base ref can lag origin: if HEAD already merged a fresher origin/<base>, the stale
# merge-base leaks those merged commits into the diff. Flagged in the output, not fixed.
base_ref_is_local_only() {
	local ref="$1"
	if [ -n "$ref" ] && ! git rev-parse --verify --quiet "refs/remotes/$ref" >/dev/null 2>&1; then
		echo "yes"
	else
		echo "no"
	fi
}

# The context file's own directory holds the caller's outputs (earlier context files, shards,
# reports), which are never part of the change.
list_untracked_files() {
	local output_dir
	output_dir="$(output_dir_relative_to_repo)"
	git -c core.quotePath=false ls-files --others --exclude-standard ${pathspec[@]+"${pathspec[@]}"} |
		awk -v prefix="$output_dir" 'prefix == "" || index($0, prefix) != 1'
}

output_dir_relative_to_repo() {
	local context_dir
	context_dir="$(dirname "$context_path")"
	case "$context_dir" in
	"$repo_root") echo "" ;;
	"$repo_root"/*) echo "${context_dir#"$repo_root"/}/" ;;
	*) echo "" ;;
	esac
}

working_tree_is_dirty() {
	! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null || [ -n "$untracked" ]
}

# Committed-work modes diff commit-to-commit so the result never depends on the working tree
# being readable — a sandbox that denies stat on a tracked path (e.g. .env) otherwise makes
# git report it as deleted. Only working-tree mode, which exists to review uncommitted
# edits, reads the tree.
select_auto_mode() {
	local empty_tree tree_dirty="no"
	empty_tree="$(git hash-object -t tree /dev/null)"
	if working_tree_is_dirty; then
		tree_dirty="yes"
	fi
	dirty="no"
	include_untracked="no"
	if [ -n "$merge_base" ] && [ "$merge_base" != "$head_sha" ]; then
		mode="branch"
		diff_args=("$merge_base" "$head_sha")
		dirty="$tree_dirty"
	elif [ "$tree_dirty" = "yes" ]; then
		mode="working-tree"
		diff_args=("${head_sha:-$empty_tree}")
		dirty="yes"
		if [ -n "$untracked" ]; then
			include_untracked="yes"
		fi
	elif [ -n "$head_sha" ] && git rev-parse --verify --quiet 'HEAD~1' >/dev/null; then
		mode="last-commit"
		diff_args=("$(git rev-parse 'HEAD~1')" "$head_sha")
	elif [ -n "$head_sha" ]; then
		mode="initial-commit"
		diff_args=("$empty_tree" "$head_sha")
	else
		mode="unborn-branch"
		diff_args=("$empty_tree")
	fi
}

collect_name_status() {
	name_status="$(git -c core.quotePath=false diff --name-status "${diff_args[@]}" ${pathspec[@]+"${pathspec[@]}"})"
	if [ "$include_untracked" = "yes" ]; then
		local untracked_rows
		untracked_rows="$(printf '%s\n' "$untracked" | awk '{ print "A\t" $0 }')"
		if [ -n "$name_status" ]; then
			name_status="$name_status"$'\n'"$untracked_rows"
		else
			name_status="$untracked_rows"
		fi
	fi
	file_count="$(printf '%s\n' "$name_status" | grep -c . || true)"
}

emit_diff() {
	git -c core.quotePath=false diff "${diff_args[@]}" ${pathspec[@]+"${pathspec[@]}"}
	[ "$include_untracked" = "yes" ] || return 0
	local path
	while IFS= read -r path; do
		[ -n "$path" ] || continue
		git -c core.quotePath=false diff --no-index -- /dev/null "$path" || [ $? -eq 1 ]
	done <<<"$untracked"
}

write_metadata_table() {
	local now_utc base_cell
	now_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	base_cell="\`${base_branch:-(none detected)}\`"
	if [ "$mode" = "branch" ] && [ "$base_is_local" = "yes" ]; then
		base_cell="$base_cell ⚠ local ref — may be stale; run \`git fetch\`, else merged-in changes can appear"
	fi
	cat <<METADATA
## Metadata

| Field | Value |
| ----- | ----- |
| Generated | \`$now_utc\` |
| Branch | \`$branch_name\` |
| Change target | \`$mode\` |
| Base | $base_cell |
| Merge base | \`${merge_base:-n/a}\` |
| HEAD | \`${head_sha:-n/a}\` |
| Working tree dirty | \`$dirty\` |
| Files changed | \`$file_count\` |
METADATA
}

write_changed_files_section() {
	cat <<CHANGED
## Changed files

\`\`\`
${name_status:-(no changes)}
\`\`\`

> \`D\` = deleted (shown in the diff for context; do not open deleted files from disk).
CHANGED
}

write_context_file() {
	{
		echo "# Change context"
		echo
		echo "The single shared snapshot of the change. Generated by \`get-changes.sh\` — do not edit by hand. Callers append their own sections below."
		echo
		write_metadata_table
		echo
		write_changed_files_section
		echo
		echo "## Unified diff"
		echo
		echo '```diff'
		emit_diff
		echo '```'
	} >"$context_path"
}

print_summary() {
	cat <<SUMMARY
MODE=$mode
BASE=$base_branch
BASE_IS_LOCAL=$base_is_local
MERGE_BASE=$merge_base
HEAD=$head_sha
DIRTY=$dirty
FILE_COUNT=$file_count
CONTEXT_FILE=$context_file
--- changed files (name-status) ---
SUMMARY
	[ -z "$name_status" ] || printf '%s\n' "$name_status"
}

main() {
	parse_args "$@"
	require_git_repo
	context_path="$(absolute_path "$context_file")"
	repo_root="$(git rev-parse --show-toplevel)"
	cd "$repo_root"
	branch_name="$(current_branch_name)"
	if [ -n "$range_spec" ]; then
		resolve_range_target
	else
		resolve_auto_target
	fi
	collect_name_status
	write_context_file
	print_summary
}

main "$@"
