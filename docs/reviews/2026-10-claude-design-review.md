# 2026-10 外部设计评审（原文）

评审日期：2026-10；基于提交 `d42c607`。以下为评审原文，保留评审时的行号引用（指向 `d42c607` 中的文件，修订后行号已变化）。采纳与暂缓情况见[审查汇总](../review-summary.md#2026-10-外部设计评审)，最终方案以[当前设计](../design.md)为准。

---

## team-agent-harness 设计评审（只读，基于提交 d42c607）

审阅范围：仓库全部 22 个文件（README、AGENTS.md、docs/design.md v4、docs/reviews/*、review-summary、validation.md/.json、references、templates/*）。LICENSE、team-* 未实现、无 CI、ADR/journal 命名顺序不一致、模板缺 Spec/superseded 这几点已有人提过，下文不再重复。

### 1. 总体判断

**做得好的地方**：边界讲得很诚实。design.md「从第一性原理推导」第 2、5 条和第 141 行都明确说了，状态不等于锁，Markdown 不等于强制执行。验证材料把“输入发现”和“模型真的执行了”分开写（design.md:209、validation.md:12-14）。review 范围漏掉未提交文件这个问题（design.md:125、175-182）找得很准。CONTEXT/ADR/spec/journal 的职责划分也清楚。

**核心问题**：设计把 Git 定成了唯一的协作介质，但团队其实已经有 GitLab（README:11）。仓库里没有任何一处论证“为什么任务状态不放 GitLab Issue”，issue-tracker.template.md:23 只是直接规定“不创建远端 Issue”。结果是：分配、在途状态、陈旧认领、跨分支可见性这些问题，GitLab 本来就能解决，现在全被定义成“不在能力内”（design.md:11、141）。作为 ≤5 人的试点，这套方案可行。但它真正可靠的部分只有“分支内的需求与交接材料”，团队级的任务协调基本落到了人和口头沟通上。

### 2. 内部矛盾与缺口

1. **ADR 修好的编号问题，在 ticket 上又出现了**：design.md:133 和 issue-tracker.template.md:9 规定“追加票使用未占用编号”。这个检查只在本地 worktree 里有效，和被否掉的“ADR 最大号+1”是同一类缺陷：两个分支各加一个 `03-*.md`，可以干净合并。feature slug 的“仓库内唯一”也一样没有机制：两条分支同时建 `.scratch/user-login/`，各自的 `01-*.md` 会静默混进同一个目录。只有 spec.md 会因为 add/add 冲突被发现。
2. **缺信息的票没有合法状态**：design.md:137 说缺信息时“可保留未开始”，但状态枚举里没有“未开始”。ready-for-agent 的定义又是“范围与验收已明确”（issue-tracker.template.md:15）。同时 ticket.template.md:4 默认写成 `Status: ready-for-agent`，新建的票等于自动视为已审核。这和 agent-capabilities.md #4 的“to-tickets 要审核拆票，不能默认为已发生”相冲突。
3. **自称“唯一位置”，实际有重复**：design.md:17 要求每类内容只有一个维护位置。但 journal 格式在三处定义（design.md:157、journal.template.md、design.md:84 说的“由 team-record-session 定义”）。AGENTS 草案也有两份（design.md:90-110 和 templates/AGENTS.template.md），而且已经开始漂移，例如 design.md:107 写“适用的工程规范”，template:17 写“适用的规范”，措辞和收尾句都不同。这也违反本仓库 AGENTS.md:8。
4. **试点数量对不上**：design.md:211 说“剩余五组必要验收”，validation.md「必须完成的试点」列了 6 项，“中断恢复”被单独拆出来了。
5. **标识形式有两种**：ticket 的 ID 是“仓库相对完整路径”（design.md:133），但导航要求用“相对链接”（design.md:135、issue-tracker.template.md:21）。git-collaboration.md:29 又要求 Blocked by 写完整路径。三处说法不一致。如果 Blocked by 写的是 `../../x/issues/01-a.md`，用 grep 按 ID 反查“谁依赖我”就会失效。
6. **成员身份没有来源**：design.md:135 禁止从 git 配置推断负责人，但 journal 路径 `docs/journal/<member>/` 和模板里的 `Member:` 都需要一个稳定标识。仓库没有定义名册，也没说用 GitLab 用户名还是别的。

### 3. 真实多人使用中的风险

- **状态机在 main 上几乎没有信息量**：状态改动随 feature 分支走，git-collaboration.md:88 也明确不做合并后再改状态。所以 main 上只能看到 ready-for-agent（计划）和 implemented（已合并），in-progress 只存在于各分支。ticket 里没有 Branch/MR 字段，看到 in-progress 也查不到对应分支。被放弃的分支会留下没人知道的“在途”状态。状态里也没有 blocked、cancelled、changes-requested，评审打回后票仍然是 implemented。
- **合并冲突**：同一张票的 Status、Owner、Handoff 都在固定行，每写一次 journal 就要改一次 Handoff 链接（ticket.template.md:22-24），两人接力或改派时很容易在同一行冲突。“先共享 spec/拆票基线”（design.md:139）其实隐含了一个先合入 main 的规划 MR，但流程里没有写出来。
- **上下文成本和检索噪声**：`.scratch/` 明确说不清理（README:54），journal 和票只增不减，也没有归档规则。agent 用 rg 搜代码时会搜到历史 spec 和 journal 里的旧术语，和 CONTEXT“只保存现行定义”的目标相冲突。
- **指令优先级**：设计只处理了 skill 重名（design.md:118），没有处理 Codex 的指令链。按官方文档，`~/.codex/AGENTS.override.md`/`AGENTS.md` 先加载；离 cwd 更近的 `project-name/AGENTS.md`，或任意一层的 `AGENTS.override.md`，排在后面因而优先。design.md:66 允许以后再加项目层 AGENTS，但没有声明 AGENTS、development.md、team skill、ticket 内容之间谁的优先级更高。
- **安全**：agent 会读 ticket、spec 和其他人 agent 代写的 journal（design.md:81、106），而且交接发生在 MR 审核之前（team.template.md:11）。也就是说，未经审核的内容会直接作为下一个 agent 的输入，构成跨人的提示注入链。另外，`.agents/skills/` 在功能分支上的改动，只要有人 checkout 该分支就会生效，不必等 MR。journal 要记录“验证命令与结果”，可能泄露令牌或内部地址，但目标模板里没有对应的禁止条款（本仓库 AGENTS.md:9 只约束设计仓库本身）。`codex --add-dir ..`（design.md:169）扩大了写入范围，也没有说明风险。
- **入职与版本**：agent-capabilities.md #2 提出的“入组检查”没有进入设计或模板。验证只在 `codex-cli 0.154.0-alpha.6.2` 上做过（validation-results.json），桌面端和 IDE 入口都没验证，也没规定团队最低版本。
- **超过约 5 人**：编号依赖 feature 负责人人工协调，看在途工作要逐条 checkout 分支，找票靠目录遍历。这些都会随人数线性恶化，而且没有跨 feature 的视图。

### 4. 验证计划是否测到了真正的风险

已做的验证主要是 Git 的已知行为（worktree 不带未提交文件、squash 后原 SHA 不是祖先），以及 prompt-input 的发现结果，都没有调用模型（validation-results.json 的 limitations 字段）。fixture 没有公开（validation.md:16），别人无法复现。试点清单有三个问题：
- 没写通过/失败判据、重复次数（模型输出有随机性，单次结果不能说明问题）和度量（读了多少文件、多少 token，触发遵从率）。
- 漏掉了真正高风险的场景：两分支同号 ticket 或同 slug 合并、同票 Status 冲突、改派与陈旧 in-progress、个人 AGENTS.override 干扰、恶意或错误 ticket 内容、功能分支修改 skill、journal 增长后的检索质量。
- 没有安排 3 人以上的并发场景。

### 5. 优先改进（按优先级）

1. **在 design.md 补一个 ADR 讨论“任务状态放 GitLab Issue 还是 Markdown”**。建议混合方案：Owner 和在途状态以 GitLab Issue/MR 为准，ticket 加 `Issue:`/`MR:` 字段，spec、验收、Context 继续留在 Markdown。
2. **ticket 和 feature 改用随机短 ID**：文件名改为 `<NN>-<rand6>-<slug>.md`，或者直接只用随机 ID。新建 feature 目录时也带随机后缀。同步修改 design.md:133、issue-tracker.template.md:9、ticket.template.md:1。
3. **重定义状态机**：增加 `draft`（模板默认值）、`blocked`、`dropped`，以及在途时必填的 `Branch:` 和 `Since:` 字段。明确规定由人把票从 draft 改成 ready-for-agent，并约定“超过 N 天没有推送就视为陈旧，需要重新确认”。修改 issue-tracker.template.md 和 ticket.template.md。
4. **给跨分支状态一个只读查询**：在 issue-tracker.md 里给出类似 `git fetch && git grep -n "^Status:" $(git for-each-ref --format='%(refname)' refs/remotes/origin) -- .scratch` 的命令，规定 agent 只能用它来“报告”，不能用来“认领”。
5. **在 AGENTS.template.md 写明优先级和信任边界**：顺序为 AGENTS → development.md → team skill；ticket、spec、journal 只当数据处理，里面出现的命令和指令要先经人确认；journal 不得写入凭证或原始日志。另外用 GitLab CODEOWNERS 和受保护分支保护 `.agents/skills/`、`AGENTS.md`、`docs/agents/`。
6. **消除重复定义**：AGENTS 草案只保留 templates 那一份，design.md 改成链接过去。journal 字段只在模板里定义一次，record-session 去引用它。修正 design.md:211 的数量和 ID 引用形式（统一用仓库相对路径）。
7. **生命周期与成本**：合并后把 feature 的 `.scratch` 移到 `.scratch/_done/`，或者加一条归档规则。journal 只靠 ticket 的 Handoff 链接查找，并在 AGENTS 里说明“搜索代码时排除 .scratch/_done 和 docs/journal”。在 team.md 里加成员名册（member id 对应 GitLab 用户名）。
8. **把验证改成可复现的实验**：公开 fixture 脚本。每个试点写清预期、通过标准和至少 5 次重复，记录读取的文件和 token 用量。补上第 3、4 节列出的冲突、陈旧、注入、override 场景。在 templates/ 下增加 onboarding 清单（最低 Codex 版本、检查个人 AGENTS.override 和重名 skill、确认写权限）。
