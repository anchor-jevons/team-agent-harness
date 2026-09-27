# Git、worktree 与团队追踪审查

日期：2026-09-25。范围：最新需求方案及研究环境中的 Matt 技能；只审查协作一致性，不修改真实项目或技能。

## 判断

目录方案可用。决定可靠性的主要因素不是再拆目录，而是明确“这些文件描述当前分支的哪一份事实”。Git 能保存、交换和合并版本，不能提供全团队实时任务锁，也不会自动发现不同文件之间互相矛盾的决策。

维持：Git 根的 AGENTS、skills、`.scratch`、规范、ADR 和 journal；根 map 指向项目目录的领域词汇表。无需新增数据库、状态服务或集中任务汇总表。

三个不同的权威范围：

- 当前 worktree：agent 当前可执行、可验证的代码和任务快照。
- 目标分支：已经合并的团队基线，未必是每个工作分支的最新内容。
- GitLab MR：审核讨论、审批和合并结果；本地状态字段不替代这些事实。

## Findings 与最小修正

### P1：不能把本地 ticket 状态当成团队任务锁或依赖完成证明

触发：两个人从相同基线开 worktree；A 更新 Owner/Status，B 的文件不会变化。即使 A 已实现并推送，B 仍可能缺少对应代码。

现有设计已经写明人工分工和依赖核对，应保留为硬约定。不能在后续引入 Matt wayfinder 后又允许 agent 扫描文件自动领取。

最小修正：

- 用户指定 ticket 和负责人；任务路径不明确时不自行挑选共享队列。
- 并行拆票的分工在开工前共享；同一 ticket 的负责人变更需明确交接。
- `Blocked by` 使用完整 ticket 路径。开工检查前置实现是否存在于当前代码，并核对接口/验收条件；仅看 `implemented` 或提交祖先关系都不充分。
- 前置尚未合入但必须提前开发时，明确采用哪条依赖分支/提交；否则等待共享基线。无需另建依赖数据库。

### P1：文件无冲突不代表 spec、ADR、CONTEXT 和代码兼容

触发：A 在 `0001-sync.md` 决定同步调用，B 在 `0001-events.md` 决定同一范围改用事件。Git 可以成功合并两个不同文件。

最小修正：MR review 在固定目标提交与待合入版本上，对本次触及的需求、领域定义和决策做一次一致性检查。共享接口或语义变化须标明受影响任务；解决代码、spec 和 ADR 的矛盾后再合并。

不要求每次重读全部历史。以 ticket 的 Context 引用和本次 diff 为入口，再检查目标分支中相关文档的新增变化。

### P1：原版 local tracker 的“claim/resolved”约定与团队执行状态不兼容

证据：`setup-matt-pocock-skills/issue-tracker-local.md` 包含 wayfinder 的 `claimed/resolved`、本地 save 即 claim、扫描 open/unclaimed frontier；团队方案采用 `ready-for-agent/in-progress/implemented`。

最小修正：精选技能第一版排除 wayfinder/自动领票；实际生成的 `docs/agents/issue-tracker.md` 删去不适用的 wayfinding 段，明确团队状态语义。不要仅在 `team.md` 追加一段相反指令，同时保留原模板冲突文本。

### P2：ADR 并行编号冲突不会必然触发 Git 冲突

证据：原版 `domain-modeling/ADR-FORMAT.md` 要求扫描最大序号加一。两个分支可以创建 `0001-a.md` 和 `0001-b.md`，文件合并成功但“ADR-0001”引用失去唯一性。

最小修正：团队 ADR 文件名使用日期、随机短标识和主题，例如 `20260925-8f31a4c2-session-storage.md`；创建时检查路径未占用，引用使用完整相对路径。日期和标识不承担时间线或审批语义。

必须同步适配 `ADR-FORMAT.md` 的编号规则，以及模板中的 `superseded by ADR-NNNN` 引用方式。只修改外部规范会给 agent 两套相反规则。

已合并 ADR 的实质决策变更使用新 ADR，旧 ADR 指向新记录；草稿可以直接修订。`accepted` 只在所属已接受基线中解释，分支内该词并不代表远端 MR 已获批准。

### P2：journal 的分支名和原始提交哈希不能单独保证长期追溯

触发：分支删除、rebase 或 squash 后，原始提交可能不在主分支历史中；旧验证结果也不一定覆盖新代码。

最小修正：

- journal 以文件自身、任务相对路径和准确验证说明作为基本证据；MR 创建后可补稳定 MR 链接。
- 存在真实提交时记录完整 SHA；验证发生在未提交工作区时明确写“包含未提交改动”，不能编造一个将来的提交。
- 不要求 journal 引用包含自己的提交，避免自引用哈希问题。
- 变基或解决冲突若改变实现，重新运行受影响验证；旧日志保留历史事实，新记录说明变化。
- `implemented` 只表示当前分支实现与约定验证完成；审核和合并查看 MR。

### P2：新增 worktree 只继承选中提交，运行中的会话也不是实时规则同步器

触发：harness/spec/journal 尚未提交，或者新 worktree 来自较旧提交，接手者无法看到最新材料。

最小修正：正式开始使用前先将 harness 提交到共享基线；交接明确 ticket 路径和可获取的分支/MR。接手方先同步对应版本，再开始新会话或明确重新载入变更规则。

普通 `git worktree add` 不复制未提交文件；某些宿主的迁移功能需另行验证，不能作为通用承诺。只有一个文件路径，没有可获取的版本，不算完成跨人交接。

### P2：根目录定位正确仍不等于子目录会话能写入 harness

最小修正：路径从 `git rev-parse --show-toplevel` 解析到当前 worktree，Markdown 链接从所在文件解析。启动时的写范围必须覆盖该 worktree 根。

不要使用固定绝对路径、原 checkout 路径或 Git common dir 作为文档根。实际 Codex 的技能发现、父目录写权限和同名技能选择属于宿主验收，不用 Git fixture 结果代替。

## 最小协作闭环

1. spec/tickets 由人明确分工；多人同一 feature 时先共享一份需求基线，小任务可随实现一起提交。
2. agent 在当前 worktree 读取指定 ticket、所需领域/ADR、最近 Handoff，检查当前代码与依赖。
3. 分支保存实现、对应 ticket 更新、短 journal；需要交接时让这些提交可被对方获取。
4. MR review 同时检查实现、相关需求与决策一致性、实际验证范围。
5. 合并后由正常 Git 同步传播；不增加“合并后再改票为 merged”的额外提交。

每人每工作阶段一个独立 journal 文件，避免所有人追加同一日记或任务总表。Handoff 是当前 ticket 的接手入口，不是全仓库日志索引。

## 已执行的隔离 Git 验证

在临时仓库运行，未操作任何真实仓库或远端：

- 两个分支各创建 `0001-*.md`，内容彼此矛盾；merge 成功且两个同号 ADR 都保留。
- 从 linked worktree 的 `project/` 启动，`--show-toplevel` 返回该 worktree 根；`.git` 是指针文件。
- 原 checkout 未提交的文件不会进入新 worktree。
- 一个 worktree 改 Owner/Status 不会修改另一个 checkout 的 ticket。
- squash 后实现文件存在，但原 feature 提交不再是主分支提交的祖先。

隔离验证结果已整理到[公开验证记录](../validation.md)，本机临时路径不在公开版本中保留。

## 试点验收

- 原 checkout 根/项目目录、新 worktree 根/项目目录四种启动位置，均读写自身 worktree 的文件。
- A 推送暂停记录，B 新会话从明确版本接手，不依赖 A 的本地未提交内容。
- 两人不同 ticket 并行，文件互不覆盖；同一 ticket 不自动竞争领取。
- 制造两个不同 ADR 文件的相反决策，review 能指出语义冲突。
- squash 合并后，仍能从 ticket、journal 和 MR 找到需求、验证说明与最终实现；不要求旧 SHA 为主分支祖先。

验证限界：已核实原版模板与上述 Git 行为；未运行真实 Codex 模型会话，未验证 GitLab 审批配置、技能发现优先级或父目录写权限。本报告不承诺 Markdown 指令能提供强制执行或实时并发控制。
