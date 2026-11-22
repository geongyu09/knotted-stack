---
name: writing-draft-actualization
description: A multi-agent pipeline orchestrator that writes the actual piece based on a broadly written draft and structure.
argument-hint: "이 구조안을 바탕으로 초안을 작성해줘. outline 파일을 바탕으로 초안작성해줘"
disable-model-invocation: false
---

# A command (skill) that writes the draft of a piece using AI

This command uses AI to write a structured draft of a piece based on its written structure plan.

- Structure-plan file to read: the structure-plan file in raw/writing/ with the [outline] prefix
- Draft file to write: raw/writing/[draft] 글 제목.md. Use the outline's main title (the one under `# 글 제목`) as-is for both the file name and the H1. Never pick from the outline's title candidates or invent a new title; if a different title seems better, propose it in the reply instead of applying it.
- If the current project has no `raw/writing/` folder, ask the user once where the outline is and where to save the draft, and skip reading `wiki/` when that folder does not exist.

## What this command does

1. Read the `raw/writing/[outline] 글 제목.md` file to grasp the piece's title, its target audience, the message or content to deliver, and the piece's direction.
   1-1. If the file does not exist or its content is empty, print the message "outline.md 파일을 확인해주세요. 해당 파일 작성을 위해 /knotted-stack:writing-draft-outline 커맨드를 실행하세요." and end the command.
   1-2. If the file exists but even one of the piece's title, target audience, message or content to deliver, or direction cannot be determined, tell the user which element cannot be determined, print the message "outline.md 파일을 확인해주세요. 해당 파일 작성을 위해 /knotted-stack:writing-draft-outline 커맨드를 실행하세요.", and end the command.
2. Write the draft based on the collected information. The outline's `## 글 방향성` is already the piece's structure, so keep its stages and bullet order, and spend the effort on turning the bullets into connected prose that delivers the piece's title, target audience, and the message or content to deliver. Do not restructure the piece on top of the outline. Also, consult the tone and manner guidelines to keep the piece's tone and manner.
   2-1. Stage labels (`[도입]`, `[본문]`, `[문제 발생]`, `[문제 정의]`, `[목표 수립]`, `[액션]`, `[결과]`, `[결론]`) mark the beats of the whole piece's 기승전결, not section titles. Do not turn a stage label or a bullet into a heading by default, and do not add tables, bullet lists, or bold labels that the outline does not have or ask for.
   2-2. A heading tells the reader that the part under it can be read on its own, so add one only over a part that has its own small 기승전결: it opens its own question or situation (기), develops it with what was done or found (승), turns on a problem, limit, or contrast (전), and closes with what it settled (결). Every heading summarizes the core content of everything under it, up to the next heading. A part that is only one beat of the whole piece fails this check (e.g., a three-bullet `[문제 발생]` turned into its own `##` section); write it as paragraphs that continue from the previous part with a transition sentence. Stages that fail the check after a headed part (often `[결과]` and `[결론]` after the last `[액션]` heading) would fall under a heading that does not summarize them, so check them together as one part (the goal recalled, what changed, what fell short, what was learned and what comes next) and give that part its own heading if it passes; if it does not pass, propose in the reply where they should go.
   2-3. If the outline already has headings inside `## 글 방향성`, keep them and their levels, write each part under them with its own small 기승전결, and add no deeper levels. If a part looks too thin for its heading, propose merging it in the reply instead of applying it.
   2-4. For a technical post, also follow the 표기 rules in `wiki/소프트스킬/기술-문서-다듬기.md`: spell out an abbreviation on first use (widely known ones like PDF and PC are exempt), write one concept with one word and keep one ending style, prefer plain words over hard Sino-Korean ones (작일→어제), write what was actually done and its numbers instead of an abstract metaphor, and cite the source of borrowed sentences, ideas, figures, and tables. Never invent a number or a source the outline and the user did not give; leave a `(출처 필요)` or `(수치 필요)` marker instead.
3. Save the written draft to the `raw/writing/[draft] 글 제목.md` file.
4. **Sentence-flow tidying (required).** After saving the draft, you must invoke the `knotted-stack:sentence-flow-editor` agent with the Agent tool and hand it the saved `raw/writing/[draft] 글 제목.md` file. Without changing the content, this agent naturally joins choppy sentences to smooth the flow between sentences, then applies the result to the same file. Do not skip this step.
   4-1. After the sentence flow has been tidied, if the user also wants AI-tell removal (natural Korean polishing), run the `knotted-stack:humanize-korean` skill next. The order is sentence-flow tidying → humanize.
