# Team harness 信息架构独立 review

日期：2026-09-25。范围：信息归属、轻量程度、协作与生命周期；不验证 Codex runtime。
依据：需求讨论及研究环境中的 Matt 的 domain-modeling、CONTEXT-FORMAT、setup 模板、to-spec、to-tickets、implement、code-review、handoff 原文。
结论：保留 Git + Markdown + Matt 方法技能；修正读写契约、依赖遗漏和异常路径，暂不增加调度器、任务数据库或自动抢票。

## 从第一性原理出发

1. 团队需要共享的是当前约定、任务承诺、决策理由和接手所需证据。
2. 四类内容变化频率不同；混在一个长期文件里会让 agent 读取过量历史并难以辨认现行规则。
3. Git 能共享经过提交的快照、review 与变更历史；不能提供实时锁、在线成员状态或崩溃时必达的日志。
4. 当前 agent 能按显式入口寻找材料并编写摘要，但自然语言指令不是可靠的强制执行机制。
5. 每多一个文件都要回答：它有独立读者、触发时机与唯一权威职责吗？否则合并或按需创建。

## 需要修正的问题

### P1：目前描述把阶段收尾当成日志保障

只在暂停/交接/完成时调用 record-session，不能覆盖崩溃、窗口关闭、上下文丢失。
关键确认发生时立即落到 spec/CONTEXT/ADR；阶段验证或交接时再写日志。
中断恢复必须核对当前 diff、提交与测试现状，不能把 journal 当作实时真相。
不承诺记录每次模型调用或完整聊天；v1 提供“每位成员的阶段性开发摘要”。
若用户实际要求所有会话完整留痕，应独立确认并设计工具级采集，不能声称 Markdown 指令已经满足。

### P1：状态文字不能作为并行协调协议

不同分支的 Owner/Status/Handoff 都可能过期；一个文件的 claimed 不是跨 worktree 锁。
明确人工分派、一票一主负责人；接手前确认负责人与当前分支材料。
主分支适合保存已共享的计划与已合并的成果，不适合展示所有成员的实时进度。
一条共享 Handoff 指针只适用于该任务单主线；并行阶段先保留各 journal 中的 ticket 链接，交接时整合权威下一步。

### P1：目录省略了原版 tracker 配置依赖

to-spec 要求 issue tracker 和 triage vocabulary；issue-tracker-local.md 指向 triage-labels.md。
不能一面宣称“原样保留 Matt”，一面遗漏这些配置。
最小兼容方案：保留 docs/agents/triage-labels.md；团队执行状态明确只在一处定义。
更小的定制方案：改相关引用，把状态词汇统一放 issue-tracker.md，然后删除多余文件。
二选一后必须检查所有选择的 skills 引用；目录图不能代替依赖闭包核验。
wayfinder 的 claimed/resolved 自动扫描抢票不在当前范围，不应从模板整段继承。

### P2：team.md 与 development.md 容易重复

工程质量、验证标准、review 要求归 development.md。
任务读写归 issue-tracker.md；日志步骤归 record-session；术语/ADR 约定归 domain.md。
剩下的一票一负责人、代码文档同 MR、接手核对现状等短规则可直接放 AGENTS.md。
因此 team.md 初期可删除；当协作约定明显变长再提取，届时 AGENTS.md 只留入口。
若团队选择保留 team.md 也可，但必须限定为跨人协作，禁止再复制状态、模板和工程规范。

### P2：强制 ticket 保存代码入口偏离原版且容易过期

Matt to-tickets/to-spec 明确避免具体实现文件路径和片段，原因是过期风险。
ticket 可以引用稳定的 spec、领域文档、ADR 和验收条件；不强制维护精确源码清单。
接手时根据领域模块描述重新搜索代码。journal 可记录当时观察到的代码位置，但必须带工作阶段语境。

### P2：原版 review 与实现组合需要另行适配

implement 先 review 后 commit；code-review 默认三点比较到 HEAD，可能遗漏本轮未提交内容。
这是明确的审查范围问题，不能靠目录设计或 AGENTS 中一句“检查代码”自动解决。
发布团队技能前明确支持 branch diff 与 working-tree diff，并报告实际审查范围。
日志只能写已执行的验证；摘要和人类审查结论不可互相冒充。

## CONTEXT 的位置与增长

原版规定 CONTEXT 只保存领域词汇，每个定义一两句；禁止混入 spec、实现细节或讨论流水。
持续建模意味着修订、去重、澄清，不意味着每次会话追加一段记录。
长度问题先靠正确内容边界解决，再依据真实领域边界拆分；项目目录层级不能替代领域划分。

单领域最原生、文件最少的方式其实仍是根 CONTEXT.md，无需 map。
但如果坚持最新决定 project-name/CONTEXT.md，则根 CONTEXT-MAP.md 是便宜的兼容桥梁。
本 review 推荐保留最新路径，避免为节省一个十行索引再引入发现机制定制。
必须标注：单条 map 用来定位项目词汇表，并不证明项目已有多个 bounded contexts。
所有内容都只有一份正文；根不再创建重复 CONTEXT.md。
首次产生词汇定义时再创建 map 和 CONTEXT；没有时正常开发，不必建空壳。
真正出现多个领域、同词异义和独立演进时再拆；不要提前创建一套 domains/ 空目录。

## 最小目录建议

```text
repo-name/
├── AGENTS.md                         # 入口、根路径约定、少量跨人规则
├── CONTEXT-MAP.md                    # 按需；指向 project-name/CONTEXT.md
├── .agents/skills/
│   ├── <selected-matt-skills>/        # 完整依赖；固定版本
│   └── record-session/              # 新增；也可由 handoff 团队适配而来
├── .scratch/
│   └── <feature>/
│       ├── spec.md                   # 按需；已确认需求、关键问答、未决项
│       └── issues/
│           └── 01-<ticket>.md        # 小任务可以只存在这份
├── docs/
│   ├── development.md               # 共用工程原则、实现/验证/review 标准
│   ├── agents/
│   │   ├── issue-tracker.md          # 路径、状态与责任语义
│   │   ├── triage-labels.md          # 原版兼容时保留；定制合并后可删
│   │   └── domain.md                # 领域文档的发现和更新协议
│   ├── adr/                         # 按需；重要取舍，避免每个任务一份
│   └── journal/<member>/            # 按需；一工作阶段一文件，链接任务
└── project-name/
    ├── CONTEXT.md                    # 按需；当前有效的领域术语
    ├── src/
    └── tests/
```

删去初期 team.md；不增加 TASKS.md、个人全局 current-task、统一实时状态清单。
如已有 CONTRIBUTING.md 或工程规范，复用其权威正文，不再创建重复 development.md。
若复用 Matt handoff，必须改临时目录输出约定并明确职责；不要让两种 handoff 输出互相竞争。
规则同步依靠仓库固定版本。skill 版本来源记录可用现有依赖管理或简短说明，不必引入新服务。

## 文件更新责任

| 内容 | 主维护者 | 生命周期 |
|---|---|---|
| AGENTS/工程规范/skills | 指定维护者，团队 MR 审查 | 当前规则；修改理由留在 MR |
| Spec | Feature 负责人 | 当前需求；重大变更明确审查 |
| Ticket | 指定执行负责人 | 当前进展与验收；历史通过 Git |
| CONTEXT | 涉及该领域的成员与 reviewer | 修订现行定义，避免追加同义版本 |
| ADR | 决策提出人与有权确认者 | 草案可修订；已接受决策由新 ADR 替代 |
| Journal | 工作成员，agent 代写 | 阶段证据；错误允许明确更正，避免重写历史 |

规范迭代：从具体任务发现问题→提出一条可复用规则→MR review→以后任务按新基线使用。
不能把 agent 在某次任务中的偏好直接提升成全团队规范，也不自动把所有技术决定写成 ADR。

## 按需读取契约

AGENTS 直接指向 tracker、工程规范和 domain 约定，避免多层“索引指向索引”。
指定任务：读 ticket、它的 spec（如有）、相关领域/ADR，以及最近必要的交接摘要。
代码维护：工程规范相关部分；不用读取全体成员日志、全部 tickets 或所有 ADR。
文档内容过长时按目录/标题搜索，但不能以“按需”为由跳过适用的全局约束。
跨领域任务由 agent 读取两个领域，而不是机械地只读第一个 map 链接。
接手材料里的事实必须与当前代码核对；正文、执行记录与推测应区分。

## 场景闭合检查

| 场景 | 最小行为 |
|---|---|
| 首个需求、尚无文档 | 明确问题；关键问答落草案 spec；词汇/ADR 按需出现 |
| 已知小修复 | 一张简短 ticket 加验收即可；不强制 grill/spec/拆票全链 |
| 用户直接让改代码、无 ticket | 清楚的小任务可按 prompt 实施，交付前补最小记录；不阻塞于形式文档 |
| 只有探索、尚无任务承诺 | journal 保存发现与未决问题，不伪造 ready-for-agent ticket |
| 跨人接手 | 明确 ticket 与分支/提交，读取交接，核对实际差异，再继续 |
| 中途暂停 | 保存已确认成果及下一步；本地未提交内容仍不等于已共享 |
| 崩溃或缺日志 | 依赖代码、diff 与最近持久化证据恢复，标注无法确认的进展 |
| 同 feature 并行 | 共享 spec 基线，各自负责 ticket；共同改需求先协调 |
| 无文本冲突但决策矛盾 | reviewer 对照 ADR/spec 与代码解决语义冲突 |

小任务“是否强制先建 ticket”应由团队选择一次；不要让各 agent 自行发明不同审批门。
建议允许直接开工、交付前有最小任务记录，兼顾可追溯与低摩擦。
无 ticket 时 record-session 仍可工作，以主题和分支标识；后续任务出现再补链接。

## 最终判断

该设计能作为轻量的团队协作协议，不能被包装成强制执行、实时调度或完整审计系统。
达到目标的关键是：唯一权威位置、明确读取触发、持久化关键结论、工作阶段交接、MR 一起审代码与文档。
先用首个需求、小修复、跨人接手和中断恢复四个真实场景验证，再增加自动化。
