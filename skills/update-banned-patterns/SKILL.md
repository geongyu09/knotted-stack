---
description: ~/Documents/Coding/knotted-stack/rules/writing-rules.md의 금지 패턴을 읽어 check-banned-patterns 훅의 banned-patterns.txt를 동기화한다
argument-hint: "[--dry-run]"
allowed-tools: Bash(cat:*), Bash(grep:*), Bash(wc:*), Bash(diff:*), Bash(cp:*), Read, Edit, Write
---

# 금지 패턴 훅 동기화

`~/Documents/Coding/knotted-stack/rules/writing-rules.md`에 적힌 금지 표현 목록과 `PostToolUse(Write|Edit)` 훅이 사용하는 정규식 목록 `~/Documents/Coding/knotted-stack/hooks/banned-patterns.txt`를 비교하여, 규칙 문서에는 있는데 훅에는 빠진 표현을 정규식으로 추가하고, 규칙 문서에서 사라진 표현의 정규식은 사용자 확인 후 제거한다. 두 파일은 플러그인 원본 저장소에 있으므로 수정 후 플러그인을 업데이트해야 반영된다(`claude plugin update knotted-stack@knotted-stack`).

인자: `$ARGUMENTS`
- `--dry-run`이 포함되어 있으면 변경 계획(추가·삭제·건너뜀 표)만 보고하고 파일은 수정하지 않는다.
- 인자가 없으면 추가는 바로 적용하고, 삭제는 사용자에게 확인받은 뒤 적용한다.

## 현재 상태 (자동 주입)

### 규칙 문서 `~/Documents/Coding/knotted-stack/rules/writing-rules.md`
!`cat ~/Documents/Coding/knotted-stack/rules/writing-rules.md`

### 훅 패턴 목록 `~/Documents/Coding/knotted-stack/hooks/banned-patterns.txt` (줄 번호 포함)
!`cat -n ~/Documents/Coding/knotted-stack/hooks/banned-patterns.txt`

### 훅 스크립트 `~/Documents/Coding/knotted-stack/hooks/check-banned-patterns.sh`
!`cat ~/Documents/Coding/knotted-stack/hooks/check-banned-patterns.sh`

## 동작 순서

### 1. 규칙 문서에서 금지 표현 수집

`writing-rules.md`의 두 영역을 모두 읽는다.

- `## Never Never use the patterns below:` 아래 목록 전체가 1차 대상이다.
- `## anti patterns` 아래 소제목 예시(`혼동하기 쉽습니다`, `발표를 가른다`, `손에 잡히는 기준`, `이런 뜻입니다` 등)처럼 구체 표현으로 적힌 것도 대상이다. 다만 "문장을 짧게 쓰기", "요약 선언문 뒤 반복" 같은 문장 구조 규칙은 정규식으로 잡을 수 없으므로 건너뛴다.

### 2. 각 표현을 정규식으로 변환

훅은 `grep -E -f`(POSIX ERE)로 한 줄씩 패턴을 읽으므로, 아래 규칙을 지켜 변환한다.

- `~`, `(a)`, `(b)`, `(무엇)` 같은 자리표시자와 문장 끝 마침표는 제거하고, 남은 고정 어구만 패턴으로 삼는다. 예: `~를 관통하는` → `관통하는`, `(a)을 가로지르는 (b)` → `가로지르는`.
- 조사는 문자 클래스로 묶는다. `를/을` → `[를을]`, `은/는` → `[은는]`, `이/가` → `[이가]`.
- 활용형은 어간까지만 적어 여러 어미를 한 번에 잡는다. 예: `짊어진다` → `짊어진`, `사실을 마주했다` → `사실을 마주했`.
- 자리표시자가 표현 가운데 끼어 있으면 `.*` 또는 `.{0,12}`로 잇는다. 예: `이번 글에서는 ~를 찾아본다` → `이번 글에서는 .*(찾아본다|알아본다)`.
- 여러 표현이 같은 어간을 공유하면 한 줄에 `|`로 합친다. 예: `~한 셈이다` → `셈이다|셈이었|셈입니다`.
- `\d`, `\b`, 전후방 탐색(lookahead)은 ERE에 없으므로 쓰지 않는다.
- **빈 줄과 주석 줄을 절대 넣지 않는다.** `grep -f`는 빈 줄을 "모든 줄에 매치"로 해석하므로 빈 줄 하나가 전체 파일을 위반으로 만든다.
- 패턴 한 줄이 잡는 범위가 지나치게 넓어 정상 문장까지 걸리면 안 된다. 다음 항목은 정규식으로 만들지 말고 "건너뜀"으로 분류하며 이유를 적는다.
  - 문법 구조 자체를 금지하는 항목: `~은 ~이다`, `3인칭 사용 (그것, 이것, 그, 이)`, `독립 따옴표 선언문`, `상투어로 마무리 하지 않기`, `이 (무엇) : "이런 (무엇)"으로 수정하기`
  - 맥락에 따라 허용되는 항목: `진단하다 (생물의 병을 진단할 때만)`처럼 예외가 명시된 것은 정규식이 예외를 구분하지 못하므로 건너뛴다.
  - 한 글자·두 글자짜리 흔한 단어만 남는 항목
- 이미 존재하는 패턴이 새 표현을 포함해서 잡아 주면 중복 추가하지 않는다. 예: `이것이다`와 `그것이다`는 `[이그]것이다` 한 줄로 이미 처리되어 있다.

### 3. 차이 계산

- **추가**: 규칙 문서에는 있으나 기존 패턴 어느 줄에도 잡히지 않는 표현.
- **삭제 후보**: 기존 패턴 중 규칙 문서의 어떤 항목과도 대응하지 않는 줄. 단, `[가-힣] ?— ?[가-힣]`, `[가-힣] ?:[ \t]*$`, `--`, `·`처럼 기호 규칙(`--` 사용, `":" + 줄바꿈`, `·` 사용)을 구현한 줄은 규칙 문서 항목과 글자가 달라도 대응하는 것으로 본다.
- **건너뜀**: 2단계 기준으로 정규식화하지 않은 항목.

### 4. 적용

`--dry-run`이면 5단계 보고만 하고 끝낸다. 아니면 다음을 수행한다.

1. `cp ~/Documents/Coding/knotted-stack/hooks/banned-patterns.txt ~/Documents/Coding/knotted-stack/hooks/banned-patterns.txt.bak`으로 백업한다.
2. 추가 패턴은 파일 끝에 한 줄씩 붙인다. 기존 줄의 순서는 바꾸지 않는다.
3. 삭제 후보가 있으면 목록을 보여 주고 사용자 확인을 받은 뒤에만 지운다.
4. 검증을 두 가지로 한다.
   - 문법 검사: 새로 추가한 각 줄에 대해 `grep -E -e '<패턴>' /dev/null` 실행 후 종료 코드가 2이면 정규식 오류이므로 고친다. 파일 전체에 대해서도 `grep -E -f ~/Documents/Coding/knotted-stack/hooks/banned-patterns.txt /dev/null`로 한 번 더 확인한다.
   - 오탐 검사: `grep -rE -c -f ~/Documents/Coding/knotted-stack/hooks/banned-patterns.txt.bak wiki/ raw/ docs/`와 새 파일로 같은 명령을 돌려 매치 수를 비교하고, 새 패턴 하나가 수십 건 이상 새로 잡히면 그 패턴이 잡은 문장을 `grep -rnE '<패턴>' wiki/ raw/ docs/ | head`로 확인하여 정상 문장이 섞여 있으면 패턴을 좁힌다. 현재 프로젝트에 `wiki/`, `raw/`, `docs/`가 없으면 오탐 검사에 쓸 글 폴더를 사용자에게 한 번 묻는다.
5. 검증이 끝나면 `.bak` 파일을 지운다. 검증에 실패하면 `.bak`을 되돌리고 원인을 보고한다.

### 5. 보고

아래 형식의 표로 결과를 정리한다.

| 구분 | 규칙 문서 표현 | 정규식 | 비고 |
| --- | --- | --- | --- |
| 추가 | 이해하는 열쇠 | `이해하는 열쇠` | |
| 삭제 | (규칙에 없음) | `...` | 사용자 확인 후 제거 |
| 건너뜀 | 3인칭 사용 | (없음) | 문법 구조 규칙이라 정규식 불가 |

마지막에 최종 패턴 줄 수(변경 전 → 후)와 오탐 검사 결과(매치 수 변화)를 한 줄로 적는다.
