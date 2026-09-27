# Team Harness v4：目录、协作契约与三方审查结论

设计审查：2026-09-25；公开整理：2026-09-26。状态：审查后的设计建议，尚未向实际项目安装团队技能或启用自动化。依据：需求讨论、三个独立 subagent 的报告、Matt 固定版本技能原文、研究时 Codex 官方文档及隔离探测。

## 结论与范围

目录方案适合试点；原版 Matt skills 直接复制后只增加 AGENTS.md，不足以实现此前承诺的团队行为。落地前需要有限且可追踪的技能适配，尤其是 review 范围、路径、状态语义和技能版本选择。

目标：团队共享规则和流程；开发与跟踪指定任务；每位成员留下可获取的 AI 开发摘要；方便跨人接手和 MR review。环境：公司内部 GitLab 托管代码与 MR；一仓库、一项目子目录；成员可从仓库根或项目目录启动 Codex，支持多个 worktree。

第一版以 Git + Markdown + Matt 方法技能为基础，借用 Trellis 的按任务读取上下文、个人工作日志和知识回写。提供分支快照与阶段记录；实时抢票、完整聊天审计、崩溃自动留痕不在这套轻量机制的能力内。

## 从第一性原理推导

1. Agent 当下可以核对的是当前会话、当前 worktree 文件和实际运行结果；其他成员的本地修改不可见。
2. 团队同步的单位是可获取的版本。文件路径、Owner 或 Status 单独存在，都不能替代版本、锁或审批。
3. 规则、任务、领域定义、决策和工作记录的变化频率不同，需要各自唯一的维护位置。
4. 每次任务应能从一个明确入口找到必要资料，而不是读取整个仓库的历史。
5. 自然语言流程能引导 agent；权限、Git 隔离、实际验证和人工 MR review 承担可检查的边界。

## 最终推荐目录

```text
repo-name/                              # 当前 checkout / worktree 根
├── AGENTS.md                           # 短入口、触发条件与根路径约定
├── CONTEXT-MAP.md                       # 按需；指向项目领域词汇表
├── .agents/
│   └── skills/
│       ├── README.md                   # 上游 SHA、名称映射、适配清单；维护时读
│       ├── team-grill-with-docs/
│       ├── team-to-spec/
│       ├── team-to-tickets/
│       ├── team-implement/
│       ├── team-code-review/
│       ├── team-record-session/        # 新增能力
│       └── …                           # team-grilling/domain-modeling/tdd 等完整依赖
├── .scratch/                           # 纳入 Git 的长期任务材料
│   └── <feature-slug>/
│       ├── spec.md                     # 按需；需求、关键问答、未决项
│       └── issues/
│           └── <NN>-<ticket>.md        # 一张票一个文件；小任务可只保留它
├── docs/
│   ├── development.md                  # 工程流程、原则、编码与验证规范
│   ├── agents/
│   │   ├── team.md                     # 仅跨人协作与交接约定
│   │   ├── issue-tracker.md            # 路径、任务格式、执行状态唯一来源
│   │   └── domain.md                   # 领域文档/ADR 的发现与更新规则
│   ├── adr/                            # 按需；重要架构取舍
│   │   └── <date>-<unique-id>-<topic>.md
│   └── journal/                        # 按需；每人每工作阶段一份记录
│       └── <member>/
│           └── <date>-<topic>-<unique-id>.md
└── project-name/                        # 成员常用启动目录
    ├── CONTEXT.md                      # 按需；当前有效的领域术语
    ├── src/
    ├── tests/
    └── …
```

这里没有第二份根 CONTEXT.md。单条 map 是沿用 Matt 发现机制的路径桥梁，不表示项目已经存在多个领域。尚无术语时，团队初始化规则明确首次同时创建 map 和项目层词汇表；已有 map 的目标必须存在。无需预建空领域目录。

`team-*` 是本次 review 后的新增建议：采用唯一团队名称，避免与成员全局安装的原版 Matt 同名。完整技能目录、元数据和内部依赖引用一起适配；不能只改文件夹名。方法正文尽量保持原版，修改范围记录在 README。方法技能保留可隐式调用，阶段入口保留显式调用，不能统一套用一种调用策略。现有个人技能不被覆盖。

当前不增加独立 triage-labels.md：团队版统一在 issue-tracker.md 定义状态，并明确移除 to-spec/to-tickets/local-template 对独立 triage vocabulary 文件的依赖；原有标签操作改为写本地 ticket 的 Status，spec 不伪装成可执行 ticket。这是要实施的适配，不是声称原版已经兼容。第一版不选入 triage、wayfinder 或 beta 调度技能。

已有 CONTRIBUTING.md 或工程规范时直接复用，避免再写重复 development.md。单项目不强制增加 project-name/AGENTS.md。

## 文件职责与维护责任

| 内容 | 唯一位置 | 主维护责任 |
| --- | --- | --- |
| Agent 的读取触发与路径基准 | AGENTS.md | Harness 维护者，团队审查 |
| 工程流程、设计原则、编码/测试/review 标准 | docs/development.md 或既有规范 | 项目维护者 |
| 多人分工、版本交接、共享规则迭代 | docs/agents/team.md | 团队共同维护 |
| Ticket 位置、状态和元数据 | docs/agents/issue-tracker.md | Harness 维护者 |
| 领域文档定位、更新及 ADR 约定 | docs/agents/domain.md | 领域维护者 |
| 需求与关键澄清 | feature/spec.md | Feature 负责人 |
| 工作切片、验收与接手入口 | ticket 文件 | 指定执行负责人 |
| 当前术语定义 | project-name/CONTEXT.md | 相关成员提出，领域 reviewer 审查 |
| 重要决策及理由 | docs/adr/ | 提出人与有权确认者 |
| 阶段事实与下一步 | docs/journal/member/ | 工作成员，agent 代写 |
| 正式 review、批准、合并结果 | GitLab MR | 团队现有审查流程 |

team.md 不重复状态表、日志模板或编码规范。记录格式由 team-record-session 定义。规则/技能版本变化通过 MR 形成新基线；单次 agent 偏好不能直接成为全团队长期约束。

## AGENTS.md 的建议入口

以下是供目标项目采用的草案，引用文档与团队技能仍需实际落地：

```markdown
# Project

<一句话说明项目解决什么问题。>
代码位于 project-name/；构建和测试在该目录运行。

## Paths

- 用 git rev-parse --show-toplevel 确定当前 worktree 根目录。
- Harness 中 .scratch/、docs/、.agents/ 和 CONTEXT-MAP.md 路径均相对该根。
- Markdown 相对链接按所在文件解析；使用当前 worktree 的材料。

## Working context

- 开始开发、跨人接手或交付时，读取 docs/agents/team.md 的相关约定。
- 创建或更新任务时，读取 docs/agents/issue-tracker.md。
- 接手指定 ticket 时，读取该票、关联 spec（如有）、Context 与 Handoff；核对当前代码和依赖。
- 实现或 review 前，读取 docs/development.md 中适用的工程规范。
- 领域语义与架构决策相关工作，按 docs/agents/domain.md 查阅 map、相关术语和 ADR。
- 关键确认及时写入对应正文；有实质进展并准备暂停、交接或交付时使用 team-record-session。
```

不在入口粘贴全套 Matt 流程、历史日志或代码目录清单。项目有真实特殊命令、约束时再补充。根路径说明约束实际读写，不授予额外文件系统权限。

## 必须进入团队版本的兼容修正

| 问题 | 最小修正 |
| --- | --- |
| Repo 与个人同名 skill 可能同时出现 | 团队选用技能与依赖统一 team- 名称；内部引用指向仓库版本；验收实际来源 |
| Matt 文本使用特定宿主 Skill tool / slash 调用 | 改成宿主支持的技能加载指令；Codex 用户显式阶段入口使用 skill mention/选择器 |
| 从项目子目录启动导致相对路径错层 | 文件读写先解析当前 worktree 根；构建命令明确项目 workdir |
| 原版 setup 倾向单项目根 CONTEXT | 团队初始化/首次建模固定 root map → project-name/CONTEXT.md；不直接运行未适配 setup 重建布局 |
| 原模板含 triage 引用及 wayfinder claim/resolved | 团队 tracker 移除不使用段；to-spec/to-tickets 读取同一状态定义；由人指定工作 |
| 原版 ADR 顺序号跨分支重复 | 修改 ADR-FORMAT.md，使用日期 + 唯一标识 + 主题；引用完整路径；替代关系同样改为链接 |
| 原版 to-spec/to-tickets 避免具体代码路径 | 保持需求正文描述行为；独立 Context/Handoff 允许稳定文档链接；不强制维护源码路径清单 |
| 原 implement 先 review 后 commit，但 review 只看 base...HEAD | 团队 review 明确 branch 与 working-tree 两种范围，覆盖本轮 tracked、staged、unstaged 和 untracked 新文件 |
| 阶段技能关闭隐式调用 | 保留用户阶段入口；不能自动从 grill 推进到实现/发布；新记录技能明确允许按收尾触发使用 |
| 原 handoff 写 OS 临时目录 | team-record-session 保存到当前 worktree journal；允许无 ticket 的探索记录 |

这是少量可定位的源文本/模板修改，但确实需要维护。仅在 team.md 写相反要求、同时保留原技能冲突段落，不算完成适配。保留上游来源与相应许可证材料。

## 任务与进度语义

Ticket 的完整仓库相对路径是标识，例如 `.scratch/user-login/issues/01-login-api.md`。Feature slug 在仓库内唯一；NN 只在 feature 内唯一。初始拆票由 feature 负责人协调；追加票使用未占用编号，不重排既有引用。

最小正文：Owner、Status、What to build、验收条件；按需补 Spec、Blocked by、Context 和 Handoff。跨文件导航优先用标准 Markdown 相对链接。不能从 git 配置或目录名猜测真实任务负责人。

执行状态：`ready-for-agent → in-progress → implemented`。遇到缺信息可保留未开始或进行中状态并写明确阻塞原因。`implemented` 只表示所记录分支实现及约定验证完成；审核/合并结果查看 MR。状态词也不证明前置依赖已经在当前分支可用。

同一个 feature 多人并行时，先共享 spec/拆票基线，再分别修改各自 ticket。简单且清楚的小修复可以按直接请求开工，交付前补最小 ticket；不强制为它制造独立 spec 或 grill 流程。只做探索时 journal 可以引用主题和已有材料，不虚构就绪任务。

Owner 是团队分工记录，不是实时锁。Agent 执行用户指定的任务，不从 Git 文件扫描并自动抢票。主分支不能展示所有工作分支的实时进度；查看进行中工作需要对应分支或 draft MR。

## 领域知识与 ADR 的持续维护

CONTEXT 保存当前定义，每项简短；持续建模采取修订、去重和澄清，不按会话追加重复定义。历史由 Git 保存。关键问答进入 spec，任务行为进入验收条件，实现经过进入 journal。

实际出现同词异义、独立演进的概念集合或任务只需局部词汇时，再把领域拆到 `project-name/docs/domains/<domain>/CONTEXT.md` 等稳定位置并更新 map。通用术语只在确实共用时保留一份，不能把跨领域同名概念强行合并。

ADR 按需创建。草稿允许修订；已接受的实质决策变化通常用新 ADR 替代，并链接旧记录。Proposed/accepted/superseded 的正文状态不取代 MR 审批事实。一个分支中的 accepted 不能被解释为其他分支已经采用。

两个不同 ADR 文件内容相反，也可能无文本冲突地合并。Reviewer 需要检查本次涉及的 spec、词汇、决策和代码是否一致，不仅检查 Git 冲突标记。编号改成唯一标识只能解决引用冲突，不能解决决策冲突。

## Journal 与跨人交接

关键结论在澄清时就写入 spec/CONTEXT/ADR。Journal 在实质工作阶段、暂停、交接或交付时生成；同一阶段可更新同一文件。正常 MR 审查下保留事实，发现旧记录错误时明确更正。

最小字段：成员、日期、实际已知的 agent、任务/主题、当前可获取的分支或 MR（如已有）、本次完成项、验证命令与结果、未做验证、剩余问题与下一步。有真实提交时可记录 SHA；若验证包含未提交修改，明确写出，不能把 HEAD 当成全部被验证内容。

每位成员独立文件，使用足够区分同日多会话的唯一标识。日志避免复制 spec 或 ADR 正文；长测试结果可引用可获取的 CI/MR 证据。仅本机临时文件不是其他成员可获取的交接证据。

共享交接至少包含任务路径和可获取版本。路径 + 未推送的本地文件不算跨成员交接完成。Squash/rebase 后旧 SHA 可能不在主分支祖先链，长期追踪结合 ticket/journal/MR；依赖完成以实际接口和行为核对，不能只检查提交祖先关系。

突然退出可能没有最后一份 journal。恢复时检查现有文件、diff、提交和验证现状，并标记不能确认的进展。第一版提供阶段摘要，不承诺完整操作日志或每次 AI 调用审计。

## 启动、worktree、权限与子 agent

所有实例保持同样的仓库相对结构。新 worktree 使用所选基线提交的 harness、任务和代码；普通 worktree add 不继承未提交材料。Codex 桌面的本地改动迁移是另一个宿主功能，不据此推导通用 Git 行为。

从根或项目目录启动，都解析当前 `git rev-parse --show-toplevel`。根 AGENTS/skills 可被发现，不代表拥有写上层文档的权限。CLI 项目子目录入口可以使用 `codex --add-dir ..`；实际桌面/企业权限独立验证。权限不足时报告缺少的范围，不在项目子目录另建一套 `.scratch`。

Codex 管理的 worktree 可能 detached HEAD，记录实际 HEAD；创建 MR 前明确保存到可推送的命名分支。日志不硬编码另一个 checkout 的绝对路径。规则升级随正常 Git 同步，新会话重新加载；运行中的会话不能被当作实时配置客户端。

委派子 agent 时明确传入：当前 worktree 根、任务/spec、所需规则与领域文档、输出目标、读写职责。Review 两轴使用同一个固定比较范围，review 期间保持相关文件不变。Reviewer 报告 findings，父 agent 统一更新 ticket/journal；并行实现分配互不冲突的写入范围或独立 worktree。

## Review 范围与证据

- 已提交分支 review：记录比较的 base/head SHA，review 相关最终 diff。
- 工作区 review：固定基线，覆盖分支已提交变更与当前 tracked 最终内容，并显式枚举、读取本轮 untracked 文件；只用 `git diff HEAD` 同样不足。
- 不混入用户原有无关修改；若工作树复杂，先标明任务范围和待排除变更。
- Review 发现问题后修复、执行受影响验证，再确认实际交付版本。单纯生成一份报告不表示所有 findings 已处理。
- 变基、解决冲突或共享需求改变后，判断哪些验证失效并补跑。旧日志保留历史事实，不伪称验证覆盖新代码。
- GitLab MR 承担正式人工 review；代码和相关任务/决策/验证记录尽量同 MR 审查。

## 三个 subagent 的意见如何取舍

全部采纳：review 未提交范围修正、独有技能名称、根路径与写权限分离、状态不能当锁、map 路由、ADR 命名模板适配、关键结论及时落盘、小任务/无 ticket 探索可运行。

两项取舍：

1. 信息架构 reviewer 建议初期删 team.md。这里暂保留，限定为跨人分工、版本交接和规范迭代；避免将这些细节塞回常驻 AGENTS。若实际内容只有两三条再合并，不为凑结构扩写。
2. 原版 triage-labels 依赖选择通过团队适配合并进 tracker，而非新增独立配置。因为已决定采用人工分配和三种执行状态，继续保留原 triage/claim 体系会产生两套语义。

三个报告提供不同维度的审查意见，不将“多个 agent 同意”当作运行可靠性证明。

## 实际验证与仍待验证

本机 CLI：`codex-cli 0.154.0-alpha.6.2`。

| 检查 | 结果与边界 |
| --- | --- |
| 根/子目录 × 原 checkout/新 worktree，共四种 cwd | `codex debug prompt-input` 均包含根 AGENTS 标记与仓库 sentinel skill 标记 |
| 领域文档是否自动注入 | 四种输入均没有 CONTEXT 正文标记；必须由 agent 按指引读取 |
| 当前 worktree 根与 map 路径 | 先前隔离 Git fixture 四种 cwd 解析正确 |
| 已提交材料继承、未提交材料不随普通 worktree add 携带 | 隔离 Git fixture 验证通过 |
| 不同 worktree 修改隔离 | 验证通过；因此本地 claim 不是全局锁 |
| 同号 ADR / 相反决策可干净合并 | 隔离 Git fixture 复现 |
| squash 后实现存在、原 SHA 非主分支祖先 | 隔离 Git fixture 复现 |

Prompt-input 诊断因本轮外层沙箱阻止运行而通过已授权的沙箱外诊断执行；没有调用模型。这些结果验证了当前 CLI 的输入构造，不能证明 workspace-write 下的工具写权限，也不能证明模型已执行技能、读过链接或会自动写日志。Sentinel skill 使用独有名字；团队命名迁移与全部依赖尚未实施。

试点剩余五组必要验收：

1. 四种 cwd 在真实项目实际调用团队技能、写入本 worktree 的 ticket/journal，验证父目录权限与技能来源。
2. 构造 committed/staged/unstaged/untracked 混合变更，确认 review 覆盖本轮全部范围，且不修改旁人的工作。
3. A 完成需求和部分实现并提供可获取版本，B 全新会话接手；缺日志或中断时明确不确定性。
4. 两位成员在不同 worktree 开发同 feature 的不同 tickets，处理共享定义变化、相反 ADR 和实际依赖。
5. MR 合并/squash 后能从任务、日志和 MR 追溯要求与验证；技能或规范升级后新会话使用新基线。

第一版可补一项小型确定性检查：在常规 CI 中核验指定 Markdown 链接、必需字段和重复路径。它只检查结构，不宣称证明语义一致或测试真实执行。是否增加以试点出现的遗漏为依据，当前不新增专用 CLI。

## 审查材料与来源

- [Agent 能力与兼容性审查](reviews/agent-capabilities.md)
- [Git/worktree 协作审查](reviews/git-collaboration.md)
- [信息架构与轻量程度审查](reviews/minimal-architecture.md)
- [汇总探测结果](validation-results.json)
- [Matt 固定版本研究](references.md#matt-pocock-skills)，[Trellis 固定版本研究](references.md#trellis)
- [官方 AGENTS 发现规则](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [官方 skills 发现与同名处理](https://learn.chatgpt.com/docs/build-skills)
- [官方 CLI add-dir](https://learn.chatgpt.com/docs/developer-commands)
- [官方 worktree 行为](https://learn.chatgpt.com/docs/environments/git-worktrees)
