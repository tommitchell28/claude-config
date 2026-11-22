#!/usr/bin/env bash
# Fetch the skills named in third-party-skills.json and stage each source as a
# skills-directory plugin under .third-party/skills/, for setup.sh to deploy.
set -euo pipefail

readonly EXIT_FETCH_FAILED=1
# Keep in step with invalid_manifest_exit_code in setup.sh. Not a code jq or
# git exits with, so setup.sh can tell a bad manifest from a failed fetch.
readonly EXIT_INVALID_MANIFEST=65
readonly CLAUDE_CODE_SKILLS_DIR_NAME="synced"
# The skill catalog that the AWS CLI's `aws agent-toolkit` commands install
# from. Its read operations need no AWS credentials.
readonly AWS_AGENT_TOOLKIT_ENDPOINT="https://agent-toolkit.us-east-1.api.aws"
# The catalog category `aws configure agent-toolkit` installs by default.
readonly AWS_AGENT_TOOLKIT_DEFAULT_CATEGORY="aws-core"
# The AWS CLI refuses a skill that unpacks to more than this; the same limit
# also caps each download.
readonly AWS_AGENT_TOOLKIT_MAX_SKILL_BYTES=$((10 * 1024 * 1024))

show_help() {
  cat <<'HELP'
Usage: fetch-third-party-skills.sh [-h|--help]

Reads third-party-skills.json at the repo root and builds a skills-directory
plugin in .third-party/skills/<plugin>/ for each source:

  .claude-plugin/plugin.json   generated; names where the skills came from
  skills/<name>/               one copy of each skill listed in "skills"

A source has one of two types:

  git (the default)   fetches "ref" from "repo" into .third-party/cache/<plugin>/
                      and copies each directory listed in "skills".
  aws-agent-toolkit   downloads the latest version of each skill named in
                      "skills" from the AWS Agent Toolkit catalog, the one
                      `aws agent-toolkit` installs from, into
                      .third-party/cache/<plugin>/. Each download is checked
                      against the catalog's SHA-256 checksum, which catches a
                      corrupted download, and refused if it unpacks to more
                      than 10 MiB, as the AWS CLI does. The skill versions are
                      written to skill-versions.txt in the plugin. Nothing is
                      installed that "skills" does not list: a skill in AWS's
                      default set that it leaves out is reported as NEW, and a
                      listed skill outside that set is noted and still
                      installed.

Each "rewrites" pair replaces the whole word "from" with "to" in the copied
files. A "from" that matches nothing is reported as a warning.

.third-party/skills/ is rebuilt from scratch on every run and is removed if
the run fails, so it never holds a stale or partial copy. Nothing outside
.third-party/ is written. Requires jq and perl, git for git sources, and curl,
unzip and sha256sum for aws-agent-toolkit sources.

Manifest entries:
  {
    "plugin": "mattpocock",
    "repo": "https://github.com/mattpocock/skills.git",
    "ref": "main",
    "skills": ["skills/engineering/tdd"],
    "rewrites": [{ "from": "code-review", "to": "reviewing-code" }]
  }
  {
    "plugin": "aws",
    "type": "aws-agent-toolkit",
    "skills": ["aws-iam", "aws-storage"]
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
  for tool in "$@"; do
    command -v "${tool}" >/dev/null 2>&1 || fail_fetch "${tool} is required."
  done
}

# Plugin names and skill paths become directory names under .third-party/ and
# ~/.claude/skills/, so the shape check also keeps them inside those directories.
# An AWS skill name's 64-character limit is the catalog's own, from the AWS CLI's
# service model.
validate_manifest_shape() {
  jq -e '
    def git_source:
      (.repo | type == "string" and length > 0) and
      (.ref | type == "string" and length > 0 and (test("[[:cntrl:]]") | not)) and
      (.skills | type == "array" and length > 0 and all(.[];
        type == "string" and (test("[[:cntrl:]]") | not) and
        (split("/") | length > 0 and all(.[]; . != "" and . != "." and . != ".."))));
    def aws_agent_toolkit_source:
      (has("repo") or has("ref") | not) and
      (.skills | type == "array" and length > 0 and all(.[];
        type == "string" and test("\\A[a-z0-9][a-z0-9-]{0,63}\\z")));
    (.sources | type == "array") and all(.sources[];
      (.plugin | type == "string" and test("\\A[a-z0-9][a-z0-9-]*\\z")) and
      (if (.type // "git") == "git" then git_source
       elif .type == "aws-agent-toolkit" then aws_agent_toolkit_source
       else false end) and
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
}

aws_agent_toolkit_get() {
  local path="$1" output="$2"
  # --speed-limit with --speed-time turns a stalled transfer into a failure,
  # which --retry then retries.
  curl --fail --silent --show-error --location --proto '=https' \
    --connect-timeout 10 --speed-limit 1 --speed-time 30 --retry 2 \
    --max-filesize "${AWS_AGENT_TOOLKIT_MAX_SKILL_BYTES}" \
    --output "${output}" "${AWS_AGENT_TOOLKIT_ENDPOINT}${path}"
}

fetch_aws_agent_toolkit_version() {
  local skill="$1" download_dir="$2"
  local version_file="${download_dir}/${skill}.latest"
  aws_agent_toolkit_get "/skills/${skill}/latest" "${version_file}" ||
    fail_fetch "could not look up the latest version of AWS skill ${skill}."
  local version
  version="$(tr -d '[:space:]' <"${version_file}")"
  [[ "${version}" =~ ^v[0-9]+$ ]] ||
    fail_fetch "AWS skill ${skill} has an unexpected latest version \"${version}\"."
  echo "${version}"
}

# The checksum comes from the same catalog as the archive, so it catches a
# corrupted download, not a tampered one.
download_aws_agent_toolkit_archive() {
  local skill="$1" version="$2" archive="$3"
  local files_path="/skills/${skill}/versions/${version}/files/download"
  local checksum_file="${archive}.sha256"
  aws_agent_toolkit_get "${files_path}" "${archive}" ||
    fail_fetch "could not download AWS skill ${skill} ${version}."
  aws_agent_toolkit_get "${files_path}/checksum" "${checksum_file}" ||
    fail_fetch "could not download the checksum of AWS skill ${skill} ${version}."
  local expected actual
  expected="$(awk '{ print tolower($1); exit }' "${checksum_file}")"
  actual="$(sha256sum "${archive}" | awk '{ print $1 }')"
  [[ "${actual}" == "${expected}" ]] ||
    fail_fetch "AWS skill ${skill} ${version} does not match its checksum."
}

# Entry names become paths on disk, so none may be absolute or climb out, and
# the unpacked total is capped against an archive that expands to fill the disk.
check_aws_agent_toolkit_archive() {
  local skill="$1" version="$2" archive="$3"
  local escaping_path_pattern='(^/|(^|/)\.\.(/|$))'
  local entries unpacked_bytes
  entries="$(unzip -Z1 "${archive}")" ||
    fail_fetch "could not read the archive of AWS skill ${skill} ${version}."
  if grep -qE "${escaping_path_pattern}" <<<"${entries}"; then
    fail_fetch "the archive of AWS skill ${skill} ${version} has a path outside the skill."
  fi
  # The summary line reads "<n> files, <bytes> bytes uncompressed, ...".
  unpacked_bytes="$(unzip -Zt "${archive}" | awk '{ print $3 }')"
  [[ "${unpacked_bytes}" =~ ^[0-9]+$ ]] ||
    fail_fetch "could not read the unpacked size of AWS skill ${skill} ${version}."
  if ((unpacked_bytes > AWS_AGENT_TOOLKIT_MAX_SKILL_BYTES)); then
    fail_fetch "AWS skill ${skill} ${version} unpacks to ${unpacked_bytes} bytes, over the ${AWS_AGENT_TOOLKIT_MAX_SKILL_BYTES}-byte limit."
  fi
}

unpack_aws_agent_toolkit_archive() {
  local skill="$1" version="$2" archive="$3" skill_dir="$4"
  mkdir -p "${skill_dir}"
  # Without stdin, a "replace?" prompt for a duplicate entry fails the unpack
  # instead of reading the caller's list of skill names as its answer.
  unzip -q "${archive}" -d "${skill_dir}" </dev/null ||
    fail_fetch "could not unpack AWS skill ${skill} ${version}."
  [[ -f "${skill_dir}/SKILL.md" ]] ||
    fail_fetch "AWS skill ${skill} ${version} has no SKILL.md."
}

stage_aws_agent_toolkit_skill() {
  local skill="$1" version="$2" download_dir="$3" plugin_dir="$4"
  local archive="${download_dir}/${skill}-${version}.zip"
  download_aws_agent_toolkit_archive "${skill}" "${version}" "${archive}"
  check_aws_agent_toolkit_archive "${skill}" "${version}" "${archive}"
  unpack_aws_agent_toolkit_archive "${skill}" "${version}" "${archive}" \
    "${plugin_dir}/skills/${skill}"
}

# Prints the default set's skill names, one per line, paging through the
# catalog. The caller runs this under `if !`, where set -e is off, so each step
# returns its own failure.
list_aws_agent_toolkit_default_skills() {
  local download_dir="$1"
  local page="${download_dir}/default-skills.json" query next_token=""
  while :; do
    query="category_filter=${AWS_AGENT_TOOLKIT_DEFAULT_CATEGORY}&max_results=100"
    [[ -z "${next_token}" ]] || query+="&next_token=${next_token}"
    aws_agent_toolkit_get "/api/skills?${query}" "${page}" || return 1
    jq -r '.skills[].name' "${page}" || return 1
    next_token="$(jq -r '.nextToken // empty | @uri' "${page}")" || return 1
    [[ -n "${next_token}" ]] || return 0
  done
}

# Nothing is installed unless the manifest lists it, so skills in AWS's default
# set that it leaves out are reported for a decision instead.
report_aws_agent_toolkit_default_set() {
  local source="$1" plugin="$2" download_dir="$3"
  local default_skills listed_skills skill
  if ! default_skills="$(list_aws_agent_toolkit_default_skills "${download_dir}" | sort)"; then
    echo "  WARNING: could not list AWS's default skills, so new ones are not reported."
    return 0
  fi
  listed_skills="$(jq -r '.skills[]' <<<"${source}" | sort)"
  while IFS= read -r skill; do
    echo "  NEW: AWS's default set has \"${skill}\", which the \"${plugin}\" source does not list. Add it to install it."
  done < <(comm -23 <(echo "${default_skills}") <(echo "${listed_skills}") | grep -v '^$')
  while IFS= read -r skill; do
    echo "  NOTE: \"${skill}\" is listed but not in AWS's default set. It is still installed while AWS serves it."
  done < <(comm -13 <(echo "${default_skills}") <(echo "${listed_skills}") | grep -v '^$')
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
  local source="$1" plugin_dir="$2" origin="$3" note="${4:-}"
  mkdir -p "${plugin_dir}/.claude-plugin"
  jq --arg origin "${origin}" --arg note "${note}" '{
    name: .plugin,
    description: ("Skills from \($origin), installed by claude-config setup.sh."
      + if $note == "" then "" else " \($note)" end)
  }' <<<"${source}" >"${plugin_dir}/.claude-plugin/plugin.json"
}

# A symlink would be deployed as-is and could point anywhere on the machine.
reject_symlinks() {
  local plugin_dir="$1"
  local symlinks
  symlinks="$(find "${plugin_dir}" -type l)"
  [[ -z "${symlinks}" ]] ||
    fail_fetch "upstream skills contain symlinks, which are not deployed: ${symlinks}"
}

# Every staged plugin gets the same safety check, rewrites and manifest,
# whichever type of source it came from.
finish_staged_plugin() {
  local source="$1" plugin_dir="$2" origin="$3" note="${4:-}"
  reject_symlinks "${plugin_dir}"
  apply_rewrites "${source}" "${plugin_dir}"
  write_plugin_manifest "${source}" "${plugin_dir}" "${origin}" "${note}"
}

stage_git_source() {
  local source="$1" plugin="$2"
  local repo ref
  repo="$(jq -r '.repo' <<<"${source}")"
  ref="$(jq -r '.ref' <<<"${source}")"
  local checkout_dir="${cache_dir}/${plugin}"
  local plugin_dir="${staged_skills_dir}/${plugin}"

  require_tools git
  local commit
  fetch_checkout "${checkout_dir}" "${repo}" "${ref}"
  commit="$(git -C "${checkout_dir}" rev-parse HEAD)"
  copy_skills "${source}" "${checkout_dir}" "${plugin_dir}"
  finish_staged_plugin "${source}" "${plugin_dir}" "${repo} at commit ${commit}"

  local skill_count
  skill_count="$(jq '.skills | length' <<<"${source}")"
  echo "  ${plugin}: ${skill_count} skills from ${repo} (${ref}) at commit ${commit}"
}

stage_aws_agent_toolkit_source() {
  local source="$1" plugin="$2"
  local download_dir="${cache_dir}/${plugin}"
  local plugin_dir="${staged_skills_dir}/${plugin}"
  local versions_file="${plugin_dir}/skill-versions.txt"

  require_tools curl unzip sha256sum
  rm -rf "${download_dir}"
  mkdir -p "${download_dir}" "${plugin_dir}/skills"
  local skill version
  while IFS= read -r skill; do
    version="$(fetch_aws_agent_toolkit_version "${skill}" "${download_dir}")"
    stage_aws_agent_toolkit_skill "${skill}" "${version}" "${download_dir}" "${plugin_dir}"
    echo "${skill} ${version}" >>"${versions_file}"
  done < <(jq -r '.skills[]' <<<"${source}")
  finish_staged_plugin "${source}" "${plugin_dir}" \
    "the AWS Agent Toolkit catalog at ${AWS_AGENT_TOOLKIT_ENDPOINT}" \
    "Skill versions are in skill-versions.txt."

  local skill_count
  skill_count="$(jq '.skills | length' <<<"${source}")"
  echo "  ${plugin}: ${skill_count} skills from the AWS Agent Toolkit catalog"
  report_aws_agent_toolkit_default_set "${source}" "${plugin}" "${download_dir}"
}

stage_source() {
  local source="$1"
  local plugin type
  plugin="$(jq -r '.plugin' <<<"${source}")"
  type="$(jq -r '.type // "git"' <<<"${source}")"
  case "${type}" in
    git) stage_git_source "${source}" "${plugin}" ;;
    aws-agent-toolkit) stage_aws_agent_toolkit_source "${source}" "${plugin}" ;;
    *) fail_manifest "source \"${plugin}\" has the unsupported type \"${type}\"." ;;
  esac
}

require_tools jq perl
[[ -f "${manifest}" ]] || fail_manifest "not found."
validate_manifest_shape
validate_manifest_names

rm -rf "${staged_skills_dir}"
mkdir -p "${cache_dir}" "${staged_skills_dir}"
while IFS= read -r source; do
  stage_source "${source}"
done < <(jq -c '.sources[]' "${manifest}")
is_staging_complete=true
