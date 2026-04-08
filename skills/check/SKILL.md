---
name: check
description: Use after completing a task or before merging. Not for exploring ideas or debugging.
version: 3.0.0
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: "bash ${CLAUDE_SKILL_DIR}/scripts/check-destructive.sh"
          statusMessage: "Checking for destructive commands..."
---

# Check: Review Before You Ship

Read the diff, find the problems, fix what can be fixed safely, ask about the rest. Do not claim done until verification has run in this session.

## Mode: AC dry-run (rubric gate)

`check` has a second mode used by `auto-harness` between Stage B and Stage C: **AC dry-run**. Trigger when the user (or auto-harness) says `check --dry-run-rubric` or "check the artifact AC quality before I build". In dry-run mode:

1. Locate the live artifact via Step 0a below.
2. **Do not** get a diff. There is no diff yet.
3. Spawn the review subagent with the artifact contents and these instructions only:
   - "You are validating whether the Acceptance Criteria in the artifact below are gradable, not whether anything was built. For each AC, return one of: `gradable` (a future diff could clearly satisfy or violate it), `tautological` (matches the bad-AC list: 'compiles', 'renders', 'returns 200', 'feature works', etc.), `vague` (no concrete observable behavior), `untestable` (would need information not available at review time)."
   - "Also check: does at least one AC describe a behavioral-negative or falsifying failure mode? If not, flag the artifact as `missing-negative`."
   - "Output as a markdown table: `| # | criterion | verdict | suggestion |`. No other commentary."
4. Main check parses the table. **Gate**: if any AC is `tautological` / `vague` / `untestable`, OR `missing-negative` is set, the artifact fails the rubric gate. Print the failing rows and tell the user (or auto-harness) to send the artifact back to `think` for re-entry. Do not proceed.
5. If every AC is `gradable` and at least one is behavioral-negative, print `rubric: gradable, ready for build` and exit.

Dry-run mode is cheap (no diff, no UI rubric, one short subagent call) and catches the most common failure mode of the artifact convention: ACs that look fine to the writer but are not actually gradable. Skipping the gate means a wasted build cycle to discover the same thing later.

## Step 0: Locate artifact, get diff, spawn subagent

`check` does not review the diff in its own context. It hands the artifact and diff to a fresh subagent so the reviewer is independent of whoever generated the work. **The subagent returns findings. You, main check, decide.** Never rubber-stamp a subagent "LGTM."

### 0a. Locate the live artifact

At repo root, enumerate live artifacts only. Live means top level of `.markl/`; never recurse into `.markl/done/` (those are shipped, not under review):

```bash
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
find "$ROOT/.markl" -maxdepth 1 -name '*.md' -type f 2>/dev/null
```

- Exactly one match: that is the artifact.
- Multiple matches: ask the user which task this `check` is for.
- Zero matches: proceed in **legacy mode** and mark `artifact: missing` in Sign-off. The review will be vibes-based and you should say so explicitly to the user.

### 0b. Get the diff

```bash
git fetch origin
git diff origin/main
```

If the base branch is not `main`, ask before running. Already on the base branch? Stop and ask which commits to review.

### 0c. Spawn the review subagent

Use the `Agent` tool, `general-purpose`. Build a self-contained prompt containing:

1. **Full contents of the artifact file** pasted inline (not the path).
2. **Full diff** pasted inline.
3. **Hard stops and Soft signals categories** from this skill pasted inline so the subagent uses the same vocabulary.
4. **If the diff touches UI files** (`.tsx`, `.jsx`, `.vue`, `.svelte`, `.css`, `.html`, or anything under `components/` or `pages/`), paste this rubric and ask the subagent to score 1 to 3 on each with a one-line justification:
   - **design quality**: commits to a visual direction or defaults to template?
   - **originality**: would a default prompt have generated the same thing?
   - **craft**: typography, spacing, color tokens, state transitions
   - **functionality**: accessibility, responsive behavior, keyboard, contrast
5. **Output contract** the subagent must follow exactly:

   ```markdown
   ## AC Verdict
   | # | criterion | status | citation |
   |---|-----------|--------|----------|
   | 1 | <quoted from artifact> | satisfied / violated / silent | <file:line or "no diff coverage"> |

   ## Hard Stops
   - <category>: <one line>, <file:line>
   (or "none")

   ## Soft Signals
   - <one line>, <file:line>
   (or "none")

   ## UI Rubric (only if UI files present)
   | dimension | score | note |
   |-----------|-------|------|
   | design quality | 1-3 | ... |
   ```

6. **Forbidden in the subagent's output**: any verdict, any merge/no-merge recommendation, any code fix. Findings only. Main check decides.
7. **Forbidden tool calls in the subagent**: `Write`, `Edit`, `NotebookEdit`. The subagent must not modify any file, especially not under `.markl/`, since the hook would record phantom `artifact_written` events and pollute evolve-skills' health metrics. State this constraint in the prompt explicitly.

### 0d. Synthesize

Parse the subagent's table directly. Count `satisfied`, `violated`, `silent` rows for the Sign-off block. Cross-check against the artifact's Reframings section: if the artifact was reframed mid-task, the subagent may be validating against ACs the user already retracted. Flag any such mismatch explicitly before proceeding.

If the subagent's reasoning seems wrong (it happens), say so to the user and explain what you think instead. Do not silently override; show the disagreement.

Telemetry for `artifact_read` is captured automatically by the `log-skill-usage.sh` PostToolUse hook the moment you `Read` the artifact file. Same hook captures `artifact_written`, `artifact_shipped`. The only manual telemetry call in `check` is for the legacy `artifact: missing` case, since no Read fires:

```bash
printf '{"ts":"%s","skill":"check","event":"artifact_missing","cwd":"%s"}\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(pwd)" \
  >> ~/.claude/markl-usage.jsonl
```

## Did We Build What Was Asked?

Before reading the code, check for scope drift:
- Pull up recent commit messages and any task files
- Does the diff match the stated goal? Flag anything outside that scope: unrelated files, voluntary additions, missing requirements
- Label it: **on target** / **drift** / **incomplete** and note it, but do not block on it

## What to Look For

### Hard stops (fix before merging)

These are not negotiable:

- **Destructive auto-execution**: any task flagged as "safe" or "auto-run" that modifies user-visible state (history files, config files, stored preferences, installed software, cache entries the user can inspect) must require explicit confirmation. "Safe" means no side effects, not "probably harmless." If a task deletes or rewrites something the user can see, it is not safe by default.
- **Release artifacts missing**: a GitHub release with an empty body, missing assets, or unuploaded build files is not a completed release. Verify every artifact listed in the release template exists as a local file and has been uploaded before declaring done.
- **Translated file naming collision**: when placing a file in a language-specific directory (e.g., `_posts_en/`, `en/`), the file name must not repeat the language suffix. Check the naming convention of existing files in the same directory first.

- **GitHub issue or PR number mismatch**: before commenting on, closing, or acting on a GitHub issue or PR, verify the number matches the one discussed in this session. Do not rely on memory. Run `gh issue view N` or `gh pr view N` to confirm the title matches before writing.

- **GitHub comment style**: PR review comments and issue replies must be brief (1-2 sentences), natural-sounding, and friendly. Not verbose. Not formatted like a report. Not AI-sounding. If a comment needs more than 2 sentences, it should be structured as a list, not a paragraph.

- **Injection and validation**: SQL, command, path injection; inputs that bypass validation at system entry points
- **Shared state**: unsynchronized writes, check-then-act races, missing locks
- **External trust**: output from LLMs, APIs, or user input fed into commands or queries without sanitization; credentials hardcoded or logged
- **Missing cases**: enum or match exhaustiveness; use grep on sibling values outside the diff to confirm
- **Dependency changes**: unexpected additions or version bumps in `package.json`, `Cargo.toml`, `go.mod`, or `requirements.txt`. Flag any new dependency not obviously required by the diff.

### Soft signals (flag, do not block)

Worth noting but not merge-blocking:

- Side effects that are not obvious from the function signature
- Magic literals that should be named constants
- Dead code, stale comments, style gaps relative to the surrounding code
- Untested new paths
- Loop queries, missing indexes, unbounded growth

## How to Handle Findings

Fix directly when the correct answer is unambiguous: clear bugs, null checks on crash paths, style inconsistencies matching the surrounding code, trivial test additions.

Batch everything else into a single AskUserQuestion when the fix involves behavior changes, architectural choices, or anything where "right" depends on intent:

```
[N items need a decision]

1. [hard stop / signal] What: ... Suggested fix: ... Keep / Skip?
2. ...
```

## GitHub Operations

Use `gh` CLI for all GitHub interactions. If `gh` is not installed, run `brew install gh && gh auth login` (or guide the user through their platform's install).

```bash
# Before commenting or closing issues, verify the number
gh issue view 123 --json title,state --jq '.title'

# Before merging, check CI status
gh pr checks

# Create PR with structured body
gh pr create --title "..." --body "..."

# Review PR diff
gh pr diff 123

# Leave a comment (keep it 1-2 sentences, natural tone)
gh pr comment 123 --body "Looks good, one small fix applied."
```

Do not use the GitHub MCP or raw API when `gh` can do the same thing. `gh` handles auth, pagination, and error messages cleanly.

## Judgment Quality

Beyond correctness, ask three questions a senior reviewer would ask:

- **Right problem?** Does the diff solve what was actually needed, or a slightly different version of it? A technically correct solution to the wrong problem is a bug with extra steps.
- **Mature approach?** Is the implementation idiomatic for this codebase and language, or does it introduce a pattern that will confuse the next person? Clever code that nobody else can maintain is a liability.
- **Honest edge cases?** Does the code handle failure modes and boundary conditions explicitly, or does it silently succeed in the happy path and silently corrupt in the others? Check what happens on nil, empty, zero, concurrent access, and upstream failure.

These do not block a merge on their own, but a "no" on any of them is worth flagging explicitly.

## Regression Coverage

For every new code path: trace it, check if a test covers it. If this change fixes a bug, a test that fails on the old code must exist before this is done.

## Verification

After all fixes are applied, run `scripts/verify.sh` from this skill's directory, or the project's known verification command:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/verify.sh"
```

If nothing is detected, ask the user for the verification command before proceeding.

Paste the full output. Report exact numbers. Done means: the command ran in this session and passed.

If no verification command exists or the command fails: halt. Do not claim done. Ask the user how to verify before proceeding.

If any of these phrases appear in your reasoning, stop and run the verification command before continuing:

- "should work now" / "should be fine"
- "probably correct" / "probably fixed"
- "seems to be working" / "appears to work"
- "I'm confident" / "clearly fixed"
- "trivial change, no need to verify"

These are rationalization patterns, not evidence. Verification ran and passed = done. Everything else = not done.

## Gotchas

Real failures from prior sessions, in order of frequency:

- **Commented on the wrong issue.** Left a comment on #249 when the conversation was about #255. Run `gh issue view N` or `gh pr view N` to confirm title before commenting or closing.
- **PR comments sounded like a report.** User had to iterate multiple times on comment tone. GitHub comments should be 1-2 sentences, natural, like a colleague, not a structured review output.
- **Announced release done before uploading artifacts.** Pushed the GitHub release with no .dmg/.zip/.sha256 attached. Verify every artifact listed in the release template exists as a local file and has been uploaded.
- **Language suffix doubled.** Placed `article.en.md` inside `_posts_en/`, generating a duplicate URL. Check the naming convention of existing files in the target directory first.
- **Skipped verification on "trivial" changes.** "It's a one-line fix" is how trivial changes break things. If the urge to skip arises, run `scripts/verify.sh` anyway.
- **Deployed without env vars.** Pushed to Vercel while API keys only existed in local `.env.local`. Site returned 401 on every request. Run `vercel env ls` or equivalent and diff against local keys before deploying.
- **Git push failed from auth mismatch.** Two failed pushes before discovering remote was HTTPS but local expected SSH. Run `git remote -v` and verify auth method before the first push in a new project.

## Sign-off

```
files changed:    N (+X -Y)
scope:            on target / drift: [what]
artifact:         .markl/<slug>.md (read) / missing (legacy mode)
ACs:              N satisfied / N violated / N silent
hard stops:       N found, N fixed, N deferred
signals:          N noted
new tests:        N
verification:     [command] → pass / fail
```
