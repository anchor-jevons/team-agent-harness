# Team harness：Agent 能力与 Matt 兼容性审查

日期：2026-09-25。范围：单 Git repo、单项目子目录；内部 GitLab 仅 Git/MR；根 `.agents/skills`、`.scratch`、`docs`、`CONTEXT-MAP.md`，项目层 `CONTEXT.md`。不把已有 v3 文档当作最新方案。

结论：目录可以成立，但不能直接复制 Matt skills 后宣称具备团队级可靠性。主要缺口是技能版本选择、review 覆盖范围、路径/权限、显式触发、收尾持久化和并行任务分配。目录移动解决不了这些问题。

## 第一性原理

1. Agent 当前能看见的是本会话输入和当前 checkout 文件；其他成员未推送的状态不可见。
2. 指令是引导，不是事务、锁、权限授予或执行成功证明。
3. Git 提供版本与分支隔离，不能自动判断决策相容、任务所有权和验证证据有效性。
4. 持久材料必须让全新会话在有限读取量下找到当前任务、权威需求、相关规则和可靠证据。
5. 因此最低可靠性来自明确输入、唯一来源、可验证输出和人工 review，而不是增加更多强制 Markdown 层级。

## P1：需要在试点前明确修复

### 1. 原版 implement 与 code-review 的顺序会漏掉本轮改动

证据：本机 `implement/SKILL.md:13-15` 先 review、后 commit；`code-review/SKILL.md:21-23` 固定 `git diff <fixed-point>...HEAD`，空 diff 则失败。该命令不包含 index/worktree 改动，也不包含未跟踪新文件。

影响：首次实现可能得到空 diff；已有 commits 时可能只 review 旧代码，随后直接提交新代码。增加 team.md 无法消除两个操作定义之间的矛盾。

最小修复：团队版 review 明确区分“已提交分支”与“当前工作区”。工作区 review 固定 base SHA，检查相对基线的 tracked 最终内容，并显式枚举/阅读 untracked 文件；不以 `git diff HEAD` 代替全部分支改动。委派 reviewer 时传同一基线、范围和文件清单；review 期间暂停写入。修复影响结论的 findings 后补做相应验证，再由既定提交政策处理 commit。

### 2. 仓库固定版本不保证同名个人 skill 被覆盖

官方 skills 文档明确：同名 skill 不合并，两者可能同时出现在选择器中。[官方说明](https://learn.chatgpt.com/docs/build-skills)

影响：若成员已在个人 skills 目录安装 Matt，加入 repo 版相同名称后，“团队都执行相同规则”并不自动成立。

最小修复：团队适配版采用明确且唯一的 skill 名称/显示名，并同步内部依赖引用；或在入组检查中明确禁用个人重复版本并验证实际加载来源。两条择一，不能依赖未证实的优先级。记录 upstream commit 与少量 patch 的范围，升级时 review 差异。

### 3. 读取根指令与能够写根文件是两件事

官方 AGENTS 发现链从项目/Git 根到 CWD；skills 从 CWD 向上发现至 repo 根，支持当前两层布局。[AGENTS](https://learn.chatgpt.com/docs/agent-configuration/agents-md)、[Skills](https://learn.chatgpt.com/docs/build-skills)

但 `project-name/` 启动的 session 不一定获准写上层 `.scratch`/`docs`。CLI `--add-dir` 只增加写入范围；权限仍以实际 profile 为准。[CLI](https://learn.chatgpt.com/docs/developer-commands)

最小修复：所有持久路径以 `git rev-parse --show-toplevel` 为基准；shell workdir 显式指定。入组/启动检查确认当前 worktree 根及可写范围。CLI 子目录启动可采用 `codex --add-dir ..`，桌面端独立验收，不宣称该参数适用于所有入口。不要让 agent 在错误层级另建 `.scratch` 来绕过权限问题。

### 4. 不能把工作流箭头理解为原版 skills 自动串行执行

Matt 的 `.agents/invocation.md` 和 README 明确区分人显式触发的阶段技能与模型可调用的方法技能。`grill-with-docs`、`to-spec`、`to-tickets`、`implement` 均有 `allow_implicit_invocation: false`。

`to-spec` 仍要求确认测试 seams；`to-tickets` 要审核拆票。这些是团队需求确认环节，不能在后台默认为已发生。

最小修复：流程图标注“可选、显式入口”；团队成员在阶段转换时调用所需技能。新 `record-session` 若希望 agent 收尾自动使用，必须具备可隐式调用配置/明确触发描述，或将写记录直接列为团队阶段技能的结束步骤。不能给它关闭自动调用又承诺自动日志。

### 5. 原版 frontier/claim 不适合 Git 文件作为跨成员抢票锁

证据：`to-tickets/SKILL.md:66` 有 work frontier；local tracker 的 wayfinding 部分按首个未认领任务设置 `claimed`，这个文件保存动作只影响本地 checkout。

影响：两个 worktree 可以同时成功认领同一任务；甚至依赖已在另一分支 implemented，也不等于当前分支具备依赖代码。

最小修复：本项目明确由人指定 owner 和 ticket，agent 不扫描并自动认领。暂不包含 wayfinder 的 claim 流程；若保留原模板，删除不使用的该段。依赖完成检查针对当前分支是否具备所需实现与验证，而非只读 Status。

## P2：重要适配与边界

### 6. 项目层 CONTEXT 需要真实 map 与 setup 适配

`domain-modeling/CONTEXT-FORMAT.md` 支持根 map 定位任意领域文件；没有 map/context 时会创建根 CONTEXT。`setup-matt-pocock-skills/SKILL.md:59-61` 对单项目默认根 CONTEXT，仅 monorepo 信号时提供多 context。

最小修复：初始化时先提交 root map，明确指向 `project-name/CONTEXT.md`；修改团队 setup 的默认约定或初始化后不再运行原版 setup 重建布局。可把单条 map 视为寻址用途，不伪造多领域划分。术语定义修订而非逐轮追加，历史交给 Git，长问答进入 spec/journal。

### 7. ADR 文件名、ticket Context 字段都不是无修改兼容

`domain-modeling/ADR-FORMAT.md` 明确按最大顺序号 +1；团队提议日期+短 ID 必须修改该 reference，不能只在 AGENTS 留一条相反要求。原 `to-spec` 和 `to-tickets` 禁止正文加入具体文件路径，而团队希望记录代码入口。

最小修复：保留需求正文的行为描述；独立 Context/Handoff 栏允许导航链接，标注只是入口提示，接手时确认仍有效。ADR 的命名和 lifecycle 只定义一处并从 skill 引用。所有 skill 附属模板、references、agents/openai.yaml 必须一起交付。

### 8. 日志能提供交接摘要，不能保证全量活动审计

Agent 的上下文可能压缩、会话可能中断，尚未写入的讨论不会自动成为仓库材料。原 `handoff/SKILL.md:8` 还明确写 OS 临时目录，而非 repo。

最小修复：record-session 在有实质产出、暂停或交付时写一份短记录；列 task 路径、成员、实际可知的 agent 标识、当前 HEAD/基线、已做事项、命令与结果、未做验证、下一步。人/模型身份不知道时不猜。每次记录独立文件，ticket 只链接最新相关 handoff，不复制全文。

保留边界：不保证突然退出前的每次操作均记录，也不是不可篡改审计。若目标未来升级为完整活动审计，需另评会话导出/事件采集及其隐私、保留规则；当前轻量 harness 不承诺该能力。

### 9. 子 agent 不应靠隐含继承获得全部任务材料

Matt code-review 已明确要求向两个 reviewer 传递 diff、commit list、规范、spec。团队更应传当前 worktree 绝对根、ticket/spec、必要规范/ADR、冻结 review 范围及只读职责。不要仅说“遵循团队规则”，也不要强制整份聊天与所有日志作为输入。

读写原则：reviewer 只报告 findings，父 agent 更新 ticket/journal；同一工作区并行实现必须分配独立写入范围，否则使用独立 worktree。共享文件系统不等于并发写入安全。

### 10. Codex worktree 不一定已有命名 feature branch

官方桌面 worktree 默认 detached HEAD；也可能带入选择的分支的未提交改动。[Worktrees](https://learn.chatgpt.com/docs/environments/git-worktrees)

最小修复：启动记录当前 HEAD 和工作区状态，不能仅存 branch 名；交付/MR 前明确保留到命名分支并推送。当前路径随 worktree 改变，仓库正文链接使用相对路径，日志不硬编码另一个 checkout 的绝对路径。

### 11. 显式读取链接不代表文档已自动注入

根 AGENTS 应短且包含可执行的读取条件：任务开始读 ticket/spec 和 team；实现/review 读 development；涉及领域概念查 map 再选择 glossary/ADR；收尾更新 journal。日志和所有 ADR 不应每次全量读取。

最小修复：每份 ticket 保存少量稳定上下文链接；父 agent 先确认引用的内容，再派任务。可在试点观察遗漏再补触发，不建立庞大固定读取清单。

### 12. Matt 的 Skill tool 指令需要宿主适配

`grill-with-docs/SKILL.md` 要求调用名为 Skill 的工具；当前 Codex 会话通过技能目录和读取 SKILL.md 应用技能，没有同名专用工具。该用词不能视为跨宿主必然可执行。

最小修复：团队版依赖调用写成宿主兼容的明确动作，例如“加载并遵循本团队的 grilling/domain-modeling skill”；解析到固定 repo 路径，验证依赖完整。Codex 用户入口采用 `$skill-name` 或选择器，文档不把 Claude 的 `/name` 当作终端/Codex 子命令。

## 最小试点

1. 四个 CWD：原 checkout 根/子目录、新 worktree 根/子目录。检查发现来源、根路径、实际写权限；仅静态 Git 路径检查不足。
2. 重名用户技能存在时，验证团队版本实际被选中；setup/template 不重建根 CONTEXT。
3. 新文件未跟踪 + 已暂存修改 + 已提交历史同时存在，review 必须覆盖指定范围的全部最终改动。
4. A 仅写仓库文档并推到 draft MR，B 新会话仅凭 ticket 与链接继续，能识别未决问题及未执行验证。
5. 两个 worktree 并行不同 tickets，ADR 同日创建、共同术语改变、依赖实现只在另一分支时，检查冲突/依赖判断。
6. 中断一个未收尾会话，确认系统准确报告日志可能不完整，不虚构自动持久化。

验证界限：本审查读取了本机真实 skills、参考文件、上游固定 snapshot 的 invocation 约定及当前官方网页；检查了本机 debug prompt-input 帮助。未启动付费模型会话、未改用户配置或安装目录、未执行这些技能。实际四位置发现探测由主 agent 单独负责。
