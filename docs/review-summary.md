# 审查与最终取舍

本文记录 2026-09 三方 subagent 审查与 2026-10 外部设计评审的采纳情况。

## 2026-09 三方审查

三个独立 subagent 分别检查 agent 能力、Git/worktree 协作、信息架构。主要发现经主 agent 核对真实技能文件、官方资料和隔离探测后合入设计。多 agent 的一致意见不代替真实运行验证。

| 发现 | 采用的修正 |
| --- | --- |
| 原 implement 先 review 后 commit，但 review 默认只看 base...HEAD | 团队版 review 必须覆盖工作区与新文件，并记录比较范围 |
| 项目与个人同名 skills 可能同时出现 | 团队技能采用 team-* 唯一名称，完整更新元数据与内部引用 |
| 发现根指令不代表能够写上层任务和日志 | 根路径解析与会话权限独立验收 |
| 本地 tracker 含 wayfinder 认领状态和 triage 配置依赖 | 第一版排除自动抢票；状态词汇统一到 tracker 并修改实际模板 |
| 持续 domain modeling 可能变成追加式流水 | CONTEXT 修订当前定义；问答、决策和日志各归其位 |
| ADR 连续编号在并行分支中重复 | 日期加唯一标识，使用完整相对链接；同步修改 ADR 模板 |
| 无文本冲突也可存在相反决策 | MR 同时审查相关 spec、领域定义、ADR 和实现 |
| 最终收尾日志无法保证中断时留痕 | 关键结论及时写正文，journal 记录阶段事实，明确中断边界 |
| 任务状态和 SHA 祖先关系不保证依赖可用 | 核对当前分支实际实现；长期追踪结合任务、journal 和 MR |

### 两项有意保留的取舍

- 信息架构审查建议初期删除 `team.md`。当前保留短文件，限定为跨人协作，避免根 AGENTS 承担全部细节；如果实际只有两三条，可再合并。
- 原版引用 `triage-labels.md`，当前选择修改相关技能和模板，把执行状态集中到 tracker；没有声称原版缺少该文件也能直接工作。

### 复核补充

Agent 能力 reviewer 对综合设计再次复核，确认关键问题已在设计中处理。实施时还需注意：方法技能保留可隐式调用，阶段技能保留显式调用；原版标签操作需要改为写本地 ticket 的 `Status`，不能只删除配置文件引用。

### 独立报告

- [Agent 能力与兼容性](reviews/agent-capabilities.md)
- [Git/worktree 协作](reviews/git-collaboration.md)
- [信息架构与轻量程度](reviews/minimal-architecture.md)

这些报告保留评审时的建议和分歧，最终采用的方案以[当前设计](design.md)为准。

## 2026-10 外部设计评审

[评审原文](reviews/2026-10-claude-design-review.md)基于提交 `d42c607`，同时汇总了此前提出的 LICENSE、命名顺序、模板字段等问题。以下修订于 2026-10-10 完成，均为文档与模板修改，相关试点**尚未执行**。

### 采纳

| 评审项 | 修改 |
| --- | --- |
| 先前意见：缺 LICENSE 与上游归属 | 新增 MIT [LICENSE](../LICENSE)；README 与[来源](references.md)写明 mattpocock/skills（MIT）与 Trellis（AGPL-3.0）在固定提交的许可证及本仓库的使用边界 |
| 先前意见：ADR 与 journal 命名顺序不一致 | 统一为 `<YYYY-MM-DD>-<rand6>-<topic>`，rand6 生成方式只在 tracker 模板定义 |
| 先前意见：ticket 缺 Spec、ADR 缺替代关系 | Ticket 增加 `Spec:`；ADR 模板写明 proposed/accepted/superseded 与 `Supersedes:`/`Superseded by:` |
| 先前意见：team 模板引用的 `.agents/skills/README.md` 没有模板 | 新增 [skills README 模板](../templates/skills-README.template.md)，含上游 SHA、许可证、名称映射、升级流程 |
| §5-1 任务状态放 GitLab 还是 Markdown | 新增 [ADR](adr/2026-10-10-443dbf-task-state-source.md) 列出三种方案与评审的混合建议；2026-10-10 Jevons 决定采用纯 Markdown（accepted）。Owner 与状态只在 ticket 中维护，不使用 GitLab Issue；ticket 只保留可选的 `MR:` 引用。评审的混合建议未采纳 |
| §2-1、§5-2 ticket/feature 编号跨分支冲突 | Feature 目录与 ticket 文件名带 rand6；NN 只表示阅读顺序 |
| §2-2、§3、§5-3 状态机 | 新增 draft（默认）、blocked、dropped；in-progress 必填 `Branch:`/`Since:`；只有人能把 draft 改为 ready-for-agent；陈旧规则（天数由团队填写，建议 7）；MR 打回回到 in-progress |
| §5-4 跨分支可见性 | Tracker 增加基于 `git fetch`/`git grep` 的只读状态查询，只用于报告，不用于认领 |
| §3、§5-5 指令优先级与安全 | AGENTS 模板增加 Priority and trust：团队规则优先级、个人 override 冲突需报告、ticket/spec/journal 视为数据、分支改动技能需报告、journal 禁写凭证；team 模板建议 CODEOWNERS 与受保护分支；设计说明 `--add-dir ..` 扩大写入范围 |
| §2-3、§5-6 重复定义 | AGENTS 草案只保留模板，设计改为链接；journal 字段只在模板定义 |
| §2-4 试点数量对不上 | 试点清单只在 validation.md 维护（6 项），设计引用它 |
| §2-5 标识形式不一致 | 引用统一写仓库相对路径，可同时给相对链接 |
| §2-6、§5-7 成员身份与生命周期 | team 模板增加成员名册；新增 `.scratch/_done/` 归档规则；入口要求搜索排除归档与 journal |
| §3 规划基线 | team 模板写明多人并行前先合入只含 spec 与拆票的规划 MR |
| §4、§5-8 验证计划 | validation.md 改为试点计划：通过标准、模型场景至少 5 次重复、记录读取文件与 token；补充 R1–R8 风险场景与 3 人以上并发；新增[入组检查模板](../templates/onboarding.template.md) |

### 暂缓、拒绝或待试点

- **CI 检查（先前意见）**：Jevons 拒绝了加入 CI 的建议，本仓库不设 CI；链接与模板一致性按 AGENTS.md 在修改后人工检查。
- **陈旧天数与最低 Codex 版本**：模板留空由团队填写；建议值 7 天未经试点验证。
- **公开可复现 fixture（§5-8）**：原临时 fixture 不在本仓库；新 fixture 随试点一起提交，本次未编写。
- **归档后路径变化**：移入 `_done/` 会改变仓库相对路径，当前以 rand6 定位旧引用；是否可接受需试点确认。
- **同票字段冲突（§3）**：本次只把 Handoff 改为追加行，Status/Owner 同行冲突仍需 R2 试点观察后再决定是否调整。
- **全部 team-* 技能实现、真实项目端到端试点、GitLab CODEOWNERS 配置**：仍未实施。
