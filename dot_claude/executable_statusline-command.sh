#!/usr/bin/env bash
# Claude Code status line — compact context usage display.
# Renders: "Opus 4.7 (1M context)  ▰▰▰▱▱▱▱▱▱▱  339K/1.0M (34% used, 66% free)"

input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name // .model.id // "Claude"')
total=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // 0')
used=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // 0')
pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')

# Context-size label: round millions show no decimal ("1M"), thousands show as "200K".
fmt_label() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) {
      v = n / 1000000
      if (v == int(v)) printf "%dM", v
      else printf "%.1fM", v
    } else if (n >= 1000) {
      printf "%dK", n / 1000
    } else {
      printf "%d", n
    }
  }'
}

# Ratio side: millions always show one decimal ("1.0M"), thousands "339K".
fmt_ratio() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.1fM", n / 1000000
    else if (n >= 1000) printf "%dK", n / 1000
    else printf "%d", n
  }'
}

total_label=$(fmt_label "$total")
total_ratio=$(fmt_ratio "$total")
used_ratio=$(fmt_ratio "$used")

if [ -n "$pct" ]; then
  filled=$(awk -v p="$pct" 'BEGIN { printf "%d", int(p/10 + 0.5) }')
  [ "$filled" -gt 10 ] && filled=10
  bar=""
  i=1
  while [ "$i" -le 10 ]; do
    if [ "$i" -le "$filled" ]; then bar="${bar}▰"; else bar="${bar}▱"; fi
    i=$((i + 1))
  done
  remaining=$(awk -v p="$pct" 'BEGIN { printf "%.0f", 100 - p }')
  printf "%s (%s context)  %s  %s/%s (%.0f%% used, %s%% free)" \
    "$model" "$total_label" "$bar" "$used_ratio" "$total_ratio" "$pct" "$remaining"
else
  printf "%s (%s context)  %s/%s" \
    "$model" "$total_label" "$used_ratio" "$total_ratio"
fi
