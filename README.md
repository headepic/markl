<div align="center">
  <h1>markl</h1>
  <p><b>个人 Claude Code 技能集，会根据你的实际使用方式持续进化。</b></p>
</div>

<br/>

markl 把一名资深工程师在不同阶段的工作习惯,固化成 10 个可单独触发的 Claude Code 技能。每个技能针对一类具体任务,有明确的进入条件、产出物和退出条件。`auto-harness` 把它们串成一条端到端的工作流,从需求描述跑到代码交付。

## 技能列表

| 技能 | 作用 |
| :--- | :--- |
| [`/auto-harness`](skills/auto-harness/SKILL.md) | 端到端编排器:把一个需求按 5 个阶段(分类→理解→构建→验证→交付)路由给下面的技能,并维护 `.markl/<task>.md` 这个跨阶段的承重 artifact。 |
| [`/think`](skills/think/SKILL.md) | 动手之前压力测试设计方案,产出含 file:line 锚点和可评分 AC 的 artifact。强制要求至少一条行为否定式 AC,禁止"能编译"这类同义反复。 |
| [`/hunt`](skills/hunt/SKILL.md) | 系统化调试,先用一句话确认根因再动手。匹配已知失败形态,管理假设,防止盲修。 |
| [`/design`](skills/design/SKILL.md) | 生成有明确审美主张的前端界面,而非默认模板。先锁定四个方向问题,再写代码。 |
| [`/check`](skills/check/SKILL.md) | 审查 diff:把 artifact + diff 交给独立子 agent 做评审,主 check 综合裁决并跑验证。也支持 dry-run 模式只校验 AC 是否可评分。 |
| [`/learn`](skills/learn/SKILL.md) | 六阶段研究流程,从资料收集到成稿输出。 |
| [`/read`](skills/read/SKILL.md) | 把任意 URL 或 PDF 抓取成干净的 Markdown。 |
| [`/write`](skills/write/SKILL.md) | 把文字改写得在中英文里都自然顺畅。 |
| [`/health`](skills/health/SKILL.md) | 审计 Claude Code 配置:CLAUDE.md、rules、skills、hooks、MCP 与行为偏差,按项目复杂度给出分级建议。 |
| [`/evolve-skills`](skills/evolve-skills/SKILL.md) | 读 hook 日志和会话记录,定位每个技能的实际摩擦点,产出针对 SKILL.md 的具体 diff,被采纳后自动提交并推送。 |

每个技能是一个独立目录,包含 `SKILL.md`、引用文档和作用域限定的 hooks,通过 slash 命令按需加载。技能之间通过仓库根目录下的 `.markl/<task>.md` artifact 文件交接,而不是依赖对话上下文。

## 工作流概览

当任务大到值得编排时,从 `/auto-harness` 开始:

```
A.   分类      判断 shape: feature / refactor / bug / ui
B.   理解      路由给 think / hunt / design,产出 .markl/<slug>.md
B.5  评分门    check --dry-run-rubric 验证每条 AC 是否可评分
C.   构建      主 agent 按 artifact 实现,只动有锚点的文件
D.   验证      check 拉独立子 agent 比对 diff 与 AC
E.   交付      提交、推送、把 artifact 移到 .markl/done/
```

单个技能也可以直接调用,不必走完整流程。`/hunt` 可以单独修 bug,`/check` 可以单独 review 一份 diff。

## 安装

```bash
./install.sh
```

将每个技能软链到 `~/.claude/skills/`,需要 Claude Code 环境。

## 进化机制

每次技能调用、每次写入或读取 `.markl/*.md` 都会被 PostToolUse hook 自动写入 `~/.claude/markl-usage.jsonl`。这是机械数据,不是模型自报。

定期运行 `/evolve-skills` 可以:

- 统计每个技能的真实调用频率和 artifact 健康度
- 扫描会话记录找出"被忽略的指引"或"反复出现的失败模式"
- 用 git log 交叉验证哪些规则已经成为 scar tissue,可以剪掉
- 对相关 `SKILL.md` 给出具体 diff,确认后自动提交并推送

## License

MIT.
