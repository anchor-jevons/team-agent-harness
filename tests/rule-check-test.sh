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
exit $fail
