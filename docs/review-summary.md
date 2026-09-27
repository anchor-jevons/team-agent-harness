# 三方审查与最终取舍

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

## 两项有意保留的取舍

- 信息架构审查建议初期删除 `team.md`。当前保留短文件，限定为跨人协作，避免根 AGENTS 承担全部细节；如果实际只有两三条，可再合并。
- 原版引用 `triage-labels.md`，当前选择修改相关技能和模板，把执行状态集中到 tracker；没有声称原版缺少该文件也能直接工作。

## 复核补充

Agent 能力 reviewer 对综合设计再次复核，确认关键问题已在设计中处理。实施时还需注意：方法技能保留可隐式调用，阶段技能保留显式调用；原版标签操作需要改为写本地 ticket 的 `Status`，不能只删除配置文件引用。

## 独立报告

- [Agent 能力与兼容性](reviews/agent-capabilities.md)
- [Git/worktree 协作](reviews/git-collaboration.md)
- [信息架构与轻量程度](reviews/minimal-architecture.md)

这些报告保留评审时的建议和分歧，最终采用的方案以[当前设计](design.md)为准。
