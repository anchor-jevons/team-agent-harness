# 入组检查

新成员首次在本仓库使用 agent 前逐项确认；结果有问题时先解决或告知团队，不在个人环境中绕过。

## 版本与入口

- [ ] Codex 版本不低于团队最低版本：<团队填写，例如 `codex --version` 的最低值>。
- [ ] 常用入口（CLI/桌面/IDE）能发现根 `AGENTS.md` 与 `.agents/skills/`。

## 个人配置

- [ ] 检查 `~/.codex/AGENTS.md` 与 `~/.codex/AGENTS.override.md`（或 `CODEX_HOME` 下同名文件），确认没有与团队规则冲突的指令。
- [ ] 本仓库内没有个人添加的 `AGENTS.override.md`。
- [ ] 也使用其他 agent 工具时，检查其个人全局指令（如 `~/.claude/CLAUDE.md`、`~/.config/opencode/AGENTS.md`、`~/.zcode/AGENTS.md`），没有与团队规则冲突的内容。
- [ ] 如开启了个人记忆（Claude、Codex、ZCode 等），它只在本机：与仓库规则冲突时以仓库规则为准并报告；团队需要的教训写进 journal 的 `Lessons`，经 `team-retro` 提案进入规则。
- [ ] 个人全局技能中没有与团队技能同名的版本；安装了原版 Matt skills 时，确认阶段入口使用的是 `team-*` 版本；个人技能（如通用 code-review）与仓库流程冲突时以仓库为准。

## 权限与身份

- [ ] 从仓库根和 `project-name/` 两种目录启动时，agent 都能写入根目录下的 `.scratch/` 与 `docs/journal/`（试写后用 `git status` 确认并删除试写文件），并能 `git commit`：Codex 的 workspace-write 沙箱默认把 `.git`、`.agents/` 设为只读，`.git` 按团队试点结论放开。
- [ ] 确认 agent 加载了仓库 `AGENTS.md`：Grok 只在项目被信任（`grok --trust`）后加载，`grok inspect` 显示 Project Instructions (0) 即未加载。
- [ ] 在 `docs/agents/team.md` 名册中登记成员 ID 与 GitLab 用户名。
- [ ] 拥有 GitLab 仓库推送与创建 MR 的权限。

## 熟悉约定

- [ ] 读过 `AGENTS.md`、`docs/agents/team.md`、`docs/agents/issue-tracker.md` 与 `docs/feature-map.md`。
- [ ] 运行过一次 tracker 中的跨分支状态查询。
- [ ] 请 agent 前先写一行开工假设；绿灯写明查了什么、没查什么。
