#!/usr/bin/env bash
# Split a change-context file into a shared header (everything except the diff) plus one
# diff shard per changed file, so a parallel agent reads only its slice. Prints a manifest
# routing each changed file to its shard. Diff bytes are copied, never rewritten.
set -euo pipefail

usage() {
	cat <<'USAGE'
Usage: shard-context.sh <context-file> <shard-dir>

Splits a change-context file into:
  <shard-dir>/header.md               metadata + changed files + any appended sections (no diff)
  <shard-dir>/files/NNN_<path>.diff   the unified diff for one changed file

Prints a manifest to stdout:
  HEADER=<header path>
  SHARD<TAB><changed-file-path><TAB><shard path>   one line per file

Earlier shards in <shard-dir>/files are removed first, so the manifest and the directory
always agree. Run it after every section the caller appends is in the context file, so the
header shard carries the full shared context.
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
	case "${1:-}" in
	-h | --help)
		usage
		exit 0
		;;
	esac
	[ $# -eq 2 ] || fail_with_usage "expected <context-file> <shard-dir>"
	context_file="$1"
	shard_dir="$2"
	[ -f "$context_file" ] || fail "context file not found: $context_file"
}

# One pass over the context file: everything outside the "## Unified diff" fence goes to the
# header file (with a pointer where the diff was); the fence body goes to stdout.
split_header_from_diff() {
	awk -v header="$header_file" '
		!done && $0 == "## Unified diff" { in_section = 1; print >header; next }
		in_section && !in_fence && /^```diff/ {
			in_fence = 1
			print "```" >header
			print "(diff omitted from the header — read the per-file shards; this shard holds the shared context only)" >header
			print "```" >header
			next
		}
		in_fence && /^```[[:space:]]*$/ { in_fence = 0; in_section = 0; done = 1; next }
		in_fence { print; next }
		{ print >header }
	' "$context_file"
}

split_into_file_shards() {
	awk -v dir="$files_dir" '
		/^diff --git / {
			if (n > 0) close(outs[n])
			n++
			path = $0
			sub(/.* b\//, "", path)
			sub(/"$/, "", path)
			safe = path
			gsub(/[^A-Za-z0-9._-]/, "_", safe)
			paths[n] = path
			outs[n] = sprintf("%s/%03d_%s.diff", dir, n, safe)
		}
		n > 0 { print >outs[n] }
		END {
			for (i = 1; i <= n; i++) {
				printf "SHARD\t%s\t%s\n", paths[i], outs[i]
			}
		}
	'
}

main() {
	parse_args "$@"
	files_dir="$shard_dir/files"
	header_file="$shard_dir/header.md"
	mkdir -p "$files_dir"
	rm -f "$files_dir"/*.diff
	echo "HEADER=$header_file"
	split_header_from_diff | split_into_file_shards
}

main "$@"
