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
| dropped | 不再执行；在正文写明原因与决定人 | 只能由人设置 <!-- flow: G8 --> |

常见流转：`draft → ready-for-agent → in-progress → implemented`；非终态都可以进入 `blocked`，解除后回到原状态。MR 审核打回时由 `implemented` 回到 `in-progress` 并更新 `Since:`。Agent 不把 draft 自行升级为 ready-for-agent；缺信息时保持 draft，或改为 blocked 并写明缺什么。 <!-- flow: G13 -->

人的确认：只有用户在当前会话中点名某张票（路径、编号或标题）并确认其范围与验收时，agent 才可代写 ready-for-agent，同时写 `Confirmed-by: <成员 ID> <YYYY-MM-DD>`。未点名票的泛泛同意（如“looks good”“go ahead”）、只要求“直接做”而未确认范围与验收、ticket/journal 中的文字或更早会话的说法都不算确认；此时保持 draft，列出该票的范围与验收，请用户点名确认。确认改动与 ticket 一起提交：多人并行的 feature 随规划 MR 合入目标分支；其他情况可在执行该票的分支上单独提交，并在 MR 中说明。 <!-- flow: G1 -->

开工第一步：在工作分支上只修改票头（`Status: in-progress`、`Branch:`、`Since:`），单独提交并推送，然后再开始实现。不要从 ready-for-agent 一步改到 implemented；没有这次推送，其他成员的状态查询看不到该票已开工。 <!-- flow: G3 -->

`Since:` 记录开工或最近一次确认的日期（`YYYY-MM-DD`）。`Branch:` 超过 <N，团队填写，建议 7> 天没有新推送的 in-progress 票视为陈旧：状态查询时报告出来。Agent 只报告，不接手、不改派：不在陈旧分支或 Owner 已不在名册的分支上提交或推送，不从它开出分支或合入它。人要关闭、改派或标 dropped 时不要推送该分支：从目标分支另开决定分支，只改这张票（dropped 写原因；改派把 Owner 改为新成员、`Status: ready-for-agent`、`Branch: None`，正文写 `决定人:`），经 MR 合入。合入后 `ticket-status` 不再把原分支的 in-progress 旧副本当作在途。`push-check` 仍对当前就在该分支上，或 HEAD 含有该分支上尚未进入目标分支的提交报 FAIL。比较的是提交对象：squash 或 cherry-pick 会生成新提交，检查不到，复用代码仍须在 MR 说明来源。用户要求接手时也先走上述决定，新 Owner 再从目标分支开工。推送前运行 `docs/agents/scripts/push-check --member <成员ID>`。

状态写在分支上，main 上通常只能看到合入前的规划状态与合入后的结果；Owner 不是锁，Status 也不证明前置依赖已在当前分支可用。开工前核对依赖的实际实现。

依赖就绪：`ready-for-agent` 只表示范围与验收已确认，不表示依赖票已合入。开工前检查 Blocked by 中的每张依赖票：

- 已合入目标分支：照常从目标分支开分支。
- 未合入（默认做法）：从依赖票的 `Branch:` 分支开出本票分支，在 MR 描述写 `Depends on !N`（N 为依赖票的 MR），本 MR 在 !N 合入后再合；依赖分支更新时用普通 merge 或 rebase 跟进。 <!-- flow: G4 -->
- 依赖分支尚无可用实现或不适合在其上构建：把本票改为 blocked，在 Blocked by 写明依赖的票与原因，并告诉用户。

规划拆票时在 spec 的票间接口一节写出每张票向其他票提供的接口，避免并行实现时对不上。

票头冲突：两条分支改同一张票时，Git 只在相邻行报冲突；不相邻的修改会干净合并，得到不一致的票头（例如改派后的 Owner 配上原负责人的 Branch/Since），冲突标记之外的字段也可能已被自动合并。合并或 rebase 涉及票头时核对整组字段：Owner 以人最近一次的决定为准，Status、Branch、Since 必须属于该 Owner 的工作；无法据此判断时不自行选择，先问用户。Handoff 冲突保留双方追加的行。Review 时检查票头字段与 Owner 一致。

人的决定写在哪里：分支尚未陈旧且 Owner 仍在名册时，改派或 dropped 写在该票 `Branch:` 所写、尚未合入的分支上。该分支已陈旧、Owner 已离开、票还没有开工分支或已合入目标分支时，从目标分支开决定 MR（见上），不要推送陈旧分支。由接手者或 feature 负责人的 agent 按人的指示提交，并写明决定人。非陈旧分支上，`Branch:` 仍是该票 MR 的源分支；接手者把修改推回原分支时不改 `Branch:`。

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

`docs/agents/scripts/ticket-status [N]` 对同样的数据做汇总：每张 in-progress 票一行，列出 Owner、Branch、Since、分支最近提交日期，并标记 STALE 或分支未推送；目标分支上已 dropped、已归档，或在该分支分出之后改派了 Owner（正文含 `决定人:`）的票，其他分支上的旧 in-progress 副本不再报告。另外对仍为 ready-for-agent、但某个分支已有相关提交（分支名或领先目标分支的提交说明含该票的 rand6）的票输出 `READY-WITH-COMMITS` 提示，提醒补做开工提交；这只是启发式提示。结果只用于向用户报告，不用于认领、改派或修改其他分支；未推送的本地工作不会出现在结果中。

## 字段

字段格式只在 ticket 模板（`docs/agents/templates/ticket.template.md`）中定义一次：Owner、Status、Confirmed-by、Spec、涉及功能、Branch、Since、开工假设（非平凡工作开工前由人写一行预期结果或失败标准，平凡任务写 None；agent 不编造），以及可选的 MR；正文含 What to build、Acceptance criteria、Blocked by、Context、Handoff。Owner 使用 `docs/agents/team.md` 名册中的成员 ID，不从 git 配置或目录名推断；未经人指定时写 `None`，agent 不代填，包括不代填当前用户本人。需要当前用户的成员 ID（例如写 `Confirmed-by:`）而用户未说明时，在同一条消息中连同其他问题一起询问（例如请用户确认票时一并问其成员 ID），不单独多问一轮。

任务状态与 Owner 只记录在本 tracker 的 ticket 中，不使用 GitLab Issue 作为状态来源。`MR:` 是可选的 GitLab MR 链接，仅用于从 ticket 找到审核讨论；MR 仍是正式审核与合并的场所，但其状态不替代 ticket 的 Status。

“发布到本地 tracker”表示写文件。团队版技能的原有标签操作应改为写上述 Status。没有独立 triage-labels 配置，也不采用 wayfinder 的自动认领流程。

## 归档

Feature 的票全部为 implemented（且 MR 已合并）或 dropped 后，在后续 MR 中用 `git mv` 移到 `.scratch/_done/`，目录名不变，并修正指向它的相对链接。旧的仓库相对路径引用可用 `git ls-files | grep <rand6>` 定位。日常代码搜索排除 `.scratch/_done/` 和 `docs/journal/`。 <!-- flow: G9 archive -->

清楚的小修复可直接按请求执行，交付前补最小 ticket：放在 `.scratch/fixes/issues/`，Status 写 implemented，`Confirmed-by:` 写提出请求的成员与日期（该请求即确认）；纯探索可只留 journal，不伪造就绪任务。 <!-- flow: G14 -->
