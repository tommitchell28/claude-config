#!/usr/bin/env bash
# Fetch the skills named in third-party-skills.json and stage each source as a
# skills-directory plugin under .third-party/skills/, for setup.sh to deploy.
set -euo pipefail

readonly EXIT_FETCH_FAILED=1
# Keep in step with invalid_manifest_exit_code in setup.sh. Not a code jq or
# git exits with, so setup.sh can tell a bad manifest from a failed fetch.
readonly EXIT_INVALID_MANIFEST=65
readonly CLAUDE_CODE_SKILLS_DIR_NAME="synced"

show_help() {
  cat <<'HELP'
Usage: fetch-third-party-skills.sh [-h|--help]

Reads third-party-skills.json at the repo root. For each source it fetches
"ref" from "repo" into .third-party/cache/<plugin>/, then builds a
skills-directory plugin in .third-party/skills/<plugin>/:

  .claude-plugin/plugin.json   generated; names the upstream repo and commit
  skills/<name>/               one copy of each directory listed in "skills"

Each "rewrites" pair replaces the whole word "from" with "to" in the copied
files. A "from" that matches nothing is reported as a warning.

.third-party/skills/ is rebuilt from scratch on every run and is removed if
the run fails, so it never holds a stale or partial copy. Nothing outside
.third-party/ is written. Requires git, jq and perl.

Manifest entry:
  {
    "plugin": "mattpocock",
    "repo": "https://github.com/mattpocock/skills.git",
    "ref": "main",
    "skills": ["skills/engineering/tdd"],
    "rewrites": [{ "from": "code-review", "to": "reviewing-code" }]
  }

Exit codes:
  0    every source was fetched and staged
  1    a fetch failed or a required tool is missing
  65   the manifest is invalid: wrong shape, a plugin name used twice, equal
       to a directory in .claude/skills/ or equal to "synced", or two skills
       in one source with the same directory name

Example:
  scripts/fetch-third-party-skills.sh
HELP
}

for argument in "$@"; do
  case "${argument}" in
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown argument: ${argument}" >&2
      echo "Run 'fetch-third-party-skills.sh --help' for usage." >&2
      exit 2
      ;;
  esac
done

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="${repo_dir}/third-party-skills.json"
own_skills_dir="${repo_dir}/.claude/skills"
cache_dir="${repo_dir}/.third-party/cache"
staged_skills_dir="${repo_dir}/.third-party/skills"

is_staging_complete=false
remove_incomplete_staging() {
  [[ "${is_staging_complete}" == true ]] || rm -rf "${staged_skills_dir}"
}
trap remove_incomplete_staging EXIT

fail_fetch() {
  echo "Error: $1" >&2
  exit "${EXIT_FETCH_FAILED}"
}

fail_manifest() {
  echo "Error: ${manifest}: $1" >&2
  exit "${EXIT_INVALID_MANIFEST}"
}

require_tools() {
  local tool
  for tool in git jq perl; do
    command -v "${tool}" >/dev/null 2>&1 || fail_fetch "${tool} is required."
  done
}

# Plugin names and skill paths become directory names under .third-party/ and
# ~/.claude/skills/, so the shape check also keeps them inside those directories.
validate_manifest_shape() {
  jq -e '
    (.sources | type == "array") and all(.sources[];
      (.plugin | type == "string" and test("\\A[a-z0-9][a-z0-9-]*\\z")) and
      (.repo | type == "string" and length > 0) and
      (.ref | type == "string" and length > 0 and (test("[[:cntrl:]]") | not)) and
      (.skills | type == "array" and length > 0 and all(.[];
        type == "string" and (test("[[:cntrl:]]") | not) and
        (split("/") | length > 0 and all(.[]; . != "" and . != "." and . != "..")))) and
      ((.rewrites // []) | type == "array" and all(.[];
        (.from | type == "string" and length > 0) and (.to | type == "string"))))
  ' "${manifest}" >/dev/null 2>&1 ||
    fail_manifest "not valid JSON in the expected shape; see --help."
}

validate_manifest_names() {
  local -a clashes
  local plugin
  mapfile -t clashes < <(jq -r '
    def repeated: group_by(.) | map(select(length > 1) | .[0]) | .[];
    (.sources | map(.plugin) | repeated
      | "plugin name \"\(.)\" is used by more than one source"),
    (.sources[] | .plugin as $plugin | .skills | map(split("/") | last) | repeated
      | "source \"\($plugin)\" lists more than one skill directory named \"\(.)\"")
  ' "${manifest}")
  while IFS= read -r plugin; do
    if [[ -e "${own_skills_dir}/${plugin}" ]]; then
      clashes+=("plugin name \"${plugin}\" matches ${own_skills_dir}/${plugin}")
    elif [[ "${plugin}" == "${CLAUDE_CODE_SKILLS_DIR_NAME}" ]]; then
      clashes+=("plugin name \"${plugin}\" is a directory Claude Code manages in ~/.claude/skills/")
    fi
  done < <(jq -r '.sources[].plugin' "${manifest}")
  [[ ${#clashes[@]} -eq 0 ]] || fail_manifest "$(printf '%s\n' "${clashes[@]}")"
}

fetch_checkout() {
  local checkout_dir="$1" repo="$2" ref="$3"
  git init --quiet "${checkout_dir}" ||
    fail_fetch "could not create ${checkout_dir}."
  GIT_TERMINAL_PROMPT=0 git -C "${checkout_dir}" fetch --quiet --depth 1 \
    --end-of-options "${repo}" "${ref}" ||
    fail_fetch "could not fetch ${ref} from ${repo}."
  git -C "${checkout_dir}" checkout --quiet --force --detach FETCH_HEAD ||
    fail_fetch "could not check out ${ref} from ${repo}."
}

copy_skills() {
  local source="$1" checkout_dir="$2" plugin_dir="$3"
  local skill_path resolved_checkout_dir
  resolved_checkout_dir="$(realpath "${checkout_dir}")"
  mkdir -p "${plugin_dir}/skills"
  while IFS= read -r skill_path; do
    [[ -f "${checkout_dir}/${skill_path}/SKILL.md" ]] ||
      fail_fetch "upstream has no ${skill_path}/SKILL.md."
    # A symlinked parent directory would make cp read from outside the checkout.
    [[ "$(realpath "${checkout_dir}/${skill_path}")" == "${resolved_checkout_dir}/${skill_path}" ]] ||
      fail_fetch "upstream ${skill_path} is reached through a symlink, which is not deployed."
    cp -R "${checkout_dir}/${skill_path}" "${plugin_dir}/skills/"
  done < <(jq -r '.skills[]' <<<"${source}")

  # A symlink would be deployed as-is and could point anywhere on the machine.
  local symlinks
  symlinks="$(find "${plugin_dir}" -type l)"
  [[ -z "${symlinks}" ]] ||
    fail_fetch "upstream skills contain symlinks, which are not deployed: ${symlinks}"
}

apply_rewrites() {
  local source="$1" plugin_dir="$2"
  local rewrite from to
  local -a matching_files
  while IFS= read -r rewrite; do
    from="$(jq -r '.from' <<<"${rewrite}")"
    to="$(jq -r '.to' <<<"${rewrite}")"
    mapfile -t matching_files < <(
      grep --recursive --files-with-matches --word-regexp --fixed-strings \
        --binary-files=without-match -e "${from}" "${plugin_dir}/skills" || true
    )
    if [[ ${#matching_files[@]} -eq 0 ]]; then
      echo "  WARNING: rewrite \"${from}\" -> \"${to}\" matched nothing; upstream may have reworded."
      continue
    fi
    REWRITE_FROM="${from}" REWRITE_TO="${to}" perl -pi -e \
      's/(?<!\w)\Q$ENV{REWRITE_FROM}\E(?!\w)/$ENV{REWRITE_TO}/g' "${matching_files[@]}"
  done < <(jq -c '(.rewrites // [])[]' <<<"${source}")
}

write_plugin_manifest() {
  local source="$1" plugin_dir="$2" commit="$3"
  mkdir -p "${plugin_dir}/.claude-plugin"
  jq --arg commit "${commit}" '{
    name: .plugin,
    description: "Skills from \(.repo) at commit \($commit), installed by claude-config setup.sh."
  }' <<<"${source}" >"${plugin_dir}/.claude-plugin/plugin.json"
}

stage_source() {
  local source="$1"
  local plugin repo ref
  plugin="$(jq -r '.plugin' <<<"${source}")"
  repo="$(jq -r '.repo' <<<"${source}")"
  ref="$(jq -r '.ref' <<<"${source}")"
  local checkout_dir="${cache_dir}/${plugin}"
  local plugin_dir="${staged_skills_dir}/${plugin}"

  local commit
  fetch_checkout "${checkout_dir}" "${repo}" "${ref}"
  commit="$(git -C "${checkout_dir}" rev-parse HEAD)"
  copy_skills "${source}" "${checkout_dir}" "${plugin_dir}"
  apply_rewrites "${source}" "${plugin_dir}"
  write_plugin_manifest "${source}" "${plugin_dir}" "${commit}"

  local skill_count
  skill_count="$(jq '.skills | length' <<<"${source}")"
  echo "  ${plugin}: ${skill_count} skills from ${repo} (${ref}) at commit ${commit}"
}

require_tools
[[ -f "${manifest}" ]] || fail_manifest "not found."
validate_manifest_shape
validate_manifest_names

rm -rf "${staged_skills_dir}"
mkdir -p "${cache_dir}" "${staged_skills_dir}"
while IFS= read -r source; do
  stage_source "${source}"
done < <(jq -c '.sources[]' "${manifest}")
is_staging_complete=true
