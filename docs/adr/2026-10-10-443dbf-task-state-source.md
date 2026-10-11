# 任务状态以 GitLab Issue/MR 还是仓库 Markdown 为准

Status: proposed
Date: 2026-10-10
Supersedes: None
Superseded by: None

本 ADR 记录一个尚未决定的设计问题，等待 Jevons 确认。在决定之前，当前设计（Markdown ticket 为任务材料与状态的唯一位置）保持不变；ticket 模板只增加了可选的 `Issue:`/`MR:` 字段，两种方案下都可以使用。

## 背景

团队已有内部 GitLab 托管代码与 MR，但 v4 设计把 Git 文件定为唯一协作介质，本地 tracker 模板直接规定“不创建远端 Issue”，仓库里没有论证这一取舍。结果是负责人分配、在途状态、陈旧认领和跨分支可见性都被定义为“不在能力内”：状态改动随 feature 分支走，main 上只能看到规划状态和合入结果，查看在途工作要逐条检查分支（见 [2026-10 设计评审](../reviews/2026-10-claude-design-review.md) 第 1、3 节）。

这些问题 GitLab Issue/MR 本身可以处理：Assignee、开关状态、标签、看板和 MR 关联都是跨分支、实时可见的。

## 方案

### A. 仅 Markdown（v4 现状）

Owner、Status、spec、验收、Context 全部在 `.scratch/` 中，随分支版本化。

- 优点：离线可读、随代码同 MR 审查、agent 不需要 GitLab 访问权限、无外部依赖。
- 代价：在途状态只存在于各分支；需要随机 ID、状态机、`Branch:`/`Since:`、陈旧规则和跨分支只读查询来弥补（本次修订已加入），人数增加后可见性仍随分支数线性变差。

### B. 全部放 GitLab Issue

需求、验收、状态都写在 Issue，仓库只放代码和 CONTEXT/ADR。

- 优点：天然跨分支可见，复用现有权限、通知和看板。
- 代价：需求与验收脱离代码版本，不能和实现同 MR 审查；agent 需要 GitLab API 权限和对应技能；与 Matt 本地 tracker 的适配差异最大。

### C. 混合（评审建议）

- 负责人与在途状态以 GitLab Issue/MR 为准：Issue 的 Assignee 即 Owner，打开的 draft MR 即 in-progress，MR 合并/关闭即结束。
- spec、验收条件、Context、Handoff 继续留在仓库 Markdown，随代码审查。
- ticket 用 `Issue:`/`MR:` 链接远端；`Status:` 只保留 draft/ready-for-agent/blocked/dropped 等规划语义，或改为由 MR 推导。

- 优点：复用 GitLab 解决可见性与改派，同时保留需求的版本化和同 MR 审查。
- 代价：Owner/状态有两个可能的来源，需要明确哪一处权威，避免互相矛盾；agent 读取远端状态需要额外权限，或只由人维护远端字段。

## 待决定

1. 选择 A、B 或 C。
2. 若选 C：ticket 中 `Owner:`/`Status:` 是删除、保留为镜像，还是只保留规划语义；谁负责创建 Issue 与链接。
3. Agent 是否获得 GitLab 读取（或写入）权限；没有权限时只由人维护远端字段。
4. 是否需要在试点中先用 A 运行一轮，再比较 C 的实际收益。

## 影响

- 选 A：保持本次修订后的设计，无需进一步改动。
- 选 B 或 C：需要修改 `templates/issue-tracker.template.md`、`templates/ticket.template.md`、`templates/team.template.md` 与设计中“任务与进度语义”一节，并增加相应试点场景。
- 无论哪种方案，正式审核与合并仍以 GitLab MR 为准。
