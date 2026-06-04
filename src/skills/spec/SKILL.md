---
name: spec
description: Make short implementation specs and planning contracts from vague ideas. Use when user want plan, scope, spec, break down, or turn work into staged Markdown checklists with agent ownership. Also suggest this skill when user clearly ask for build plan, architecture plan, refactor plan, migration plan, bugfix plan, or implementation contract.
---

# Spec

Turn rough idea into short Markdown spec another worker can build.

Local style rule: `references/caveman-style.md`

## Core behavior

- Interview user until ambiguity gone. Keep probing, no guessing.
- Focus on discovery and architecture. Do not expand into full delivery workflow unless user asks.
- This skill only write plan down. Do not execute plan, dispatch workers, run implementation steps, or carry out spec after draft.
- Keep spec short and readable, but keep important constraints and decisions.
- Keep chat output light. Avoid big console paragraphs when file-based prompt clearer.
- Only add items to actionable plan after user explicitly agrees.
- Ask clarifying questions first when request ambiguous or materially underspecified.
- If request already clear enough, do not print full Markdown draft in chat first. Write spec file direct, then tell user file created and ask if they want changes.
- If user disagrees with section or step, rewrite only that part unless bigger rewrite clearly needed.
- If more than 2 clarifying questions in round, write them to separate Markdown question file in working directory so user can answer there, not in chat.
- When re-asking questions in later round, overwrite existing question file unless user asks preserve previous prompts.
- Every artifact this skill writes must follow local caveman style rule, including spec files, question files, and chat replies about generated output.

## Default agent roster

Use these agent names unless user gives replacements:

- `orchestrator`
- `researcher`
- `architect`
- `frontend`
- `backend`
- `designer`
- `reviewer`

## Output rules

- By default, only artifact this skill should create is one Markdown spec file in working directory unless user gives another path.
- Choose short descriptive slug and end filename with `-spec.md`.
- Use consistent structure so workers know where look.
- Use empty checkboxes for stages and actionable tasks.
- Make each task one concrete action taking about five minutes. Do not split hard if task already atomic.
- Make every task directly executable by worker with no extra interpretation. Start with imperative verb and name concrete object, file, endpoint, test, or artifact to touch.
- Ban vague task text like `investigate`, `handle`, `support`, `improve`, `refine`, `prepare`, `wire things up`, `do setup`, or `make it better` unless task also says exact output and target.
- Discovery tasks still must produce concrete artifact, note, list, diff, decision, or file change. No placeholder research-only tasks.
- If every task in stage has same owner, declare owner once at stage level and do not repeat agent name on each task line.
- When stage intentionally mixes owners, write `- Owner: mixed` at stage level and annotate every task with owner using suffix ` (Owner: \`agent\`)`.
- Only annotate individual task with agent name when that task owned by someone different from stage owner.
- Do not create code, tickets, follow-up files, or execution logs as part of this skill.
- Exception: if interview needs more than 2 questions in one round, create or overwrite one Markdown question file for user answers.
- Keep question file compact and easy scan. Prefer numbered prompts with short answer slots.
- Keep question prompts in caveman style too. Short, direct, no filler.

## Approval rule

Possible work not approved yet belongs in `Out of Scope`, not in stage checklist.

Do not move item into actionable plan until user explicitly agrees.

## Completion rule

- Skill complete once Markdown spec file written and user had chance request changes.
- Do not execute any stage, task, or agent assignment from spec unless user separately asks for execution outside this skill.

## Spec template

Use this structure:

```md
# <Title>

## Goal
<1-3 lines>

## Constraints
- <constraint>

## Architecture
- <key design decision>

## Stages
### Stage 1: <name>
- Owner: `agent`
- [ ] <task>

### Stage 2: <name>
- Owner: mixed
- [ ] <task> (Owner: `frontend`)
- [ ] <task> (Owner: `backend`)

## Open Questions
- <question or unresolved point>

## Out of Scope
- <possible future work or unapproved task>
```

Task wording pattern:

- Good: `- [ ] Add POST /tickets route in \`src/api/tickets.ts\` and return stub JSON`
- Good: `- [ ] List current auth entry points in \`docs/auth-audit.md\``
- Bad: `- [ ] Investigate ticket flow`
- Bad: `- [ ] Improve backend`

## Interview flow

Resolve these before writing spec:

- goal and success criteria
- users or systems affected
- constraints, risks, and non-goals
- architecture choices that materially change implementation
- what should be staged now vs logged for later

Ask only useful questions, but keep asking until plan clear enough to hand to worker.

When asking questions:

- If 1-2 short questions, ask in chat.
- If more than 2 questions, write or overwrite Markdown question file, then tell user where answer it.
- Once user says they finished answering file, read it and continue interview or write spec.
- Write questions in caveman style: short, direct, exact.

Once plan clear:

1. If clarification needed, resolve open points with user first.
2. Write Markdown spec file direct instead of pasting full file content into chat.
3. Tell user file created and ask if they want changes.

## Revision flow

- When user changes one step, patch that step.
- When user rejects whole section, rewrite that section and preserve rest.
- Preserve existing checkbox state unless user asks reset it.
- Apply requested edits to file direct, then tell user it was updated.
