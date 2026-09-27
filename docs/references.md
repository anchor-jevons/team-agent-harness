# 来源与研究基线

本仓库区分上游原有行为、团队适配建议与实际验证。以下固定版本用于研究，不表示上游最新版本永远保持这些行为。

## Matt Pocock skills

- 仓库：[mattpocock/skills](https://github.com/mattpocock/skills)
- 研究提交：`c55ee46073ed923f86ce59a5eb3b6d895095d1b7`，研究时 package/plugin 版本为 `1.2.3`。
- [固定版本源码](https://github.com/mattpocock/skills/tree/c55ee46073ed923f86ce59a5eb3b6d895095d1b7)
- [AGENTS.md 完全指南](https://www.aihero.dev/a-complete-guide-to-agents-md)
- [本地 tracker 模板](https://github.com/mattpocock/skills/blob/c55ee46073ed923f86ce59a5eb3b6d895095d1b7/skills/engineering/setup-matt-pocock-skills/issue-tracker-local.md)
- [领域建模](https://github.com/mattpocock/skills/blob/c55ee46073ed923f86ce59a5eb3b6d895095d1b7/skills/engineering/domain-modeling/SKILL.md)
- [CONTEXT 格式](https://github.com/mattpocock/skills/blob/c55ee46073ed923f86ce59a5eb3b6d895095d1b7/skills/engineering/domain-modeling/CONTEXT-FORMAT.md)
- [ADR 格式](https://github.com/mattpocock/skills/blob/c55ee46073ed923f86ce59a5eb3b6d895095d1b7/skills/engineering/domain-modeling/ADR-FORMAT.md)
- [implement](https://github.com/mattpocock/skills/blob/c55ee46073ed923f86ce59a5eb3b6d895095d1b7/skills/engineering/implement/SKILL.md)
- [code-review](https://github.com/mattpocock/skills/blob/c55ee46073ed923f86ce59a5eb3b6d895095d1b7/skills/engineering/code-review/SKILL.md)

研究基线的技能通过自然语言规定行为。目录、调用策略和模板之间存在需要团队适配的接缝；本仓库不宣称原版具有统一运行时、事务锁或自动审计能力。

## Trellis

- 仓库：[mindfold-ai/Trellis](https://github.com/mindfold-ai/Trellis)
- 研究提交：`e77ae89f648a78d5859fa2e8ac314655898421a5`，研究时 CLI 版本为 `0.6.17`。
- [固定版本源码](https://github.com/mindfold-ai/Trellis/tree/e77ae89f648a78d5859fa2e8ac314655898421a5)

本设计借鉴共享规范、任务上下文、个人 journal 和知识回写的组织方式；没有引入其 CLI、hooks、任务状态脚本或 channel 调度体系。

## Codex 官方资料

- [AGENTS.md 发现与分层](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [Skills 发现、调用与同名处理](https://learn.chatgpt.com/docs/build-skills)
- [CLI 参数，包括 add-dir](https://learn.chatgpt.com/docs/developer-commands)
- [Worktrees](https://learn.chatgpt.com/docs/environments/git-worktrees)

CLI 发现探测使用 `codex-cli 0.154.0-alpha.6.2`。官方页面及宿主行为可能变化，升级后需要重新确认实际技能来源、根目录发现与文件写权限。
