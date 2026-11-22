#!/usr/bin/env bash
# knotted-stack 위임 실행기: `claude -p` 또는 `codex exec` 세션 하나를 백그라운드 에이전트 하나로 다룬다.
# 상태는 전부 $KNOTTED_HOME/agents/<id>/ 아래 파일로 둔다.
set -euo pipefail

ROOT="${KNOTTED_HOME:-$HOME/.knotted-stack}"
AGENTS="$ROOT/agents"
HERE="$(cd "$(dirname "$0")" && pwd)"
SELF="$HERE/$(basename "$0")"
MAX_TURNS=3 # 한 에이전트와의 대화는 3번까지만 허용한다.

die() { echo "error: $*" >&2; exit 1; }
dir_of() { [ -d "$AGENTS/$1" ] || die "에이전트가 없습니다: $1"; echo "$AGENTS/$1"; }
turns() { find "$1" -name 'prompt-*.md' | wc -l | tr -d ' '; }
# 사용자 프로필 파일이 있으면 그 파일을, 없으면 플러그인에 든 기본 파일을 읽는다.
profiles_file() { [ -f "$ROOT/profiles.json" ] && echo "$ROOT/profiles.json" || echo "$HERE/../profiles.json"; }

state() {
  local d=$1 n
  n=$(turns "$d")
  if [ -f "$d/exit-$n" ]; then
    [ "$(cat "$d/exit-$n")" = 0 ] && echo done || echo failed
  elif kill -0 "$(cat "$d/pid")" 2>/dev/null; then
    echo running
  else
    echo failed
  fi
}

# launch <dir> <turn>
launch() {
  local d=$1 n=$2 model effort args
  model=$(cat "$d/model") effort=$(cat "$d/effort")
  case $(cat "$d/provider") in
    claude)
      args=(claude -p --permission-mode bypassPermissions --output-format stream-json --verbose)
      [ "$n" = 1 ] && args+=(--session-id "$(cat "$d/session")") || args+=(--resume "$(cat "$d/session")")
      [ -n "$model" ] && args+=(--model "$model")
      [ -n "$effort" ] && args+=(--effort "$effort")
      ;;
    codex)
      args=(codex exec)
      # codex의 세션 id는 첫 대화의 스트림에 찍힌다.
      [ "$n" = 1 ] || args+=(resume "$(jq -rR 'fromjson? | select(.type=="thread.started") | .thread_id' "$d/stream-1.jsonl" | head -1)")
      args+=(--json --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox -o "$d/reply-$n.md")
      [ -n "$model" ] && args+=(-m "$model")
      [ -n "$effort" ] && args+=(-c "model_reasoning_effort=$effort")
      args+=(-)
      ;;
    *) die "지원하지 않는 프로바이더: $(cat "$d/provider")" ;;
  esac
  (
    cd "$(cat "$d/cwd")"
    # claude는 최종 응답을 스트림의 result 이벤트에서 꺼내고, codex는 -o 로 직접 쓴다.
    nohup bash -c '
      d=$0 n=$1; shift
      "$@" <"$d/prompt-$n.md" >"$d/stream-$n.jsonl" 2>"$d/stderr-$n.log"; code=$?
      [ -s "$d/reply-$n.md" ] || jq -rR "fromjson? | select(.type==\"result\") | .result // empty" "$d/stream-$n.jsonl" >"$d/reply-$n.md"
      echo $code >"$d/exit-$n"' "$d" "$n" "${args[@]}" >/dev/null 2>&1 &
    echo $! >"$d/pid"
  )
}

cmd_create() {
  local title="" provider="" model="" effort="" cwd="$PWD" branch="" profile=""
  while [ $# -gt 0 ]; do
    case $1 in
      --title) title=$2 ;; --profile) profile=$2 ;; --provider) provider=$2 ;;
      --model) model=$2 ;; --effort) effort=$2 ;;
      --cwd) cwd=$2 ;; --worktree) branch=$2 ;;
      *) die "알 수 없는 옵션: $1" ;;
    esac
    shift 2
  done
  [ -n "$title" ] || die "--title 이 필요합니다."
  if [ -n "$profile" ]; then
    local pf; pf=$(profiles_file)
    jq -e --arg p "$profile" 'has($p)' "$pf" >/dev/null || die "프로필이 없습니다: $profile (agent.sh profiles 로 확인)"
    # 직접 준 옵션이 프로필 값보다 우선한다.
    : "${provider:=$(jq -r --arg p "$profile" '.[$p].provider // ""' "$pf")}"
    : "${model:=$(jq -r --arg p "$profile" '.[$p].model // ""' "$pf")}"
    : "${effort:=$(jq -r --arg p "$profile" '.[$p].effort // ""' "$pf")}"
  fi
  : "${provider:=claude}"
  case $provider in claude | codex) ;; *) die "지원하지 않는 프로바이더: $provider" ;; esac
  local task
  task=$(cat)
  # 목표와 종료 조건이 없는 과제는 받지 않는다.
  grep -q '목표' <<<"$task" || die "과제에 '목표'가 없습니다."
  grep -q '종료 조건' <<<"$task" || die "과제에 '종료 조건'이 없습니다."

  local id d
  id="$(date +%m%d-%H%M%S)-$RANDOM"
  d="$AGENTS/$id"
  mkdir -p "$d"
  if [ -n "$branch" ]; then
    git -C "$cwd" worktree add -q "$ROOT/worktrees/$id" -b "$branch"
    cwd="$ROOT/worktrees/$id"
  fi
  echo "$title" >"$d/title"; echo "$cwd" >"$d/cwd"; echo "$provider" >"$d/provider"
  echo "$model" >"$d/model"; echo "$effort" >"$d/effort"
  uuidgen | tr 'A-Z' 'a-z' >"$d/session"
  # 작업자 규칙은 스크립트가 항상 앞에 붙인다.
  { cat "$HERE/../worker.md"; printf '\n---\n\n# 과제\n\n%s\n' "$task"; } >"$d/prompt-1.md"
  launch "$d" 1
  echo "$id"
}

cmd_send() {
  local d n
  d=$(dir_of "${1:?id가 필요합니다}")
  [ "$(state "$d")" != running ] || die "아직 실행 중입니다. wait 이후에 보내세요."
  n=$(($(turns "$d") + 1))
  [ "$n" -le "$MAX_TURNS" ] || die "대화 한도(${MAX_TURNS}번)를 넘었습니다. archive 후 새 에이전트를 만드세요."
  cat >"$d/prompt-$n.md"
  launch "$d" "$n"
  echo "$1 turn $n"
}

cmd_status() {
  [ -d "$AGENTS" ] || return 0
  local d
  for d in "$AGENTS"/${1:-*}/; do
    [ -d "$d" ] || continue
    d=${d%/}
    printf '%s\t%s\tturn %s/%s\t%s/%s\t%s\n' "$(basename "$d")" "$(state "$d")" "$(turns "$d")" "$MAX_TURNS" \
      "$(cat "$d/provider")" "$(cat "$d/model")" "$(cat "$d/title")"
  done
}

cmd_wait() {
  [ $# -gt 0 ] || die "id가 필요합니다."
  local id
  for id in "$@"; do
    while [ "$(state "$(dir_of "$id")")" = running ]; do sleep 3; done
  done
  for id in "$@"; do cmd_status "$id"; done
}

cmd_read() {
  local d
  d=$(dir_of "${1:?id가 필요합니다}")
  cat "$d/reply-$(turns "$d").md"
  [ "$(state "$d")" != failed ] || { echo "--- stderr ---"; cat "$d/stderr-$(turns "$d").log"; }
}

# activity <id> [줄 수]: 실행 중이거나 끝난 대화의 도구 호출과 발화를 최근 순서로 보여 준다.
cmd_activity() {
  local d
  d=$(dir_of "${1:?id가 필요합니다}")
  jq -rR '
    def short: tostring | gsub("\n"; " ") | .[0:160];
    fromjson?
    | if .type == "assistant" then
        .message.content[]?
        | if .type == "tool_use" then "tool\t\(.name) \(.input | short)"
          elif .type == "text" then "text\t\(.text | short)"
          else empty end
      elif .type == "item.completed" then
        "\(.item.type)\t\(.item.text // .item.command // (.item | del(.id, .type)) | short)"
      else empty end' "$d/stream-$(turns "$d").jsonl" | tail -n "${2:-15}"
}

cmd_profiles() {
  jq -r 'to_entries[] | "\(.key)\t\(.value.provider)/\(.value.model)\t@\(.value.effort // "-")\t\(.value.notes // "")"' "$(profiles_file)"
}

cmd_archive() {
  local id d
  for id in "$@"; do
    d=$(dir_of "$id")
    [ "$(state "$d")" != running ] || kill "$(cat "$d/pid")" 2>/dev/null || true
    mkdir -p "$ROOT/archive"
    mv "$d" "$ROOT/archive/$id"
    case "$(cat "$ROOT/archive/$id/cwd")" in
      "$ROOT/worktrees/"*) echo "worktree는 지우지 않았습니다: $(cat "$ROOT/archive/$id/cwd")" ;;
    esac
  done
}

# schedule add --cron "<식>" <create 옵션...> < 과제 | ls | rm <sid> | run <sid>
# cron이 정한 시각마다 새 에이전트를 만든다. 등록은 사용자 crontab에 한 줄을 추가하는 방식이다.
cmd_schedule() {
  local sub=${1:-ls} S="$ROOT/schedules" sid
  [ $# -gt 0 ] && shift
  case $sub in
    add)
      local cron="" args=() has_cwd=""
      while [ $# -gt 0 ]; do
        case $1 in
          --cron) cron=$2 ;;
          --cwd) has_cwd=1; args+=("$1" "$2") ;;
          *) args+=("$1" "$2") ;;
        esac
        shift 2
      done
      [ -n "$cron" ] || die "--cron 이 필요합니다."
      [ -n "$has_cwd" ] || args+=(--cwd "$PWD")
      sid="s$(date +%m%d%H%M%S)$RANDOM"
      mkdir -p "$S/$sid"
      cat >"$S/$sid/task.md"
      grep -q '종료 조건' "$S/$sid/task.md" || { rm -r "$S/$sid"; die "과제에 '종료 조건'이 없습니다."; }
      printf '%s\n' "${args[@]}" >"$S/$sid/args"
      echo "$cron" >"$S/$sid/cron"
      # crontab 한 줄은 길이 제한이 있어서 PATH는 실행 파일에 적는다.
      printf '#!/bin/sh\nexport PATH=%q KNOTTED_HOME=%q\nexec %q schedule run %s >>%q 2>&1\n' \
        "$PATH" "$ROOT" "$SELF" "$sid" "$S/$sid/log" >"$S/$sid/run.sh"
      chmod +x "$S/$sid/run.sh"
      local tab; tab=$(crontab -l 2>/dev/null || true)
      printf '%s\n' ${tab:+"$tab"} "$cron '$S/$sid/run.sh' # knotted-stack:$sid" | crontab -
      echo "$sid"
      ;;
    run)
      sid=${1:?sid가 필요합니다}
      local args=() line
      while IFS= read -r line; do args+=("$line"); done <"$S/$sid/args"
      cmd_create "${args[@]}" <"$S/$sid/task.md"
      ;;
    ls)
      [ -d "$S" ] || return 0
      for sid in "$S"/*/; do
        [ -d "$sid" ] || continue
        printf '%s\t%s\t%s\n' "$(basename "$sid")" "$(cat "$sid/cron")" "$(tr '\n' ' ' <"$sid/args")"
      done
      ;;
    rm)
      sid=${1:?sid가 필요합니다}
      [ -d "$S/$sid" ] || die "스케줄이 없습니다: $sid"
      # 다 읽은 뒤에 쓴다. 남는 줄이 없을 때 grep이 내는 1은 실패가 아니다.
      local tab; tab=$(crontab -l 2>/dev/null | grep -v "# knotted-stack:$sid\$" || true)
      printf '%s\n' "$tab" | crontab -
      rm -r "${S:?}/$sid"
      ;;
    *) die "사용법: agent.sh schedule add|ls|rm|run" ;;
  esac
}

sub=${1:-}
[ $# -gt 0 ] && shift
case $sub in
  create | send | status | wait | read | activity | profiles | archive | schedule) "cmd_$sub" "$@" ;;
  *) die "사용법: agent.sh create|send|status|wait|read|activity|profiles|archive|schedule" ;;
esac
