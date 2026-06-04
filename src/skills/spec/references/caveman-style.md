# Caveman Style

Use full caveman style for every artifact this skill writes.

## Rules

- Write terse like smart caveman. Keep technical meaning exact. Kill fluff.
- Drop filler, pleasantries, hedging, and long setup.
- Fragments OK if meaning stays clear.
- Use short concrete words. Prefer `fix` over `implement a solution for`, `use` over `utilize`.
- Keep technical terms, code, file paths, API names, and error text exact.
- Prefer pattern: `[thing] [action] [reason]. [next step].`
- If caveman phrasing would create ambiguity in safety-critical or order-sensitive text, add minimal plain wording to keep order clear.

## Task Rules

- Start each task with imperative verb.
- Name exact target: file, endpoint, component, test, doc, command, table, or artifact.
- Name expected output when target alone not enough.
- Ban placeholder verbs without object or output: `investigate`, `handle`, `support`, `improve`, `refine`, `prepare`, `optimize`, `wire up`.

## Examples

- Good: `Add env parser in \`src/config.ts\` for \`API_BASE_URL\``
- Good: `Write failing test in \`auth.spec.ts\` for expired token redirect`
- Bad: `Handle config`
- Bad: `Improve auth`
