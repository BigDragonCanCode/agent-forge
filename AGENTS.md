# Repository Guidelines

## Project Structure & Module Organization
`src/skills/` contains the versioned source of each skill. Each skill lives in its own directory with a required `SKILL.md`; some also include `scripts/`, `references/`, `rules/`, `assets/`, or `eval-viewer/`. `scripts/` at the repo root holds maintenance helpers such as vendoring and publishing. Runtime copies may appear under `.claude/skills/`, `.codex/skills/`, or `.agent/skills/`; treat those as generated targets, not source of truth.

## Build, Test, and Development Commands
Use Node 18+.

- `npm run vendor-skill -- <repo> <skill-name>`: download a skill from an external repo into `src/skills/`.
- `npm run publish-skill -- <skill-name> <agent-name>`: copy a local skill into `.claude`, `.codex`, or `.agent` for manual use.
- `bash scripts/publish-skill.sh skill-creator codex`: direct example without `npm`.

There is no single repo-wide build step today. Many skills ship their own helper scripts; read that skill’s `SKILL.md` before running them.

## Coding Style & Naming Conventions
Keep Markdown direct and procedural. Skill directories use lowercase kebab-case such as `slack-gif-creator`; required entry file is always `SKILL.md`. Prefer small, focused helper scripts under a skill-local `scripts/` directory. Shell scripts should be portable Bash with `set -e` unless stricter flags are justified. Preserve existing indentation in touched files; current shell and JSON files use 2 spaces or simple no-indent key/value formatting.

## Agent Workflow Preferences
- Do not ask for approval before normal file edits. Proceed directly with routine code and documentation changes.
- Ask only for dangerous, destructive, or permission-blocked actions.
- The main agent should act primarily as an orchestrator.
- When the user asks to do work, prefer dispatching the task to subagents so the main agent keeps context light and worker context stays fresh.
- Keep orchestration explicit: assign clear ownership and avoid overlapping edit scopes between subagents.

## Testing Guidelines
There is no centralized test runner or coverage gate. Validate changes at the skill level:

- read the target skill’s `SKILL.md` for expected workflow
- run its local helper scripts if present
- for new or changed skills, add or update realistic eval inputs under that skill’s workspace or `evals/` files when the skill supports them

Document manual verification in the PR when automation is absent.

## Commit & Pull Request Guidelines
Recent commits use short, imperative summaries such as `fix vendor-skill.sh` and `added some web skills`. Follow that style: concise subject, no trailing period, lead with the changed area when helpful.

PRs should state:
- what skill or script changed
- why the change was needed
- how you verified it
- any generated directories reviewers can ignore

Include screenshots only when changing HTML review assets or other visual outputs.
