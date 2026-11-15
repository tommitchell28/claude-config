#!/usr/bin/env bash
# PostToolUse hook: flag house jargon in prose that was just written, as a soft advisory.
# Exit 2 is the channel that shows a PostToolUse hook's stderr to Claude; the write has
# already happened, so this never blocks.

set -uo pipefail

show_help() {
	cat <<'HELP'
Usage: check-jargon.sh < event.json

PostToolUse hook for Write and Edit. Reads the hook event JSON on stdin. When the
written text of a prose file (.md, .mdx, .markdown, .txt) contains a term from the
jargon ban list, prints an advisory with plainer alternatives on stderr and exits 2.
Exits 0 silently for code files, clean text, or when the ban list is missing.

The ban list is ../skills/simplify-response/references/jargon-banlist.json, relative
to this script.

Example:
  echo '{"tool_input":{"file_path":"notes.md","content":"a footgun"}}' | check-jargon.sh
HELP
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
	show_help
	exit 0
fi

# hooks/ and skills/ are siblings both in the repo and when deployed to ~/.claude.
hooks_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
banlist="${hooks_dir}/../skills/simplify-response/references/jargon-banlist.json"

input=$(cat)

path=$(jq -r '.tool_input.file_path // ""' <<<"$input")
case $path in
*.md | *.mdx | *.markdown | *.txt) ;;
*) exit 0 ;;
esac

# Write puts the whole file in .content; Edit puts the added text in .new_string.
content=$(jq -r '.tool_input.content // .tool_input.new_string // ""' <<<"$input")
[[ -n $content ]] || exit 0
[[ -f $banlist ]] || exit 0

# Fields are joined with the unit separator, not @tsv: @tsv doubles the backslashes in a
# pattern, and tab is IFS whitespace so an empty field would shift the ones after it.
field_separator=$'\x1f'
entries=$(jq -r '.autoMatched[] | [.pattern, .avoid, .prefer] | map(. // "") | join("\u001f")' "$banlist" 2>/dev/null)
[[ -n $entries ]] || exit 0

hits=$(
	while IFS="$field_separator" read -r pattern avoid prefer; do
		[[ -n $pattern ]] || continue
		# A here-string, not a pipe: with pipefail, grep -q closing a pipe early on a
		# large file would turn a match into a miss.
		if grep -iqE -- "$pattern" <<<"$content"; then
			printf '  - %s → %s\n' "$avoid" "$prefer"
		fi
	done <<<"$entries"
)
[[ -n $hits ]] || exit 0

{
	echo "Plain-voice advisory (not blocking) for $path — house jargon spotted, with plainer alternatives:"
	printf '%s\n' "$hits"
	echo "Swap in the plainer wording where it carries the same meaning. Leave any term that is genuinely the technical name for the thing."
} >&2
exit 2
