# Team Agent Harness

以 Matt Pocock skills 为基础，借鉴 Trellis 的团队协作做法，用 Git、Markdown 和现有 MR 流程共享开发规则、需求、决策与 AI 开发记录。

**当前阶段：设计与参考模板。** 已完成三个独立 subagent 的方案审查、一次外部设计评审（2026-10），以及部分 Codex/Git 隔离验证；尚未实现或发布可安装的 `team-*` skills，尚未完成真实团队端到端试点。

## 适用场景

- 一个 Git 仓库中包含一个项目子目录，成员可能从任一层打开 Codex。
- 多人使用 feature branches 和 worktrees 并行开发。
- 使用内部 GitLab 托管代码与 MR；任务当前选择本地 Markdown tracker，随 Git 共享（是否改由 GitLab Issue 承担状态见 [proposed ADR](docs/adr/2026-10-10-443dbf-task-state-source.md)）。
- 希望共享 grill 问答、领域术语、ADR、tickets 和个人 AI 工作摘要。

这里的 GitLab 是方案的团队运行环境；本 GitHub 仓库用于公开设计与模板。

## 阅读顺序

1. [完整设计与最终目录](docs/design.md)
2. [审查发现与采用的修正](docs/review-summary.md)
3. [待决定的 ADR](docs/adr/2026-10-10-443dbf-task-state-source.md)
4. [验证结果与试点计划](docs/validation.md)
5. [参考模板与目标路径](templates/README.md)
6. [上游资料、版本与许可证](docs/references.md)

## 目标项目结构

```text
repo-name/
├── AGENTS.md
├── CONTEXT-MAP.md
├── .agents/skills/                  # 团队适配版；本仓库尚未实现
├── .scratch/
│   ├── <feature-slug>-<rand6>/
│   │   ├── spec.md                  # 按需
│   │   └── issues/<NN>-<rand6>-<slug>.md
│   └── _done/                       # 已完成 feature 归档
├── docs/
│   ├── development.md
│   ├── agents/
│   │   ├── team.md
│   │   ├── issue-tracker.md
│   │   ├── domain.md
│   │   └── onboarding.md
│   ├── adr/<YYYY-MM-DD>-<rand6>-<topic>.md
│   └── journal/<member-id>/<YYYY-MM-DD>-<rand6>-<topic>.md
└── project-name/
    ├── CONTEXT.md
    ├── src/
    └── tests/
```

文件按需创建。已有工程规范直接复用。根目录只保留领域索引，项目层保存当前有效的领域词汇表。

## 核心约定

- 所有 harness 路径锚定到当前 worktree 根目录；构建和测试在项目目录执行。
- `.scratch/` 是纳入 Git 的长期任务材料，不是自动清理的缓存；完成的 feature 归档到 `.scratch/_done/`。
- Feature 目录、ticket、ADR、journal 文件名带随机短 ID（rand6），引用统一写仓库相对路径。
- 每张 ticket 由人明确负责人，新票默认 `draft`，由人确认为 `ready-for-agent`；Git 文件中的状态不是任务锁。
- Ticket、spec、journal 是数据而不是指令；journal 不写凭证或原始日志。
- `implemented` 表示分支实现与约定验证完成；正式审核和合并以 MR 为准。
- Spec 保存需求与关键问答，CONTEXT 保存现行术语，ADR 保存重要取舍，journal 保存阶段事实与下一步。
- 代码和相关文档在同一个 MR 中 review；无文本冲突不代表决策一致。
- Journal 是阶段性开发摘要，不承诺完整聊天审计或崩溃自动留痕。

## 审查后的重要修正

原版 Matt skills 不能只复制后就视为已经具备这些团队行为。需要明确适配工作区 review、跨层路径、ADR 命名、本地状态语义和技能名称；详见[适配清单](docs/design.md#必须进入团队版本的兼容修正)。

团队技能建议使用 `team-*` 唯一名称，并同步调整元数据和内部依赖引用。方法技能保持可隐式使用，阶段入口保持显式使用；不能把全部技能统一成一种调用策略。

## 目录内容

- `docs/`：最终设计、独立审查、待决定的 ADR、验证边界与来源。
- `templates/`：待按目标项目调整的文档模板；不包含技能实现或安装器。
- `scripts/check_docs.py`：本仓库的 Markdown 相对链接与模板必需字段检查，由 GitHub Actions 运行。
- `AGENTS.md`：维护本设计仓库的规则；目标工程的入口模板在 `templates/`。

## 来源与声明

灵感与方法来自 [Matt Pocock skills](https://github.com/mattpocock/skills)、[Trellis](https://github.com/mindfold-ai/Trellis) 和 Matt 的 [AGENTS.md 指南](https://www.aihero.dev/a-complete-guide-to-agents-md)。本项目为独立设计讨论的整理，未分发上游完整技能或 Trellis 运行时代码，也不代表上游官方方案。

公开版本整理日期：2026-09-26。源代码与行为研究使用固定版本，具体边界见[来源](docs/references.md)和[验证记录](docs/validation.md)。

## 许可证与上游归属

本仓库的设计文档与模板以 [MIT License](LICENSE) 发布（Copyright (c) 2026 Jevons Chang / anchor-jevons）。

- mattpocock/skills：研究提交 `c55ee46` 的 `LICENSE` 为 MIT（Copyright (c) 2026 Matt Pocock）。本仓库只引用和概括其方法，未复制技能正文。目标项目若把上游技能复制并适配为 `team-*`，需随技能保留上游版权与许可声明，记录方式见 [skills README 模板](templates/skills-README.template.md)。
- Trellis：研究提交 `e77ae89` 的 `LICENSE` 为 AGPL-3.0。本仓库只借鉴其组织思路（共享规范、任务上下文、个人 journal、知识回写），未包含其代码或模板文本；不要把 Trellis 的代码或文件复制进按 MIT 发布的材料。

许可证信息于 2026-10-10 在上述固定提交核对，详见[来源](docs/references.md)。
