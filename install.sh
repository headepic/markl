#!/bin/bash
# markl skill installer: symlinks all skills into ~/.claude/skills/
set -e

MARKL_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

mkdir -p "$SKILLS_DIR"

for dir in "$MARKL_DIR"/skills/*/; do
  name=$(basename "$dir")
  target="$SKILLS_DIR/$name"
  ln -sfn "$dir" "$target"
  echo "  linked: $name -> $target"
done

echo ""
echo "markl installed. Available skills:"
for dir in "$MARKL_DIR"/skills/*/; do
  name=$(basename "$dir")
  desc=$(grep '^description:' "$dir/SKILL.md" 2>/dev/null | head -1 | sed 's/description: *//' | tr -d '"')
  printf "  /%-10s %s\n" "$name" "$desc"
done

# Auto-evolution hook: PostToolUse logger for markl skills.
SETTINGS="$HOME/.claude/settings.json"
HOOK_CMD="$MARKL_DIR/hooks/log-skill-usage.sh"
chmod +x "$HOOK_CMD" 2>/dev/null || true

if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
  tmp=$(mktemp)
  jq --arg cmd "$HOOK_CMD" '
    .hooks = (.hooks // {}) |
    .hooks.PostToolUse = (.hooks.PostToolUse // []) |
    # ensure Skill matcher entry exists
    (if (.hooks.PostToolUse | map(select(.matcher == "Skill" and (.hooks[]?.command == $cmd))) | length) == 0
     then .hooks.PostToolUse += [{matcher: "Skill", hooks: [{type: "command", command: $cmd}]}]
     else . end) |
    # ensure Write|Edit|Read matcher entry exists (artifact event capture)
    (if (.hooks.PostToolUse | map(select(.matcher == "Write|Edit|Read" and (.hooks[]?.command == $cmd))) | length) == 0
     then .hooks.PostToolUse += [{matcher: "Write|Edit|Read", hooks: [{type: "command", command: $cmd}]}]
     else . end)
  ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "Auto-evolve hook installed in $SETTINGS (Skill + Write|Edit|Read matchers)."
else
  echo "Skipped hook install (no $SETTINGS or jq missing). Add manually:"
  echo "  PostToolUse matcher=Skill              -> $HOOK_CMD"
  echo "  PostToolUse matcher=Write|Edit|Read    -> $HOOK_CMD"
fi

# English coaching prompt
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
MARKER="## English Coaching"

echo ""
if grep -q "$MARKER" "$CLAUDE_MD" 2>/dev/null; then
  echo "English coaching already enabled in $CLAUDE_MD. Skipping."
else
  printf "Add passive English coaching to %s? [y/N] " "$CLAUDE_MD"
  read -r REPLY
  if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    echo "" >> "$CLAUDE_MD"
    cat "$MARKL_DIR/templates/english-coaching.md" >> "$CLAUDE_MD"
    echo "English coaching added to $CLAUDE_MD."
  fi
fi
