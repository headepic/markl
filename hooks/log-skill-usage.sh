#!/bin/bash
# markl: log Skill tool invocations and artifact events for auto-evolution analysis.
# Wired via PostToolUse hooks in ~/.claude/settings.json (matchers: Skill, Write, Read).
# Only records markl's own skills and .markl/ artifact events; ignores everything else.

set -e

LOG="${MARKL_USAGE_LOG:-$HOME/.claude/markl-usage.jsonl}"
MARKL_SKILLS="check design evolve-skills health hunt learn auto-harness read think write"

payload=$(cat)
tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // empty')
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
session=$(printf '%s' "$payload" | jq -r '.session_id // empty')
cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty')

case "$tool_name" in
  Skill)
    skill=$(printf '%s' "$payload" | jq -r '.tool_input.skill // empty')
    [ -n "$skill" ] || exit 0
    case " $MARKL_SKILLS " in
      *" $skill "*) ;;
      *) exit 0 ;;
    esac
    args=$(printf '%s' "$payload" | jq -r '.tool_input.args // empty')
    jq -nc \
      --arg ts "$ts" --arg skill "$skill" --arg session "$session" \
      --arg cwd "$cwd" --arg args "$args" \
      '{ts:$ts, skill:$skill, event:"invoked", session:$session, cwd:$cwd, args:$args}' \
      >> "$LOG"
    ;;

  Write|Edit)
    fp=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')
    [ -n "$fp" ] || exit 0
    case "$fp" in
      */.markl/done/*.md)
        event="artifact_shipped"
        ;;
      */.markl/*.md)
        event="artifact_written"
        ;;
      *)
        exit 0
        ;;
    esac
    jq -nc \
      --arg ts "$ts" --arg event "$event" --arg session "$session" \
      --arg cwd "$cwd" --arg fp "$fp" \
      '{ts:$ts, skill:"_hook", event:$event, session:$session, cwd:$cwd, artifact:$fp}' \
      >> "$LOG"
    ;;

  Read)
    fp=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')
    [ -n "$fp" ] || exit 0
    case "$fp" in
      */.markl/done/*.md) exit 0 ;;
      */.markl/*.md)
        jq -nc \
          --arg ts "$ts" --arg session "$session" \
          --arg cwd "$cwd" --arg fp "$fp" \
          '{ts:$ts, skill:"_hook", event:"artifact_read", session:$session, cwd:$cwd, artifact:$fp}' \
          >> "$LOG"
        ;;
    esac
    ;;
esac

exit 0
