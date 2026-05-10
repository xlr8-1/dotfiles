#!/bin/bash
# Two-line statusline with visual context progress bar and usage limits
#
# Line 1: Model, folder, branch
# Line 2: Progress bar, context %, cost, duration, 5h/7d usage limits
#
# Context % uses Claude Code's pre-calculated remaining_percentage,
# which accounts for compaction reserves. 100% = compaction fires.
#
# Usage limits fetched from Anthropic API (oauth/usage), cached 3 min.
# NOTE: utilization field is already a percentage (e.g. 6.0 = 6%), not 0-1.

# Read stdin (Claude Code passes JSON data via stdin)
stdin_data=$(cat)

# Single jq call - extract all values at once
IFS=$'\t' read -r current_dir model_name cost lines_added lines_removed duration_ms ctx_used cache_pct < <(
	echo "$stdin_data" | jq -r '[
        .workspace.current_dir // "unknown",
        .model.display_name // "Unknown",
        (try (.cost.total_cost_usd // 0 | . * 100 | floor / 100) catch 0),
        (.cost.total_lines_added // 0),
        (.cost.total_lines_removed // 0),
        (.cost.total_duration_ms // 0),
        (try (
            if (.context_window.remaining_percentage // null) != null then
                100 - (.context_window.remaining_percentage | floor)
            elif (.context_window.context_window_size // 0) > 0 then
                (((.context_window.current_usage.input_tokens // 0) +
                  (.context_window.current_usage.cache_creation_input_tokens // 0) +
                  (.context_window.current_usage.cache_read_input_tokens // 0)) * 100 /
                 .context_window.context_window_size) | floor
            else "null" end
        ) catch "null"),
        (try (
            (.context_window.current_usage // {}) |
            if (.input_tokens // 0) + (.cache_read_input_tokens // 0) > 0 then
                ((.cache_read_input_tokens // 0) * 100 /
                 ((.input_tokens // 0) + (.cache_read_input_tokens // 0))) | floor
            else 0 end
        ) catch 0)
    ] | @tsv'
)

# Bash-level fallback
if [ -z "$current_dir" ] && [ -z "$model_name" ]; then
	current_dir=$(echo "$stdin_data" | jq -r '.workspace.current_dir // .cwd // "unknown"' 2>/dev/null)
	model_name=$(echo "$stdin_data" | jq -r '.model.display_name // "Unknown"' 2>/dev/null)
	cost=$(echo "$stdin_data" | jq -r '(.cost.total_cost_usd // 0)' 2>/dev/null)
	lines_added=$(echo "$stdin_data" | jq -r '(.cost.total_lines_added // 0)' 2>/dev/null)
	lines_removed=$(echo "$stdin_data" | jq -r '(.cost.total_lines_removed // 0)' 2>/dev/null)
	duration_ms=$(echo "$stdin_data" | jq -r '(.cost.total_duration_ms // 0)' 2>/dev/null)
	ctx_used=""
	cache_pct="0"
	: "${current_dir:=unknown}"
	: "${model_name:=Unknown}"
	: "${cost:=0}"
	: "${lines_added:=0}"
	: "${lines_removed:=0}"
	: "${duration_ms:=0}"
fi

# Git info
if cd "$current_dir" 2>/dev/null; then
	git_branch=$(git -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null)
	git_root=$(git -c core.useBuiltinFSMonitor=false rev-parse --show-toplevel 2>/dev/null)
fi

# Folder display
if [ -n "$git_root" ]; then
	repo_name=$(basename "$git_root")
	if [ "$current_dir" = "$git_root" ]; then
		folder_name="$repo_name"
	else
		folder_name=$(basename "$current_dir")
	fi
else
	folder_name=$(basename "$current_dir")
fi

# Visual progress bar for context usage
# Only show bar if we have a real value (not null)
progress_bar=""
bar_width=12
ctx_pct=""

if [ -n "$ctx_used" ] && [ "$ctx_used" != "null" ]; then
	filled=$((ctx_used * bar_width / 100))
	empty=$((bar_width - filled))

	if [ "$ctx_used" -lt 50 ]; then
		bar_color='\033[32m' # Green
	elif [ "$ctx_used" -lt 80 ]; then
		bar_color='\033[33m' # Yellow
	else
		bar_color='\033[31m' # Red
	fi

	progress_bar="${bar_color}"
	for ((i = 0; i < filled; i++)); do
		progress_bar="${progress_bar}█"
	done
	progress_bar="${progress_bar}\033[2m"
	for ((i = 0; i < empty; i++)); do
		progress_bar="${progress_bar}⣿"
	done
	progress_bar="${progress_bar}\033[0m"

	ctx_pct="${ctx_used}%"
fi

# Session time
if [ "$duration_ms" -gt 0 ] 2>/dev/null; then
	total_sec=$((duration_ms / 1000))
	hours=$((total_sec / 3600))
	minutes=$(((total_sec % 3600) / 60))
	seconds=$((total_sec % 60))
	if [ "$hours" -gt 0 ]; then
		session_time="${hours}h ${minutes}m"
	elif [ "$minutes" -gt 0 ]; then
		session_time="${minutes}m ${seconds}s"
	else
		session_time="${seconds}s"
	fi
else
	session_time=""
fi

# ── Usage limits (5-hour and 7-day) ─────────────────────────────────────────
# The API returns utilization as a plain percentage float (e.g. 6.0 = 6%).
# Cached to avoid hammering the endpoint; refresh runs in background.
USAGE_CACHE="/tmp/cc_usage_limits.json"
USAGE_CACHE_AGE=180 # seconds between refreshes

_refresh_usage_cache() {
	local token=""
	# macOS Keychain
	if command -v security &>/dev/null; then
		local raw
		raw=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
		token=$(echo "$raw" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
	fi
	# Linux / WSL credentials file
	if [ -z "$token" ] && [ -f ~/.claude/.credentials.json ]; then
		token=$(jq -r '.claudeAiOauth.accessToken // empty' ~/.claude/.credentials.json 2>/dev/null)
	fi
	[ -z "$token" ] && return 1

	curl -sf --max-time 5 \
		-H "Authorization: Bearer $token" \
		-H "anthropic-beta: oauth-2025-04-20" \
		-H "Content-Type: application/json" \
		"https://api.anthropic.com/api/oauth/usage" \
		-o "$USAGE_CACHE" 2>/dev/null
}

_cache_stale() {
	[ ! -f "$USAGE_CACHE" ] && return 0
	local now mod age
	now=$(date +%s)
	mod=$(stat -f %m "$USAGE_CACHE" 2>/dev/null || stat -c %Y "$USAGE_CACHE" 2>/dev/null)
	age=$((now - mod))
	[ "$age" -gt "$USAGE_CACHE_AGE" ]
}

# Color thresholds for usage percentage
_pct_color() {
	local pct=$1
	if [ "$pct" -lt 50 ]; then
		printf '\033[32m' # green
	elif [ "$pct" -lt 80 ]; then
		printf '\033[33m' # yellow
	elif [ "$pct" -lt 95 ]; then
		printf '\033[91m' # bright orange-red
	else
		printf '\033[31m' # dark red
	fi
}

# Human-readable reset time (e.g. "2am" or "May 16 9pm")
_fmt_reset() {
	local iso="$1"
	[ -z "$iso" ] && return

	# Parse ISO timestamp; try GNU date then BSD date
	local epoch
	epoch=$(date -d "$iso" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso" +%s 2>/dev/null)
	[ -z "$epoch" ] && return

	local today_date reset_date hour ampm
	today_date=$(date +%Y-%m-%d)
	reset_date=$(date -d "@$epoch" +%Y-%m-%d 2>/dev/null || date -r "$epoch" +%Y-%m-%d 2>/dev/null)
	hour=$(date -d "@$epoch" +%-I 2>/dev/null || date -r "$epoch" +%-I 2>/dev/null || date -r "$epoch" +%I | sed 's/^0//')
	ampm=$(date -d "@$epoch" +%p 2>/dev/null || date -r "$epoch" +%p 2>/dev/null)
	ampm=$(echo "$ampm" | tr '[:upper:]' '[:lower:]')

	if [ "$reset_date" = "$today_date" ]; then
		printf "%s%s" "$hour" "$ampm"
	else
		local mon day
		mon=$(date -d "@$epoch" +%b 2>/dev/null || date -r "$epoch" +%b 2>/dev/null)
		day=$(date -d "@$epoch" +%-d 2>/dev/null || date -r "$epoch" +%-d 2>/dev/null || date -r "$epoch" +%d | sed 's/^0//')
		printf "%s %s %s%s" "$mon" "$day" "$hour" "$ampm"
	fi
}

usage_str=""
if _cache_stale; then
	_refresh_usage_cache & # non-blocking
	disown 2>/dev/null
fi

if [ -f "$USAGE_CACHE" ]; then
	# utilization is already a percentage (6.0 = 6%), NOT a 0-1 fraction
	h5_raw=$(jq -r '.five_hour.utilization // empty' "$USAGE_CACHE" 2>/dev/null)
	w7_raw=$(jq -r '.seven_day.utilization // empty' "$USAGE_CACHE" 2>/dev/null)
	h5_reset=$(jq -r '.five_hour.resets_at // empty' "$USAGE_CACHE" 2>/dev/null)
	w7_reset=$(jq -r '.seven_day.resets_at // empty' "$USAGE_CACHE" 2>/dev/null)

	if [ -n "$h5_raw" ] && [ -n "$w7_raw" ]; then
		# Round to nearest integer
		h5_pct=$(awk "BEGIN{printf \"%d\", $h5_raw + 0.5}")
		w7_pct=$(awk "BEGIN{printf \"%d\", $w7_raw + 0.5}")

		h5_col=$(_pct_color "$h5_pct")
		w7_col=$(_pct_color "$w7_pct")
		reset='\033[0m'

		h5_reset_str=$(_fmt_reset "$h5_reset")
		w7_reset_str=$(_fmt_reset "$w7_reset")

		# Format: "5h:6%↺2am  7d:1%↺May 16 9pm"
		h5_label="5h:${h5_pct}%"
		w7_label="7d:${w7_pct}%"
		[ -n "$h5_reset_str" ] && h5_label="${h5_label}↺${h5_reset_str}"
		[ -n "$w7_reset_str" ] && w7_label="${w7_label}↺${w7_reset_str}"

		usage_str=$(printf "${h5_col}%s${reset} ${w7_col}%s${reset}" \
			"$h5_label" "$w7_label")
	fi
fi
# ─────────────────────────────────────────────────────────────────────────────

# Separator
SEP='\033[2m│\033[0m'

# Short model name
short_model=$(echo "$model_name" | sed -E 's/Claude [0-9.]+ //; s/^Claude //')

# LINE 1: [Model] folder | branch
line1=$(printf '\033[37m[%s]\033[0m' "$short_model")
line1="$line1 $(printf '\033[94m📁 %s\033[0m' "$folder_name")"
if [ -n "$git_branch" ]; then
	line1="$line1 $(printf '%b \033[96m🌿 %s\033[0m' "$SEP" "$git_branch")"
fi

# LINE 2: bar | ctx% | $cost | ⏱ time | ↻cache% | 5h/7d limits
line2=""
if [ -n "$progress_bar" ]; then
	line2=$(printf '%b' "$progress_bar")
fi
if [ -n "$ctx_pct" ]; then
	if [ -n "$line2" ]; then
		line2="$line2 $(printf '\033[37m%s\033[0m' "$ctx_pct")"
	else
		line2=$(printf '\033[37m%s\033[0m' "$ctx_pct")
	fi
fi
if [ -n "$line2" ]; then
	line2="$line2 $(printf '%b \033[33m$%s\033[0m' "$SEP" "$cost")"
else
	line2=$(printf '\033[33m$%s\033[0m' "$cost")
fi
if [ -n "$session_time" ]; then
	line2="$line2 $(printf '%b \033[36m⏱ %s\033[0m' "$SEP" "$session_time")"
fi
if [ "$cache_pct" -gt 0 ] 2>/dev/null; then
	line2="$line2 $(printf ' \033[2m↻%s%%\033[0m' "$cache_pct")"
fi
if [ -n "$usage_str" ]; then
	line2="$line2 $(printf '%b ' "$SEP")$(printf '%b' "$usage_str")"
fi

printf '%b\n\n%b' "$line1" "$line2"
