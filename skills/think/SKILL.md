---
name: think
description: Use before building anything new or when a plan needs review. Not for bug fixes or small edits.
version: 3.0.0
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - WebSearch
  - AskUserQuestion
---

# Think: Design and Validate Before You Build

Turn a rough idea into a clear, approved plan, then pressure-test the architecture before a line of code is written.

No code, no scaffolding, no implementation until the user has approved a design. No code snippets, no pseudo-code, no "just to illustrate" examples. Words and diagrams only.

Give opinions directly. Avoid: "That's an interesting approach," "There are many ways to think about this," "You might want to consider." Take a position and state what evidence would change it.

## Phase 1: Understand the Problem

Start by running `git log --oneline -10` and reading CLAUDE.md (if present). Then read the files the user mentioned or that are obviously related to the idea (entry points, main modules). Ask if it is unclear which files are relevant. Then work through the idea one question at a time: purpose first, constraints second, success criteria third.

**Confirm the working path before touching the filesystem.** Before creating, moving, or writing files, verify the absolute path with `pwd` or `git rev-parse --show-toplevel`. Do not assume `~/project` and `~/www/project` are the same. If the user gives a relative or ambiguous path, ask once to confirm the full absolute path.

**State all dependencies before asking for credentials.** If the task requires API keys, tokens, or third-party accounts beyond what the user named, list every dependency with a one-line explanation of why it is needed, before asking for any of them. Do not surface credential requests mid-implementation.

**Verify external tool availability before starting.** If the task depends on MCP servers, external APIs, or third-party CLIs, list them upfront and confirm each is reachable before the first implementation step. A plan that requires a tool that is not loaded is not a plan.

**Check existing work on GitHub.** Before designing, search for related issues and PRs:

```bash
gh issue list --search "feature keyword" --state all --limit 5
gh pr list --search "feature keyword" --state all --limit 5
```

If `gh` is not installed: `brew install gh && gh auth login`.

Challenge whether it is the right problem:
- What does the user actually want to happen? Not the feature described, the outcome they care about.
- What changes if nothing is built? Is there a cheaper path to the same result?
- What already exists in the codebase that covers part of this? Map sub-problems to existing code before proposing new code.
- Does this decision hold up in 12 months, or does it create drag?

## Scope Mode

Name the mode at the start:

| Mode | When | Posture |
|------|------|---------|
| **expand** | New feature, blank slate | Push scope up. Ask what would make this 10x better. |
| **shape** | Adding to existing | Hold the baseline, surface expansion options one at a time. |
| **hold** | Bug fix, tight constraints | Scope is locked. Make it correct. |
| **cut** | Plan that grew too large | Strip to the minimum that solves the real problem. |

## Phase 2: Propose Approaches

Offer 2 or 3 options with tradeoffs and a recommendation. For each: one-sentence summary, effort, risk, two strongest reasons for and against, what existing code it builds on. Always include one minimal option and one architecturally complete option.

When comparing, ask:
- Which decisions are hard to undo? Slow down on those.
- What would cause this to fail? Design away from that first.
- What are we explicitly not building?
- Would the same result hold with less: fewer fields, fewer states, fewer APIs?

Before presenting the recommendation: attack it. Ask yourself what would make this approach fail. If the attack holds, the approach deforms, and you should present the deformed version instead. If the attack shatters the approach entirely, discard it and tell the user why.

Get approval before proceeding. If the user rejects the design, do not start over from scratch. Ask what specifically did not work, incorporate those constraints, and re-enter Phase 2 with a narrowed option set.

## Phase 3: Validate the Architecture

Once a direction is approved, check structural correctness before implementation starts:

**Scope.** Grep for existing implementations of each sub-problem. Flag anything deferrable. More than 8 files or 2 new services? Acknowledge it explicitly.

**Dependencies and data flow.** If more than 3 components exchange data, draw an ASCII diagram. Look for cycles and hidden coupling. Trace the main path, then break it: nil input, empty collection, upstream timeout, partial failure.

**Test coverage.** List every meaningful path: happy path, error branches, edge cases. List gaps with file, assertion, test type. Any bug fix without a reproducing test is not done.

**Risk.** Name every component whose loss degrades the system. Can this be rolled back without touching data? Is the technology choice boring enough; non-standard choices accumulate maintenance cost.

If any section cannot be meaningfully evaluated from available information, say so explicitly: "Cannot assess X without seeing Y." Do not guess to fill the gap.

**No placeholders in approved plans.** Before the user approves, every step must be concrete. Forbidden patterns: TBD, TODO, "implement later", "similar to step N", "details to be determined", "as needed". A plan with placeholders is not a plan. It is a promise to plan later.

## Gotchas

Real failures from prior sessions, in order of frequency:

- **Wrong path assumed.** Moved files to `~/project` when the repo was at `~/www/project`. Always run `pwd` or `git rev-parse --show-toplevel` before the first filesystem operation.
- **Credentials surfaced mid-build.** Asked for DashScope API key after three implementation steps. List every dependency with a one-line explanation of why it is needed, before starting.
- **Analyzed when execution was requested.** User said "帮我做" and got three options. "帮我做," "优化," "改回去" = execute immediately. No option framework.
- **Designed around a tool that wasn't available.** Planned an MCP-dependent workflow without checking if the MCP server was loaded. Verify external tool availability before the first design step.
- **Rejected design restarted from scratch.** User said the direction was wrong. Should have asked what specifically failed and re-entered Phase 2 with narrowed constraints, not a blank slate.
- **Assumed regional API variants were identical.** Shengwang (China) and Agora (International) have different endpoints, auth schemes, and supported vendors. Built against the wrong one. List all regional differences before writing integration code.
- **Added a new runtime without asking.** Followed official docs' FastAPI examples into a Next.js project, creating a Python backend nobody wanted. Translate doc examples to the user's existing stack; never add a new language or runtime without explicit approval.

## Output

For each issue found in Phase 3:
- What it is (1 sentence)
- Specific recommendation ("move X to Y because Z", not "consider refactoring")
- Fix size: small, medium, large
- Risk if ignored: low, medium, high

Close with one-line status per architecture section: clear, flagged, or skipped with reason.

## Artifact: `.markl/<task>.md`

Once the design is approved, write it to a file before any implementation begins. This artifact is the load-bearing handoff to `check` and any other downstream skill or fresh session. It is not a summary you also keep in your head, it is the source of truth.

**Where**: at the repo root, resolved via `git rev-parse --show-toplevel`. Fall back to `pwd` for non-git projects and tell the user.

**Always run this once before the first artifact write in any repo**, to keep scratchpads out of version control:

```bash
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || ROOT=$(pwd)
mkdir -p "$ROOT/.markl/done"
grep -qxF '.markl/' "$ROOT/.gitignore" 2>/dev/null || echo '.markl/' >> "$ROOT/.gitignore"
```

This is idempotent, safe to run every time. Do not skip it on the assumption "the user already added it", verify mechanically.

**Filename**: `.markl/<short-slug>.md`. Slug from the task in 2-4 words, kebab-case. Never write to `.markl/done/`, that subdirectory is reserved for shipped artifacts moved by `auto-harness` after `check` passes.

**Required sections** (in order, no placeholders, no TBDs):

```markdown
# <task title>

## Goal
<one sentence: the outcome the user actually wants>

## Decisions
- <decision>, anchor: `path/to/file.ts:42`
- <decision>, anchor: `path/to/other.ts:108`
(every decision must cite a file:line from Phase 1 exploration; no anchors means you did not actually explore)

## Acceptance Criteria
- [ ] <criterion>
- [ ] <criterion>
(at least ONE must be behavioral-negative, see rules below)

## Known Unknowns
- <thing that may need resolution during implementation>

## Reframings
<empty at first; appended to on re-entry, see below>
```

### Acceptance Criteria rules

ACs are what `check` will tick. Trivial ACs produce green ticks on hollow work, so:

- **At least one criterion must be behavioral-negative or describe a falsifying failure mode.** Examples:
  - "Does NOT refetch user data when only `theme` prop changes"
  - "Returns 409, not 500, when the same idempotency key is reused with a different body"
  - "Cancelling mid-upload leaves no partial file on disk"
- **Forbidden tautologies** (do not write these, they are not ACs):
  - "Code compiles" / "Tests pass" / "No type errors"
  - "Component renders" / "Page loads"
  - "Endpoint returns 200" / "Function returns a value"
  - "Feature works" / "Implements the design"
- If you cannot write a behavioral-negative criterion, you do not understand the change well enough yet. Go back to Phase 1.

### Re-entry on reframing

`think` is **re-runnable mid-task**. When the user changes direction, contradicts an earlier decision, or reframes the goal:

1. Re-read the existing artifact.
2. Append a new dated entry under `## Reframings`:
   ```
   ### 2026-04-08, <one line summary>
   <what changed, what decisions/ACs are now stale, what replaces them>
   ```
3. Update or strike through stale items in `## Decisions` and `## Acceptance Criteria` so the artifact reflects current truth, not history.

Do not start a new file for the same task. Do not silently revise the original sections without leaving a Reframings entry, `check` needs to see what shifted.

The artifact is only useful if it is current. A stale artifact is worse than no artifact, because the downstream subagent will confidently validate the wrong thing.

### Telemetry

Telemetry is mechanical, not reflective. The `log-skill-usage.sh` PostToolUse hook detects every `Write`/`Edit` to `.markl/*.md` and emits an `artifact_written` event automatically. Do not append manually, the hook owns this. If you need to verify it fired, check `~/.claude/markl-usage.jsonl` for the latest line.
