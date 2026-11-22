# knotted-stack

개인 하네스 스택을 담은 Claude Code 플러그인입니다. 세션이 시작될 때 짧은 라우팅 지시문을 넣고, 조건에 맞는 진입 스킬이 필요한 파일만 골라 읽습니다.

## 구성

| 영역 | 경로 | 내용 |
| --- | --- | --- |
| 라우팅 | `hooks/routing.md` | 조건과 스킬을 짝지은 표입니다. |
| 개발 | `skills/knot-mode/` | 진입 스킬, 개발 기본 규칙 `ponytail.md`, 플레이북 3개, 원칙 3개입니다. |
| 위임 | `skills/delegate/` | 위임 스킬, 작업자 규칙 `worker.md`, 프로필 `profiles.json`, 실행기 `scripts/agent.sh`입니다. |
| 설명 | `skills/how/`, `skills/why/`, `skills/teach/` | 동작 방식, 결정의 근거, 둘을 엮은 설명입니다. |
| 커밋 | `skills/commit/` | 변경 사항을 확인해 커밋 메시지를 제안하고, 승인을 받은 뒤 커밋과 푸시를 합니다. |
| 글쓰기 | `skills/writing-draft-outline/`, `skills/writing-draft-actualization/`, `skills/proofread/`, `skills/humanize-korean/` | 개요, 본문 작성, 첨삭, AI 문체 제거입니다. |
| 글쓰기 에이전트 | `agents/` | 문장 흐름 편집, 문장 비평, humanize 3종입니다. |
| 글쓰기 규칙 | `rules/writing-rules.md`, `hooks/check-banned-patterns.sh`, `hooks/banned-patterns.txt` | 규칙 문서와, `.md`를 쓰거나 고칠 때 금지 표현을 막는 훅입니다. |
| 규칙 관리 | `skills/add-banned-pattern/`, `skills/update-banned-patterns/` | 금지 표현 추가와 훅 정규식 동기화입니다. |

## 설치

```text
/plugin marketplace add geongyu09/knotted-stack
/plugin install knotted-stack@knotted-stack
```

새 버전을 받으려면 `claude plugin update knotted-stack@knotted-stack`을 실행합니다.

## 라이선스

MIT 라이선스로 배포합니다. 원문은 `LICENSE`에 있습니다.

## 점검

```sh
bash skills/delegate/scripts/agent.test.sh
claude plugin validate .
```

## 가져온 자료

- `skills/how`, `skills/why`, `skills/teach`는 pstack(MIT, Lauren Tan, Michael Denyer)에서 가져와 고쳤습니다.
- `skills/knot-mode/ponytail.md`는 ponytail(MIT, DietrichGebert)에서 가져왔습니다.
- 라이선스 원문은 `licenses/`에 있습니다.
