# 参考模板

这些模板供设计评审和后续试点使用。先替换项目名称与占位内容，再按目标路径放置；不要将空模板当作已经完成的需求、规则或记录。

模板正文里的路径相对目标项目解释，并不表示本设计仓库已经存在那些文件。团队版 skills 尚未实现，`team-record-session` 等名称目前是计划中的接口。

| 模板 | 目标仓库中的位置 |
| --- | --- |
| [AGENTS](AGENTS.template.md) | `AGENTS.md` |
| [Context map](CONTEXT-MAP.template.md) | `CONTEXT-MAP.md` |
| [领域词汇](CONTEXT.template.md) | `project-name/CONTEXT.md` |
| [工程规范](development.template.md) | `docs/development.md`，或合入既有规范 |
| [协作约定](team.template.md) | `docs/agents/team.md` |
| [本地 tracker](issue-tracker.template.md) | `docs/agents/issue-tracker.md` |
| [领域文档规则](domain.template.md) | `docs/agents/domain.md` |
| [入组检查](onboarding.template.md) | `docs/agents/onboarding.md` |
| [Skills README](skills-README.template.md) | `.agents/skills/README.md` |
| [Spec](spec.template.md) | `.scratch/<feature-slug>-<rand6>/spec.md` |
| [Ticket](ticket.template.md) | `.scratch/<feature-slug>-<rand6>/issues/<NN>-<rand6>-<ticket-slug>.md` |
| [ADR](adr.template.md) | `docs/adr/<YYYY-MM-DD>-<rand6>-<topic>.md` |
| [Journal](journal.template.md) | `docs/journal/<member-id>/<YYYY-MM-DD>-<rand6>-<topic>.md` |
| [票状态汇总脚本](scripts/ticket-status) | `docs/agents/scripts/ticket-status`（保留可执行权限） |

`<rand6>` 是 6 位小写十六进制随机串，生成与引用规则只在[本地 tracker](issue-tracker.template.md#标识) 中定义。Journal 字段只在 journal 模板中定义。

没有领域术语时，无需创建 map/CONTEXT 空壳；首次产生定义时两者同时落地。小任务可以只有 ticket。ADR 与 journal 按实际工作产生。新建 ticket 默认 `Status: draft`，由人确认后改为 ready-for-agent。

后续接入前完成[设计中的适配清单](../docs/design.md#必须进入团队版本的兼容修正)与[真实试点](../docs/validation.md)。
