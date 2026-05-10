---
name: implement
description: Execute one approved stage from a `*-spec.md` implementation spec by finding the requested stage, dispatching the owner named in that stage, and updating checklist progress. Use this whenever the user says things like "implement stage 2", "execute stage 3 from the spec", "work through this staged plan", or wants a spec turned into real code while preserving owner assignments and task tracking.
---

# Implement

Execute a single approved stage from a spec written by the `spec` skill or a compatible `*-spec.md` file.

This skill complements `spec`:

- `spec` writes the staged contract.
- `implement` reads that contract, executes one stage, records decisions, and updates progress.

## Core behavior

- Find the target `*-spec.md` file before doing implementation work. If there is exactly one obvious spec in the working directory, use it. Otherwise ask the user which spec to use.
- Find the requested stage by its heading inside `## Stages`, such as `### Stage 2: API wiring`.
- Execute only the requested stage unless the user explicitly asks for more.
- Respect `Out of Scope`, `Constraints`, and `Open Questions`. Do not silently pull unapproved work into the stage.
- Keep the chat output light. Put durable execution details into files, not long chat recaps.
- Prefer dispatching subagents when the environment supports them. The main agent should orchestrate, keep context small, and integrate results.
- If subagents are unavailable, execute inline while still following the ownership and logging rules below.

## Supported spec format

Assume the spec follows this structure:

- Stage heading: `### Stage N: Name`
- Stage owner line: `- Owner: \`agent\`` or `- Owner: mixed`
- Task line: `- [ ] Task text`
- Mixed-owner task line: `- [ ] Task text (Owner: \`agent\`)`

Treat task ownership as follows:

- Restrict parsing to the `## Stages` section. Do not match incidental mentions of `Stage 2` elsewhere in the file.
- Match stages by number first. Treat the title after `:` as descriptive text, not the primary identifier.
- If the stage owner is a single agent, dispatch one worker for the whole stage.
- If the stage owner is `mixed`, dispatch work per task using the owner on each task line.
- If a task has an explicit owner suffix, that task owner overrides the stage owner.

If the file contains duplicate headings for the requested stage number, stop and ask which one to execute.
If the owner syntax is malformed but still understandable, make the smallest safe interpretation and note it in the work log. If ownership is genuinely unclear, stop and ask.

## Execution flow

1. Locate the spec file and requested stage.
2. Read only the sections needed to execute safely:
   - `Goal`
   - `Constraints`
   - `Architecture`
   - the target stage
   - `Open Questions`
   - `Out of Scope`
3. Build a short execution plan from the unchecked tasks in that stage.
4. Dispatch workers by owner:
   - Single-owner stage: one worker owns the whole stage.
   - Mixed-owner stage: one worker per task owner, with a disjoint task set.
5. Tell each worker to complete its assigned work without expanding scope, and to report:
   - what changed
   - which tasks are complete
   - any implementation decisions the spec left open
   - whether they intentionally chose a simpler working approach for this stage
   - any better or more complex alternative worth considering later
   - any blockers or assumptions
6. Integrate the results.
7. Update the stage checklist in the spec by changing completed items from `- [ ]` to `- [x]`.
8. Append a short work log entry describing what was implemented and any important choices made.

## Work log rules

Create a sibling Markdown log file named `<spec-slug>-worklog.md` the first time implementation begins for a spec. Reuse it on later stages.

Use the log to record decisions the spec intentionally left open. This keeps the spec stable while still leaving an audit trail for implementation choices.

Good log entries are short and concrete:

- what was built
- what assumption was made
- why that choice was reasonable
- whether a simpler implementation was intentionally chosen for speed, safety, or scope control
- what more advanced alternative could replace it later, if that tradeoff would become worthwhile

Example note:

```md
## Stage 2 - Cache and lookup
- Used an in-memory hash map for session lookup because the spec only required temporary in-process storage, and constant-time reads kept the hot path simple.
- A process-external cache could be a better long-term fit if this needs cross-instance consistency later.
```

Do not log obvious trivia or restate the entire diff.
Do not force an "upgrade path" note when the shipped solution is already the right level of complexity. Add it only when the worker intentionally chose a simpler option and sees a meaningful future alternative.

## Checkbox rules

- Only check a task after the code or artifact for that task is actually complete.
- Treat pre-existing `- [x]` items as already done and skip them by default.
- Preserve existing checkbox state outside the requested stage.
- If a task is partially complete, leave it unchecked and mention the partial progress in the work log or final status.
- Do not invent extra checklist items unless the user asks to revise the spec.

## Ambiguity rules

- If the spec leaves an implementation detail open, choose a reasonable approach and record it briefly in the work log.
- When choosing between a minimal working solution and a more optimized one, prefer the option that best fits the stage's scope, risk, and constraints. If the simpler choice is intentional, record the tradeoff and the stronger alternative briefly in the work log.
- Prefer simple, local decisions over opening a planning loop again.
- Stop and ask only when the ambiguity changes behavior, scope, external interfaces, or safety constraints in a material way.

## Dispatch guidance

When spawning workers, assign explicit ownership and keep write scopes disjoint when possible.

For a single-owner stage, give the worker:

- the spec path
- the exact stage heading
- the relevant constraints and architecture notes
- instructions to report completed tasks, implementation decisions, and any intentional tradeoff between a simple shipped solution and a more advanced alternative

For mixed ownership:

- group tasks by owner
- spawn one worker per owner when the write scopes are independent
- if the tasks are tightly coupled, keep orchestration local and execute sequentially while still honoring ownership in the log

Tell workers they are not alone in the codebase and must not revert unrelated changes.

## Completion rule

This skill is complete when:

- the requested stage has been implemented as far as possible
- completed tasks in that stage are checked off in the spec
- implementation decisions are recorded in `<spec-slug>-worklog.md`
- the user receives a short status update with blockers or remaining unchecked tasks

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
