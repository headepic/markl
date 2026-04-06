#!/bin/bash
# markl: log Skill tool invocations for auto-evolution analysis.
# Wired via PostToolUse hook in ~/.claude/settings.json.
# Only records markl's own skills; ignores everything else.

set -e

LOG="${MARKL_USAGE_LOG:-$HOME/.claude/markl-usage.jsonl}"
MARKL_SKILLS="check design evolve health hunt learn read think write"

# Hook payload arrives on stdin as JSON.
payload=$(cat)

tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // empty')
[ "$tool_name" = "Skill" ] || exit 0

skill=$(printf '%s' "$payload" | jq -r '.tool_input.skill // empty')
[ -n "$skill" ] || exit 0

# Filter to markl skills only.
case " $MARKL_SKILLS " in
  *" $skill "*) ;;
  *) exit 0 ;;
esac

ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
session=$(printf '%s' "$payload" | jq -r '.session_id // empty')
cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty')
args=$(printf '%s' "$payload" | jq -r '.tool_input.args // empty')

jq -nc \
  --arg ts "$ts" \
  --arg skill "$skill" \
  --arg session "$session" \
  --arg cwd "$cwd" \
  --arg args "$args" \
  '{ts:$ts, skill:$skill, session:$session, cwd:$cwd, args:$args}' \
  >> "$LOG"

exit 0
