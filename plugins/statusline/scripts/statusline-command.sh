#!/bin/sh
input=$(cat)

# Colors
RESET='\033[0m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'

# Separator (spaces only, no pipe)
SEP="  "

# Thick block bar: ▰▰▰▱▱▱▱ style
make_block_bar() {
  pct=$1
  width=${2:-20}
  filled=$(( pct * width / 100 ))
  empty=$(( width - filled ))
  bar=""
  i=0
  while [ $i -lt $filled ]; do
    bar="${bar}▰"
    i=$(( i + 1 ))
  done
  i=0
  while [ $i -lt $empty ]; do
    bar="${bar}▱"
    i=$(( i + 1 ))
  done
  printf '%s' "$bar"
}

# Format tokens always as K (50000 → 50K, 1000000 → 1000K)
fmt_k() {
  n=$1
  if [ "$n" -ge 1000 ]; then
    printf '%dK' $(( n / 1000 ))
  else
    printf '%d' "$n"
  fi
}

# Format context size as M or K (1000000 → 1M, 200000 → 200K)
fmt_ctx_size() {
  n=$1
  if [ "$n" -ge 1000000 ]; then
    printf '%dM' $(( n / 1000000 ))
  elif [ "$n" -ge 1000 ]; then
    printf '%dK' $(( n / 1000 ))
  else
    printf '%d' "$n"
  fi
}

# Session name or ID
session_name=$(echo "$input" | jq -r '.session_name // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')
if [ -n "$session_name" ]; then
  session_label="$session_name"
elif [ -n "$session_id" ]; then
  session_label=$(printf '%.8s' "$session_id")
else
  session_label=""
fi

# Working directory
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')

# Git branch + dirty status
git_branch=""
git_dirty=""
if [ -n "$cwd" ] && command -v git >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$git_branch" ]; then
    git_status=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
    [ -n "$git_status" ] && git_dirty="*"
  fi
fi

# Model
model_name=$(echo "$input" | jq -r '.model.display_name // empty')

# Context usage
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_used=$(echo "$input" | jq -r '.context_window.used_tokens // empty')
ctx_max=$(echo "$input" | jq -r '.context_window.max_tokens // empty')

# Code changes
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')

# Cost
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# Rate limits
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_h_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Build output helpers
line1=""
line2=""

append_line1() {
  if [ -z "$line1" ]; then
    line1="$1"
  else
    line1="${line1}${SEP}$1"
  fi
}

append_line2() {
  if [ -z "$line2" ]; then
    line2="$1"
  else
    line2="${line2}${SEP}$1"
  fi
}

# --- Line 1: Environment ---

# Session
if [ -n "$session_label" ]; then
  append_line1 "$(printf '%b' "🏷️  ${CYAN}${BOLD}${session_label}${RESET}")"
fi

# Model + context size
if [ -n "$model_name" ]; then
  if [ -n "$ctx_max" ]; then
    ctx_size=$(fmt_ctx_size "$ctx_max")
    append_line1 "$(printf '%b' "🤖 ${MAGENTA}${BOLD}${model_name}${RESET} ${DIM}(${ctx_size} context)${RESET}")"
  else
    append_line1 "$(printf '%b' "🤖 ${MAGENTA}${BOLD}${model_name}${RESET}")"
  fi
fi

# Context dot bar + token counts
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  if [ "$used_int" -gt 80 ]; then
    ctx_color="$RED"
  elif [ "$used_int" -gt 50 ]; then
    ctx_color="$YELLOW"
  else
    ctx_color="$GREEN"
  fi
  bar=$(make_block_bar "$used_int" 20)
  if [ -n "$ctx_used" ] && [ -n "$ctx_max" ]; then
    used_label="$(fmt_k "$ctx_used")/$(fmt_k "$ctx_max")"
    append_line1 "$(printf '%b' "${ctx_color}${bar}${RESET} ${DIM}${used_label} (${used_int}%)${RESET}")"
  else
    append_line1 "$(printf '%b' "${ctx_color}${bar}${RESET} ${DIM}${used_int}%${RESET}")"
  fi
fi

# Working directory
if [ -n "$cwd" ]; then
  short_cwd=$(echo "$cwd" | sed "s|$HOME|~|")
  append_line1 "$(printf '%b' "📔 ${YELLOW}${short_cwd}${RESET}")"
fi

# Git branch + code changes
if [ -n "$git_branch" ]; then
  changes=""
  if [ -n "$lines_added" ] || [ -n "$lines_removed" ]; then
    added="${lines_added:-0}"
    removed="${lines_removed:-0}"
    changes=" ${DIM}(${RESET}${GREEN}+${added}${RESET} ${RED}-${removed}${RESET}${DIM})${RESET}"
  fi
  append_line1 "$(printf '%b' "🌿 ${GREEN}${git_branch}${git_dirty}${RESET}${changes}")"
fi

# --- Line 2: Usage ---

# Rate limits
if [ -n "$five_h" ]; then
  five_int=$(printf '%.0f' "$five_h")
  if [ "$five_int" -gt 80 ]; then
    five_color="$RED"; five_icon="🪫"
  elif [ "$five_int" -gt 50 ]; then
    five_color="$YELLOW"; five_icon="🔋"
  else
    five_color="$GREEN"; five_icon="🔋"
  fi
  bar=$(make_block_bar "$five_int" 12)
  reset_label=""
  if [ -n "$five_h_resets" ]; then
    reset_ts=$(date -r "$five_h_resets" '+%H:%M' 2>/dev/null || date -d "@$five_h_resets" '+%H:%M' 2>/dev/null)
    [ -n "$reset_ts" ] && reset_label=" ${DIM}→${reset_ts}${RESET}"
  fi
  append_line2 "$(printf '%b' "${five_icon} ${CYAN}5h${RESET} ${five_color}${bar} ${five_int}%${RESET}${reset_label}")"
fi
if [ -n "$seven_d" ]; then
  seven_int=$(printf '%.0f' "$seven_d")
  if [ "$seven_int" -gt 80 ]; then
    seven_color="$RED"
  elif [ "$seven_int" -gt 50 ]; then
    seven_color="$YELLOW"
  else
    seven_color="$GREEN"
  fi
  bar=$(make_block_bar "$seven_int" 12)
  append_line2 "$(printf '%b' "🗓️  ${CYAN}7d${RESET} ${seven_color}${bar} ${seven_int}%${RESET}")"
fi

# Cost
if [ -n "$total_cost" ]; then
  append_line2 "$(printf '%b' "💰 ${CYAN}Cost${RESET} ${YELLOW}\$$(printf '%.2f' "$total_cost")${RESET}")"
fi

# Output
if [ -n "$line1" ] && [ -n "$line2" ]; then
  printf '%b\n%b' "$line1" "$line2"
elif [ -n "$line1" ]; then
  printf '%b' "$line1"
elif [ -n "$line2" ]; then
  printf '%b' "$line2"
fi
