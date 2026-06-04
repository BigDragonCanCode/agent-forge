---
name: implement
description: Do one approved stage from `*-spec.md` impl spec by finding asked stage, dispatching named owner in that stage, and updating checklist progress. Use when user say things like "implement stage 2", "execute stage 3 from the spec", "work through this staged plan", or want spec turned into real code while preserving owner assignments and task tracking.
---

# Implement

Do one approved stage from spec written by `spec` skill or compatible `*-spec.md` file.

This skill complements `spec`:

- `spec` write staged contract.
- `implement` read contract, do one stage, record decisions, and update progress.

## Core behavior

- Find target `*-spec.md` file before implementation work. If exactly one obvious spec in working directory, use it. Else ask user which spec.
- Find requested stage by heading inside `## Stages`, like `### Stage 2: API wiring`.
- Do only requested stage unless user explicitly ask more.
- Respect `Out of Scope`, `Constraints`, and `Open Questions`. Do not silently pull unapproved work into stage.
- Keep chat light. Put durable execution detail in files, not long chat recap.
- Prefer dispatching subagents when environment supports. Main agent orchestrate, keep context small, integrate results.
- If subagents unavailable, do inline while still following ownership and logging rules below.

## Supported spec format

Assume spec follow this structure:

- Stage heading: `### Stage N: Name`
- Stage owner line: `- Owner: \`agent\`` or `- Owner: mixed`
- Task line: `- [ ] Task text`
- Mixed-owner task line: `- [ ] Task text (Owner: \`agent\`)`

Treat task ownership as follows:

- Restrict parsing to the `## Stages` section. Do not match incidental mentions of `Stage 2` elsewhere in the file.
- Match stages by number first. Treat the title after `:` as descriptive text, not the primary identifier.
- If stage owner one agent, dispatch one worker for whole stage.
- If stage owner `mixed`, dispatch work per task using owner on each task line.
- If task has explicit owner suffix, that task owner overrides stage owner.

If file has duplicate headings for requested stage number, stop and ask which one.
If owner syntax malformed but still understandable, make smallest safe interpretation and note in work log. If ownership genuinely unclear, stop and ask.

## Execution flow

1. Locate spec file and requested stage.
2. Read only the sections needed to execute safely:
   - `Goal`
   - `Constraints`
   - `Architecture`
   - target stage
   - `Open Questions`
   - `Out of Scope`
3. Build a short execution plan from the unchecked tasks in that stage.
4. Dispatch workers by owner:
   - Single-owner stage: one worker owns the whole stage.
   - Mixed-owner stage: one worker per task owner, with a disjoint task set.
5. Tell each worker to complete its assigned work without expanding scope, and to report:
   - what changed
   - which tasks are complete
   - any implementation decisions spec left open
   - whether they intentionally chose a simpler working approach for this stage
   - any better or more complex alternative worth considering later
   - any blockers or assumptions
6. Integrate results.
7. Update stage checklist in spec by changing completed items from `- [ ]` to `- [x]`.
8. Append a short work log entry describing what was implemented and any important choices made.

## Work log rules

Create a sibling Markdown log file named `<spec-slug>-worklog.md` the first time implementation begins for a spec. Reuse it on later stages.

Use the log to record decisions the spec intentionally left open. This keeps the spec stable while still leaving an audit trail for implementation choices.

Good log entries are short and concrete:

- what built
- what assumption made
- why choice reasonable
- whether simpler implementation intentionally chosen for speed, safety, or scope control
- what more advanced alternative could replace later, if that tradeoff becomes worthwhile

Example note:

```md
## Stage 2 - Cache and lookup
- Used an in-memory hash map for session lookup because the spec only required temporary in-process storage, and constant-time reads kept the hot path simple.
- A process-external cache could be a better long-term fit if this needs cross-instance consistency later.
```

Do not log obvious trivia or restate entire diff.
Do not force "upgrade path" note when shipped solution already right complexity level. Add only when worker intentionally chose simpler option and sees meaningful future alternative.

## Checkbox rules

- Only check task after code or artifact for task actually complete.
- Treat pre-existing `- [x]` items as already done and skip them by default.
- Preserve existing checkbox state outside requested stage.
- If task partially complete, leave unchecked and mention partial progress in work log or final status.
- Do not invent extra checklist items unless user asks revise spec.

## Ambiguity rules

- If spec leaves implementation detail open, choose reasonable approach and record brief in work log.
- When choosing between minimal working solution and more optimized one, prefer option that best fits stage scope, risk, and constraints. If simpler choice intentional, record tradeoff and stronger alternative brief in work log.
- Prefer simple, local decisions over opening planning loop again.
- Stop and ask only when ambiguity changes behavior, scope, external interfaces, or safety constraints in material way.

## Dispatch guidance

When spawning workers, assign explicit ownership and keep write scopes disjoint when possible.

For a single-owner stage, give the worker:

- spec path
- exact stage heading
- the relevant constraints and architecture notes
- instructions to report completed tasks, implementation decisions, and any intentional tradeoff between a simple shipped solution and a more advanced alternative

For mixed ownership:

- group tasks by owner
- spawn one worker per owner when write scopes independent
- if tasks tightly coupled, keep orchestration local and do sequentially while still honoring ownership in log

Tell workers they not alone in codebase and must not revert unrelated changes.

## Completion rule

This skill is complete when:

- requested stage implemented as far as possible
- completed tasks in that stage checked off in spec
- implementation decisions are recorded in `<spec-slug>-worklog.md`
- user receives short status update with blockers or remaining unchecked tasks

## Example

User request:

```text
implement stage 2 from auth-flow-spec.md
```

Expected behavior:

- Read `auth-flow-spec.md`
- Find `### Stage 2: ...`
- Dispatch the owner from that stage, or task owners if the stage says `mixed`
- Implement only that stage
- Check completed boxes in the stage
- Append concise implementation notes to `auth-flow-worklog.md`