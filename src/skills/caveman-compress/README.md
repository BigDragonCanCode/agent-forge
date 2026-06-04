<p align="center">
  <img src="https://em-content.zobj.net/source/apple/391/rock_1faa8.png" width="80" />
</p>

<h1 align="center">caveman-compress</h1>

<p align="center">
  <strong>shrink memory file. save token every session.</strong>
</p>

---

Skill compress project memory files (`CLAUDE.md`, todos, preferences) into caveman format, so every session auto-load fewer tokens.

Agent read `CLAUDE.md` every session start. File big, cost big. Caveman make file small. Cost stay down forever.

## What It Do

```
/caveman-compress CLAUDE.md
```

```
CLAUDE.md ← compressed in place (fewer tokens every session)
```

Skill overwrites target file directly. No `.original.md` backup file created.

## Benchmarks

Real result from real project files:

| File | Original | Compressed | Saved |
|------|----------:|----------:|------:|
| `claude-md-preferences.md` | 706 | 285 | **59.6%** |
| `project-notes.md` | 1145 | 535 | **53.3%** |
| `claude-md-project.md` | 1122 | 636 | **43.3%** |
| `todo-list.md` | 627 | 388 | **38.1%** |
| `mixed-with-code.md` | 888 | 560 | **36.9%** |
| **Average** | **898** | **481** | **46%** |

All validation pass ✅. Headings, code blocks, URLs, file paths preserve exact.

## Before / After

<table>
<tr>
<td width="50%">

### 📄 Original (706 tokens)

> "I strongly prefer TypeScript with strict mode enabled for all new code. Please don't use `any` type unless there's genuinely no way around it, and if you do, leave a comment explaining the reasoning. I find that taking the time to properly type things catches a lot of bugs before they ever make it to runtime."

</td>
<td width="50%">

### <img src="../../docs/assets/dancing-rock.svg" width="20" height="20" alt="rock"/> Caveman (285 tokens)

> "Prefer TypeScript strict mode always. No `any` unless unavoidable — comment why if used. Proper types catch bugs early."

</td>
</tr>
</table>

**Same instruction. 60% fewer tokens. Every. Single. Session.**

## Security

`caveman-compress` flagged Snyk High Risk because static analysis see subprocess and file I/O patterns. False positive. See [SECURITY.md](./SECURITY.md) for full explanation of what skill do and not do.

## Install

Compress built in with `caveman` plugin. Install `caveman` once, then use `/caveman-compress`.

If need local files, compress skill live at:

```bash
caveman-compress/
```

**Requires:** Python 3.10+

## Usage

```
/caveman-compress <filepath>
```

Examples:
```
/caveman-compress CLAUDE.md
/caveman-compress docs/preferences.md
/caveman-compress todos.md
```

### What files work

| Type | Compress? |
|------|-----------|
| `.md`, `.txt`, `.rst`, `.typ`, `.typst`, `.tex` | ✅ Yes |
| Extensionless natural language | ✅ Yes |
| `.py`, `.js`, `.ts`, `.json`, `.yaml` | ❌ Skip (code/config) |
| `*.original.md` | ❌ Skip (backup files) |
| `LICENSE*` | ❌ Skip (never read or modify) |

## How It Work

```
/caveman-compress CLAUDE.md
        ↓
detect file type        (no tokens)
        ↓
Codex compresses if CLI available, else OpenAI if `OPENAI_API_KEY` set, else Claude       (tokens — one call)
        ↓
validate output         (no tokens)
  checks: headings, code blocks, URLs, file paths, bullets
        ↓
if errors: same model fixes cherry-picked issues only   (tokens — targeted fix)
  does NOT recompress — only patches broken parts
        ↓
retry up to 2 times
        ↓
write compressed → CLAUDE.md
```

Only two things use tokens: initial compress + targeted fix if validation fails. Everything else local Python.

## What Is Preserved

Caveman compress natural language. Never touch:

- Code blocks (` ``` ` fenced or indented)
- Inline code (`` `backtick content` ``)
- URLs and links
- File paths (`/src/components/...`)
- Commands (`npm install`, `git commit`)
- Technical terms, library names, API names
- Headings (exact text preserved)
- Tables (structure preserved, cell text compressed)
- Dates, version numbers, numeric values

## Why This Matter

`CLAUDE.md` load on **every session start**. A 1000-token project memory file cost tokens every single time you open project. Over 100 sessions, that 100,000 tokens overhead just for context you already wrote.

Caveman cut that by ~46% average. Same instruction. Same accuracy. Less waste.

```
┌────────────────────────────────────────────┐
│  TOKEN SAVINGS PER FILE    █████       46% │
│  SESSIONS THAT BENEFIT     ██████████ 100% │
│  INFORMATION PRESERVED     ██████████ 100% │
│  SETUP TIME                █            1x │
└────────────────────────────────────────────┘
```

## Part of Caveman

This skill part of [caveman](https://github.com/JuliusBrussee/caveman) toolkit. Goal: agents use fewer tokens without losing accuracy.

- **caveman** — make agent *speak* like caveman (cuts response tokens ~65%)
- **caveman-compress** — make agent *read* less (cuts context tokens ~46%)
