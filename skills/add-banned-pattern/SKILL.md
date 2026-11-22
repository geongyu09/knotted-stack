---
name: add-banned-pattern
description: "Adds a new banned expression to the `## Never Never use the patterns below:` list in ~/Documents/Coding/knotted-stack/rules/writing-rules.md and immediately mirrors it as a regex into ~/Documents/Coding/knotted-stack/hooks/banned-patterns.txt so the check-banned-patterns hook enforces it, and also appends it to the 절대 사용하지 않는 표현 list in the Aside SOUL file (~/.aside/u/0/SOUL.md). Triggers — \"~~ 이거 금지패턴 추가해\", \"이거 금지 패턴에 추가\", \"금지 패턴에 넣어줘\", \"이 표현 금지해줘\", \"앞으로 ~~ 쓰지 마\", \"금지어 추가\", \"add-banned-pattern\". Use this skill whenever the user asks to ban a specific word or phrase, even if the skill name is not called. Full re-sync of the whole list is handled by /knotted-stack:update-banned-patterns."
version: 0.1.0
---

# Add Banned Pattern — 금지 표현 한 건 추가

사용자가 `"~~" 이거 금지패턴 추가해`처럼 특정 표현을 금지해 달라고 하면, 규칙 문서, 훅 정규식 파일, Aside SOUL 파일 세 곳에 그 표현을 동시에 추가한다.

## 대상 파일

| 파일 | 역할 | 추가 위치 |
| --- | --- | --- |
| `~/Documents/Coding/knotted-stack/rules/writing-rules.md` | 사람이 읽는 규칙 문서 | `## Never Never use the patterns below:` 목록의 맨 끝 |
| `~/Documents/Coding/knotted-stack/hooks/banned-patterns.txt` | `check-banned-patterns.sh` 훅이 `grep -E -f`로 읽는 POSIX ERE 목록 | 파일 맨 끝 |
| `~/.aside/u/0/SOUL.md` | Aside 에이전트가 읽는 말투 규칙 (볼트 밖, git 미추적) | `## 절대 사용하지 않는 표현` 목록의 맨 끝 |

앞의 두 파일은 플러그인 폴더 안에 있어서 훅 검사에서 제외되고, SOUL 파일은 볼트 밖이라 훅 대상이 아니므로 편집 시 훅이 막지 않는다. 앞의 두 파일은 플러그인 원본 저장소를 고치므로 수정 후 플러그인을 업데이트해야 반영된다(`claude plugin update knotted-stack@knotted-stack`).

## 동작 순서

### 1. 표현 추출

- 사용자 메시지에서 큰따옴표(`" "`)·작은따옴표·백틱으로 감싼 부분을 금지 표현으로 본다. 감싼 부분이 여러 개면 각각 별도 항목으로 처리한다.
- 감싼 부분이 없으면 문맥에서 표현을 추정하되, 추정이 애매하면 한 번만 되묻는다. 추측으로 저장하지 않는다.
- 사용자가 대체 표현이나 조건을 함께 말하면(예: `"중요한 것은" 금지, "~이 중요하다"로 고쳐`) 규칙 문서 항목 뒤에 ` : ~로 수정하기` 또는 괄호 설명으로 덧붙인다. 기존 항목 `중요한 것은 ~ : 이 문장은 "~이 중요하다"로 수정해야함.` 형식을 따른다.

### 2. 중복 확인

1. `Read`로 `~/Documents/Coding/knotted-stack/rules/writing-rules.md`의 `## Never Never use the patterns below:` 목록을 읽는다.
2. 같은 표현이 이미 있으면 추가하지 않고 "이미 N번째 줄에 있음"으로 알린다.
3. `~/Documents/Coding/knotted-stack/hooks/banned-patterns.txt`에 대해 `printf '%s\n' '<표현>' | grep -E -f ~/Documents/Coding/knotted-stack/hooks/banned-patterns.txt`를 실행해, 기존 정규식이 이미 잡는 표현이면 규칙 문서에만 추가하고 정규식은 추가하지 않는다.

### 3. 규칙 문서 추가

- `Edit`로 목록의 마지막 항목 줄 뒤에 `  - <표현>` 한 줄을 붙인다. 들여쓰기는 공백 2칸, 기존 항목의 서식(`~` 자리표시자, 마침표 유무)을 그대로 따른다.
- `writing-rules.md`는 파일 끝에 개행이 없을 수 있으므로, `>>`로 붙일 때는 먼저 `tail -c1 ~/Documents/Coding/knotted-stack/rules/writing-rules.md | od -c`로 마지막 바이트가 `\n`인지 확인하고, 아니면 `printf '\n' >> ~/Documents/Coding/knotted-stack/rules/writing-rules.md`로 개행을 넣은 뒤 항목을 붙인다. 붙인 뒤 `tail -3`으로 이전 항목과 같은 줄에 붙지 않았는지 확인한다.
- 목록 이외의 다른 섹션(`## anti patterns` 등)은 건드리지 않는다.

### 3-1. Aside SOUL 파일 추가

- `~/.aside/u/0/SOUL.md`의 `## 절대 사용하지 않는 표현` 섹션을 읽어, 같은 표현이 이미 있으면 추가하지 않는다.
- 없으면 섹션의 마지막 항목 줄 뒤에 `- <표현>` 한 줄을 붙인다. SOUL 파일은 들여쓰기 없이 `- `로 시작하므로 `writing-rules.md`의 공백 2칸을 그대로 쓰지 않는다. 규칙 문서에 붙인 괄호 설명이나 대체 표현도 똑같이 붙인다.
- 섹션이 파일 맨 끝이 아니게 바뀌었을 수 있으므로, `>>` 대신 `Edit`로 섹션 마지막 항목 뒤에 넣는 것을 기본으로 하고, 섹션이 파일 끝일 때만 개행 확인 후 `>>`로 붙인다.
- 파일이 없거나 섹션 제목을 찾지 못하면 건드리지 않고 보고에 "SOUL 건너뜀"과 사유를 적는다.

### 4. 훅 정규식 추가

표현을 아래 규칙으로 POSIX ERE 한 줄로 바꿔 `~/Documents/Coding/knotted-stack/hooks/banned-patterns.txt` 맨 끝에 붙인다. 규칙은 `/knotted-stack:update-banned-patterns` 스킬의 변환 규칙과 같다.

- `~`, `(a)`, `(b)`, `(무엇)` 같은 자리표시자와 문장 끝 마침표는 제거하고 고정 어구만 남긴다. 예: `~를 관통하는` → `관통하는`.
- 조사는 문자 클래스로 묶는다. `를/을` → `[를을]`, `은/는` → `[은는]`, `이/가` → `[이가]`.
- 활용형은 어간까지만 적는다. 예: `짊어진다` → `짊어진`, `사실을 마주했다` → `사실을 마주했`.
- 자리표시자가 가운데 끼면 `.*` 또는 `.{0,12}`로 잇는다. 예: `이번 글에서는 ~를 찾아본다` → `이번 글에서는 .*(찾아본다|알아본다)`.
- `\d`, `\b`, lookahead는 ERE에 없으므로 쓰지 않는다.
- **빈 줄·주석 줄을 절대 넣지 않는다.** `grep -f`는 빈 줄을 "모든 줄 매치"로 해석해 파일 전체가 위반 처리된다. 추가할 때는 `printf '%s\n' '<정규식>' >> ~/Documents/Coding/knotted-stack/hooks/banned-patterns.txt`처럼 개행을 정확히 하나만 붙인다.
- 문법 구조 자체를 금지하는 항목(`~은 ~이다`, `3인칭 사용`), 예외가 명시된 항목(`진단하다`처럼 특정 맥락은 허용), 한두 글자 흔한 단어만 남는 항목은 정규식으로 만들지 않고 규칙 문서에만 추가한 뒤 "건너뜀" 사유를 보고한다.

### 5. 검증

1. 문법 검사: `grep -E -e '<정규식>' /dev/null; echo $?` 의 종료 코드가 2이면 정규식 오류이므로 고친다. 파일 전체도 `grep -E -f ~/Documents/Coding/knotted-stack/hooks/banned-patterns.txt /dev/null`로 한 번 더 확인한다.
2. 매치 확인: `printf '%s\n' '<원래 표현 예문>' | grep -E -e '<정규식>'`로 새 정규식이 실제로 그 표현을 잡는지 확인한다.
3. 오탐 검사: `grep -rnE -e '<정규식>' wiki/ raw/ docs/ | head -15`로 기존 글에서 잡히는 문장을 훑어, 정상 문장이 섞여 있으면 패턴을 좁힌다. 수십 건 이상 잡히면 반드시 좁힌다. 현재 프로젝트에 `wiki/`, `raw/`, `docs/`가 없으면 오탐 검사에 쓸 글 폴더를 사용자에게 한 번 묻는다.
4. 검증 실패 시 방금 붙인 줄을 지우고(`sed -i '' '$d'`) 원인을 보고한다.

### 6. 보고

아래 형식으로 짧게 알린다.

| 구분 | 규칙 문서 표현 | 정규식 | 비고 |
| --- | --- | --- | --- |
| 추가 | 이해하는 열쇠 | `이해하는 열쇠` | 오탐 0건, SOUL 반영 |
| 건너뜀 | ~은 ~이다 | (없음) | 문법 구조 규칙이라 정규식 불가 |

마지막에 `writing-rules.md` 목록 항목 수, `banned-patterns.txt` 줄 수, SOUL 목록 항목 수(변경 전 → 후)를 한 줄로 적는다.

## 제외

- 여러 항목을 한꺼번에 재동기화하거나 삭제하는 작업은 `/knotted-stack:update-banned-patterns` 스킬로 보낸다.
- `## anti patterns`의 문장 구조 규칙(짧은 문장 금지, 요약 선언문 반복 금지 등)을 새로 쓰는 요청은 이 스킬 대상이 아니며, 사용자가 명시하면 해당 섹션을 직접 편집한다.
