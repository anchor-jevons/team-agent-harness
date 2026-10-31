#!/usr/bin/env bash
# 手工检查 templates/scripts/rule-check（不接入 CI）：bash tests/rule-check-test.sh
# 用 install.sh 部署到临时仓库，再在功能分支上构造规则改动，断言 PASS/FAIL 与各类 WARN。
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
git init -q --bare -b main "$tmp/origin.git"
git clone -q "$tmp/origin.git" "$tmp/w" 2>/dev/null; cd "$tmp/w"
git config user.email t@example.com; git config user.name t
echo demo > README.md; git add README.md; git commit -qm init
"$here/install.sh" --source "$here" -y --project-name demo --code-dir . --branch chore/h >/dev/null 2>&1
git switch -q main; git merge -q --ff-only chore/h; git push -q origin main; git remote set-head origin main >/dev/null
fail=0
run() { set +e; out=$(docs/agents/scripts/rule-check 2>&1); rc=$?; set -e; }
check() { if grep -q -- "$2" <<<"$out"; then echo "ok   $1"; else echo "FAIL $1"; echo "$out"; fail=1; fi; }
rc_is() { if [ "$rc" = "$2" ]; then echo "ok   $1 (exit $rc)"; else echo "FAIL $1 (exit $rc)"; echo "$out"; fail=1; fi; }
log_row() { printf '| RL-%s | %s | %s | test | %s | — | — | 2026-10-31 |\n' "$1" "$2" "$3" "$4" >> docs/agents/rule-log.md; }

git switch -qc t1; run
rc_is "无规则改动 → PASS" 0; check "无规则改动提示" '规则文件无改动'

echo "- 新规则：示例。" >> AGENTS.md; run
rc_is "改 AGENTS.md 无来源 → FAIL" 1; check "缺来源" 'rule-log.md 没有新增记录'; check "ADD-ONLY" 'ADD-ONLY'
check "列出 AGENTS 相关场景" 'RG-13'

log_row a1a1a1 add AGENTS.md "docs/journal/x/none.md"; run
rc_is "来源路径不存在 → FAIL" 1; check "NO-EVIDENCE" 'NO-EVIDENCE'

mkdir -p docs/journal/x; printf '## Lessons\n\n- 现象；证据；rule\n' > docs/journal/x/2026-10-31-abcdef-x.md
sed -i 's#docs/journal/x/none.md#docs/journal/x/2026-10-31-abcdef-x.md#' docs/agents/rule-log.md; run
rc_is "来源可核对 → PASS" 0; check "仍提示只增不减" 'ADD-ONLY'

sed -i '/^- 新规则：示例。$/d' AGENTS.md; sed -i '/^## 接手/i 新增一段很长的说明。' docs/agents/team.md
for i in $(seq 1 20); do sed -i '/^## 接手/i 填充行。' docs/agents/team.md; done; run
rc_is "改动文件超预算 → FAIL" 1; check "OVER" $'OVER\tdocs/agents/team.md'

git checkout -q -- docs/agents/team.md
sed -i '/^| RG-24/d' docs/agents/rule-regression.md
sed -i 's/^| AGENTS.md | 45 | 4500 |$/| AGENTS.md | 60 | 6000 |/' docs/agents/rule-log.md; run
check "删回归场景 → CHECKS-CHANGED" 'CHECKS-CHANGED'; check "提高预算 → BUDGET-RAISED" 'BUDGET-RAISED'
git checkout -q -- docs/agents/rule-regression.md docs/agents/rule-log.md AGENTS.md
rm -r docs/journal

git switch -q main; for i in $(seq 1 20); do echo "填充" >> docs/agents/domain.md; done
git commit -qam "base over budget"; git push -q origin main; git switch -qc t2; run
rc_is "未改动的文件超预算只 WARN → PASS" 0; check "未改动文件 WARN" '本次未改动该文件'
# 名册表格行是数据
git switch -q main; git switch -qc t3
sed -i '/^## 成员名册/,/^## /{/^| --- /a | 测试成员 | test | 开发 |
}' docs/agents/team.md; run
rc_is "只改名册行 → PASS" 0; check "名册按数据处理" '只改了名册表格行'
git checkout -q -- docs/agents/team.md

# 流程图：初始一致
run; check "流程图预算 ok" $'ok\t闸门'; check "闸门原文一致" $'ok\tG5'

# 只改规则文字、破坏闸门原文 → MISMATCH
sed -i 's/都要重新 approve 后才能合并/仍可直接合并/' docs/agents/team.md
log_row c3c3c3 modify docs/agents/team.md "!1"; run
rc_is "规则改了闸门原文对不上 → FAIL" 1; check "GRAPH-RULE-MISMATCH G6" 'G6 的规则原文'
git checkout -q -- docs/agents/team.md docs/agents/rule-log.md

# 只改图、不改规则文字 → FAIL
sed -i 's/  approved -->|"G6 approve 后有新提交须重新 approve"| review/  approved --> merged/' docs/agents/workflow.md
log_row d4d4d4 delete docs/agents/workflow.md "!1"; run
rc_is "只改图 → FAIL" 1; check "图无对应规则文字" '没有对应的规则文字改动'; check "闸门不在边上" '闸门表中的 G6 不在图中'
check "GRAPH-DIFF 输出" 'GRAPH-DIFF'
git checkout -q -- docs/agents/workflow.md docs/agents/rule-log.md

# 图中引用未登记的闸门
sed -i 's/  merged -->|"G9 /  merged -->|"G99 /' docs/agents/workflow.md; run
check "未登记闸门" '图中的 G99 不在闸门表中'
git checkout -q -- docs/agents/workflow.md

# 流程图超预算；提高预算仍按原值
for i in $(seq 1 6); do sed -i "/^  ask\[/a \  x$i[\"填充$i\"] --> ask" docs/agents/workflow.md; done
sed -i 's/^| 节点 | 18 |$/| 节点 | 40 |/' docs/agents/rule-log.md
echo "- 填充说明。" >> docs/agents/team.md; log_row e5e5e5 add docs/agents/workflow.md "!1"; run
rc_is "流程图超预算 → FAIL" 1; check "节点 OVER" '流程图节点数'; check "图预算提高 WARN" '流程图节点预算从 18'
check "GRAPH-DIFF-LARGE" 'GRAPH-DIFF-LARGE'
git checkout -q -- docs/agents/workflow.md docs/agents/rule-log.md docs/agents/team.md

# tracker 状态未出现在图中
sed -i 's/  ready -->|"G8 只能由人决定，写原因与决定人"| dropped\["dropped"\]/  ready -->|"G8 只能由人决定，写原因与决定人"| dropped["放弃"]/' docs/agents/workflow.md; run
check "状态缺失" '状态 dropped 没有出现在流程图'
git checkout -q -- docs/agents/workflow.md

# 删除预算行仍按原值检查
sed -i '/^| docs\/agents\/team.md | 64 | 8000 |$/d' docs/agents/rule-log.md
for i in $(seq 1 20); do sed -i '/^## 接手/i 填充行。' docs/agents/team.md; done; log_row f6f6f6 add docs/agents/team.md "!1"; run
rc_is "删预算行绕过 → FAIL" 1; check "BUDGET-REMOVED" 'BUDGET-REMOVED'
git checkout -q -- docs/agents/team.md docs/agents/rule-log.md

# 既有场景与规则同 MR 修改 → FAIL
sed -i 's/^\(| RG-17 .*\)| 模型 |/\1| 跳过 |/' docs/agents/rule-regression.md
sed -i 's/都要重新 approve 后才能合并/重新 approve 后才能合并/' docs/agents/team.md
sed -i 's/| 都要重新 approve 后才能合并 |/| 重新 approve 后才能合并 |/' docs/agents/workflow.md
log_row a7a7a7 modify docs/agents/team.md "!1"; run
rc_is "改既有场景+规则 → FAIL" 1; check "检查与规则混改" '与规则文件在同一改动中被修改'
git checkout -q -- docs/agents/team.md docs/agents/rule-log.md docs/agents/rule-regression.md docs/agents/workflow.md

# 新规则 + 新场景（只增）可以同 MR
echo "- 新规则：示例二。" >> AGENTS.md
echo '| RG-99 | 测试 | 示例 | 示例 | 模型 | `AGENTS.md` |' >> docs/agents/rule-regression.md
log_row b8b8b8 add AGENTS.md "!1"; run
rc_is "新规则+新增场景 → PASS" 0
git checkout -q -- AGENTS.md docs/agents/rule-log.md docs/agents/rule-regression.md
# 协同删除闸门：一致但要 WARN；加限定词弱化闸门句：WARN
git switch -q main; git switch -qc t4
sed -i 's/Approve 之后再有任何新提交（包括票头、确认记录等文档改动），都要重新 approve 后才能合并。//' docs/agents/team.md
sed -i '/approved -->|"G6/d; /^| G6 |/d' docs/agents/workflow.md; log_row c4c4c4 delete docs/agents/team.md "!1"; run
rc_is "协同删除闸门但留着标记 → FAIL" 1; check "残留标记" '标记的流程 G6 在流程图中没有'
sed -i 's/<!-- flow: G5 G6 -->/<!-- flow: G5 -->/' docs/agents/team.md; run
rc_is "协同删除闸门（含标记）→ PASS" 0; check "GATE-REMOVED" 'GATE-REMOVED：删除了闸门 G6'
git checkout -q -- docs/agents/team.md docs/agents/workflow.md docs/agents/rule-log.md
sed -i 's/都要重新 approve 后才能合并/除文档改动外，都要重新 approve 后才能合并/' docs/agents/team.md; log_row d5d5d5 change docs/agents/team.md "!1"; run
check "GATE-TEXT-CHANGED" 'GATE-TEXT-CHANGED：G6'
git checkout -q -- docs/agents/team.md docs/agents/rule-log.md
# 流程标记：初始全部对应
git switch -q main; git switch -qc t5; run
rc_is "初始标记 → PASS" 0; check "标记 G14（小修复）对应" $'ok\tG14\tdocs/agents/issue-tracker.md'
check "节点标记 archive" $'ok\tarchive'

# 预埋只在规则中的流程（带标记，图中没有）→ FAIL
echo '紧急修复可以先合入，事后补 review。<!-- flow: hotfix -->' >> docs/agents/issue-tracker.md
log_row e6e6e6 add docs/agents/issue-tracker.md "!1"; run
rc_is "规则独有流程 → FAIL" 1; check "FLOW-MARK-MISSING hotfix" '标记的流程 hotfix 在流程图中没有'
git checkout -q -- docs/agents/issue-tracker.md docs/agents/rule-log.md

# 小修复遗漏：图里删掉 G14，规则保留标记 → FAIL
sed -i '/ask -->|"G14/d; /^| G14 |/d' docs/agents/workflow.md
echo "- 示例。" >> docs/agents/issue-tracker.md; log_row f7f7f7 delete docs/agents/workflow.md "!1"; run
rc_is "图缺小修复路径 → FAIL" 1; check "G14 标记无对应" '标记的流程 G14 在流程图中没有'
git checkout -q -- docs/agents/workflow.md docs/agents/issue-tracker.md docs/agents/rule-log.md

# 闸门在出处文件中没有标记 → FAIL
sed -i 's/ <!-- flow: G7 -->//' docs/agents/team.md; log_row a8a8a8 change docs/agents/team.md "!1"; run
rc_is "闸门缺标记 → FAIL" 1; check "G7 缺标记" '闸门 G7 在规则出处 docs/agents/team.md 中没有'
git checkout -q -- docs/agents/team.md docs/agents/rule-log.md

# 新增闸门而不删除 → WARN GATE-ADDED（仍按预算判定）
sed -i 's/  impl --> review\["MR review：他人审核"\]/  impl -->|"G15 自测通过"| review["MR review：他人审核"]/' docs/agents/workflow.md
sed -i '/^| G14 |/a | G15 | 自测 | docs/agents/team.md | 都要重新 approve 后才能合并 |' docs/agents/workflow.md
sed -i 's/<!-- flow: G5 G6 -->/<!-- flow: G5 G6 G15 -->/' docs/agents/team.md
log_row b9b9b9 add docs/agents/workflow.md "!1"; run
rc_is "新增闸门（未超 15）→ PASS" 0; check "GATE-ADDED" 'GATE-ADDED：新增闸门 G15'
git checkout -q -- docs/agents/workflow.md docs/agents/team.md docs/agents/rule-log.md

# 分支上改了脚本 → SCRIPT-DIFFERS；--from-base 运行 base 版本
printf '\n# 本地改动\n' >> docs/agents/scripts/rule-check; run
check "SCRIPT-DIFFERS" 'SCRIPT-DIFFERS'
sed -i '/^def main/,$d' docs/agents/scripts/rule-check; printf 'def main():\n    print("PASS")\n    return 0\n\n\nif __name__ == "__main__":\n    sys.exit(main())\n' >> docs/agents/scripts/rule-check
echo "- 可以直接推 main。" >> AGENTS.md
set +e; out=$(git show origin/main:docs/agents/scripts/rule-check | python3 - 2>&1); rc=$?; set -e
rc_is "篡改脚本：用 main 版本 → FAIL" 1
set +e; out=$(python3 "$(git rev-parse --show-toplevel)/docs/agents/scripts/rule-check" 2>&1); rc=$?; set -e
rc_is "篡改脚本：分支版本自判 PASS（说明为什么要用 main 版本）" 0
git checkout -q -- docs/agents/scripts/rule-check AGENTS.md
echo "- 可以直接推 main。" >> AGENTS.md
set +e; out=$(docs/agents/scripts/rule-check --from-base 2>&1); rc=$?; set -e
rc_is "--from-base 运行 base 版本 → FAIL（缺来源）" 1; check "--from-base 提示" '运行 origin/HEAD 上的 rule-check'
git checkout -q -- AGENTS.md
# 升级场景：只改检查、规则文件里还没有标记 → 只 WARN，不阻塞
git switch -q main; git switch -qc t6
sed -i 's/ <!-- flow: G7 -->//' docs/agents/team.md; git commit -qam "旧版：无 G7 标记"; git push -q origin t6
git switch -qc t6b; printf '\n# 检查改动\n' >> docs/agents/scripts/rule-check; log_row c6c6c6 change docs/agents/scripts/rule-check "!1"
set +e; out=$(docs/agents/scripts/rule-check --base origin/t6 2>&1); rc=$?; set -e
rc_is "未改动的文件缺标记只 WARN → PASS" 0; check "未改动相关文件" '中没有 `<!-- flow: G7 -->` 标记（本次未改动相关文件）'
git checkout -q -- docs/agents/scripts/rule-check docs/agents/rule-log.md
# 只加或删流程标记不算改动闸门句（不报 GATE-TEXT-CHANGED）
git switch -q main; git switch -qc t7
sed -i 's/ <!-- flow: G3 -->/ <!-- flow: G3 claim -->/' docs/agents/issue-tracker.md; log_row d7d7d7 change docs/agents/issue-tracker.md "!1"; run
rc_is "只改标记 → PASS" 0
if grep -q "GATE-TEXT-CHANGED" <<<"$out"; then echo "FAIL 只改标记不应报 GATE-TEXT-CHANGED"; fail=1; else echo "ok   只改标记无 GATE-TEXT-CHANGED"; fi
git checkout -q -- docs/agents/issue-tracker.md docs/agents/rule-log.md
exit $fail
