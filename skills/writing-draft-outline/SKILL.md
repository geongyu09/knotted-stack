---
name: writing-draft-outline
description: A skill that writes the draft of a piece. When the user specifies the piece's topic, genre, tone, length, and so on, it generates a draft accordingly.
argument-hint: "개괄적으로 글의 구조를 잡아줘. 글의 뼈대를 만들어줘"
disable-model-invocation: false
---

# writing-draft — Writing a draft

Writes a draft for blog writing.

## Sequence of operation

1. Understand what was entered in the prompt to grasp the direction the user has in mind for the piece and the concerns/content that have come up so far.
   1-1. If the user has not said much: in the next step you absolutely must ask the user about the core elements needed to write the piece, such as the piece's direction, its audience, the message to deliver, and the length. Move on to the next step once your understanding is fully complete.
   **[Caution] Never, ever guess what the user thought or felt**
2. Based on what has been written, identify the core elements needed to write a blog post — the direction, the audience, the message to deliver, and so on — and gather the necessary information.
  2-1. For the user's activities, impressions, concerns, thoughts, and the like, consult the existing retrospectives and writing in the user's profile/ folder to understand what the user has been thinking about, what they have been worrying over, what they have been doing, and so on. After that, confirm with the user whether it is okay to structure the piece based on this information.
  2-2. Draw up the questions needed to settle the piece's direction, audience, and the message to deliver, and ask the user.
3. Based on the identified core elements and the collected information, write a structured draft of the piece.
   3-1. **Pick the structure first.** Choose one structure below for `## 글 방향성` and use only its stage labels, in the listed order.

     | Structure | Stage labels (in order) | Fits when |
     | --- | --- | --- |
     | 설명형 | `[도입]`, `[본문]`, `[결론]` | The point of the piece is knowledge the reader takes away: a concept, how something works, a comparison, a tutorial, an opinion. |
     | 문제 해결형 | `[도입]`, `[문제 발생]`, `[문제 정의]`, `[목표 수립]`, `[액션]`, `[결과]`, `[결론]` | The point of the piece is something the writer did: a bug fix, troubleshooting, a performance improvement, a refactoring, a migration, a technical decision in a project. |

     How to choose:
     - If the user names a structure, use it.
     - Look at what most bullets will be about. If they explain how something works, use 설명형. If they follow what the writer tried, changed, and measured, use 문제 해결형.
     - A concept post that starts from a problem the writer hit (e.g. "왜 렌더링이 두 번 되지?" leading to an explanation of StrictMode) is still 설명형; put the problem in `[도입]` as the hook.
     - 문제 해결형 needs an action the writer actually took. If the material has a problem but no action yet, use 설명형 or ask the user.
     - If neither fits (an essay, a book review, a cover letter), propose a stage list to the user before writing instead of forcing one of these.

     What each 문제 해결형 stage holds, and when to drop it (`[도입]`, `[액션]`, `[결론]` are always kept, and at least one of `[문제 발생]` and `[문제 정의]` stays):
     - `[도입]`: the background (the service, the situation, why this piece), the scope, and the target reader.
     - `[문제 발생]`: the moment the problem showed up (a user report, an error, a number that got worse). Drop it when there was no such moment (known tech debt, a planned improvement) and state the problem in `[문제 정의]`.
     - `[문제 정의]`: what the problem is and its cause, with how the writer reproduced, measured, or narrowed it down. Drop it only when the symptom already shows the cause and there was nothing to analyze.
     - `[목표 수립]`: the target and its constraints (a number to reach, what is out of scope and why, options that were ruled out). Drop it when the goal is only "make the problem go away".
     - `[액션]`: what the writer did, in order, including attempts that did not work.
     - `[결과]`: before/after numbers or the change people noticed, and what is still unsolved. Drop it when the outcome adds nothing beyond "the problem is gone". Never invent a number; write `(수치 필요)`.
     - `[결론]`: what the writer learned and what comes next.
     - When a stage is dropped, put its bullets in the neighboring stage. Do not rename, merge, or add stages.

     Rules for every structure:
     - **Never split a stage into sub-topics.** Do not write numbered parts or titled sections such as `[1부: ...]`, `[2부: ...]`, `Part 1`, `1장`, `## 1. ...`. Write each stage as bullets in the order they will appear in the piece, separating topics with a blank line. Do not refer to parts by number anywhere else in the outline either (e.g. "1부에서", "2~6부").
     - In the reply, state in one line which structure was chosen, which stages were dropped, and why.
   3-2. Before saving, check the outline against the structure questions below (퇴고 3단계 step 1 from the technical writing course, `wiki/소프트스킬/기술-문서-다듬기.md`). Fix the outline where a check fails, or ask the user when the fix needs content only they have.
     - Can a first-time reader follow the bullets in order? Is anything missing, and is there a digression that can go?
     - Does the body (`[본문]`, or every stage between `[도입]` and `[결론]`) give the steps and grounds a reader needs to follow along, with the point placed early?
     - For 문제 해결형, does every `[액션]` bullet answer the problem in `[문제 정의]` (or `[문제 발생]`), and does `[결과]` answer `[목표 수립]` when both exist?
     - Does `[도입]` give the background (why this piece), the scope (what it covers), and the target reader (who should read it)?
     - Does `[결론]` close with a summary, the piece's value, or references and next steps, not "이상입니다" or a thank-you formula?
     - For a technical post, does the title carry the point and a number when one exists ("게임 MySQL 샤딩" → "200만 동접 게임을 위한 MySQL 샤딩")? Propose a title change to the user instead of applying it.
4. Save the written draft as a `raw/writing/[outline] 글 제목.md` file. (Name the file based on the piece's title)
   4-1. If the current project has no `raw/writing/` folder, ask the user once where to save the file, and skip reading `profile/` or `wiki/` when that folder does not exist.


## Example result — 설명형

```markdown
# 글 제목

"LLM은 어떻게 개발자가 되는가 — Claude Code라는 하네스의 해부"

## 대상 독자

- LLM에 대해서 관심이 있는 사람
- Claude Code라는 프로젝트에 관심이 있거나 사용해본 적 있는 사람

## 전달하려는 메시지 / 담고싶은 내용

- Claude Code가 Claude 모델을 어떻게 하네스 하여 실제 세상에 영향을 주고, 실제로 개발자처럼 일할 수 있게 만드는가에 대한 정보 전달

## 글 방향성

[도입]

- Claude Code를 처음 썼을 때의 인상 ("모델이 똑똑한 건가?")
- 그런데 써보니 단순히 모델이 똑똑한 게 아니라는 의심
- 이 글의 질문: "Claude Code는 LLM을 어떻게 하네스하는가?"

[본문]

- 모델(뇌) vs 하네스(몸) 비유
- 공식 문서가 쓰는 정확한 표현: "Claude Code는 Claude 주변의 에이전트 하네스 역할을 한다"
- 하네스가 없으면 LLM은 그냥 텍스트 생성기

- 에이전트 루프: 컨텍스트 수집 → 작업 수행 → 결과 검증
- 이 루프가 "개발자처럼 일한다"의 본질
- JS 개발자라면 익숙한 비유로: setInterval이 아니라 while (!done) 같은 것

- 내장 도구 5가지 카테고리
- "도구가 없으면 Claude는 텍스트만 뱉는다"
- 도구 호출(tool use)의 메커니즘 — 여기서 살짝 API 레벨의 이야기

- LLM은 컨텍스트 윈도우가 유한하다
- CLAUDE.md, skills, subagents, 자동 압축
- 이게 왜 "하네스의 공학적 기여"인지

- Skills, MCP, Hooks, Subagents가 각자 에이전트 루프의 어디에 끼어드는가
- 독자가 직접 만질 수 있는 부분

- 커뮤니티가 리버스 엔지니어링으로 분석한 것들 (system prompt 유출, 도구 호출 방식 추정)
- 여기선 신중하게 "추정이다"를 명시하면서
- 실제 의사결정 (예: 왜 CLAUDE.md를 매 요청마다 로드하는가)

[결론]

- 하네스의 관점에서 본 Claude Code의 설계 철학
- LLM 시대의 "애플리케이션"은 이렇게 만들어진다
- 다음 글 예고 (있다면)
```

## Example result — 문제 해결형

```markdown
# 글 제목

"무한 스크롤 목록의 첫 화면 로딩 4.2초를 1.3초로 줄이기"

## 대상 독자

- React로 목록 화면을 만들어 본 프론트엔드 개발자
- 첫 로딩 속도를 측정해서 줄여 본 적이 없는 사람

## 전달하려는 메시지 / 담고싶은 내용

- 측정으로 원인을 좁힌 뒤에 고쳐야 엉뚱한 곳을 고치지 않는다는 경험 공유

## 글 방향성

[도입]

- 서비스 소개와 첫 방문 대부분이 목록 화면으로 들어온다는 사실
- 다루는 범위는 첫 화면 로딩이고, 스크롤 중 성능은 다루지 않음
- 대상 독자

[문제 발생]

- 사용자 피드백 "처음 들어가면 하얀 화면이 오래 보여요"
- 저사양 안드로이드 기기에서 직접 재현했더니 첫 화면까지 4.2초

[문제 정의]

- Lighthouse와 Network 탭으로 측정해 보니 첫 화면에서 쓰지 않는 차트 라이브러리까지 한 번에 내려받고 있었음
- 목록 데이터 요청이 JS 실행이 끝난 뒤에야 시작되는 요청 폭포
- 원인을 두 가지로 좁힌 근거

[목표 수립]

- 같은 기기에서 첫 화면 2초 이하
- 서버 렌더링 도입을 범위에서 뺀 이유 (일정, 인프라)

[액션]

- 라우트 단위 코드 분할과 차트 라이브러리 지연 로딩
- 목록 첫 페이지 요청을 preload로 앞당김
- 시도했다가 되돌린 것: 이미지 lazy loading 범위 조정 (측정해 보니 효과가 없었음)

[결과]

- 첫 화면 4.2초 → 1.3초, 번들 크기 변화
- 아직 해결하지 못한 병목

[결론]

- 원인을 측정으로 좁히고 나서 고친 경험에서 배운 점
- 다음 글 예고: 스크롤 중 성능 (있다면)
```

## Writing workflow

When writing a proper blog post, follow this order:

1. **Clarify the topic**: confirm the topic the user wants and the target audience
2. **Write the outline**: pick the structure and organize the content as ordered bullet points under its stage labels, without sub-topic sections (see 3-1)
3. **Write the draft**: write each section following the guide above
4. **Add code examples**: insert code with explanations where needed
5. **Write the conclusion**: summarize the 3 key points as bullet points
6. **Final review**: check that the tone, structure, and code explanations follow the guide

## Step-by-step guide for writing a piece from a prompt

1. Fix the scope — this conversation, right now. Lock in the audience, length, and depth first.
2. Build the outline — decide in one sentence what the piece centers on, pick the structure (3-1), and build the skeleton as ordered bullets under its stage labels (no sub-topic sections).
3. Gather information — purposefully find only the material each outline bullet needs. (Official docs, web search, direct experiments, etc.)
4. Write the draft — write the actual piece following the tone-and-manner guide.
5. Polish — check against the structure questions in 3-2.
