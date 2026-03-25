#!/usr/bin/env bash
set -euo pipefail

# Status line script: displays model, context bar, git branch, rate limits, duration
# Receives JSON on stdin from Claude Code after each assistant message.

input="$(cat)"

# Extract all fields in a single jq call for performance
eval "$(echo "$input" | jq -r '
  @sh "model_name=\(.model.display_name // "")",
  @sh "ctx_pct=\(.context_window.used_percentage // "")",
  @sh "ctx_size=\(.context_window.context_window_size // "")",
  @sh "input_tokens=\(.context_window.total_input_tokens // "")",
  @sh "output_tokens=\(.context_window.total_output_tokens // "")",
  @sh "duration_ms=\(.cost.total_duration_ms // "")",
  @sh "rate_5h=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "rate_7d=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "current_dir=\(.workspace.current_dir // "")"
')"

# Git branch (reads .git/HEAD — fast, no network)
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")"

# ANSI color codes
CYAN='\033[36m'
BLUE='\033[34m'
MAGENTA='\033[35m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# Returns color code based on percentage thresholds
color_for_pct() {
  local pct="${1:-}"
  if [[ -z "$pct" ]]; then
    echo "$RESET"
  elif [[ "$pct" -ge 80 ]]; then
    echo "$RED"
  elif [[ "$pct" -ge 50 ]]; then
    echo "$YELLOW"
  else
    echo "$GREEN"
  fi
}

# --- Model ---
short_model="${model_name#Claude }"
short_model="${short_model:-...}"

# --- Directory (show just the basename) ---
dir_name="${current_dir##*/}"
dir_name="${dir_name:-?}"

# --- Context progress bar (10 chars) + token count ---
format_tokens() {
  local tokens="$1"
  if [[ -z "$tokens" ]]; then
    echo "--"
  elif [[ "$tokens" -ge 1000000 ]]; then
    echo "$(( tokens / 1000000 )).$(( (tokens % 1000000) / 100000 ))M"
  elif [[ "$tokens" -ge 1000 ]]; then
    echo "$(( tokens / 1000 ))k"
  else
    echo "$tokens"
  fi
}

if [[ -n "$ctx_pct" ]]; then
  pct_int="${ctx_pct%%.*}"
  filled=$((pct_int * 10 / 100))
  empty=$((10 - filled))
  bar=""
  for ((i = 0; i < filled; i++)); do bar+="█"; done
  for ((i = 0; i < empty; i++)); do bar+="░"; done
  ctx_color="$(color_for_pct "$pct_int")"
  total_tokens=$(( ${input_tokens:-0} + ${output_tokens:-0} ))
  tokens_fmt="$(format_tokens "$total_tokens")"
  size_fmt="$(format_tokens "${ctx_size:-0}")"
  ctx_display="${ctx_color}${bar} ${pct_int}%${RESET} ${DIM}(${tokens_fmt}/${size_fmt})${RESET}"
else
  ctx_display="░░░░░░░░░░ --"
fi

# --- Rate limits ---
format_rate() {
  local label="$1" val="$2"
  if [[ -n "$val" ]]; then
    local int_val="${val%%.*}"
    local color
    color="$(color_for_pct "$int_val")"
    echo "${label}:${color}${int_val}%${RESET}"
  else
    echo "${label}:--"
  fi
}

rate_5h_display="$(format_rate "5h" "$rate_5h")"
rate_7d_display="$(format_rate "7d" "$rate_7d")"

# --- Duration ---
if [[ -n "$duration_ms" ]]; then
  total_sec=$((${duration_ms%%.*} / 1000))
  hours=$((total_sec / 3600))
  mins=$(((total_sec % 3600) / 60))
  if [[ "$hours" -gt 0 ]]; then
    dur_display="${hours}h ${mins}m"
  else
    dur_display="${mins}m"
  fi
else
  dur_display="--"
fi

# --- Assemble and output ---
echo -e "Dir: ${YELLOW}${dir_name}${RESET} ${DIM}|${RESET} Model: ${CYAN}${short_model}${RESET} ${DIM}|${RESET} Context: ${ctx_display} ${DIM}|${RESET} Branch: ${MAGENTA}${branch}${RESET} ${DIM}|${RESET} Usage: ${rate_5h_display} ${rate_7d_display} ${DIM}|${RESET} Session: ${BLUE}${dur_display}${RESET}"
