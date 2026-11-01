# 参考模板

这些模板供设计评审和后续试点使用。先替换项目名称与占位内容，再按目标路径放置（或使用[一键部署](#一键部署)脚本）；不要将空模板当作已经完成的需求、规则或记录。

模板正文里的路径相对目标项目解释，并不表示本设计仓库已经存在那些文件。团队版 skills 中只有 `team-retro` 已提供；`team-record-session` 等名称目前是计划中的接口。

| 模板 | 目标仓库中的位置 |
| --- | --- |
| [AGENTS](AGENTS.template.md) | `AGENTS.md` |
| [Context map](CONTEXT-MAP.template.md) | `CONTEXT-MAP.md` |
| [领域词汇](CONTEXT.template.md) | `project-name/CONTEXT.md` |
| [工程规范](development.template.md) | `docs/development.md`，或合入既有规范 |
| [功能地图](feature-map.template.md) | `docs/feature-map.md` |
| [协作约定](team.template.md) | `docs/agents/team.md` |
| [本地 tracker](issue-tracker.template.md) | `docs/agents/issue-tracker.md` |
| [领域文档规则](domain.template.md) | `docs/agents/domain.md` |
| [入组检查](onboarding.template.md) | `docs/agents/onboarding.md` |
| [Skills README](skills-README.template.md) | `.agents/skills/README.md` |
| [规则回归清单](rule-regression.template.md) | `docs/agents/rule-regression.md` |
| [规则来源与预算](rule-log.template.md) | `docs/agents/rule-log.md` |
| [团队流程图](workflow.template.md) | `docs/agents/workflow.md` |
| [team-retro 技能](skills/team-retro/SKILL.md) | `.agents/skills/team-retro/`（连同 `agents/openai.yaml` 与上游许可声明副本） |
| [Spec](spec.template.md) | `.scratch/<feature-slug>-<rand6>/spec.md` |
| [Ticket](ticket.template.md) | `.scratch/<feature-slug>-<rand6>/issues/<NN>-<rand6>-<ticket-slug>.md` |
| [ADR](adr.template.md) | `docs/adr/<YYYY-MM-DD>-<rand6>-<topic>.md` |
| [Journal](journal.template.md) | `docs/journal/<member-id>/<YYYY-MM-DD>-<rand6>-<topic>.md` |
| [票状态汇总脚本](scripts/ticket-status) | `docs/agents/scripts/ticket-status`（保留可执行权限） |
| [推送前检查脚本](scripts/push-check) | `docs/agents/scripts/push-check`（保留可执行权限） |
| [规则检查脚本](scripts/rule-check) | `docs/agents/scripts/rule-check`（保留可执行权限） |

Spec、Ticket、ADR、Journal 四个模板另外原样复制到目标仓库的 `docs/agents/templates/`（保留文件名与字段，只按项目调整占位说明），作为目标仓库中这些文件格式的唯一定义；其他规则提到的“ticket 模板”“journal 模板”“ADR 模板”都指那里的文件。上表右列是按模板新建的文件所在位置。

`<rand6>` 是 6 位小写十六进制随机串，生成与引用规则只在[本地 tracker](issue-tracker.template.md#标识) 中定义。Journal 字段只在 journal 模板中定义。

功能地图（`docs/feature-map.md`）像 sitemap 一样列出面向用户的功能：ID、作用、入口（CLI 命令、页面与 DOM 元素、快捷键、API）、可运行的验证步骤、Owner 与最近验证。Agent 先用它把含糊的请求对到具体功能，对不上就问人；改用户可见行为的 MR 同时更新条目，ticket 用 `涉及功能:` 引用条目 ID，`push-check` 对漏更新给出 WARN FEATURE-MAP。思路来自 poteto 关于 agent 自我验证的演讲（“A feature map gives context. A CLI gives control.”）；本仓库不提供验证 CLI，条目的“验证”写项目已有的命令。

没有领域术语时，无需创建 map/CONTEXT 空壳；首次产生定义时两者同时落地。小任务可以只有 ticket。ADR 与 journal 按实际工作产生。新建 ticket 默认 `Status: draft`、`Owner: None`，由人确认后改为 ready-for-agent 并记录 `Confirmed-by:`。

后续接入前完成[设计中的适配清单](../docs/design.md#必须进入团队版本的兼容修正)与[真实试点](../docs/validation.md)。

## 一键部署

仓库根目录的 `install.sh` 按上表把规则与模板部署到目标仓库，依赖只有 bash、git、coreutils 和 sed（部署后的 `ticket-status`、`push-check` 需要 python3）。

```bash
# 本地克隆：目标目录默认为当前目录所在仓库
/path/to/team-agent-harness/install.sh [选项] [目标目录]

# 远程：在目标仓库内运行，脚本浅克隆 harness 仓库（--ref 选择分支/标签/提交，默认 main）
curl -fsSL https://raw.githubusercontent.com/anchor-jevons/team-agent-harness/main/install.sh | bash -s -- [选项]

# 合入 main 之前，用分支上的脚本和模板
curl -fsSL https://raw.githubusercontent.com/anchor-jevons/team-agent-harness/<分支>/install.sh | bash -s -- --ref <分支> [选项]
```

常用选项（`--help` 查看全部）：

| 选项 | 作用 |
| --- | --- |
| `--project-name`、`--code-dir` | 项目名（AGENTS.md 标题，默认仓库目录名）与代码目录（替换 `project-name/`；默认取同名子目录、所在一级子目录或仓库根 `.`） |
| `--description` | AGENTS.md 的一句话项目说明 |
| `--members "alice:alice-gl,bob:bob-gl"` | 填写 `team.md` 名册（`成员ID[:GitLab 用户名[:备注]]`） |
| `--min-codex-version` | 填写 `onboarding.md` 的 Codex 最低版本 |
| `--test-cmd`、`--lint-cmd` | 填写 `development.md` 的“验证”一节 |
| `--stale-days` | tracker 的陈旧天数，默认 7 |
| `--branch`、`--no-branch` | 提交到指定新分支（默认 `chore/agent-harness`，不推送）；或只写文件不提交 |
| `--dry-run`、`--force`、`-y` | 只预览；工作区不干净时仍继续；不交互 |

行为约定：

- 目标必须是 Git 工作区；工作区不干净时拒绝执行（`--force` 例外，且只提交脚本创建的文件）。有终端时询问未提供的值，否则使用默认值或保留占位符。
- 不覆盖任何已有文件。内容相同的文件跳过；已有且不同的文件（常见于 `AGENTS.md`、`docs/development.md`）在旁边写 `<文件>.harness-new`，不提交，由人合并后删除。重复运行不会产生新改动。
- `CONTEXT-MAP.md` 与 `CONTEXT.md` 不创建；不读写 `~/.codex`；不推送、不创建 MR。
- `docs/agents/HARNESS-VERSION` 记录来源仓库、ref 与提交 SHA，升级时以此为基线对比模板变化。
- `docs/agents/rule-log.md` 的预算是起始建议值，部署后按团队实际情况调整；之后修改规则文件的 MR 附 `docs/agents/scripts/rule-check` 输出与 `docs/agents/rule-regression.md` 中受影响场景的结果，见 `team.md` 的“规则迭代与保护”。`docs/agents/workflow.md` 的闸门表引用 `team.md` 与 `issue-tracker.md` 的原句；部署后若改写这些句子，同一 MR 中同步更新闸门表，否则 `rule-check` 报 GRAPH-RULE-MISMATCH。规则中描述流程步骤的句子末尾带 `<!-- flow: <ID> -->` 标记（ID 为图中的节点或闸门），`rule-check` 双向核对标记与图；改写这些句子时保留标记。升级已部署的仓库时，若同时改动检查（`docs/agents/scripts/`、`rule-regression.md` 的既有内容）与规则文件，`rule-check` 判 FAIL；依次拆成 MR：先合入只含检查的，需要提高预算时再单独合入预算（预算取 base 与当前中较严的值），最后合入规则部分。
- 脚本不修改 GitLab 设置。部署后建议把 main 设为受保护分支（禁止直接推送与强推、只经 MR 合入），并在 MR 审批设置中开启 “Reset approvals on push”，与 `team.md` 的“分支与合并”一致。
- 结束时列出已创建、跳过和待合并的文件，以及仍需团队填写的占位符（如 `development.md` 的工作流程与工程原则、skills README 的上游 SHA），并给出后续步骤：review、推送并开 MR、配置 CODEOWNERS、按 onboarding 检查、运行 `ticket-status`。

修改模板中的占位符、目标路径或文件名时，同步更新 `install.sh`。
