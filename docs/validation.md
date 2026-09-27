# 验证记录与能力边界

研究/审查日期：2026-09-25；公开整理日期：2026-09-26。

## 已执行

1. 读取固定版本和研究环境中真实 Matt skill 主文件、附属模板与调用配置。
2. 使用独立临时 Git 仓库检查原 checkout 和 linked worktree 的根定位、文件继承与隔离。
3. 用 `codex-cli 0.154.0-alpha.6.2` 的 `debug prompt-input` 检查四种 cwd：原 checkout 根/项目子目录、新 worktree 根/项目子目录。
4. 复现不同 ADR 文件拥有同一数字编号仍可合并、相反决策仍可干净合并、squash 后原 SHA 非主分支祖先但实现存在。

四种 Codex 输入探测均包含根 AGENTS 标记与仓库独有 sentinel skill 标记；均不包含 CONTEXT 正文标记。这里只证明输入发现，不证明模型随后读取了链接或执行了技能。

诊断通过允许的沙箱外命令运行，没有调用模型。它不能证明真实 workspace-write 会话允许写上层文档。Git fixture 也不能代替 Codex 的工具权限检查。

[机器可读的脱敏结果摘要](validation-results.json)只包含观察结果，不包含本机目录、原始提示输入或用户配置。临时 fixture 未作为本仓库交付物提供；以下为后续试点的复核步骤。

## 必须完成的试点

- 在四种 cwd 实际调用团队版本 skill，确认加载来源、根路径及 ticket/journal 写入权限。
- 混合 committed、staged、unstaged 和 untracked 改动，确认 review 覆盖任务范围且排除无关改动。
- A 保存并推送需求与部分实现，B 用全新会话接手；不依赖 A 的未提交文件。
- 两位成员并行不同 tickets，检查共享定义、相反 ADR、依赖尚在其他分支的情况。
- 中断未收尾会话，恢复时区分已持久化事实与无法确认的进展。
- Squash/rebase 后，仍可从任务、journal 和 MR 追踪需求与验证；不以旧 SHA 的祖先关系作为唯一依据。

## 未实施

可安装的 team-* 技能、自动日志 hooks、真实项目端到端执行、GitLab 权限与 MR 流程均未实施或验证。本仓库发布只交付设计、审查和参考模板。
