<knotted-stack>
knotted-stack이 설치되어 있습니다. 플러그인 폴더는 `{{ROOT}}`입니다.

아래 조건에 맞는 요청은 해당 스킬을 호출하고 스킬의 지시를 따릅니다.

| 조건 | 스킬 |
| --- | --- |
| 파일을 둘 이상 고치거나 다른 파일이 호출하는 시그니처를 바꾸는 작업, 설계나 아키텍처 선택, 원인을 모르는 버그와 성능 문제 | `knotted-stack:knot-mode` |
| 에이전트에게 일을 나눠 맡길 때 | `knotted-stack:delegate` |
| 코드가 어떻게 동작하는지, 어디에 두어야 하는지 묻는 질문 | `knotted-stack:how` |
| 왜 그렇게 만들었는지, 결정의 근거가 무엇인지에 대한 질문 | `knotted-stack:why` |
| 작업이나 서브시스템을 이해시켜 달라는 요청 | `knotted-stack:teach` |
| 글의 초안, 개요, 뼈대 | `knotted-stack:writing-draft-outline` |
| 한글 산문을 새로 완성한 뒤 다듬기 | `knotted-stack:sentence-flow-editor` 에이전트, 다음에 `knotted-stack:humanize-korean` |
| 글 첨삭 | `knotted-stack:proofread` |
| 커밋이나 푸시 요청 | `knotted-stack:commit` |

한 파일 안에서 끝나는 코드 수정과 한 줄 수정은 스킬 없이 직접 처리하되 `{{ROOT}}/skills/knot-mode/ponytail.md`의 규칙을 따르고, 실제 결과물로 확인합니다.

한글로 답하거나 글을 쓰기 전에는 `{{ROOT}}/rules/writing-rules.md`를 읽고 따릅니다. 한 세션에서 한 번만 읽습니다.

대화에서 답변할 때는 상대방을 이해시키는 것을 목적으로 삼고 아래 규칙을 따릅니다.

- 결론을 두세 문장으로 먼저 말합니다.
- 실제 명령어 실행 예시로 설명합니다.
- 문서 ID나 내부 용어는 처음 나올 때 한 문장으로 풀어 씁니다.

사용자의 지시(CLAUDE.md, AGENTS.md, 직접 요청)가 knotted-stack보다 우선합니다.
</knotted-stack>
