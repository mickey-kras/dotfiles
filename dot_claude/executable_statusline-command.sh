#!/usr/bin/env bash
# Claude Code status line — context fill + (subscription quota OR API cost) + cache hit ratio
# Reads JSON over stdin (Claude Code statusline contract). Single-line output.
set -u

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
model_id=$(echo "$input" | jq -r '.model.id // ""')
total=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
used=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')

# --- helpers ---
fmt_tokens() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then
    printf "%.1fM" "$(echo "scale=1; $n/1000000" | bc)"
  elif [ "$n" -ge 1000 ]; then
    printf "%.0fK" "$(echo "scale=0; $n/1000" | bc)"
  else
    printf "%d" "$n"
  fi
}

# --- fill bar (colored by threshold) ---
# Embed real ESC bytes so the final `printf "%s"` renders the color.
ESC=$(printf '\033')
RESET="${ESC}[0m"
bar=""
if [ -n "$pct" ]; then
  filled=$(echo "$pct" | awk '{printf "%d", int($1/10 + 0.5)}')
  pct_int=$(printf '%.0f' "$pct")
  if   [ "$pct_int" -ge 80 ]; then bar_color="${ESC}[31m"   # red:    dangerous
  elif [ "$pct_int" -ge 50 ]; then bar_color="${ESC}[33m"   # yellow: warning
  else                             bar_color="${ESC}[32m"   # green:  ok
  fi
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then bar="${bar}▰"; else bar="${bar}▱"; fi
  done
  bar="${bar_color}${bar}${RESET}"
else
  bar="▱▱▱▱▱▱▱▱▱▱"
fi

# --- auth detection (subscription via keychain OAuth, else API key) ---
# Cached for 1 hour to avoid hitting the keychain on every statusline render.
AUTH_CACHE="${TMPDIR:-/tmp}/claude-statusline-auth-${UID:-$(id -u)}.json"
if [ -f "$AUTH_CACHE" ] && [ "$(($(date +%s) - $(stat -f %m "$AUTH_CACHE" 2>/dev/null || stat -c %Y "$AUTH_CACHE")))" -lt 3600 ]; then
  auth_blob=$(cat "$AUTH_CACHE")
else
  sub_type=""
  rate_tier=""
  cred=$(security find-generic-password -s "Claude Code-credentials" -a "${USER:-$(whoami)}" -w 2>/dev/null || true)
  if [ -n "$cred" ]; then
    sub_type=$(echo "$cred" | jq -r '.claudeAiOauth.subscriptionType // empty' 2>/dev/null || echo "")
    rate_tier=$(echo "$cred" | jq -r '.claudeAiOauth.rateLimitTier // empty' 2>/dev/null || echo "")
  fi

  auth_kind=""
  tier_label=""
  if [ -n "$sub_type" ]; then
    auth_kind="oauth"
    case "$rate_tier" in
      *_claude_max_20x) tier_label="Max 20x" ;;
      *_claude_max_5x)  tier_label="Max 5x"  ;;
      *_claude_pro)     tier_label="Pro"     ;;
      "")               tier_label="$(echo "$sub_type" | tr '[:lower:]' '[:upper:]' | head -c 1)$(echo "$sub_type" | cut -c2-)" ;;
      *)                tier_label="$rate_tier" ;;
    esac
  elif [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "$(jq -r '.apiKeyHelper // empty' ~/.claude/settings.json 2>/dev/null)" ]; then
    auth_kind="api"
  fi

  auth_blob=$(printf '{"kind":"%s","tier":"%s"}' "$auth_kind" "$tier_label")
  echo "$auth_blob" > "$AUTH_CACHE" 2>/dev/null || true
fi
auth_kind=$(echo "$auth_blob" | jq -r '.kind // ""')
tier_label=$(echo "$auth_blob" | jq -r '.tier // ""')

# --- usage suffix: subscription quota OR API cost ---
suffix=""
case "$auth_kind" in
  oauth)
    # Cap per tier (rolling 5h soft cap, approximate; override via CLAUDE_QUOTA_CAP_5H).
    case "$tier_label" in
      "Max 20x") DEFAULT_CAP=900 ;;
      "Max 5x")  DEFAULT_CAP=225 ;;
      "Pro")     DEFAULT_CAP=45  ;;
      *)         DEFAULT_CAP=0   ;;
    esac
    cap=${CLAUDE_QUOTA_CAP_5H:-$DEFAULT_CAP}

    # Count assistant messages with usage across all transcripts touched in last 5h.
    # -mmin works on both BSD (macOS) and GNU find; -newermt "@epoch" is GNU-only.
    msgs5h=0
    proj_dir="$HOME/.claude/projects"
    if [ -d "$proj_dir" ]; then
      cutoff=$(($(date +%s) - 5 * 3600))
      while IFS= read -r f; do
        # Sum assistant turns whose own message timestamp is within 5h
        n=$(jq -rs --argjson cutoff "$cutoff" '
          [.[] | select(.message.usage) | select(
            (.timestamp // "" | sub("\\..*"; "Z") | fromdateiso8601? // 0) >= $cutoff
          )] | length
        ' "$f" 2>/dev/null || echo 0)
        msgs5h=$((msgs5h + n))
      done < <(find "$proj_dir" -name "*.jsonl" -type f -mmin -300 2>/dev/null)
    fi

    if [ "$cap" -gt 0 ]; then
      pct5h=$(awk -v m="$msgs5h" -v c="$cap" 'BEGIN { printf "%.0f", m/c*100 }')
      suffix="${tier_label} · ${msgs5h}/${cap} (${pct5h}%)"
    else
      suffix="${tier_label} · ${msgs5h} msg/5h"
    fi
    ;;
  api)
    if [ -n "$transcript" ] && [ -f "$transcript" ]; then
      case "$model_id" in
        claude-opus-4-7*|claude-opus-4-6*|claude-opus-4-5*)
          INP_PRICE=15; OUT_PRICE=75; CW_PRICE=18.75; CR_PRICE=1.50 ;;
        claude-sonnet-4-6*|claude-sonnet-4-5*)
          INP_PRICE=3;  OUT_PRICE=15; CW_PRICE=3.75;  CR_PRICE=0.30 ;;
        claude-haiku-4-5*)
          INP_PRICE=1;  OUT_PRICE=5;  CW_PRICE=1.25;  CR_PRICE=0.10 ;;
        *)
          INP_PRICE=0;  OUT_PRICE=0;  CW_PRICE=0;     CR_PRICE=0 ;;
      esac
      if [ "$INP_PRICE" != "0" ]; then
        totals=$(jq -rs '
          [.[] | select(.message.usage)] |
          {
            inp:  (map(.message.usage.input_tokens // 0)               | add // 0),
            out:  (map(.message.usage.output_tokens // 0)              | add // 0),
            cw:   (map(.message.usage.cache_creation_input_tokens // 0)| add // 0),
            cr:   (map(.message.usage.cache_read_input_tokens // 0)    | add // 0)
          } | "\(.inp) \(.out) \(.cw) \(.cr)"
        ' "$transcript" 2>/dev/null || echo "0 0 0 0")
        read -r inp out cw cr <<< "$totals"
        inp=${inp:-0}; out=${out:-0}; cw=${cw:-0}; cr=${cr:-0}
        if [ "$((inp + out + cw + cr))" -gt 0 ]; then
          cost=$(awk -v inp="$inp" -v out="$out" -v cw="$cw" -v cr="$cr" \
                     -v IP="$INP_PRICE" -v OP="$OUT_PRICE" -v WP="$CW_PRICE" -v RP="$CR_PRICE" \
                     'BEGIN { printf "%.2f", (inp*IP + out*OP + cw*WP + cr*RP) / 1000000 }')
          suffix="\$${cost}"
        fi
      fi
    fi
    ;;
esac

# --- cache hit ratio (transcript-derived; useful in both modes) ---
cache_str=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  totals=$(jq -rs '
    [.[] | select(.message.usage)] |
    {
      inp:  (map(.message.usage.input_tokens // 0)               | add // 0),
      cw:   (map(.message.usage.cache_creation_input_tokens // 0)| add // 0),
      cr:   (map(.message.usage.cache_read_input_tokens // 0)    | add // 0)
    } | "\(.inp) \(.cw) \(.cr)"
  ' "$transcript" 2>/dev/null || echo "0 0 0")
  read -r inp cw cr <<< "$totals"
  inp=${inp:-0}; cw=${cw:-0}; cr=${cr:-0}
  cache_in=$((inp + cw + cr))
  if [ "$cache_in" -gt 0 ] && [ "$cr" -gt 0 ]; then
    cache_pct=$(awk -v cr="$cr" -v t="$cache_in" 'BEGIN { printf "%.0f", cr/t*100 }')
    cache_str="cache ${cache_pct}%"
  fi
fi

# --- render ---
used_fmt=$(fmt_tokens "$used")
total_fmt=$(fmt_tokens "$total")
out_line="${model}  ${bar}  ${used_fmt}/${total_fmt}"
if [ -n "$pct" ]; then
  remaining=$(echo "$pct" | awk '{printf "%.0f", 100 - $1}')
  out_line="${out_line} (${pct%.*}% used, ${remaining}% free)"
fi
[ -n "$suffix" ]    && out_line="${out_line}  ${suffix}"
[ -n "$cache_str" ] && out_line="${out_line}  ${cache_str}"

printf "%s" "$out_line"
