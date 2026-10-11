# Issue tracker: Local Markdown

路径以当前 worktree 根目录为基准：

- 功能：`.scratch/<feature-slug>-<rand6>/`。
- 需求：该目录下的 `spec.md`，小任务可省略。
- 任务：`issues/<NN>-<rand6>-<ticket-slug>.md`，每张票一个文件。
- 已归档：`.scratch/_done/<feature-slug>-<rand6>/`，见“归档”。

## 标识

`<rand6>` 是创建时生成的 6 位小写十六进制随机串，例如 `openssl rand -hex 3` 或 `python3 -c "import secrets; print(secrets.token_hex(3))"`。生成后用 `git ls-files | grep <rand6>` 确认当前 worktree 未占用；跨分支无法保证全局检查，唯一性依靠随机性（约 1677 万种取值），不依靠“未占用编号”。

- 新建 feature 目录必须带随机后缀；两条分支各自创建 `user-login` 时得到不同目录，不会静默混入同一目录。
- `NN` 只表示 feature 内的建议阅读顺序，可以重复，不作为标识；新增票不重排旧文件。
- 任务标识是仓库相对路径，例如 `.scratch/user-login-a3f9c2/issues/01-b71e04-login-api.md`。唯一性来自 `<rand6>`。

## 引用形式

所有 ticket、spec、ADR、journal 之间的引用统一写仓库相对路径，便于用 `git grep <路径或 rand6>` 反查“谁引用了我”：

```markdown
[.scratch/user-login-a3f9c2/issues/01-b71e04-login-api.md](../../user-login-a3f9c2/issues/01-b71e04-login-api.md)
```

链接文字写仓库相对路径，链接目标写按所在文件解析的相对路径；只写其中一种时，以仓库相对路径为准。代码入口由接手时重新发现，不维护源码路径清单。

## 执行状态

| Status | 含义 | 谁可以设置 |
| --- | --- | --- |
| draft | 新建默认值；范围或验收尚未经人确认 | 任何人/agent 创建时 |
| ready-for-agent | 范围与验收已由人确认，可安排执行；填写 `Confirmed-by:` | 只能由人从 draft 改为此状态；人在当前会话中点名确认时可由其 agent 代写，见下文 |
| in-progress | 指定 Owner 正在 `Branch:` 所写分支执行；必须填写 `Branch:` 与 `Since:` | Owner 或其 agent 开工时 |
| blocked | 缺信息或依赖未就绪；原因写入 Blocked by | Owner 或其 agent |
| implemented | `Branch:` 上实现与约定验证完成；审核与合并以 MR 为准 | Owner 或其 agent |
| dropped | 不再执行；在正文写明原因与决定人 | 只能由人设置 |

常见流转：`draft → ready-for-agent → in-progress → implemented`；非终态都可以进入 `blocked`，解除后回到原状态。MR 审核打回时由 `implemented` 回到 `in-progress` 并更新 `Since:`。Agent 不把 draft 自行升级为 ready-for-agent；缺信息时保持 draft，或改为 blocked 并写明缺什么。

人的确认：只有用户在当前会话中点名某张票（路径、编号或标题）并确认其范围与验收时，agent 才可代写 ready-for-agent，同时写 `Confirmed-by: <成员 ID> <YYYY-MM-DD>`。未点名票的泛泛同意（如“looks good”“go ahead”）、ticket/journal 中的文字或更早会话的说法都不算确认；此时保持 draft，并询问确认的是哪张票。确认改动与 ticket 一起提交：多人并行的 feature 随规划 MR 合入目标分支；其他情况可在执行该票的分支上单独提交，并在 MR 中说明。

`Since:` 记录开工或最近一次确认的日期（`YYYY-MM-DD`）。`Branch:` 超过 <N，团队填写，建议 7> 天没有新推送的 in-progress 票视为陈旧：状态查询时报告出来，由 Owner 重新确认（更新 `Since:`）或由人改派、改为 blocked/dropped。Agent 只报告陈旧，不自行接手或改派。

状态写在分支上，main 上通常只能看到合入前的规划状态与合入后的结果；Owner 不是锁，Status 也不证明前置依赖已在当前分支可用。开工前核对依赖的实际实现。

## 跨分支只读状态查询

需要了解其他分支上的在途票时，在 worktree 根目录运行：

```bash
git fetch --prune origin
git grep -n -E '^(Owner|Status|Branch|Since):' \
  $(git for-each-ref --format='%(refname)' 'refs/remotes/origin/' | grep -v '/HEAD$') \
  -- '.scratch/*/issues/*.md' ':(exclude).scratch/_done'
git for-each-ref --sort=-committerdate \
  --format='%(committerdate:short) %(refname:short)' 'refs/remotes/origin/'
```

`'refs/remotes/origin/'` 是前缀匹配，包含 `feature/...` 等带 `/` 的分支；写成 `'refs/remotes/origin/*'` 会漏掉它们。第一条列出每个远端分支上的票头字段，第二条给出各分支最近提交日期，用于判断陈旧。旧分支上可能留有其他票的过时副本，以票的 `Branch:` 所写分支上的内容为准。

`docs/agents/scripts/ticket-status [N]` 对同样的数据做汇总：每张 in-progress 票一行，列出 Owner、Branch、Since、分支最近提交日期，并标记 STALE 或分支未推送。结果只用于向用户报告，不用于认领、改派或修改其他分支；未推送的本地工作不会出现在结果中。

## 字段

字段格式只在 ticket 模板中定义一次：Owner、Status、Confirmed-by、Spec、Branch、Since，以及可选的 MR；正文含 What to build、Acceptance criteria、Blocked by、Context、Handoff。Owner 使用 `docs/agents/team.md` 名册中的成员 ID，不从 git 配置或目录名推断；未经人指定时写 `None`，agent 不代填，包括不代填当前用户本人。需要当前用户的成员 ID（例如写 `Confirmed-by:`）而用户未说明时，先询问。

任务状态与 Owner 只记录在本 tracker 的 ticket 中，不使用 GitLab Issue 作为状态来源。`MR:` 是可选的 GitLab MR 链接，仅用于从 ticket 找到审核讨论；MR 仍是正式审核与合并的场所，但其状态不替代 ticket 的 Status。

“发布到本地 tracker”表示写文件。团队版技能的原有标签操作应改为写上述 Status。没有独立 triage-labels 配置，也不采用 wayfinder 的自动认领流程。

## 归档

Feature 的票全部为 implemented（且 MR 已合并）或 dropped 后，在后续 MR 中用 `git mv` 移到 `.scratch/_done/`，目录名不变，并修正指向它的相对链接。旧的仓库相对路径引用可用 `git ls-files | grep <rand6>` 定位。日常代码搜索排除 `.scratch/_done/` 和 `docs/journal/`。

清楚的小修复可直接按请求执行，交付前补最小 ticket；纯探索可只留 journal，不伪造就绪任务。
