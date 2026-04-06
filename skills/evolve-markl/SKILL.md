---
name: evolve
description: Use when the user wants to review markl skill usage, analyze friction, and propose improvements to SKILL.md files. Not for writing new skills from scratch.
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

# /evolve — markl auto-evolution

Review how markl's skills are actually being used, identify friction, and
propose concrete edits to the relevant `SKILL.md` files. Changes are always
shown as a diff and confirmed with the user before being written or committed.

## Data source

Every invocation of a markl skill is logged to `~/.claude/markl-usage.jsonl`
by the `log-skill-usage.sh` PostToolUse hook. One JSON object per line:

```json
{"ts":"2026-04-06T10:00:00Z","skill":"hunt","session":"...","cwd":"...","args":"..."}
```

No automatic feedback signal is captured in v0.1 — friction is inferred
manually by reading the session transcripts referenced by `session_id`.

## Workflow

When invoked as `/evolve` (all skills) or `/evolve <skill-name>` (one skill):

### 1. Summarize usage
- Read `~/.claude/markl-usage.jsonl` (create if missing, report and exit).
- Aggregate counts per skill since the last evolve commit (see step 5).
- Report: total invocations, per-skill counts, top cwds, time range.

### 2. Sample recent sessions
- For the target skill(s), pick up to 5 recent `session_id`s from the log.
- For each, locate the transcript under
  `~/.claude/projects/<encoded-cwd>/<session_id>.jsonl` and read the turns
  around the Skill tool call (±10 messages).
- Look for signals:
  - User correction right after the skill ran ("no", "不对", "重来", "wrong")
  - Skill output followed by the user asking for something the skill should
    have done automatically
  - Skill invoked but immediately abandoned for a different approach
  - Repeated invocations in the same session (skill not sticky enough)

### 3. Diagnose
Group findings into categories:
- **Trigger drift** — skill fires when it shouldn't, or fails to fire when it should. Fix: tighten the `description:` frontmatter.
- **Missing preconditions** — skill jumps ahead of a required step. Fix: add a numbered precondition to the skill body.
- **Weak guardrail** — skill produces a class of mistake repeatedly. Fix: add an explicit "do not" rule with the observed failure mode.
- **Dead text** — sections of SKILL.md the skill clearly never honors. Fix: delete.

### 4. Propose diffs
For each finding, produce a minimal `Edit` against the relevant
`skills/<name>/SKILL.md` in the markl repo (absolute path
`/Users/jowang/Documents/github/markl`). Prefer surgical edits over rewrites.
Show all proposed edits to the user *before* applying, grouped by skill,
with the triggering evidence (session id + one-line quote) attached.

### 5. Apply and commit
After user confirms:
- Apply the edits.
- `git -C /Users/jowang/Documents/github/markl add -A`
- Commit with a message like:
  `evolve: <skill> — <one-line summary of change> (N sessions analyzed)`
- The commit acts as the watermark for the next `/evolve` run — only sessions
  logged *after* `HEAD`'s commit timestamp are considered "new" next time.

### 6. Report
Print:
- What changed (per skill, bullet list)
- What was looked at but left alone (and why)
- Next evolve candidates (skills with signal but not enough evidence yet)

## Guardrails

- **Never edit a skill without showing the diff first.** User always confirms.
- **Never mass-rewrite** — if a skill needs >30 lines changed, stop and ask
  the user whether to rewrite instead of evolving.
- **Do not touch `evolve/SKILL.md` itself** unless the user explicitly asks.
  Self-modification needs human review.
- **Do not invent evidence.** Every proposed edit must cite at least one
  real `session_id` from the log. If there's no evidence, say so and skip.
- **Log file is append-only.** Never truncate or rewrite it; if it grows
  too large, archive to `markl-usage.<date>.jsonl` and start fresh.

## First-run behavior

If `~/.claude/markl-usage.jsonl` does not exist or is empty:
- Report "no usage data yet — hook may not be installed or no skills invoked since install".
- Check `~/.claude/settings.json` for the `log-skill-usage.sh` hook.
- If missing, point the user at `markl/install.sh`.
- Exit without making changes.
