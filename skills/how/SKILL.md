---
name: how
description: "Use for \"how does X work\", code walkthroughs before changing something, and placement / ownership / layering questions (\"where should this live\", \"which package owns this\", \"is this the right layer\"). Explains subsystem architecture, runtime flow, onboarding mental models. Use why for motivation."
---

# How

Explore the codebase to answer "how does X work?" questions.

If the scope is ambiguous, state your interpretation and explore. The user can redirect.

## 1. Explain

For a small question you can answer by reading a few files, explore and explain it yourself. Otherwise create one agent with the `knotted-stack:delegate` skill (never an `Agent` subagent) that explores and explains in one pass. Its task has `목표` set to the user's question, `종료 조건` set to "the explanation cites `file:line` for every claim about the code", `범위` set to read-only, and this brief:

> You are writing an architectural explanation for a senior engineer. Explore the codebase and write an explanation that a senior engineer unfamiliar with this area could read and walk away with a solid mental model. They should understand the architecture well enough to start working in it confidently. You have read-only access to the codebase.

## 2. Present

Present the agent's output. Light edits for clarity or context from the conversation are fine. Do not substantially rewrite it.

<!-- 출처: pstack (MIT, Lauren Tan, Michael Denyer). licenses/LICENSE-pstack 참고. -->
