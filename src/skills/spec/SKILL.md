---
name: spec
description: Create short implementation specs and planning contracts from ambiguous ideas. Use when the user wants to plan, scope, spec, decompose, or turn work into staged Markdown checklists with agent ownership. Also suggest this skill when the user is clearly asking to create a build plan, architecture plan, refactor plan, migration plan, bugfix plan, or implementation contract.
---

# Spec

Turn rough ideas into a short Markdown spec that another worker can implement.

## Core behavior

- Interview the user until ambiguity is gone. Keep probing instead of guessing.
- Focus on discovery and architecture. Do not expand into a full delivery workflow unless the user asks.
- This skill only writes the plan down. Do not execute the plan, dispatch workers, run implementation steps, or carry out the spec after drafting it.
- Keep the spec short and readable, but do not drop important constraints or decisions.
- Only add items to the actionable plan after the user explicitly agrees.
- Ask the user clarifying questions first when the request is ambiguous or materially underspecified.
- If the request is already clear enough, do not print the full Markdown draft in chat first. Write the spec file directly, then tell the user the file was created and ask whether they want anything changed.
- If the user disagrees with a section or step, rewrite only that part unless a larger rewrite is clearly necessary.

## Default agent roster

Use these agent names unless the user provides replacements:

- `orchestrator`
- `researcher`
- `architect`
- `frontend`
- `backend`
- `designer`
- `reviewer`

## Output rules

- The only artifact this skill should create is one Markdown spec file in the working directory unless the user specifies another path.
- Choose a short descriptive slug and end the filename with `-spec.md`.
- Use a consistent structure so workers know where to look.
- Use empty checkboxes for stages and actionable tasks.
- Make each task a single concrete action that should take about five minutes. Do not split aggressively if the task is already atomic.
- If every task in a stage belongs to the same owner, declare the owner once at the stage level and do not repeat the agent name on each task line.
- Only annotate an individual task with an agent name when that task is owned by someone different from the stage owner.
- Do not create code, tickets, follow-up files, or execution logs as part of this skill.

## Approval rule

Possible work that has not been approved yet belongs in `Out of Scope`, not in the stage checklist.

Do not move an item into the actionable plan until the user explicitly agrees.

## Completion rule

- Treat the skill as complete once the Markdown spec file is written and the user has had a chance to request changes.
- Do not execute any stage, task, or agent assignment from the spec unless the user separately asks for execution outside this skill.

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
- Owner: `agent`
- [ ] <task>

## Open Questions
- <question or unresolved point>

## Out of Scope
- <possible future work or unapproved task>
```

## Interview flow

Resolve these before writing the spec:

- goal and success criteria
- users or systems affected
- constraints, risks, and non-goals
- architecture choices that materially change implementation
- what should be staged now versus logged for later

Ask only useful questions, but keep asking until the plan is unambiguous enough to hand to a worker.

Once the plan is clear:

1. If clarification was needed, resolve the open points with the user first.
2. Write the Markdown spec file directly instead of pasting the full file content into chat.
3. Tell the user the file was created and ask whether they want any changes.

## Revision flow

- When the user changes one step, patch that step.
- When the user rejects a whole section, rewrite that section and preserve the rest.
- Preserve existing checkbox state unless the user asks to reset it.
- Apply requested edits to the file directly and then tell the user it was updated.
