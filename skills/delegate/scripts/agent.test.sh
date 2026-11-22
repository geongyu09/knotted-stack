#!/usr/bin/env bash
# agent.sh 자체 점검: 가짜 claude, codex, crontab을 PATH 앞에 두어서 토큰을 쓰지 않고 실제 crontab도 건드리지 않는다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export KNOTTED_HOME="$T/home"
mkdir "$T/bin"
cat >"$T/bin/claude" <<'E'
#!/bin/sh
cat >/dev/null
echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"ls"}}]}}'
printf '{"type":"result","result":"결과: PASS (%s)"}\n' "$*"
E
cat >"$T/bin/codex" <<'E'
#!/bin/sh
cat >/dev/null
echo '{"type":"thread.started","thread_id":"thread-123"}'
echo '{"type":"item.completed","item":{"id":"i","type":"command_execution","command":"ls"}}'
prev=""; for a in "$@"; do [ "$prev" = "-o" ] && echo "결과: PASS ($*)" >"$a"; prev=$a; done
E
cat >"$T/bin/crontab" <<E
#!/bin/sh
if [ "\$1" = "-l" ]; then cat "$T/crontab" 2>/dev/null; else cat >"$T/crontab"; fi
E
chmod +x "$T"/bin/*
export PATH="$T/bin:$PATH"
A="$HERE/agent.sh"
ok() { echo "ok - $1"; }
fail() { echo "FAIL - $1"; exit 1; }
task() { printf '목표: x\n종료 조건: y\n'; }

echo "목표: x" | "$A" create --title t 2>/dev/null && fail "종료 조건 없는 과제를 받음"
ok "종료 조건 없는 과제 거부"

id=$(task | "$A" create --title "테스트" --model sonnet)
"$A" wait "$id" | grep -q "done" || fail "create 후 done 아님"
ok "create, wait"

grep -q "작업자 규칙" "$KNOTTED_HOME/agents/$id/prompt-1.md" || fail "worker.md 미포함"
"$A" read "$id" | grep -q -- "--session-id .* --model sonnet" || fail "claude 인자 틀림"
ok "worker.md 첨부, claude 인자, 스트림에서 응답 추출"

"$A" activity "$id" | grep -q "tool.Bash" || fail "activity가 도구 호출을 보여 주지 않음"
ok "activity (claude)"

echo "추가" | "$A" send "$id" >/dev/null; "$A" wait "$id" >/dev/null
"$A" read "$id" | grep -q -- "--resume" || fail "send가 resume을 쓰지 않음"
echo "추가" | "$A" send "$id" >/dev/null; "$A" wait "$id" >/dev/null
echo "추가" | "$A" send "$id" 2>/dev/null && fail "4번째 대화를 허용함"
ok "send는 resume, 대화 3번 제한"

"$A" profiles | grep -q "^review.codex/" || fail "profiles 목록 틀림"
cid=$(task | "$A" create --title "코덱스" --profile review)
"$A" wait "$cid" | grep -q "done.*codex/gpt-6-astra" || fail "프로필이 적용되지 않음"
"$A" read "$cid" | grep -q -- "-m gpt-6-astra -c model_reasoning_effort=xhigh" || fail "codex 인자 틀림"
"$A" activity "$cid" | grep -q "command_execution.ls" || fail "activity (codex) 틀림"
echo "추가" | "$A" send "$cid" >/dev/null; "$A" wait "$cid" >/dev/null
"$A" read "$cid" | grep -q "exec resume thread-123" || fail "codex send가 세션을 재개하지 않음"
task | "$A" create --title x --profile none 2>/dev/null && fail "없는 프로필을 받음"
ok "profiles, codex 프로바이더, codex resume"

"$A" archive "$id" "$cid"
[ -d "$KNOTTED_HOME/archive/$id" ] && [ -z "$("$A" status)" ] || fail "archive 실패"
ok "archive"

sid=$(task | "$A" schedule add --cron "0 9 * * 1" --title "주간 점검" --profile chore)
grep -q "^0 9 \* \* 1 .*/$sid/run.sh' # knotted-stack:$sid\$" "$T/crontab" || fail "crontab 줄 틀림"
"$A" schedule ls | grep -q "$sid.*주간 점검" || fail "schedule ls 틀림"
"$KNOTTED_HOME/schedules/$sid/run.sh"; rid=$(tail -1 "$KNOTTED_HOME/schedules/$sid/log"); "$A" wait "$rid" | grep -q "done.*claude-haiku-5-5.*주간 점검" || fail "schedule run 틀림"
echo "# 남의 줄" >>"$T/crontab"
"$A" schedule rm "$sid"
[ "$(cat "$T/crontab")" = "# 남의 줄" ] && [ -z "$("$A" schedule ls)" ] || fail "schedule rm 틀림"
ok "schedule add, ls, run, rm"
echo "all passed"
