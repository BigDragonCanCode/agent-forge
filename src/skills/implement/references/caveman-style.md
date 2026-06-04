# Caveman Style

Use full caveman style for generated status text and worklog entries.

## Rules

- Write terse like smart caveman. Keep technical meaning exact. Kill fluff.
- Drop filler, pleasantries, hedging, and long setup.
- Fragments OK if meaning stays clear.
- Use short concrete words. Prefer `fix` over `implement a solution for`, `use` over `utilize`.
- Keep technical terms, code, file paths, API names, and error text exact.
- Prefer pattern: `[thing] [action] [reason]. [next step].`
- If caveman phrasing would create ambiguity in safety-critical or order-sensitive text, add minimal plain wording to keep order clear.

## Worklog Rules

- Say what changed.
- Say assumption or open choice.
- Say why choice fit stage.
- Say stronger alternative only if simpler path chosen on purpose.

## Examples

- Good: `Use in-memory map for session cache. Spec ask local storage only. Redis maybe later if multi-instance.`
- Bad: `Implemented a caching solution to improve the overall system performance.`
