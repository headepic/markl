---
name: auto-harness
description: Use to run a task end-to-end from requirement description to shipped code. Routes between think/hunt/design/check based on task shape and owns the artifact handoff. Not for one-off edits, single-skill invocations, or pure investigation.
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
---

# auto-harness: end-to-end workflow orchestration

A meta-skill that routes a single task through markl's phase skills and owns the artifact lifecycle (`.markl/<slug>.md`). Does not do the work itself, delegates to `think` / `hunt` / `design` / `check`.

The harness exists because markl's individual skills are sharp but unaware of each other. Without orchestration, the model picks skills ad-hoc, drops artifacts on the floor, and skips phases under pressure. This skill is the connective tissue.

Stages are named A through E to avoid colliding with `think`'s own internal Phase 1 / 2 / 3 numbering.

## When to use

Trigger when the user describes a unit of work bigger than a one-off edit:

- "build X" / "implement Y" / "add support for Z"
- "我想做一个..." / "帮我从头做这个" / "完整做完这个需求"
- Anything where you would otherwise have to decide which markl skill to invoke first

Do not trigger for:

- Single-line fixes or grep-and-replace work
- Pure investigation ("how does X work"), that is `learn`
- Standalone debugging where the user already knows the bug, that is `hunt` directly
- Reviewing an existing diff, that is `check` directly

## Stage map

| # | Stage | Owner | Entry condition | Exit artifact |
|---|-------|-------|----------------|---------------|
| A | Classify | this skill | New task described | Task shape decided |
| B | Understand | `think` / `hunt` / `design` | Shape known | `.markl/<slug>.md` written |
| B.5 | Rubric gate | `check --dry-run-rubric` | Artifact written | Every AC marked gradable |
| C | Build | main agent | Rubric gate passed | Diff matching artifact |
| D | Verify | `check` | Diff exists | Sign-off block, ACs ticked |
| E | Ship | main agent | check passed | Commit / PR / deploy |

Stages are sequential. No parallelism. No skipping forward.

## Stage A: Classify the task

Decide the task shape in one line. Ask the user only if genuinely ambiguous.

| Shape | Signals | Stage B routes to |
|-------|---------|-------------------|
| **feature** | "add", "build", "implement", new capability | `think` |
| **refactor** | "clean up", "restructure", behavior unchanged | `think` (mode: shape) |
| **bug** | "fix", "broken", "crashes", error attached | `hunt` |
| **ui** | "design", "page", "component", visual work | `design` (after `think` if scope > 1 component) |
| **investigation-first** | "I want to understand X then change it" | `learn`, then re-classify |

State the shape explicitly to the user before routing: `Shape: feature, routing to think.` This is the first observable output of the harness. If the user disagrees, they correct it before any work happens.

## Stage B: Run the entry skill

Invoke the routed skill in the main agent's context. Wait for its exit artifact:

- `think` exits with `.markl/<slug>.md` containing Goal / Decisions (with file:line anchors) / Acceptance Criteria (with at least one behavioral-negative criterion) / Known Unknowns / Reframings.
- `hunt` exits with the same artifact shape, lighter content. See `hunt`'s "Artifact (when invoked under auto-harness)" section.
- `design` exits with the same artifact shape, UI-flavored content. See `design`'s "Artifact (when invoked under auto-harness)" section.

**Hard stop**: do not proceed to Stage C until the artifact file exists at `<repo-root>/.markl/<slug>.md` (top level, not under `done/`) and has been shown to the user. **No code before approval.** This is non-negotiable, it is the entire point of the harness.

The `log-skill-usage.sh` hook fires `artifact_written` automatically when the entry skill writes the file. You do not append telemetry for this stage.

## Stage B.5: Rubric gate

Before any code is written, invoke `check` in **dry-run rubric mode** to verify the artifact's Acceptance Criteria are actually gradable. This catches the most common artifact failure mode (tautological or vague ACs) at near-zero cost, before a build cycle is wasted.

Invocation: tell `check` "dry-run-rubric on `.markl/<slug>.md`" or run `/check --dry-run-rubric` (see `check`'s "Mode: AC dry-run" section). It does NOT touch the diff. It spawns a small subagent that grades each AC as `gradable` / `tautological` / `vague` / `untestable` and checks for at least one behavioral-negative criterion.

Three outcomes:

- **All ACs gradable + at least one behavioral-negative**: print `[auto-harness] Stage B.5: rubric gate, all ACs gradable, proceeding to build` and advance to Stage C.
- **Any AC tautological / vague / untestable, OR no behavioral-negative AC**: print the failing rows, **do not advance**. Re-enter `think` in re-entry mode (append the rubric findings to Reframings as guidance) and rewrite the failing ACs. Then re-run B.5.
- **Re-entry loop > 2**: stop. The artifact's underlying understanding is wrong, not the AC wording. Ask the user to reframe the task.

The rubric gate is the cheapest mistake-catcher in the harness. Skipping it is the same as building first and discovering the AC was always going to be ungradable, except more expensive.

## Stage C: Build

Implement against the artifact. Rules:

- **Re-read the artifact at the start of every build session.** Never trust memory across sessions or even across long stretches in one session. Reading the file also fires `artifact_read` in the hook, which is the signal evolve-skills uses to confirm the handoff was honored.
- **Touch only files anchored in Decisions.** If you find yourself editing something not anchored, stop. Either the artifact is wrong (re-enter `think`) or you are scope-creeping.
- **Build in the smallest steps that produce a runnable state.** Verify each step before moving on. This is not formal TDD, it is "do not write 200 lines before the first run".
- **If a decision changes mid-build, stop and re-run `think` in re-entry mode** (append to Reframings). Do not silently drift.

## Stage D: Verify

Invoke `check`. It will:

- Locate the artifact at `<repo-root>/.markl/*.md` (top level, never recurses into `.markl/done/`)
- Spawn its independent review subagent with (artifact + diff)
- Return Sign-off block with ACs satisfied / violated / silent

If `check` reports violations:

- **AC violated**: return to Stage C, fix, re-check.
- **AC silent**: either the AC was wrong (re-enter `think`) or the diff is incomplete (return to Stage C).
- **Hard stops**: fix before anything else.

**Loop limit**: after 2 build → check cycles without convergence, stop. The problem is upstream, the artifact is wrong, the ACs are tautological, or the task was misclassified at Stage A. Ask the user. The harness cannot mechanically enforce this; treat it as a hard rule on yourself, and be honest in the output line ("cycle 3, stopping per harness rule").

## Stage E: Ship

Only after `check` passes:

- Commit with a message that references the artifact slug, e.g. `feat(<slug>): <one line>`.
- Push / PR / deploy per the user's explicit instruction (do not assume).
- Move the artifact to `.markl/done/<slug>.md` via `mv`. Keep it as evidence; do not delete. The hook detects writes under `.markl/done/` as `artifact_shipped`. Future `evolve-skills` runs scan this directory to learn from completed work.

## Re-entry rules

- **User reframes mid-task**: re-run `think` in re-entry mode (append to Reframings). Do not start a new harness run.
- **Bug discovered during build of a feature**: spawn a side `hunt` invocation, fix, return to build. Note the side trip in the artifact's Reframings.
- **New related task surfaces**: if it fits the current Goal, expand the artifact via re-entry; if it does not, finish the current task first, then start a new harness run.
- **User says "也帮我顺便..."**: it almost always does not fit. Default to "let us finish this first, then start a new task for that".

## Stop conditions

Halt and ask the user when:

- Stage A cannot classify the task with one-line confidence
- Stage B produces an artifact whose ACs you cannot make non-tautological (you do not understand the change well enough)
- Stage D build → check loop has run twice without converging
- The user has been silent through 3 stage transitions (they may have stopped tracking)

## Anti-patterns

- **Skipping Stage B.** "It is small, I will just code it" produces work that fails check with stale assumptions. The artifact takes 5 minutes; the rework takes 50. If the task is genuinely too small for an artifact, it is too small for the harness, invoke the single skill directly.
- **Parallel stages.** Do not think and build simultaneously. Do not check while still building. The stages are sequential because mixing them is how regressions hide.
- **Treating the artifact as documentation.** It is a load-bearing handoff between agents and sessions. If you write it once and then ignore it during build, you have negated the entire harness.
- **Looping check → build silently past round 2.** Past two rounds, the problem is upstream. Stop. Do not keep patching against the same failing AC.
- **Routing UI work to `design` without `think` first when scope is non-trivial.** `design` is for committed visual direction, not for deciding what to build. Multi-component UI work needs `think` first.
- **Calling the harness for one-line edits.** The harness has overhead. Use it for tasks that justify the overhead, typically anything that touches more than 2 files or takes more than 30 minutes to implement.

## Telemetry

Most events are mechanical. The `log-skill-usage.sh` hook captures:

- `Skill` invocation of any markl skill, including `auto-harness` itself
- `artifact_written` on every `Write`/`Edit` to `<repo-root>/.markl/*.md`
- `artifact_read` on every `Read` of the same
- `artifact_shipped` on every `Write`/`Edit` to `<repo-root>/.markl/done/*.md`

The harness does not need to append anything for these. The only reflective telemetry is the stage transition itself, which has no clean tool trigger. This is acknowledged as best-effort: append one line per stage boundary if you remember, otherwise rely on the hook events to reconstruct what happened:

```bash
printf '{"ts":"%s","skill":"auto-harness","event":"stage_%s","cwd":"%s"}\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$STAGE" "$(pwd)" \
  >> ~/.claude/markl-usage.jsonl
```

`$STAGE` is one of: `classify`, `entry_done`, `build_start`, `check_start`, `ship`, `aborted`. `evolve-skills` treats absence of these as low-signal; it does not over-index on missing stage events.

## Output contract

At each stage boundary, output one line to the user:

```
[auto-harness] Stage {letter}: {stage_name}, {next_action}
```

Examples:

```
[auto-harness] Stage A: classify, Shape: feature, routing to think
[auto-harness] Stage B: understand, artifact written: .markl/user-import.md, awaiting your approval
[auto-harness] Stage C: build, 3 files anchored, starting incremental build
[auto-harness] Stage D: verify, check passed, 4/4 ACs satisfied, ready to ship
[auto-harness] Stage E: ship, committed as feat(user-import); push?
```

These lines are the user's tracker. If you stop emitting them, the user loses sight of where the harness is and trust collapses.
