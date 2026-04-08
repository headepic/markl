# markl

Personal skill collection for Claude Code. Ten skills covering the complete engineering workflow: auto-harness, think, hunt, design, check, learn, read, write, health, evolve-skills.

## Communication

- Do not use em dashes (U+2014) in any output. Use commas, periods, colons, or semicolons instead.
- This applies to all skill templates, report examples, progress lines, and any example output embedded in skill files.

## Structure

```
skills/
├── auto-harness/   -- end-to-end orchestrator: classify, understand, gate, build, verify, ship
├── check/          -- code review before merging, with independent subagent + dry-run rubric mode
├── design/         -- production-grade frontend UI with a committed visual direction
├── evolve-skills/  -- analyze hook log + transcripts, propose SKILL.md edits
├── health/         -- Claude Code config audit
│   └── agents/     -- agent1-context.md, agent2-control.md
├── hunt/           -- systematic debugging, root cause before fix
├── learn/          -- six-stage research to published output
├── read/           -- fetch URL or PDF as Markdown
├── think/          -- design and validate before building, owns .markl/<task>.md artifact
└── write/          -- natural prose in Chinese and English
    └── references/ -- write-zh.md, write-en.md
.claude-plugin/
└── marketplace.json  -- plugin registry for npx distribution
hooks/
└── log-skill-usage.sh  -- PostToolUse telemetry: skill invocations + .markl/ artifact events
install.sh              -- symlink installer
```

Each skill has a `SKILL.md` (loaded on demand). The orchestrator (`auto-harness`) and the artifact-aware skills (`think`, `hunt`, `design`, `check`) communicate via `<repo-root>/.markl/<task>.md`, not via conversation context.

## Verification

```bash
# All SKILL.md files have valid frontmatter
for f in skills/*/SKILL.md; do head -5 "$f" | grep -q "^name:" && echo "ok: $f" || echo "MISSING name: $f"; done

# Frontmatter name matches directory name
for d in skills/*/; do
  name=$(basename "$d")
  declared=$(grep '^name:' "$d/SKILL.md" | awk '{print $2}')
  [ "$name" = "$declared" ] && echo "ok: $name" || echo "MISMATCH: dir=$name name=$declared"
done

# No em dashes anywhere
! grep -l '—' skills/*/SKILL.md hooks/*.sh README.md CLAUDE.md 2>/dev/null && echo "em dashes: clean"

# Hook script syntax
bash -n hooks/log-skill-usage.sh && echo "hook: ok"

# marketplace.json is valid JSON
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))" && echo "marketplace.json: ok"
```

## Commit Convention

`{type}: {description}` where type is one of: feat, fix, refactor, docs, chore.

`evolve-skills` uses its own prefix: `evolve: <skill>, <one-line summary> (N sessions analyzed)`. These commits act as the watermark for the next evolve run.

## Artifact Convention

Skills that participate in the harness flow read and write artifacts at `<repo-root>/.markl/<slug>.md`. Live artifacts sit at the top level of `.markl/`; shipped artifacts move to `.markl/done/`. The PostToolUse hook in `hooks/log-skill-usage.sh` automatically logs every Read, Write, and Edit on these paths to `~/.claude/markl-usage.jsonl`. Skills must not append telemetry manually except for the one legacy case in `check` (artifact_missing).

`.markl/` should be in every consuming project's `.gitignore`. `think` adds it idempotently before the first artifact write.
