# 规则来源与预算

本文件记录规则文件（`AGENTS.md`、`docs/agents/`、`.agents/skills/`）的大小预算，以及每次新增、修改、合并、删除规则的来源。`docs/agents/scripts/rule-check` 读取本文件。由 `team-retro` 的提案或其他改规则的 MR 维护；日常开发不需要读取。

## 预算

规则文件会进入每位成员的 agent 上下文，越长越难被遵守。超出预算时先删除或合并，再新增；提高或删除预算要单独 MR 说明理由；合入前 `rule-check` 仍按原值检查（标为 BUDGET-RAISED 或 BUDGET-REMOVED）。起始值约为部署时大小加 15%，按团队实际情况调整。`*` 表示每个匹配的文件各自计算。

| 文件 | 行数上限 | 字节上限 |
| --- | --- | --- |
| AGENTS.md | 45 | 4500 |
| docs/agents/team.md | 62 | 7000 |
| docs/agents/issue-tracker.md | 100 | 10500 |
| docs/agents/domain.md | 22 | 1600 |
| docs/agents/onboarding.md | 32 | 2200 |
| docs/agents/workflow.md | 60 | 6500 |
| .agents/skills/*/SKILL.md | 150 | 12000 |

## 流程图预算

`docs/agents/workflow.md` 的复杂度上限。只能通过单独说明的 MR 提高；`rule-check` 按 base 与当前中较小的值检查。

| 元素 | 上限 |
| --- | --- |
| 节点 | 18 |
| 边 | 26 |
| 闸门 | 15 |

## 记录

每项改动一行，最新的在最后。`ID` 写 `RL-<rand6>`（生成方式同 tracker 的 rand6）。`操作` 为 add、change、merge、delete 或 baseline。`来源证据` 写已打开核实过的事件：journal 的 Lessons、ticket、MR（`!N`）或回归结果的仓库相对路径；只凭推测、没有实际事件的规则不登记、不合入。部署时已有的规则记为一行 baseline，某条规则第一次被修改时再单独登记。删除或合并的规则保留原行，另加一行说明去向。

| ID | 操作 | 位置 | 规则摘要 | 来源证据 | 回归结果 | MR | 日期 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| RL-000000 | baseline | 全部规则文件 | team-agent-harness 部署时的规则 | docs/agents/HARNESS-VERSION | — | <部署 MR> | <YYYY-MM-DD> |
