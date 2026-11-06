#!/usr/bin/env bash
# 手工检查 install.sh（不接入 CI）：bash tests/install-test.sh
# I1 不覆盖已有且不同的 .harness-new；I2 写入前拒绝越界/悬空符号链接；I3 不改已保留脚本的 index 模式。
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail=0
say() { printf '%s\n' "$*"; }
ok() { say "ok   $1"; }
bad() { say "FAIL $1"; fail=1; }

git_id() {
  git config user.email t@example.com
  git config user.name t
}

run_install() {
  set +e
  out=$("$here/install.sh" --source "$here" -y --project-name demo --code-dir . "$@" 2>&1)
  rc=$?
  set -e
}

# ---------- I1：升级时已有人工合并稿不得覆盖 ----------
git init -q -b main "$tmp/i1"
(
  cd "$tmp/i1"
  git_id
  printf '# Custom project\n' > AGENTS.md
  git add AGENTS.md
  git commit -qm init
)
run_install --branch chore/agent-harness "$tmp/i1"
if [ "$rc" = 0 ] && grep -q . "$tmp/i1/AGENTS.md.harness-new"; then
  ok "I1 首次：不同的 AGENTS.md 生成 sidecar"
else
  bad "I1 首次安装未生成 sidecar（exit $rc）"
  printf '%s\n' "$out"
fi
cp "$tmp/i1/AGENTS.md.harness-new" "$tmp/sidecar.orig"
printf '\nUSER HAND-MERGED NOTES\n' >> "$tmp/i1/AGENTS.md.harness-new"
before=$(cd "$tmp/i1" && git status --porcelain && cksum AGENTS.md AGENTS.md.harness-new)
run_install --no-branch "$tmp/i1"
after=$(cd "$tmp/i1" && git status --porcelain && cksum AGENTS.md AGENTS.md.harness-new)
if [ "$rc" != 0 ] && printf '%s\n' "$out" | grep -q '人工合并稿' \
  && grep -q 'USER HAND-MERGED NOTES' "$tmp/i1/AGENTS.md.harness-new" \
  && grep -q '# Custom project' "$tmp/i1/AGENTS.md" && [ "$before" = "$after" ]; then
  ok "I1 已有不同 sidecar：停止且人工内容与仓库都不变"
else
  bad "I1 升级覆盖或仍写入（exit $rc）"
  printf '%s\n' "$out"
fi
cp "$tmp/sidecar.orig" "$tmp/i1/AGENTS.md.harness-new"
run_install --no-branch "$tmp/i1"
if [ "$rc" = 0 ] && cmp -s "$tmp/i1/AGENTS.md.harness-new" "$tmp/sidecar.orig"; then
  ok "I1 sidecar 与新模板相同：不改写并成功返回"
else
  bad "I1 相同 sidecar 重跑失败（exit $rc）"
  printf '%s\n' "$out"
fi

# ---------- I2：符号链接不得把安装写出仓库；预检在任何写入之前 ----------
outside=$tmp/outside
mkdir -p "$outside/parent-target"
git init -q -b main "$tmp/i2-parent"
(
  cd "$tmp/i2-parent"
  git_id
  ln -s "$outside/parent-target" docs
  git add docs
  git commit -qm 'docs symlink'
)
run_install --no-branch "$tmp/i2-parent"
parent_files=$(find "$outside/parent-target" -type f | wc -l | tr -d ' ')
if [ "$rc" != 0 ] && [ "$parent_files" = 0 ] && [ ! -e "$tmp/i2-parent/AGENTS.md" ] \
  && [ -z "$(git -C "$tmp/i2-parent" status --porcelain)" ]; then
  ok "I2 父目录符号链接指向仓库外：拒绝且仓库内外都没有新文件"
else
  bad "I2 父目录符号链接（exit $rc，外部文件 $parent_files）"
  printf '%s\n' "$out"
  git -C "$tmp/i2-parent" status --porcelain
fi

git init -q -b main "$tmp/i2-leaf"
(
  cd "$tmp/i2-leaf"
  git_id
  ln -s "$outside/missing-agents.md" AGENTS.md
  git add AGENTS.md
  git commit -qm 'dangling AGENTS.md'
)
run_install --no-branch "$tmp/i2-leaf"
if [ "$rc" != 0 ] && [ ! -e "$outside/missing-agents.md" ] && [ ! -e "$tmp/i2-leaf/docs" ] \
  && [ -L "$tmp/i2-leaf/AGENTS.md" ] && [ -z "$(git -C "$tmp/i2-leaf" status --porcelain)" ]; then
  ok "I2 悬空叶子符号链接：拒绝且不在外部创建目标"
else
  bad "I2 悬空叶子符号链接（exit $rc）"
  printf '%s\n' "$out"
  git -C "$tmp/i2-leaf" status --porcelain
fi

git init -q -b main "$tmp/i2-inside"
(
  cd "$tmp/i2-inside"
  git_id
  mkdir real-docs
  ln -s real-docs docs
  git add docs real-docs
  git commit -qm 'in-repo docs symlink'
)
run_install --no-branch "$tmp/i2-inside"
inside_dev=$tmp/i2-inside/real-docs/development.md
if [ "$rc" = 0 ] && [ -f "$inside_dev" ] && python3 - "$tmp/i2-inside" "$inside_dev" <<'PY'
import os, sys
root, path = sys.argv[1:]
root = os.path.realpath(root)
got = os.path.realpath(path)
raise SystemExit(0 if got == root or got.startswith(root + os.sep) else 1)
PY
then ok "I2 解析后仍在仓库内的符号链接：允许写入"
else
  bad "I2 仓库内符号链接被拒绝（exit $rc）"
  printf '%s\n' "$out"
fi

# ---------- I3：不改已保留脚本的 index 模式；新建并提交的脚本才 chmod ----------
git init -q -b main "$tmp/i3"
(
  cd "$tmp/i3"
  git_id
  mkdir -p docs/agents/scripts
  printf 'echo old-ticket-status\n' > docs/agents/scripts/ticket-status
  chmod 644 docs/agents/scripts/ticket-status
  printf 'base\n' > README.md
  git add README.md docs/agents/scripts/ticket-status
  git commit -qm base
  printf 'staged user edit\n' >> README.md
  git add README.md
)
before_mode=$(git -C "$tmp/i3" ls-files -s -- docs/agents/scripts/ticket-status | awk '{print $1}')
run_install --force --branch chore/agent-harness "$tmp/i3"
(
  cd "$tmp/i3"
  mode=$(git ls-files -s -- docs/agents/scripts/ticket-status | awk '{print $1}')
  head_mode=$(git ls-tree HEAD -- docs/agents/scripts/ticket-status | awk '{print $1}')
  push_mode=$(git ls-files -s -- docs/agents/scripts/push-check | awk '{print $1}')
  rule_mode=$(git ls-files -s -- docs/agents/scripts/rule-check | awk '{print $1}')
  cached=$(git diff --cached --raw)
  commit_names=$(git show --name-only --pretty=format: HEAD)
  printf '%s\n' "$mode" > "$tmp/mode"
  printf '%s\n' "$head_mode" > "$tmp/head-mode"
  printf '%s\n' "$push_mode" > "$tmp/push-mode"
  printf '%s\n' "$rule_mode" > "$tmp/rule-mode"
  printf '%s\n' "$cached" > "$tmp/cached"
  printf '%s\n' "$commit_names" > "$tmp/commit-names"
  git status --porcelain > "$tmp/status"
  git ls-files -s > "$tmp/index"
)
mode=$(cat "$tmp/mode")
head_mode=$(cat "$tmp/head-mode")
push_mode=$(cat "$tmp/push-mode")
rule_mode=$(cat "$tmp/rule-mode")
if [ "$rc" = 0 ] && [ "$before_mode" = 100644 ] && [ "$mode" = 100644 ] && [ "$head_mode" = 100644 ] \
  && [ "$push_mode" = 100755 ] && [ "$rule_mode" = 100755 ] \
  && ! grep -q 'ticket-status' "$tmp/cached" \
  && grep -qx 'README.md' <<<"$(git -C "$tmp/i3" diff --cached --name-only)" \
  && ! grep -qx 'README.md' "$tmp/commit-names" \
  && grep -q 'old-ticket-status' "$tmp/i3/docs/agents/scripts/ticket-status" \
  && ! grep -E 'docs/agents/scripts/ticket-status$' "$tmp/status" >/dev/null; then
  ok "I3 完整 index：保留文件仍是 100644，新建脚本为 100755，暂存的 README 未被安装提交"
else
  bad "I3 index 模式（exit $rc，before $before_mode，index $mode，HEAD $head_mode，push $push_mode，rule $rule_mode）"
  printf '%s\n' "$out"
  echo '--- cached ---'
  cat "$tmp/cached"
  echo '--- status ---'
  cat "$tmp/status"
  echo '--- index scripts ---'
  grep 'docs/agents/scripts/' "$tmp/index" || true
fi

exit "$fail"
