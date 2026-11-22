#!/bin/bash
# PostToolUse(Write|Edit) hook — knotted-stack 플러그인 rules/writing-rules.md 금지 패턴 검사.
# 위반 발견 시 decision:"block"으로 위반 목록을 에이전트에게 돌려보내 재작성을 강제한다.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')

# 마크다운 산문만 검사
[[ "$FILE" == *.md ]] || exit 0

# 제외: 플러그인 자신의 폴더(규칙/스킬/에이전트 문서가 금지 표현을 예시로 담는다).
# 마켓플레이스 설치 시 캐시 경로와 원본 저장소 경로가 달라서 원본 저장소도 함께 제외한다.
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
case "$FILE" in
  "$PLUGIN_ROOT"/*|"$HOME/Documents/Coding/knotted-stack"/*) exit 0 ;;
esac

# 제외: 규칙/설정 파일 자체, 시스템 문서, 사용자 원문 보존 영역
# CLAUDE.md·profile/index.md 등 프로젝트 지침 문서는 anti-pattern 예시(대시 등)를
# 본문에 담으므로 자기 자신을 검사하면 항상 걸린다. 규칙 문서로서 제외한다.
# profile/communication/(preferences·writing 가이드)과 profile/_history/도 금기 목록
# 자체를 본문에 문서화하므로 같은 이유로 제외한다.
case "$FILE" in
  */.claude/*|*/.aside/*|*/.agents/*|*/.codex/*|*/AGENTS.md|*/context/*|*/profile/retrospective/*|*/CLAUDE.md|*/profile/index.md|*/profile/communication/*|*/profile/_history/*) exit 0 ;;
esac

[ -f "$FILE" ] || exit 0

PATTERNS="$(cd "$(dirname "$0")" && pwd)/banned-patterns.txt"
[ -f "$PATTERNS" ] || exit 0

# 검사 전 전처리: 코드 블록 내부 제외, 인라인 코드·HTML 주석 마커·URL 제거,
# 마크다운 구분선/표 구분 행/frontmatter 경계(--- 등) 제외
# URL은 금지 패턴(예: `--`)이 아니라 링크 주소이므로 통째로 지운다
# (Storybook 프리뷰 `fe-feature--369.…` 같은 봇 생성 링크가 매번 걸리던 문제).
VIOLATIONS=$(awk '
  /^```/ { code = !code; next }
  code { next }
  {
    line = $0
    gsub(/`[^`]*`/, "", line)
    gsub(/<!--|-->/, "", line)
    gsub(/https?:\/\/[^ \t)>\]"\x27]+/, "", line)
    if (line ~ /^[ \t]*[-|: \t]+$/) next
    print NR ": " line
  }
' "$FILE" | grep -E -f "$PATTERNS" | head -15)

if [ -n "$VIOLATIONS" ]; then
  jq -n --arg v "$VIOLATIONS" --arg f "$FILE" --arg r "$PLUGIN_ROOT/rules/writing-rules.md" \
    '{decision: "block", reason: ("금지 패턴 위반(" + $r + "): " + $f + " 에서 아래 표현이 발견되었습니다. 규칙 파일의 anti-pattern 목록을 다시 읽고, 해당 문장을 다른 표현으로 고쳐 파일을 수정하세요.\n\n" + $v)}'
fi
exit 0
