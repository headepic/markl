<div align="center">
  <h1>markl</h1>
  <p><b>A personal Claude Code skill collection that learns from how you actually work.</b></p>
</div>

<br/>

## Why

Most skill collections are static: someone writes a playbook, you install it, it never changes. markl is the opposite. It ships with a small set of engineering skills, plus one meta-skill (`/evolve-markl`) that reviews how you have been using them and proposes edits to the playbooks themselves. The collection sharpens over time against your real friction, not someone else's.

## Skills

| Skill | When | What it does |
| :--- | :--- | :--- |
| [`/think`](skills/think/SKILL.md) | Before building anything new | Pressure-tests the design and validates architecture before code. |
| [`/design`](skills/design/SKILL.md) | Building frontend interfaces | Produces distinctive UI with a committed aesthetic, not generic defaults. |
| [`/check`](skills/check/SKILL.md) | After a task, before merging | Reviews the diff, auto-fixes safe issues, verifies with evidence. |
| [`/hunt`](skills/hunt/SKILL.md) | Any bug or unexpected behavior | Systematic debugging. Root cause confirmed before any fix. |
| [`/write`](skills/write/SKILL.md) | Writing or editing prose | Rewrites prose to sound natural in Chinese and English. |
| [`/learn`](skills/learn/SKILL.md) | Diving into an unfamiliar domain | Six-phase research workflow from collection to published output. |
| [`/read`](skills/read/SKILL.md) | Any URL or PDF | Fetches content as clean Markdown. |
| [`/health`](skills/health/SKILL.md) | Auditing Claude Code setup | Checks CLAUDE.md, rules, skills, hooks, MCP, and behavior. |
| [`/evolve-markl`](skills/evolve-markl/SKILL.md) | Reviewing skill usage | Analyzes usage logs, surfaces friction, proposes SKILL.md edits. |

Each skill is a folder with `SKILL.md`, references, and scoped hooks. Skills load on demand via their slash command.

## Install

```bash
./install.sh
```

Symlinks each skill into `~/.claude/skills/`. Requires Claude Code.

## Evolving the collection

`markl` logs skill usage through a hook. Run `/evolve-markl` periodically to review the log, identify where a skill misfired or where guidance was ignored, and get concrete diffs for the relevant `SKILL.md` files. Accepted edits are committed and pushed automatically.

## License

MIT. Forked from [tw93/Waza](https://github.com/tw93/Waza).
