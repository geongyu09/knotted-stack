---
name: proofread
description: "A multi-agent pipeline for critiquing Korean writing. It splits the designated piece into sentences, attaches a sentence-critic in parallel to evaluate each sentence, gets the user's confirmation on the direction of fixes, edits the body, and then finishes in the order sentence-flow-editor → humanize-korean. Triggers — \"첨삭해줘\", \"이 글 첨삭\", \"/proofread\". For evaluating a single sentence use sentence-critic alone, and for critiquing prose retrospectives use retro-editor."
argument-hint: "첨삭할 파일 경로 또는 텍스트 (부분 첨삭이면 범위도 함께)"
disable-model-invocation: false
---

# proofread — Sentence-level critique pipeline

When this skill is invoked, you are the **orchestrator**. Sentence evaluation, connection fixes, and AI-tell removal are all delegated to sub-agents; you yourself directly handle only sentence splitting, result collection and organization, user confirmation, and body edits.

## Pipeline flow

```
User command (whole piece or a specified part)
    │
    ▼
[0] Confirm the target   — read the file, fix the critique range and sentence list
    │
    ▼ (run in parallel per sentence)
[1] sentence-critic × N  — one agent per sentence, evaluated against the full text
    │
    ▼
[2] Collect and organize problems — one report ordered 구조 → 문장 → 표기 (퇴고 3단계)
    │
    ▼
[3] Confirm direction (user)  — get confirmation on which remarks to apply
    │
    ▼
[4] Edit the body            — apply only approved remarks (orchestrator does it directly)
    │
    ▼
[5] sentence-flow-editor — identify and fix sentence connection problems
    │
    ▼
[6] humanize-korean skill — remove AI tells → final version
```

## Step-by-step instructions

### [0] Confirm the target

1. Obtain the file path or text the user provided. For a partial critique, target only that range, but **always obtain the full text as well** (sentence-critic requires the full text).
2. Split the target range into sentences. Split on periods, question marks, and exclamation marks, but take care not to split on punctuation inside quotations or code identifiers. Titles, list items, and code blocks are not counted as sentences and are excluded.
3. Make a numbered sentence list and briefly tell the user how many sentences will be evaluated. If there are more than 40 sentences, proceed anyway, only mentioning that the parallel calls will be split into batches.

### [1] Per-sentence evaluation — sentence-critic × N

- For each sentence, invoke one `knotted-stack:sentence-critic` agent with the Agent tool. **These are independent tasks, so bundle multiple calls into one message to run them in parallel.**
- The prompt passed to each agent must include the following.
  - The sentence under evaluation (verbatim)
  - The full text (the path if there is a file path, otherwise the entire body)
  - Which sentence number it is in the piece, and what the preceding and following sentences are
  - The instruction "판정(점수)·이유·단어별 지적을 sentence-critic 출력 형식대로 반환하라"
- Collect the score, verdict, reason list, and per-word remarks from the return values. Retry a failed call once; if it still fails, mark that sentence "평가 실패" and continue.

### [2] Collect and organize problems

When all agents have finished, consolidate the results into one report.

- In sentence-number order: the original sentence, score, verdict, and a summary of the reasons.
- For sentences at 90 or above (acceptable), show only the score in the list and omit the remarks.
- For sentences below 90, organize the remarks in order of severity.
- Group problems that recur across multiple sentences (the same cliché, tone mismatches, etc.) into a separate "공통 문제" section.

Order the report by the 퇴고 3단계 from the technical writing course (`wiki/소프트스킬/기술-문서-다듬기.md`) so the user reviews one kind of problem at a time: 구조 first, then the sentence results above, then 표기. sentence-critic sees one sentence at a time, so the orchestrator itself reads the full text for the 구조 and 표기 sections. If the current project has no `wiki/` folder, skip reading that document and use the checks listed below.

- 구조 (top of the report): answer four questions on the full text. Can a first-time reader follow the order? Is anything missing, or is there a digression that can go? Is an abbreviation or background skipped without explanation? Is there a spot where one example would make it easier? For a technical document, also check that the intro gives background, scope, and target reader, that the ending is a summary, the piece's value, or references and next steps (not "이상입니다" or a thank-you formula), and that the title carries the point and a number when one exists. List only the checks that fail, each with the paragraph it points to.
- 표기 (bottom of the report): mixed 합니다/한다 endings, one concept written two ways (아이디 vs ID), abbreviations not spelled out on first use (widely known ones like PDF and PC are exempt), product names not in their official spelling, and borrowed sentences, ideas, figures, or tables without a source.

### [3] Confirm the direction — always ask the user

After showing the collected report, **always get confirmation before starting edits.** Use the AskUserQuestion tool to ask the following.

- Whether to apply all remarks / apply only the severe ones / let the user pick the items.
- For remarks where judgment on tone or direction could go either way (e.g., a sentence-deletion proposal, a tone change), confirm individually.

Do not apply remarks outside the range the user approved.

A 구조 remark often needs content only the writer has (a missing step, an example, a source). For those, ask whether the user will write it or wants a suggested sentence, and never fill in facts yourself.

### [4] Edit the body

- Apply only the approved remarks; the orchestrator edits the body directly with Edit.
- Follow each remark's "고칠 방향", but do not change the sentence's facts, claims, numbers, or quotations.
- If the original is a file, edit the file directly; if it is inline text, save the revised version as a file in the scratchpad and pass it to the later steps.

### [5] Tidy sentence connections — sentence-flow-editor

- Invoke the `knotted-stack:sentence-flow-editor` agent with the Agent tool to have it identify and fix choppy sentences and awkward connections in the edited body.
- Pass it the edited file path and the instruction "첨삭 반영 직후이니 내용은 그대로 두고 연결만 다듬으라".

### [6] Remove AI tells — humanize-korean

- Finally, run the `knotted-stack:humanize-korean` skill with the Skill tool to make the AI-tell-free result the final version.
- The order is strictly sentence-flow tidying ([5]) → AI-tell removal ([6]). Same as the rule in CLAUDE.md.

### Final report

Along with the final version's location (file path), briefly report the following.

- The number of sentences evaluated, and the number of sentences that were below 90
- The number of remarks applied / the number of remarks the user excluded
- A summary of what additionally changed in steps [5] and [6]

## Exclusions

- A request to evaluate just one sentence → not this skill but a standalone `knotted-stack:sentence-critic` call.
- Critiquing a prose retrospective → `retro-editor`.
- Simple spelling/typo correction, or text of one or two sentences → handle directly.
- Code, JSON, tables, commands, and logs are not treated as sentences.
