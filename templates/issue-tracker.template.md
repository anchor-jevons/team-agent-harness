# Issue tracker: Local Markdown

路径以当前 worktree 根目录为基准：

- 功能：`.scratch/<feature-slug>/`。
- 需求：该目录下的 `spec.md`，小任务可省略。
- 任务：`issues/<NN>-<ticket>.md`，每张票一个文件。

完整仓库相对路径是任务标识。Feature slug 在仓库内唯一，NN 只在当前功能内唯一。由 feature 负责人协调初始编号，新增票不重排旧编号。

## 执行状态

| Status | 含义 |
| --- | --- |
| ready-for-agent | 范围与验收已明确，可安排执行 |
| in-progress | 指定负责人正在当前工作分支执行 |
| implemented | 当前分支实现和约定验证完成 |

阻塞原因与依赖写入 Blocked by；开工前核对依赖实现是否在当前分支可用。审核和合并以 MR 为准。

最小字段：Owner、Status、What to build、验收条件。Spec、Context、Blocked by 与 Handoff 按需补充。导航引用使用相对链接，代码入口由接手时重新发现。

“发布到本地 tracker”表示写文件；不创建远端 Issue。团队版技能的原有标签操作应改为写上述 Status。没有独立 triage-labels 配置，也不采用 wayfinder 的自动认领流程。

清楚的小修复可直接按请求执行，交付前补最小 ticket；纯探索可只留 journal，不伪造就绪任务。
