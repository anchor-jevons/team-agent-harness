# 入组检查

新成员首次在本仓库使用 agent 前逐项确认；结果有问题时先解决或告知团队，不在个人环境中绕过。

## 版本与入口

- [ ] Codex 版本不低于团队最低版本：<团队填写，例如 `codex --version` 的最低值>。
- [ ] 常用入口（CLI/桌面/IDE）已按团队试点结论确认可以发现根 `AGENTS.md` 与 `.agents/skills/`。

## 个人配置

- [ ] 检查 `~/.codex/AGENTS.md` 与 `~/.codex/AGENTS.override.md`（或 `CODEX_HOME` 下同名文件），确认没有与团队规则冲突的指令。
- [ ] 本仓库内没有个人添加的 `AGENTS.override.md`。
- [ ] 个人全局技能中没有与团队技能同名的版本；安装了原版 Matt skills 时，确认阶段入口使用的是 `team-*` 版本。

## 权限与身份

- [ ] 从仓库根和 `project-name/` 两种目录启动时，agent 都能写入根目录下的 `.scratch/` 与 `docs/journal/`（试写后用 `git status` 确认并删除试写文件）。
- [ ] 在 `docs/agents/team.md` 名册中登记成员 ID 与 GitLab 用户名。
- [ ] 拥有 GitLab 仓库推送与创建 MR 的权限。

## 熟悉约定

- [ ] 读过 `AGENTS.md`、`docs/agents/team.md` 与 `docs/agents/issue-tracker.md`。
- [ ] 运行过一次 tracker 中的跨分支只读状态查询，了解当前在途工作。
