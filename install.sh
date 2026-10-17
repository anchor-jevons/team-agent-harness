#!/usr/bin/env bash
# team-agent-harness 一键部署：把规则与模板部署到目标 Git 仓库（不安装 team-* skills）。
#
# 本地：  /path/to/team-agent-harness/install.sh [选项] [目标目录]
# 远程：  curl -fsSL https://raw.githubusercontent.com/anchor-jevons/team-agent-harness/main/install.sh | bash -s -- [选项] [目标目录]
#
# 依赖：bash 3.2+、git、coreutils、sed；python3 仅供部署后的 ticket-status 使用。
# 运行 install.sh --help 查看全部选项。整个脚本包在 main() 中，便于 curl | bash 时完整读入后再执行。

set -o errexit -o pipefail

DEFAULT_REPO="https://github.com/anchor-jevons/team-agent-harness.git"
DEFAULT_REF="main"
DEFAULT_BRANCH="chore/agent-harness"

say()  { printf '%s\n' "$*" >&2; }
info() { printf '==> %s\n' "$*" >&2; }
warn() { printf '警告：%s\n' "$*" >&2; WARNINGS+=("$*"); }
die()  { printf '错误：%s\n' "$*" >&2; exit 1; }

TMP=""
cleanup() { [ -z "$TMP" ] || rm -rf "$TMP"; }

usage() {
  cat <<'EOF'
用法：install.sh [选项] [目标目录]

把 team-agent-harness 的规则与模板部署到目标 Git 仓库（默认为当前目录所在仓库，可在子目录运行）。
不覆盖任何已有文件：已存在且内容不同的文件改写为 <文件>.harness-new，供手工合并。

项目信息（未提供时，有终端则交互询问，否则用默认值或保留占位符）：
  --project-name NAME     项目名称，用于 AGENTS.md 标题（默认：仓库目录名）
  --code-dir DIR          项目代码目录，替换模板中的 project-name/（默认：与项目名同名的子目录存在时用它，否则为仓库根 "."）
  --description TEXT      AGENTS.md 中一句话项目说明
  --members LIST          成员名册，如 "alice:alice-gl,bob:bob-gl"（成员ID[:GitLab 用户名[:备注]]）
  --min-codex-version V   团队要求的 Codex 最低版本（写入 onboarding.md）
  --test-cmd CMD          测试命令（写入 docs/development.md 的“验证”一节）
  --lint-cmd CMD          Lint 命令（同上）
  --stale-days N          in-progress 票陈旧天数（默认 7，与 ticket-status 默认值一致）

来源：
  --ref REF               从远端仓库浅克隆该分支/标签/提交（默认 main）；指定后即使在本地克隆中运行也从远端获取
  --repo URL              harness 仓库地址（默认 https://github.com/anchor-jevons/team-agent-harness.git）
  --source DIR            使用本地的 harness 目录作为来源

Git 与执行：
  --branch NAME           在新分支上提交（默认 chore/agent-harness）；不推送
  --no-branch             只写文件，不建分支、不提交
  --dry-run               只显示将要执行的操作，不写任何文件
  --force                 工作区不干净时仍然继续（只提交本脚本创建的文件）
  -y, --non-interactive   不询问，缺失值用默认值或保留占位符
  -h, --help              显示本帮助
EOF
}

# 把文件 $1 中所有字面量 $2 替换为 $3；找不到时返回 1。纯 bash，值中可以包含 / & | 等字符。
replace_in_file() {
  local f=$1 pat=$2 rep=$3 content
  content=$(cat "$f"; printf x)
  content=${content%x}
  case $content in
    *"$pat"*) ;;
    *) return 1 ;;
  esac
  content=${content//"$pat"/"$rep"}
  printf '%s' "$content" > "$f"
}

# 必须命中的替换：模板结构变化时给出警告，而不是静默跳过。
fill() {
  replace_in_file "$@" || warn "$(basename "$1")：模板中未找到要替换的内容「$2」，请手工填写"
}

trim() {
  local s=$1
  s=${s#"${s%%[![:space:]]*}"}
  s=${s%"${s##*[![:space:]]}"}
  printf '%s' "$s"
}

# 交互询问：ask 变量名 提示 默认值
ask() {
  local __var=$1 prompt=$2 def=$3 ans=""
  if [ -n "$def" ]; then
    printf '%s [%s]: ' "$prompt" "$def" >&2
  else
    printf '%s（可留空）: ' "$prompt" >&2
  fi
  IFS= read -r ans <&3 || ans=""
  ans=$(trim "$ans")
  [ -n "$ans" ] || ans=$def
  printf -v "$__var" '%s' "$ans"
}

list_placeholders() {
  # 列出正文中尚未填写的 <...> 占位符；忽略行内代码与代码块中的写法示例（如 `<rand6>`）。
  local f=$1 label=$2 hits
  # shellcheck disable=SC2016  # 反引号是 sed 正则中的字面量
  hits=$(sed -e '/^```/,/^```/s/.*//' -e 's/`[^`]*`//g' "$f" | grep -n -o '<[^<>]*>' || true)
  [ -n "$hits" ] || return 0
  printf '%s\n' "$hits" | while IFS= read -r h; do
    printf '  %s:%s\n' "$label" "$h"
  done
}

main() {
  WARNINGS=()
  local project_name="" code_dir="" description="" members="" min_codex="" test_cmd="" lint_cmd=""
  local stale_days="" ref="" repo="$DEFAULT_REPO" source_dir="" branch="$DEFAULT_BRANCH"
  local no_branch=0 dry_run=0 force=0 assume_yes=0 target="" ref_given=0
  local set_project=0 set_code=0 set_desc=0 set_members=0 set_codex=0 set_test=0 set_lint=0

  need_arg() { [ $# -ge 2 ] || die "$1 需要一个参数"; }
  while [ $# -gt 0 ]; do
    case $1 in
      --project-name) need_arg "$@"; project_name=$2; set_project=1; shift 2 ;;
      --code-dir) need_arg "$@"; code_dir=$2; set_code=1; shift 2 ;;
      --description) need_arg "$@"; description=$2; set_desc=1; shift 2 ;;
      --members) need_arg "$@"; members=$2; set_members=1; shift 2 ;;
      --min-codex-version) need_arg "$@"; min_codex=$2; set_codex=1; shift 2 ;;
      --test-cmd) need_arg "$@"; test_cmd=$2; set_test=1; shift 2 ;;
      --lint-cmd) need_arg "$@"; lint_cmd=$2; set_lint=1; shift 2 ;;
      --stale-days) need_arg "$@"; stale_days=$2; shift 2 ;;
      --ref) need_arg "$@"; ref=$2; ref_given=1; shift 2 ;;
      --repo) need_arg "$@"; repo=$2; shift 2 ;;
      --source) need_arg "$@"; source_dir=$2; shift 2 ;;
      --branch) need_arg "$@"; branch=$2; shift 2 ;;
      --no-branch) no_branch=1; shift ;;
      --dry-run) dry_run=1; shift ;;
      --force) force=1; shift ;;
      -y|--yes|--non-interactive) assume_yes=1; shift ;;
      -h|--help) usage; exit 0 ;;
      --) shift; [ $# -le 1 ] || die "只能指定一个目标目录"; [ $# -eq 0 ] || target=$1; break ;;
      -*) die "未知选项：$1（见 --help）" ;;
      *) [ -z "$target" ] || die "只能指定一个目标目录"; target=$1; shift ;;
    esac
  done
  [ -n "$target" ] || target=$PWD
  [ -n "$ref" ] || ref=$DEFAULT_REF
  [ -n "$stale_days" ] || stale_days=7
  case $stale_days in ''|*[!0-9]*) die "--stale-days 必须是正整数" ;; esac

  command -v git >/dev/null 2>&1 || die "需要 git"
  TMP=$(mktemp -d "${TMPDIR:-/tmp}/team-agent-harness.XXXXXX") || die "无法创建临时目录"
  trap cleanup EXIT

  # ---------- 目标仓库 ----------
  [ -d "$target" ] || die "目标目录不存在：$target"
  local top
  top=$(cd "$target" && git rev-parse --show-toplevel 2>/dev/null) || die "目标不是 Git 工作区：$target"
  top=$(cd "$top" && pwd -P)

  # ---------- 模板来源 ----------
  local src="" src_ref="" src_commit="" mode="" tmp=$TMP
  if [ -z "$source_dir" ] && [ "$ref_given" = 0 ]; then
    local self=${BASH_SOURCE[0]:-}
    if [ -n "$self" ] && [ -f "$self" ]; then
      local self_dir
      self_dir=$(cd "$(dirname "$self")" && pwd -P)
      [ -f "$self_dir/templates/AGENTS.template.md" ] && source_dir=$self_dir
    fi
  fi
  if [ -n "$source_dir" ]; then
    mode=local
    src=$(cd "$source_dir" && pwd -P) || die "来源目录不存在：$source_dir"
    if git -C "$src" rev-parse --git-dir >/dev/null 2>&1; then
      src_ref=$(git -C "$src" symbolic-ref --short -q HEAD || echo "(detached)")
      src_commit=$(git -C "$src" rev-parse HEAD 2>/dev/null || echo unknown)
      if [ -n "$(git -C "$src" status --porcelain -- templates 2>/dev/null)" ]; then
        src_commit="$src_commit-dirty"
        warn "harness 来源中的 templates/ 有未提交修改，版本记录为 $src_commit"
      fi
    else
      src_ref="(非 Git 目录)"; src_commit=unknown
    fi
    repo=$(git -C "$src" config --get remote.origin.url 2>/dev/null || echo "$src")
    repo=$(printf '%s' "$repo" | sed 's#://[^/@]*@#://#')  # 不记录 URL 中的凭证
  else
    mode=remote
    info "从 $repo 浅克隆 $ref"
    if ! GIT_TERMINAL_PROMPT=0 git clone -q --depth 1 --branch "$ref" "$repo" "$tmp/src" 2>/dev/null; then
      # --branch 不接受提交 SHA；退回按 ref 直接 fetch。
      rm -rf "$tmp/src"
      git init -q "$tmp/src"
      if ! GIT_TERMINAL_PROMPT=0 git -C "$tmp/src" fetch -q --depth 1 "$repo" "$ref" 2>/dev/null; then
        die "无法从 $repo 获取 $ref"
      fi
      git -C "$tmp/src" -c advice.detachedHead=false checkout -q FETCH_HEAD
    fi
    src=$tmp/src
    src_ref=$ref
    src_commit=$(git -C "$src" rev-parse HEAD)
  fi
  local T=$src/templates f
  for f in AGENTS development team issue-tracker domain onboarding skills-README spec ticket adr journal; do
    [ -f "$T/$f.template.md" ] || die "来源中缺少模板：templates/$f.template.md（来源：$src）"
  done
  [ -f "$T/scripts/ticket-status" ] || die "来源中缺少 templates/scripts/ticket-status"
  case "$top/" in "$src/"*) die "目标仓库就是 harness 仓库本身；请指定要部署到的项目仓库" ;; esac

  # ---------- 工作区检查 ----------
  local dirty
  dirty=$(git -C "$top" status --porcelain --untracked-files=all | grep -v '\.harness-new"\{0,1\}$' || true)
  if [ -n "$dirty" ]; then
    if [ "$force" = 1 ]; then
      warn "工作区不干净，因 --force 继续；只提交本脚本创建的文件"
    else
      say "$dirty"
      die "工作区不干净（见上）。请先提交或暂存（git stash -u），或使用 --force"
    fi
  fi

  # ---------- 收集参数 ----------
  local interactive=0
  if [ "$assume_yes" = 0 ] && { exec 3</dev/tty; } 2>/dev/null; then interactive=1; fi
  local default_name
  default_name=$(basename "$top")
  if [ "$interactive" = 1 ]; then
    say "部署 team-agent-harness 到 $top（直接回车使用默认值）"
    [ "$set_project" = 1 ] || ask project_name "项目名称" "$default_name"
  fi
  [ -n "$project_name" ] || project_name=$default_name
  # 代码目录默认值：与项目同名的子目录；否则若在某个一级子目录中运行，取该子目录；否则为仓库根。
  local default_code="." here rel first
  if [ -d "$top/$project_name" ]; then
    default_code=$project_name
  else
    here=$(pwd -P)
    case "$here/" in
      "$top"/?*)
        rel=${here#"$top"/}; first=${rel%%/*}
        case $first in .*|docs) ;; *) [ "$(cd "$target" && pwd -P)" = "$top" ] || default_code=$first ;; esac
        ;;
    esac
  fi
  if [ "$interactive" = 1 ]; then
    [ "$set_code" = 1 ] || ask code_dir "代码目录（相对仓库根，. 表示根目录）" "$default_code"
    [ "$set_desc" = 1 ] || ask description "一句话项目说明" ""
    [ "$set_members" = 1 ] || ask members "成员名册（成员ID:GitLab用户名，逗号分隔）" ""
    [ "$set_codex" = 1 ] || ask min_codex "Codex 最低版本" ""
    [ "$set_test" = 1 ] || ask test_cmd "测试命令" ""
    [ "$set_lint" = 1 ] || ask lint_cmd "Lint 命令" ""
  fi
  [ -n "$code_dir" ] || code_dir=$default_code
  while case $code_dir in ./?*) true ;; *) false ;; esac; do code_dir=${code_dir#./}; done
  while case $code_dir in ?*/) true ;; *) false ;; esac; do code_dir=${code_dir%/}; done
  case $code_dir in
    /*|..|../*|*/../*|*/..) die "--code-dir 必须是仓库内的相对路径：$code_dir" ;;
  esac
  [ "$code_dir" = "." ] || [ -d "$top/$code_dir" ] || warn "代码目录 $code_dir/ 目前不存在"
  if [ "$set_code" = 0 ] && [ "$interactive" = 0 ]; then
    if [ "$code_dir" = "." ]; then
      warn "未找到与项目同名的子目录，代码目录按仓库根处理；如有项目子目录请用 --code-dir 指定"
    elif [ "$code_dir" != "$project_name" ]; then
      warn "代码目录按当前所在子目录推断为 $code_dir/；不对时请用 --code-dir 指定"
    fi
  fi

  # 成员名册
  local roster="" m id gl note rest
  if [ -n "$members" ]; then
    local IFS_SAVE=$IFS; IFS=,
    set -f
    # shellcheck disable=SC2086
    set -- $members
    set +f
    IFS=$IFS_SAVE
    for m in "$@"; do
      m=$(trim "$m"); [ -n "$m" ] || continue
      id=$(trim "${m%%:*}"); rest=""; gl=""; note=""
      case $m in *:*) rest=${m#*:} ;; esac
      gl=$(trim "${rest%%:*}")
      case $rest in *:*) note=$(trim "${rest#*:}") ;; esac
      [ -n "$gl" ] || gl=$id
      case $id in ''|*[!A-Za-z0-9._-]*) die "成员 ID 只能包含字母、数字、. _ -：「$id」" ;; esac
      case $gl in *[!A-Za-z0-9._-]*) die "GitLab 用户名只能包含字母、数字、. _ -：「$gl」" ;; esac
      case $note in *'|'*) die "成员备注不能包含 |：「$note」" ;; esac
      roster="$roster| $id | $gl | $note |"$'\n'
    done
    roster=${roster%$'\n'}
    roster=${roster//"|  |"/"| |"}
  fi

  # ---------- 渲染到临时目录 ----------
  local out=$tmp/out
  mkdir -p "$out/docs/agents/templates" "$out/docs/agents/scripts" "$out/.agents/skills"
  cp "$T/AGENTS.template.md" "$out/AGENTS.md"
  cp "$T/development.template.md" "$out/docs/development.md"
  for f in team issue-tracker domain onboarding; do cp "$T/$f.template.md" "$out/docs/agents/$f.md"; done
  for f in spec ticket adr journal; do cp "$T/$f.template.md" "$out/docs/agents/templates/$f.template.md"; done
  cp "$T/scripts/ticket-status" "$out/docs/agents/scripts/ticket-status"
  chmod 755 "$out/docs/agents/scripts/ticket-status"
  cp "$T/skills-README.template.md" "$out/.agents/skills/README.md"

  # AGENTS.md
  fill "$out/AGENTS.md" $'# Project\n' "# $project_name"$'\n'
  [ -z "$description" ] || fill "$out/AGENTS.md" "<一句话说明项目解决什么问题。>" "$description"
  replace_in_file "$out/AGENTS.md" "采用前需替换项目路径并安装/验证团队技能；本模板不会自行安装技能或授予文件写权限。" \
    "本文件由 team-agent-harness 部署（来源版本见 \`docs/agents/HARNESS-VERSION\`）；团队技能需另行安装与验证，本文件不会自行安装技能或授予文件写权限。" || true
  # 代码目录
  if [ "$code_dir" = "." ]; then
    fill "$out/AGENTS.md" "代码位于 \`project-name/\`，构建和测试在该目录运行。" "代码位于仓库根目录，构建和测试在根目录运行。"
    fill "$out/docs/agents/domain.md" "和 \`project-name/CONTEXT.md\`" "和根目录的 \`CONTEXT.md\`"
    fill "$out/docs/agents/onboarding.md" "从仓库根和 \`project-name/\` 两种目录启动时" "从仓库根和任一子目录启动时"
  fi
  local cd_disp=$code_dir
  [ "$code_dir" != "." ] || cd_disp="仓库根目录"
  for f in AGENTS.md docs/development.md docs/agents/team.md docs/agents/issue-tracker.md docs/agents/domain.md docs/agents/onboarding.md .agents/skills/README.md; do
    if [ "$code_dir" = "." ]; then
      replace_in_file "$out/$f" "\`project-name/\`" "$cd_disp" || true
    else
      replace_in_file "$out/$f" "project-name/" "$code_dir/" || true
    fi
    if grep -q 'project-name' "$out/$f"; then warn "$f 中仍有 project-name，请手工替换"; fi
  done
  # team.md 名册
  [ -z "$roster" ] || fill "$out/docs/agents/team.md" "| <member-id> | <gitlab-username> | <角色，例如 feature 负责人、领域 reviewer> |" "$roster"
  # issue-tracker 陈旧天数
  fill "$out/docs/agents/issue-tracker.md" "<N，团队填写，建议 7>" "$stale_days"
  # onboarding Codex 版本
  [ -z "$min_codex" ] || fill "$out/docs/agents/onboarding.md" "<团队填写，例如 \`codex --version\` 的最低值>" "\`$min_codex\`（用 \`codex --version\` 检查）"
  # development.md 验证命令
  if [ -n "$test_cmd$lint_cmd" ]; then
    local vtext="在${cd_disp}"
    [ "$code_dir" = "." ] || vtext="在 \`$code_dir/\` 目录"
    vtext="$vtext运行："$'\n'
    [ -z "$test_cmd" ] || vtext="$vtext"$'\n'"- 测试：\`$test_cmd\`"
    [ -z "$lint_cmd" ] || vtext="$vtext"$'\n'"- Lint：\`$lint_cmd\`"
    vtext="$vtext"$'\n\n'"改动涉及的其他验证（如集成、手工检查）按需补充。"
    fill "$out/docs/development.md" "<从哪里查找真实测试命令，哪些改动需要哪些验证。>" "$vtext"
  fi
  # 版本记录
  cat > "$out/docs/agents/HARNESS-VERSION" <<EOF
# 由 team-agent-harness install.sh 生成：记录部署所用的 harness 版本。
# 升级时以 commit 为基线对比上游 templates/ 的变化，再经 MR 合入；不要手工改写下列值。
# 模板以 MIT License 发布，Copyright (c) 2026 Jevons Chang / anchor-jevons。
repo=$repo
ref=$src_ref
commit=$src_commit
EOF

  # ---------- 计划 ----------
  local files=(AGENTS.md docs/development.md docs/agents/team.md docs/agents/issue-tracker.md docs/agents/domain.md
    docs/agents/onboarding.md docs/agents/templates/spec.template.md docs/agents/templates/ticket.template.md
    docs/agents/templates/adr.template.md docs/agents/templates/journal.template.md docs/agents/scripts/ticket-status
    .agents/skills/README.md docs/agents/HARNESS-VERSION)
  local create=() same=() newf=() newsame=() ign=() a b
  for f in "${files[@]}"; do
    if [ -d "$top/$f" ]; then die "$f 是目录，无法部署"; fi
    if [ ! -e "$top/$f" ]; then
      create+=("$f")
      if git -C "$top" check-ignore -q --no-index "$f" 2>/dev/null; then ign+=("$f"); fi
      continue
    fi
    a=$(cat "$top/$f"; printf x); b=$(cat "$out/$f"; printf x)
    if [ "$a" = "$b" ]; then same+=("$f"); continue; fi
    if [ -e "$top/$f.harness-new" ]; then
      a=$(cat "$top/$f.harness-new"; printf x)
      if [ "$a" = "$b" ]; then newsame+=("$f.harness-new"); continue; fi
    fi
    newf+=("$f.harness-new")
  done

  for f in .scratch/x/issues/01-abcdef-x.md docs/journal/x/x.md; do
    if git -C "$top" check-ignore -q --no-index "$f" 2>/dev/null; then
      warn ".gitignore 忽略了 ${f%%/x*}/ ；harness 要求它纳入 Git，请调整 .gitignore"
    fi
  done
  [ "${#ign[@]}" = 0 ] || warn "以下文件被 .gitignore 忽略，会写入但不提交：${ign[*]}"
  command -v python3 >/dev/null 2>&1 || warn "未找到 python3；docs/agents/scripts/ticket-status 需要 python3 (>=3.9)"

  info "目标仓库：$top"
  info "来源：$repo  ref=$src_ref  commit=$src_commit（$mode）"
  info "项目：$project_name  代码目录：$code_dir"

  local commit_files=()
  for f in ${create[@]+"${create[@]}"}; do
    case " ${ign[*]} " in *" $f "*) ;; *) commit_files+=("$f") ;; esac
  done

  # ---------- 分支检查（写文件之前）----------
  local cur do_commit=0
  cur=$(git -C "$top" symbolic-ref --short -q HEAD || true)
  if [ "$no_branch" = 0 ] && [ "${#commit_files[@]}" -gt 0 ]; then
    do_commit=1
    git check-ref-format --branch "$branch" >/dev/null 2>&1 || die "无效的分支名：$branch"
    if [ "$cur" != "$branch" ] && git -C "$top" show-ref --verify --quiet "refs/heads/$branch"; then
      die "分支 $branch 已存在。请先 git switch $branch 后重跑，或用 --branch 指定新分支 / --no-branch"
    fi
    if ! git -C "$top" var GIT_COMMITTER_IDENT >/dev/null 2>&1; then
      [ "$dry_run" = 1 ] || die "未配置 git user.name/user.email，无法提交；请先配置，或使用 --no-branch"
      warn "未配置 git user.name/user.email，实际运行时会因无法提交而停止"
    fi
  fi

  if [ "$dry_run" = 0 ] && [ "$interactive" = 1 ] && { [ "${#create[@]}" -gt 0 ] || [ "${#newf[@]}" -gt 0 ]; }; then
    local go=""
    printf '将创建 %s 个文件、生成 %s 个 .harness-new%s。继续？[Y/n] ' "${#create[@]}" "${#newf[@]}" \
      "$([ "$do_commit" = 1 ] && printf '，并在分支 %s 上提交' "$branch")" >&2
    IFS= read -r go <&3 || go=""
    case $go in n|N|no|NO) die "已取消，未写入任何文件" ;; esac
  fi

  # ---------- 执行 ----------
  local verb_create="已创建" verb_new="已生成"
  if [ "$dry_run" = 1 ]; then
    verb_create="将创建"; verb_new="将生成"
    [ "$do_commit" = 0 ] || info "[dry-run] 将切换到新分支 $branch（当前：${cur:-detached HEAD}）并提交 ${#commit_files[@]} 个文件"
  else
    if [ "$do_commit" = 1 ] && [ "$cur" != "$branch" ]; then
      git -C "$top" checkout -q -b "$branch"
      info "已创建并切换到分支 $branch"
    fi
    for f in ${create[@]+"${create[@]}"}; do
      mkdir -p "$top/$(dirname "$f")"
      cp "$out/$f" "$top/$f"
    done
    case " ${create[*]} " in
      *" docs/agents/scripts/ticket-status "*) chmod 755 "$top/docs/agents/scripts/ticket-status" ;;
    esac
    for f in ${newf[@]+"${newf[@]}"}; do
      cp "$out/${f%.harness-new}" "$top/$f"
    done
    if [ "$do_commit" = 1 ]; then
      git -C "$top" add -- "${commit_files[@]}"
      git -C "$top" update-index --chmod=+x -- docs/agents/scripts/ticket-status 2>/dev/null || true
      git -C "$top" commit -q -m "chore: 部署 team-agent-harness 规则与模板（${src_commit:0:12}）" \
        -m "来源：$repo ref=$src_ref commit=$src_commit" -m "由 install.sh 生成；team-* skills 尚未包含。" \
        -- "${commit_files[@]}" || die "提交失败（文件已写入并暂存在分支 ${branch}）；处理后手工 git commit"
      info "已在分支 $branch 提交：$(git -C "$top" rev-parse --short HEAD)"
    fi
  fi

  # ---------- 汇总 ----------
  say ""
  say "======== 部署汇总 ========"
  if [ "${#create[@]}" -gt 0 ]; then say "$verb_create："; for f in "${create[@]}"; do say "  + $f"; done; fi
  if [ "${#same[@]}" -gt 0 ]; then say "已存在且内容相同，跳过："; for f in "${same[@]}"; do say "  = $f"; done; fi
  if [ "${#newsame[@]}" -gt 0 ]; then say "已有相同的待合并文件，跳过："; for f in "${newsame[@]}"; do say "  = $f"; done; fi
  if [ "${#newf[@]}" -gt 0 ] || [ "${#newsame[@]}" -gt 0 ]; then
    say "原文件已存在且不同，未覆盖；新内容${verb_new}在旁边，请手工合并后删除（不会被提交）："
    for f in ${newf[@]+"${newf[@]}"} ${newsame[@]+"${newsame[@]}"}; do say "  ! $f  （对比：diff -u ${f%.harness-new} $f）"; done
  fi
  [ "${#create[@]}" -gt 0 ] || [ "${#newf[@]}" -gt 0 ] || say "没有需要写入的文件（已是最新）。"

  local ph="" one
  for f in AGENTS.md docs/development.md docs/agents/team.md docs/agents/issue-tracker.md docs/agents/domain.md docs/agents/onboarding.md .agents/skills/README.md; do
    case " ${newf[*]} ${newsame[*]} " in
      *" $f.harness-new "*) one=$(list_placeholders "$out/$f" "$f.harness-new") ;;
      *) one=$(list_placeholders "$out/$f" "$f") ;;
    esac
    [ -z "$one" ] || ph="$ph$one"$'\n'
  done
  if [ -n "$ph" ]; then
    say ""
    say "仍需团队填写的占位符（按部署内容统计；docs/agents/templates/ 下的模板保留占位符是预期的）："
    printf '%s' "$ph" >&2
  fi

  if [ "${#WARNINGS[@]}" -gt 0 ]; then
    say ""; say "警告汇总："; for f in "${WARNINGS[@]}"; do say "  - $f"; done
  fi

  local owners="@<gitlab-username>"
  if [ -n "$roster" ]; then
    owners=$(printf '%s\n' "$roster" | sed -n 's/^| [^|]* | \([^ |]*\) |.*/@\1/p' | tr '\n' ' ')
    owners=${owners% }
  fi
  say ""
  say "下一步："
  if [ "$dry_run" = 1 ]; then
    say "  0. 这是 --dry-run，未写入任何文件；去掉 --dry-run 后执行。"
  fi
  if [ "$do_commit" = 1 ]; then
    say "  1. 审阅提交：git -C '$top' show --stat HEAD；补全上面列出的占位符（git commit --amend 或追加提交）。"
  else
    say "  1. 审阅改动：git -C '$top' status；补全上面列出的占位符后自行提交。"
  fi
  if [ "${#newf[@]}" -gt 0 ] || [ "${#newsame[@]}" -gt 0 ]; then
    say "     把 *.harness-new 的内容合并进原文件后删除 *.harness-new。"
  fi
  say "  2. 推送并创建 MR（本脚本不推送）：git push -u origin ${branch}，由团队 review 后合入。"
  say "  3. 建议配置 CODEOWNERS（如 .gitlab/CODEOWNERS）并对目标分支开启「需要 Code Owner 批准」："
  say "       /AGENTS.md       $owners"
  say "       /.agents/skills/ $owners"
  say "       /docs/agents/    $owners"
  say "     并把 main 设为受保护分支（禁止直接推送与强推），在 MR 审批设置中开启「Reset approvals on push」。"
  say "  4. 每位成员按 docs/agents/onboarding.md 完成入组检查，并在 docs/agents/team.md 登记。"
  say "  5. 查看在途工作：git fetch --prune origin && docs/agents/scripts/ticket-status"
  say "  注：team-* skills 尚未发布，本次只部署规则与模板；CONTEXT-MAP.md 与 CONTEXT.md 在首次需要领域术语时再建。"
}

main "$@"
