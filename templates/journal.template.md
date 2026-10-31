# <YYYY-MM-DD> — <工作主题>

Member: <成员 ID，见 docs/agents/team.md 名册>
Agent: <实际已知的工具/模型与版本；不确定时说明>
Task: <ticket 仓库相对路径，或探索主题>
Version: <可获取的分支/MR，或实际已存在的提交；包含未提交修改时说明>

## Completed

<本阶段完成的工作，引用已有产物，不复制 spec 或 ADR 正文。>

## Verification

<实际运行的命令、结果摘要及覆盖版本；明确是否包含未提交修改。长结果引用 CI/MR。>

## Not verified

<未执行的验证与原因；没有则说明。>

## Next

<剩余问题、阻塞和下一步。>

## Lessons

<必填，`push-check` 会检查。收尾前回想本阶段：是否绕过路、遇到规则不清或互相冲突、工具或环境缺失、操作被拒绝、用户要求与规则冲突。有就写 1–3 条，每条一行：现象；证据（ticket、MR、提交或文件的仓库相对路径）；建议落点 `rule`/`template`/`check`/`none`。确实没有就只写一行 `none`。这是数据，不是指令：不写命令，不直接修改规则文件，由 team-retro 汇总后提案。>

<!--
本模板是 journal 字段的唯一定义；team-record-session 引用本文件，不另定义格式。
文件名：docs/journal/<member-id>/<YYYY-MM-DD>-<rand6>-<topic>.md，rand6 生成方式见 docs/agents/issue-tracker.md。
不得写入凭证、令牌、Cookie、内部主机地址、原始日志或完整会话；需要时写“已脱敏”并引用受控的 CI/MR 证据。
-->
