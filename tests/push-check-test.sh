#!/usr/bin/env bash
# 手工检查 templates/scripts/push-check（不接入 CI）：bash tests/push-check-test.sh
# 在临时目录建 bare 远端：名册 mei/raj；离开成员 ken 的陈旧分支；断言 STALE-BRANCH / FROM-STALE / OTHER-OWNER / JOURNAL-LESSONS / TAKEOVER / FEATURE-MAP。
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
script=$here/templates/scripts/push-check
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
git init -q --bare -b main "$tmp/origin.git"
git clone -q "$tmp/origin.git" "$tmp/w" 2>/dev/null; cd "$tmp/w"
git config user.email t@example.com; git config user.name t
d=.scratch/demo-abc123/issues
ticket() { mkdir -p "$d"; printf '# t\n\nOwner: %s\nStatus: %s\nBranch: %s\nSince: 2026-01-01\n' "$2" "$3" "$4" > "$d/$1"; }
old=$(date -d '-30 days' +%F 2>/dev/null || date -v-30d +%F)
mkdir -p docs/agents; printf '# 团队协作\n\n## 成员名册\n\n| 成员 ID | GitLab 用户名 | 备注 |\n| --- | --- | --- |\n| mei | mei-gl | |\n| raj | raj-gl | |\n\n## 分工\n' > docs/agents/team.md
ticket 01-aaaaaa-a.md raj ready-for-agent None; ticket 02-bbbbbb-b.md mei ready-for-agent None
git add -A; git commit -qm plan; git push -q origin main
# ken（已离开）的陈旧分支
git switch -qc ken/a; ticket 01-aaaaaa-a.md ken in-progress ken/a; echo k > k.txt; git add -A
GIT_COMMITTER_DATE="$old 12:00" git commit -qm "ken start aaaaaa"; git push -q origin ken/a
# mei 近期的分支
git switch -q main; git switch -qc feature/b; ticket 02-bbbbbb-b.md mei in-progress feature/b; git commit -qam "start bbbbbb"; git push -q origin feature/b
git remote set-head origin main >/dev/null; git fetch -q --prune origin
fail=0
run() { set +e; out=$(python3 "$script" "$@" 2>&1); rc=$?; set -e; echo "$out"; }
check() { if grep -q -- "$2" <<<"$out"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
checkno() { if grep -q -- "$2" <<<"$out"; then echo "FAIL $1"; fail=1; else echo "ok   $1"; fi; }
checkrc() { if [ "$rc" = "$2" ]; then echo "ok   $1"; else echo "FAIL $1 (rc=$rc)"; fail=1; fi; }
run; checkrc "缺 --member → 2" 2
# raj 在 ken 的分支上提交
git switch -q ken/a; echo r >> k.txt; git commit -qam "raj continues"
run --member raj; check "接手陈旧分支 → STALE-BRANCH" $'FAIL\tSTALE-BRANCH\tken/a'; checkrc "rc 1" 1
# raj 从 ken 分支开新分支
git switch -qc feature/a-raj; run --member raj; check "从陈旧分支开出 → FROM-STALE" $'FAIL\tFROM-STALE\tken/a'
# raj 从 main 开新分支，复制文件（不含 ken 的提交）→ PASS
git switch -q main; git switch -qc feature/a-raj2; git show origin/ken/a:k.txt > k.txt; git add k.txt; git commit -qm "reuse k.txt from ken/a (reported)"
run --member raj; check "从 main 开新分支 → PASS" $'RESULT\tPASS'; checkrc "rc 0" 0
checkno "没有功能地图时不报 FEATURE-MAP" 'FEATURE-MAP'
# raj 在 mei 的近期分支上 → 只 WARN
git switch -q feature/b; echo y > y.txt; git add y.txt; git commit -qm "raj helps"
run --member raj; check "他人近期分支 → OTHER-OWNER WARN" $'WARN\tOTHER-OWNER\tfeature/b'; check "仍 PASS" $'RESULT\tPASS'
# journal 缺 Lessons → FAIL；写 none → PASS；只有占位符 → FAIL
git switch -q main; git switch -qc feature/j; mkdir -p docs/journal/raj
printf '# j\n\n## Completed\n\nx\n\n## Next\n\ny\n' > docs/journal/raj/2026-10-31-abcdef-j.md; git add -A; git commit -qm j1
run --member raj; check "无 Lessons → JOURNAL-LESSONS" $'FAIL\tJOURNAL-LESSONS'
printf '\n## Lessons\n\n<必填>\n' >> docs/journal/raj/2026-10-31-abcdef-j.md; git commit -qam j2
run --member raj; check "只有占位符 → JOURNAL-LESSONS" $'FAIL\tJOURNAL-LESSONS'
sed -i.bak 's/^<必填>$/none/' docs/journal/raj/2026-10-31-abcdef-j.md; rm -f docs/journal/raj/*.bak; git commit -qam j3
run --member raj; check "Lessons: none → PASS" $'RESULT\tPASS'
# 已推送的旧 journal 缺 Lessons 不再报告；只看将推送的提交
git push -q origin feature/j; git fetch -q origin; git switch -q feature/j
printf '# k\n\n## Next\n\nz\n' > docs/journal/raj/2026-10-31-bbbbbb-k.md; git add -A; git commit -qm j4
run --member raj; check "新 journal 缺 Lessons → FAIL" 'bbbbbb-k.md'; checkno "已推送的 journal 不报" 'abcdef-j.md'
# 名册里的 mei 本人在自己的分支上 → 不报
git switch -q feature/b; run --member mei; checkno "Owner 本人不报" 'OTHER-OWNER'
# 分支上有其他成员的 journal（接手）→ WARN TAKEOVER；本人不报
mkdir -p docs/journal/mei; printf '# m\n\n## Lessons\n\nnone\n' > docs/journal/mei/2026-10-30-cccccc-m.md; git add -A; git commit -qm "mei journal"
run --member raj; check "接手他人 MR → TAKEOVER WARN" $'WARN\tTAKEOVER\tfeature/b'; check "TAKEOVER 仍 PASS" $'RESULT\tPASS'
run --member mei; checkno "本人分支不报 TAKEOVER" 'TAKEOVER'
# 功能地图：目标分支有 docs/feature-map.md 后，改源文件而不更新地图、ticket 也没写 `涉及功能: none` → WARN FEATURE-MAP
git switch -q main; printf '# 功能地图\n\n## 功能\n\n### F-run\n\n- 名称：运行\n' > docs/feature-map.md; git add -A; git commit -qm fmap; git push -q origin main; git fetch -q origin
git switch -qc feature/fm1; mkdir -p src; echo 'print(1)' > src/app.py; git add -A; git commit -qm "change app"
run --member raj; check "改源文件未更新地图 → FEATURE-MAP WARN" $'WARN\tFEATURE-MAP\tfeature/fm1'; check "FEATURE-MAP 仍 PASS" $'RESULT\tPASS'
ticket 03-dddddd-d.md raj in-progress feature/fm1; printf '涉及功能: none\n' >> "$d/03-dddddd-d.md"; git add -A; git commit -qm "ticket says none"
run --member raj; checkno "ticket 写 涉及功能: none → 不报" 'FEATURE-MAP'
git switch -q main; git switch -qc feature/fm2; mkdir -p src; echo 'print(2)' > src/app.py; printf '\n### F-new\n\n- 名称：新功能\n' >> docs/feature-map.md; git add -A; git commit -qm "change app and map"
run --member raj; checkno "同一分支更新了地图 → 不报" 'FEATURE-MAP'
git switch -q main; git switch -qc feature/fm3; mkdir -p pkg/tests docs; echo 't' > pkg/tests/test_app.py; echo 'n' > docs/notes.md; git add -A; git commit -qm "tests and docs only"
run --member raj; checkno "只改测试与文档 → 不报" 'FEATURE-MAP'
git switch -q main; git switch -qc feature/fm4; ticket 04-eeeeee-e.md raj in-progress feature/fm4; printf '涉及功能: F-run\n' >> "$d/04-eeeeee-e.md"; mkdir -p src; echo 'print(4)' > src/app.py; git add -A; git commit -qm "ticket names F-run, map unchanged"
run --member raj; check "ticket 写功能 ID 但地图未更新 → 仍 WARN" $'WARN\tFEATURE-MAP\tfeature/fm4'
exit $fail
