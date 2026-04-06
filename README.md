<div align="center">
  <h1>markl</h1>
  <p><b>个人 Claude Code 技能集，会根据你的实际使用方式持续进化。</b></p>
</div>

<br/>

## 技能列表

| 技能 | 作用 |
| :--- | :--- |
| [`/think`](skills/think/SKILL.md) | 在动手之前压力测试设计方案，验证架构。 |
| [`/design`](skills/design/SKILL.md) | 生成有明确审美主张的前端界面，而非千篇一律的默认样式。 |
| [`/check`](skills/check/SKILL.md) | 审查 diff，自动修复安全问题，并用证据验证结果。 |
| [`/hunt`](skills/hunt/SKILL.md) | 系统化调试,先确认根因再动手修复。 |
| [`/write`](skills/write/SKILL.md) | 把文字改写得在中英文里都自然顺畅。 |
| [`/learn`](skills/learn/SKILL.md) | 六阶段研究流程,从资料收集到成稿输出。 |
| [`/read`](skills/read/SKILL.md) | 把任意 URL 或 PDF 抓取成干净的 Markdown。 |
| [`/health`](skills/health/SKILL.md) | 审计 Claude Code 配置:CLAUDE.md、规则、技能、hooks、MCP 与行为。 |
| [`/evolve-markl`](skills/evolve-markl/SKILL.md) | 分析使用日志,定位摩擦点,给出 SKILL.md 的修改建议。 |

每个技能是一个独立目录,包含 `SKILL.md`、引用文档和限定作用域的 hooks,通过 slash 命令按需加载。

## 安装

```bash
./install.sh
```

将每个技能软链到 `~/.claude/skills/`,需要 Claude Code 环境。

## 进化机制

`markl` 通过 hook 记录技能使用情况。定期运行 `/evolve-markl` 可以回顾日志,找出技能失灵或指引被忽略的地方,并对相关 `SKILL.md` 给出具体 diff。被采纳的修改会自动提交并推送。

## License

MIT。Forked from [tw93/Waza](https://github.com/tw93/Waza)。
