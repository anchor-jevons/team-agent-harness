# Project

<一句话说明项目解决什么问题。>
代码位于 `project-name/`，构建和测试在该目录运行。

## Paths

- 用 `git rev-parse --show-toplevel` 确定当前 worktree 根目录。
- `.scratch/`、`docs/`、`.agents/` 和 `CONTEXT-MAP.md` 路径均相对该根目录。
- Markdown 相对链接按所在文件解析；使用当前 worktree 的材料。

## Working context

- 开始开发、跨人接手或交付时，读取 `docs/agents/team.md` 的相关约定。
- 创建或更新任务时，读取 `docs/agents/issue-tracker.md`。
- 接手指定 ticket 时，读取该票、关联 spec（如有）、Context 与 Handoff；核对当前代码和依赖。
- 实现或 review 前，读取 `docs/development.md` 中适用的规范。
- 领域语义与架构决策相关工作，按 `docs/agents/domain.md` 查阅 map、相关术语和 ADR。
- 关键确认及时写入对应正文；有实质进展并准备暂停、交接或交付时使用已安装的 `team-record-session`。

采用前需替换项目路径并安装/验证团队技能；本模板不会自行安装技能或授予文件写权限。
