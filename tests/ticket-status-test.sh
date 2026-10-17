#!/usr/bin/env bash
# 手工检查 templates/scripts/ticket-status（不接入 CI）：bash tests/ticket-status-test.sh
# 在临时目录建 bare 远端与若干分支，断言 STALE / ok / READY-WITH-COMMITS 以及目标分支 dropped 时忽略旧副本。
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
script=$here/templates/scripts/ticket-status
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
git init -q --bare -b main "$tmp/origin.git"
git clone -q "$tmp/origin.git" "$tmp/w" 2>/dev/null; cd "$tmp/w"
git config user.email t@example.com; git config user.name t
d=.scratch/demo-abc123/issues
ticket() { # file owner status branch since
  mkdir -p "$d"; printf '# t\n\nOwner: %s\nStatus: %s\nConfirmed-by: None\nSpec: None\nBranch: %s\nSince: %s\n' "$2" "$3" "$4" "$5" > "$d/$1"; }
old=$(date -d '-30 days' +%F 2>/dev/null || date -v-30d +%F)
ticket 01-aaaaaa-a.md None ready-for-agent None None
ticket 02-bbbbbb-b.md None ready-for-agent None None
ticket 03-cccccc-c.md None ready-for-agent None None
git add -A; git commit -qm plan; git push -q origin main
# 01：开工提交已推送、近期 → ok
git switch -qc feature/a; ticket 01-aaaaaa-a.md alice in-progress feature/a "$(date +%F)"
git commit -qam "start aaaaaa"; git push -q origin feature/a
# 02：分支有代码提交但票仍 ready-for-agent → READY-WITH-COMMITS
git switch -q main; git switch -qc feature/b-bbbbbb; echo x > code.txt; git add code.txt
git commit -qm "implement b"; git push -q origin feature/b-bbbbbb
# 03：离开成员分支上陈旧 in-progress → STALE；之后 main 上 dropped → 不再报告
git switch -q main; git switch -qc ken/c; ticket 03-cccccc-c.md ken in-progress ken/c "$old"
GIT_COMMITTER_DATE="$old 12:00" git commit -qam "start cccccc"; git push -q origin ken/c
git remote set-head origin main >/dev/null
fail=0
check() { if grep -q -- "$2" <<<"$out"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
checkno() { if grep -q -- "$2" <<<"$out"; then echo "FAIL $1"; fail=1; else echo "ok   $1"; fi; }
git fetch -q --prune origin; out=$(python3 "$script" 7); echo "$out"
check "01 ok" $'01-aaaaaa-a.md\talice\tfeature/a\t.*\tok\t'
check "02 READY-WITH-COMMITS" $'02-bbbbbb-b.md\t.*READY-WITH-COMMITS'
check "03 STALE" $'03-cccccc-c.md\tken\tken/c\t.*STALE'
git switch -q main; ticket 03-cccccc-c.md ken dropped ken/c "$old"; git commit -qam "drop cccccc"; git push -q origin main
git fetch -q --prune origin; out=$(python3 "$script" 7); echo "$out"
checkno "03 dropped on main → 不报告" '03-cccccc-c.md'
check "01 仍报告" '01-aaaaaa-a.md'
exit $fail
