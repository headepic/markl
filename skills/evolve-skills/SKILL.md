---
name: evolve-skills
description: Use when the user wants to review markl skill usage, analyze friction, and propose improvements to SKILL.md files. Not for writing new skills from scratch.
version: 0.2.0
allowed-tools:
  - Bash
  - Read
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

# /evolve-skills, markl auto-evolution

Review how markl's skills are actually being used, identify friction, and propose concrete edits to the relevant `SKILL.md` files. Changes are always shown as a diff and confirmed with the user before being written or committed.

## Data source

Every markl skill invocation and every `.markl/` artifact event is logged to `~/.claude/markl-usage.jsonl` by the `log-skill-usage.sh` PostToolUse hook (matchers: `Skill`, `Write|Edit|Read`). One JSON object per line, three event shapes:

```json
{"ts":"...","skill":"hunt","event":"invoked","session":"...","cwd":"...","args":"..."}
{"ts":"...","skill":"_hook","event":"artifact_written","session":"...","cwd":"...","artifact":"/path/.markl/foo.md"}
{"ts":"...","skill":"_hook","event":"artifact_read","session":"...","cwd":"...","artifact":"/path/.markl/foo.md"}
{"ts":"...","skill":"_hook","event":"artifact_shipped","session":"...","cwd":"...","artifact":"/path/.markl/done/foo.md"}
{"ts":"...","skill":"check","event":"artifact_missing","cwd":"..."}
```

`artifact_*` events are mechanical (hook-driven, reliable). `invoked` and `artifact_missing` are also mechanical via the same hook except for `artifact_missing` which `check` writes manually in the legacy path. Do not trust any other "self-reported" telemetry: if you see fields that no skill writes, treat as noise.

## Workflow

When invoked as `/evolve-skills` (all skills) or `/evolve-skills <skill-name>` (one skill):

### 1. Summarize usage

- Read `~/.claude/markl-usage.jsonl` (create if missing, report and exit).
- Aggregate counts per skill since the last evolve commit (see step 5).
- Report: total invocations, per-skill counts, top cwds, time range, and the artifact event totals (`written`, `read`, `shipped`, `missing`).

### 2. Sample recent sessions

- For the target skill(s), pick up to 5 recent `session_id`s from the log.
- For each, locate the transcript under `~/.claude/projects/<encoded-cwd>/<session_id>.jsonl` and read the turns around the Skill tool call (plus or minus 10 messages).
- Look for signals:
  - User correction right after the skill ran ("no", "不对", "重来", "wrong")
  - Skill output followed by the user asking for something the skill should have done automatically
  - Skill invoked but immediately abandoned for a different approach
  - Repeated invocations in the same session (skill not sticky enough)

### 3. Diagnose

Group findings into categories:

- **Trigger drift**: skill fires when it should not, or fails to fire when it should. Fix: tighten the `description:` frontmatter.
- **Missing preconditions**: skill jumps ahead of a required step. Fix: add a numbered precondition to the skill body.
- **Weak guardrail**: skill produces a class of mistake repeatedly. Fix: add an explicit "do not" rule with the observed failure mode.
- **Dead text**: sections of SKILL.md the skill clearly never honors. Fix: delete.
- **Scar tissue**: a rule, gotcha, or guardrail whose original failure mode no longer occurs on the current model. Fix: delete or relax. See step 3a.
- **Artifact health**: the `.markl/` handoff is drifting. See step 3b.

### 3a. Scar-tissue scan

Every guardrail in markl encodes an assumption about a model limitation. As models improve, some assumptions stop holding and the guardrail becomes ceremony. Prune cautiously, not aggressively.

For each skill in scope:

1. **Extract every "do not" rule and Gotcha bullet** from the SKILL.md.
2. **Search the conversation transcripts (same sample as step 2)** for evidence the failure mode the rule prevents actually occurred or was averted. Use grep on keywords from the rule itself.
3. **Classify** each rule as `load-bearing` (evidence found) or `dormant` (no evidence in this sample).
4. **Cross-run check via git log**: for each `dormant` rule, run `git -C /Users/jowang/Documents/github/markl log --grep "evolve:" --pretty=format:"%s %b" -- skills/<name>/SKILL.md` and look for any prior `evolve:` commit that touched this rule (by quoting a phrase from it). If a prior evolve commit also flagged this rule as dormant or kept-with-watch, this is the second observation, propose deletion with the prior commit hash as evidence. If no prior mention, do not propose deletion this run, just note "watching for next run, no prior evidence".

This is a soft signal, not a mechanical purge. A rule that has been dormant across two evolve runs may still be load-bearing for a class of failures the sample window did not catch. Always show the user the rule and ask before deleting; never auto-delete from this scan.

Scar-tissue findings go in their own section of the report so the user can reject pruning per-rule without affecting the additive proposals.

### 3b. Artifact health (think → check handoff)

Read the artifact event totals from step 1:

- **High `artifact_missing` ratio** (more than ~30% of `check` invocations): `think` is being skipped or its artifact step is not being honored. Root cause: tighten `think` Output section, or `think` description is not triggering when it should, or the user is invoking `check` directly and bypassing the harness.
- **`artifact_written` without matching `artifact_read` later in the same session_id**: `think` writes the artifact but `check` is being run from a different cwd or the file is being moved. Check the path resolution in both skills.
- **`artifact_shipped` without preceding `artifact_read`**: `auto-harness` moved an artifact to `done/` without `check` ever reading it. Stage C → D guard is broken.

Also scan recent `.markl/*.md` artifacts under known project roots (extract cwds from session logs):

- Artifacts with **zero file:line anchors** in Decisions: `think`/`hunt`/`design` is writing ceremonial artifacts. Tighten the anchor requirement.
- Artifacts with **only tautological ACs** ("compiles", "renders", "returns 200"): the anti-tautology rule is not firing. Add the violating examples to `think`'s bad-AC list.
- Artifacts with an **empty Reframings section across many tasks**: either users never reframe (unlikely on long tasks) or the re-entry rule is not being honored. Sample the transcripts to find out which.

These checks turn the artifact convention from a procedural rule into a measurable signal. If artifact health is bad, no other improvement matters because the handoff is already broken.

### 4. Propose diffs

For each finding, produce a minimal `Edit` against the relevant `skills/<name>/SKILL.md` in the markl repo (absolute path `/Users/jowang/Documents/github/markl`). Prefer surgical edits over rewrites. Show all proposed edits to the user before applying, grouped by skill, with the triggering evidence (session id + one-line quote) attached.

### 5. Apply and commit

After user confirms:

- Apply the edits.
- `git -C /Users/jowang/Documents/github/markl add -A`
- Commit with a message like: `evolve: <skill>, <one-line summary of change> (N sessions analyzed)`
- `git -C /Users/jowang/Documents/github/markl push`. Every evolve commit MUST be pushed to the remote so the markl repo on GitHub stays in sync. Trust the upstream tracking branch, do not hardcode `origin main` since the user may be on a different branch. If push fails (network, auth, conflict), report the error to the user and stop; do not leave local commits unpushed silently.
- The commit acts as the watermark for the next `/evolve-skills` run. Only sessions logged after `HEAD`'s commit timestamp are considered "new" next time.

### 6. Report

Print:

- What changed (per skill, bullet list)
- What was looked at but left alone (and why)
- Next evolve candidates (skills with signal but not enough evidence yet)
- Artifact health summary line (e.g. `artifacts: 12 written / 11 read / 8 shipped / 1 missing`)

## Guardrails

- **Never edit a skill without showing the diff first.** User always confirms.
- **Never mass-rewrite.** If a skill needs more than 30 lines changed, stop and ask the user whether to rewrite instead of evolving.
- **Do not touch `evolve-skills/SKILL.md` itself** unless the user explicitly asks. Self-modification needs human review.
- **Do not invent evidence.** Every proposed edit must cite at least one real `session_id` from the log. If there is no evidence, say so and skip.
- **Log file is append-only.** Never truncate or rewrite it; if it grows too large, archive to `markl-usage.<date>.jsonl` and start fresh.

## First-run behavior

If `~/.claude/markl-usage.jsonl` does not exist or is empty:

- Report "no usage data yet, hook may not be installed or no skills invoked since install".
- Check `~/.claude/settings.json` for the `log-skill-usage.sh` hook on both `Skill` and `Write|Edit|Read` matchers. If either is missing, point the user at `markl/install.sh` or guide them to add the matcher manually.
- Exit without making changes.
