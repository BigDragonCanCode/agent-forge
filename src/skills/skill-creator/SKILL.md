---
name: skill-creator
description: Make new skills, improve old skills, measure skill performance. Use when user want create skill from zero, edit or optimize skill, run evals to test skill, benchmark skill with variance analysis, or optimize skill description for better triggering.
---

# Skill Creator

Skill for making new skills and improving them over time.

High level process:

- Decide what skill do and rough how do it
- Write draft skill
- Make few test prompts and run claude-with-access-to-the-skill on them
- Help user judge results, both qualitative and quantitative
  - While runs happen in background, draft quantitative evals if none exist (or reuse/change existing ones if needed). Then explain them to user (or explain existing ones)
  - Use the `eval-viewer/generate_review.py` script to show user results and quantitative metrics
- Rewrite skill from user feedback on results (and from obvious problems shown by benchmarks)
- Repeat until satisfied
- Expand test set and try again bigger scale

Your job with this skill: figure out where user is in this process, then jump in and help move them forward. Maybe user says "I want make skill for X". You can help narrow meaning, write draft, write tests, decide evaluation, run prompts, repeat.

Or maybe user already has draft skill. Then go straight to eval/iterate loop.

Be flexible. If user says "I don't need many evaluations, just vibe with me", do that instead.

After skill done (order flexible), you can also run skill description improver. Separate script exists. Use it to optimize skill triggering.

Cool? Cool.

## Communicating with the user

Skill creator may be used by people with very different comfort with coding jargon. If you have not heard, there is new trend: Claude power makes plumbers open terminals, parents and grandparents google "how to install npm". But many users still fairly computer-literate.

So watch context cues and match phrasing. Default rough guide:

- "evaluation" and "benchmark" maybe borderline, but OK
- for "JSON" and "assertion" you want strong cues user knows those before using without explanation

OK to briefly explain terms if unsure. Clarify with short definition if user may not get it.

---

## Creating a skill

### Capture Intent

Start by understanding user intent. Current conversation may already contain workflow user wants capture (example: "turn this into a skill"). If yes, first extract answers from conversation history: tools used, step sequence, corrections user made, seen input/output formats. User may fill gaps, and should confirm before next step.

1. What should this skill enable Claude to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What's expected output format?
4. Should we set up test cases to verify skill works? Skills with objectively verifiable outputs (file transforms, data extraction, code generation, fixed workflow steps) gain from test cases. Skills with subjective outputs (writing style, art) often do not. Suggest right default from skill type, but let user choose.
5. Where should skill be created? If user has no preference, default to `src/skills`.

### Interview and Research

Ask ahead about edge cases, input/output formats, example files, success criteria, dependencies. Wait to write test prompts until this part solid.

Check available MCPs. If useful for research (docs search, similar skills, best practices), research in parallel via subagents if available, else inline. Arrive with context so user carries less burden.

### Write the SKILL.md

From user interview, fill these parts:

- **name**: Skill identifier
- **description**: When trigger, what it does. This is main trigger mechanism. Include both what skill does AND specific contexts for when to use it. Put all "when to use" info here, not in body. Note: right now Claude tends to undertrigger skills. To fight that, make descriptions a little pushy. Example: instead of "How to build a simple fast dashboard to display internal Anthropic data.", write "How to build a simple fast dashboard to display internal Anthropic data. Make sure to use this skill whenever the user mentions dashboards, data visualization, internal metrics, or wants to display any kind of company data, even if they don't explicitly ask for a 'dashboard.'"
- **compatibility**: Required tools, dependencies (optional, rare)
- **the rest of the skill :)**

### Skill Writing Guide

#### Anatomy of a Skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/    - Executable code for deterministic/repetitive tasks
    ├── references/ - Docs loaded into context as needed
    └── assets/     - Files used in output (templates, icons, fonts)
```

#### Progressive Disclosure

Skills use three-level loading:
1. **Metadata** (name + description) - Always in context (~100 words)
2. **SKILL.md body** - In context whenever skill triggers (<500 lines ideal)
3. **Bundled resources** - As needed (unlimited, scripts can run without loading)

Word counts approximate. Going longer if needed is fine.

**Key patterns:**
- Keep SKILL.md under 500 lines. If near limit, add more hierarchy and clear pointers for where model using skill should go next.
- Reference files clearly from SKILL.md and say when to read them
- For big reference files (>300 lines), include table of contents

**Domain organization**: If skill supports many domains/frameworks, organize by variant:
```
cloud-deploy/
├── SKILL.md (workflow + selection)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```
Claude reads only relevant reference file.

#### Principle of Lack of Surprise

Should go without saying: skills must not contain malware, exploit code, or anything that could compromise system security. Skill content should not surprise user beyond described intent. Do not help create misleading skills or skills meant to enable unauthorized access, data exfiltration, or other malicious acts. Things like "roleplay as an XYZ" are OK though.

#### Writing Patterns

Prefer imperative instructions.

**Defining output formats** - You can do it like this:
```markdown
## Report structure
ALWAYS use this exact template:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

**Examples pattern** - Examples help. You can format like this (but if examples use "Input" and "Output" you may want slight variation):
```markdown
## Commit message format
**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

### Writing Style

Explain to the model why things matter instead of hitting it with dusty MUSTs. Use theory of mind. Make skill general, not too narrow to examples. Write draft first, then revisit with fresh eyes and improve.

### Test Cases

After writing skill draft, make 2-3 realistic test prompts, the kind a real user would say. Share with user: [you don't have to use this exact language] "Here are a few test cases I'd like to try. Do these look right, or do you want to add more?" Then run them.

Save test cases to `evals/evals.json`. Do not write assertions yet, only prompts. Draft assertions in next step while runs happen.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

See `references/schemas.md` for full schema (including `assertions`, which you add later).

## Running and evaluating test cases

This section is one continuous sequence. Do not stop halfway. Do NOT use `/skill-test` or any other testing skill.

Put results in `<skill-name>-workspace/` as sibling to skill directory. Inside workspace, organize by iteration (`iteration-1/`, `iteration-2/`, etc.), and inside each, each test case gets directory (`eval-0/`, `eval-1/`, etc.). Do not create everything upfront, only as needed.

### Step 1: Spawn all runs (with-skill AND baseline) in the same turn

For each test case, spawn two subagents in same turn: one with skill, one without. Important: do not run with-skill first and baseline later. Launch all at once so all finish around same time.

**With-skill run:**

```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Outputs to save: <what the user cares about — e.g., "the .docx file", "the final CSV">
```

**Baseline run** (same prompt, baseline depends on context):
- **Creating a new skill**: no skill at all. Same prompt, no skill path, save to `without_skill/outputs/`.
- **Improving an existing skill**: old version. Before editing, snapshot skill (`cp -r <skill-path> <workspace>/skill-snapshot/`), then point baseline subagent to snapshot. Save to `old_skill/outputs/`.

Write `eval_metadata.json` for each test case (assertions can stay empty now). Give each eval a descriptive name for what it tests, not just "eval-0". Use that name for directory too. If this iteration has new or changed prompts, create these files for each new eval directory; do not assume previous iteration carries them over.

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

### Step 2: While runs are in progress, draft assertions

Do not sit idle while runs finish. Use time. Draft quantitative assertions for each test case and explain them to user. If assertions already exist in `evals/evals.json`, review and explain what they check.

Good assertions are objective and descriptively named. They should read clearly in benchmark viewer so quick glance tells what each checks. Subjective skills (writing style, design quality) are better judged qualitatively; do not force assertions where human judgment needed.

Update `eval_metadata.json` files and `evals/evals.json` with assertions after drafting. Also explain to user what viewer will show: both qualitative outputs and quantitative benchmark.

### Step 3: As runs complete, capture timing data

When each subagent task completes, you get notification with `total_tokens` and `duration_ms`. Save immediately to `timing.json` in run directory:

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

Only chance to capture this data. It comes through task notification and is not saved elsewhere. Process each notification when it arrives, not later in batch.

### Step 4: Grade, aggregate, and launch the viewer

When all runs finish:

1. **Grade each run** — spawn grader subagent (or grade inline) that reads `agents/grader.md` and checks each assertion against outputs. Save results to `grading.json` in each run directory. In `grading.json`, expectations array must use fields `text`, `passed`, and `evidence` exactly. Not `name`/`met`/`details` or other variants. Viewer depends on exact field names. If assertion can be checked programmatically, write and run script instead of eyeballing. Faster, more reliable, reusable across iterations.

2. **Aggregate into benchmark** — run aggregation script from skill-creator directory:
   ```bash
   python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```
   This makes `benchmark.json` and `benchmark.md` with pass_rate, time, and tokens for each configuration, including mean ± stddev and delta. If making `benchmark.json` manually, see `references/schemas.md` for exact viewer schema.
Put each with_skill version before baseline counterpart.

3. **Do analyst pass** — read benchmark data and surface patterns aggregate stats may hide. See `agents/analyzer.md` ("Analyzing Benchmark Results") for what to inspect: assertions that always pass regardless of skill (non-discriminating), high-variance evals (maybe flaky), time/token tradeoffs.

4. **Launch the viewer** with qualitative outputs and quantitative data:
   ```bash
   nohup python <skill-creator-path>/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json \
     > /dev/null 2>&1 &
   VIEWER_PID=$!
   ```
   For iteration 2+, also pass `--previous-workspace <workspace>/iteration-<N-1>`.

   **Cowork / headless environments:** If `webbrowser.open()` unavailable or no display, use `--static <output_path>` to write standalone HTML instead of starting server. Feedback downloads as `feedback.json` when user clicks "Submit All Reviews". After download, copy `feedback.json` into workspace directory so next iteration can pick it up.

Note: use `generate_review.py` to make viewer. No need to write custom HTML.

5. **Tell the user** something like: "I've opened the results in your browser. There are two tabs — 'Outputs' lets you click through each test case and leave feedback, 'Benchmark' shows the quantitative comparison. When you're done, come back here and let me know."

### What the user sees in the viewer

"Outputs" tab shows one test case at a time:
- **Prompt**: task given
- **Output**: files skill produced, rendered inline when possible
- **Previous Output** (iteration 2+): collapsed section with last iteration output
- **Formal Grades** (if grading ran): collapsed section with assertion pass/fail
- **Feedback**: textbox that auto-saves while user types
- **Previous Feedback** (iteration 2+): last comments shown below textbox

"Benchmark" tab shows stats summary: pass rates, timing, token usage for each configuration, plus per-eval breakdowns and analyst observations.

Navigation uses prev/next buttons or arrow keys. When done, user clicks "Submit All Reviews", which saves all feedback to `feedback.json`.

### Step 5: Read the feedback

When user says done, read `feedback.json`:

```json
{
  "reviews": [
    {"run_id": "eval-0-with_skill", "feedback": "the chart is missing axis labels", "timestamp": "..."},
    {"run_id": "eval-1-with_skill", "feedback": "", "timestamp": "..."},
    {"run_id": "eval-2-with_skill", "feedback": "perfect, love this", "timestamp": "..."}
  ],
  "status": "complete"
}
```

Empty feedback means user thought it was fine. Focus improvements on test cases where user had specific complaints.

Kill viewer server when done:

```bash
kill $VIEWER_PID 2>/dev/null
```

---

## Improving the skill

This is heart of loop. You ran tests, user reviewed results, now make skill better from feedback.

### How to think about improvements

1. **Generalize from the feedback.** Big picture: we want skills usable a million times, maybe literally, maybe more, across many prompts. You and user iterate on only a few examples because that is fast. User knows those examples deeply and can judge quickly. But if skill only works for those examples, skill useless. Do not make fiddly overfit changes or oppressive MUSTs. If issue stays stubborn, try branching out: different metaphors, different working patterns. Cheap to try, maybe lands something great.

2. **Keep the prompt lean.** Remove things not earning their keep. Read transcripts, not just final outputs. If skill makes model waste time on unproductive work, remove the parts causing that and test again.

3. **Explain the why.** Work hard to explain the **why** behind every instruction. Today's LLMs are smart. Good theory of mind, and with good harness they can go beyond rote instruction and truly make things happen. Even if user feedback terse or frustrated, actually understand task, why user wrote what they wrote, and what they truly need, then transmit that understanding into instructions. If you find yourself writing ALWAYS or NEVER in all caps, yellow flag. If possible, reframe and explain reasoning so model understands why request matters. More humane, more powerful, more effective.

4. **Look for repeated work across test cases.** Read transcripts and notice whether subagents all separately wrote similar helper scripts or used same multi-step approach. If all 3 test cases ended with subagent writing `create_docx.py` or `build_chart.py`, strong signal skill should bundle that script. Write once, put in `scripts/`, tell skill to use it. Saves every future invocation from reinventing wheel.

This task matters a lot (we are trying to create billions a year in economic value here!), and thinking time is not blocker. Take time and really think. Good pattern: write draft revision, then reread fresh and improve. Do best to get into user's head and understand what they want and need.

### The iteration loop

After improving skill:

1. Apply improvements to skill
2. Rerun all test cases into new `iteration-<N+1>/` directory, including baseline runs. If creating new skill, baseline always `without_skill` (no skill), same each iteration. If improving existing skill, use judgment for baseline: original version user brought, or previous iteration.
3. Launch reviewer with `--previous-workspace` pointing to previous iteration
4. Wait for user to review and say done
5. Read new feedback, improve again, repeat

Keep going until:
- User says happy
- Feedback all empty (everything looks good)
- You are not making meaningful progress

---

## Advanced: Blind comparison

If you want more rigorous comparison between two skill versions (example: user asks "is new version actually better?"), there is blind comparison system. Read `agents/comparator.md` and `agents/analyzer.md` for details. Basic idea: give two outputs to independent agent without telling which is which, let it judge quality, then analyze why winner won.

Optional. Needs subagents. Most users do not need it. Human review loop usually enough.

---

## Description Optimization

The description field in SKILL.md frontmatter is main mechanism deciding whether Claude invokes skill. After creating or improving a skill, offer to optimize description for better triggering accuracy.

### Step 1: Generate trigger eval queries

Create 20 eval queries, mix of should-trigger and should-not-trigger. Save as JSON:

```json
[
  {"query": "the user prompt", "should_trigger": true},
  {"query": "another prompt", "should_trigger": false}
]
```

Queries must be realistic, like something Claude Code or Claude.ai user would actually type. Not abstract asks, but concrete, specific, with real detail. Examples: file paths, personal job/situation context, column names and values, company names, URLs. Small backstory. Some lowercase, abbreviations, typos, casual speech. Mix lengths. Focus on edge cases, not obvious ones. User will review them.

Bad: `"Format this data"`, `"Extract text from PDF"`, `"Create a chart"`

Good: `"ok so my boss just sent me this xlsx file (its in my downloads, called something like 'Q4 sales final FINAL v2.xlsx') and she wants me to add a column that shows the profit margin as a percentage. The revenue is in column C and costs are in column D i think"`

For **should-trigger** queries (8-10), think coverage. You want many phrasings of same intent: formal, casual, etc. Include cases where user does not explicitly name skill or file type but clearly needs it. Include uncommon use cases and cases where this skill competes with another but should win.

For **should-not-trigger** queries (8-10), best ones are near-misses: queries sharing keywords or concepts with skill but actually needing something else. Think adjacent domains, ambiguous phrasing where naive keyword match would trigger but should not, and cases that touch skill area but another tool fits better.

Main thing to avoid: do not make should-not-trigger queries obviously irrelevant. "Write a fibonacci function" as negative test for PDF skill is too easy. It tests nothing. Negative cases should be genuinely tricky.

### Step 2: Review with user

Present the eval set to the user for review using the HTML template:

1. Read the template from `assets/eval_review.html`
2. Replace the placeholders:
   - `__EVAL_DATA_PLACEHOLDER__` → the JSON array of eval items (no quotes around it — it's a JS variable assignment)
   - `__SKILL_NAME_PLACEHOLDER__` → the skill's name
   - `__SKILL_DESCRIPTION_PLACEHOLDER__` → the skill's current description
3. Write to a temp file (e.g., `/tmp/eval_review_<skill-name>.html`) and open it: `open /tmp/eval_review_<skill-name>.html`
4. The user can edit queries, toggle should-trigger, add/remove entries, then click "Export Eval Set"
5. The file downloads to `~/Downloads/eval_set.json` — check the Downloads folder for the most recent version in case there are multiple (e.g., `eval_set (1).json`)

This step matters — bad eval queries lead to bad descriptions.

### Step 3: Run the optimization loop

Tell the user: "This will take some time — I'll run the optimization loop in the background and check on it periodically."

Save the eval set to the workspace, then run in the background:

```bash
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <model-id-powering-this-session> \
  --max-iterations 5 \
  --verbose
```

Use the model ID from your system prompt (the one powering the current session) so the triggering test matches what the user actually experiences.

While it runs, periodically tail the output to give the user updates on which iteration it's on and what the scores look like.

This handles the full optimization loop automatically. It splits the eval set into 60% train and 40% held-out test, evaluates the current description (running each query 3 times to get a reliable trigger rate), then calls Claude to propose improvements based on what failed. It re-evaluates each new description on both train and test, iterating up to 5 times. When it's done, it opens an HTML report in the browser showing the results per iteration and returns JSON with `best_description` — selected by test score rather than train score to avoid overfitting.

### How skill triggering works

Understanding the triggering mechanism helps design better eval queries. Skills appear in Claude's `available_skills` list with their name + description, and Claude decides whether to consult a skill based on that description. The important thing to know is that Claude only consults skills for tasks it can't easily handle on its own — simple, one-step queries like "read this PDF" may not trigger a skill even if the description matches perfectly, because Claude can handle them directly with basic tools. Complex, multi-step, or specialized queries reliably trigger skills when the description matches.

This means your eval queries should be substantive enough that Claude would actually benefit from consulting a skill. Simple queries like "read file X" are poor test cases — they won't trigger skills regardless of description quality.

### Step 4: Apply the result

Take `best_description` from JSON output and update skill's SKILL.md frontmatter. Show user before/after and report scores.

---

### Package and Present (only if `present_files` tool is available)

Check whether you have access to the `present_files` tool. If you don't, skip this step. If you do, package the skill and present the .skill file to the user:

```bash
python -m scripts.package_skill <path/to/skill-folder>
```

After packaging, direct the user to the resulting `.skill` file path so they can install it.

---

## Claude.ai-specific instructions

In Claude.ai, the core workflow is the same (draft → test → review → improve → repeat), but because Claude.ai doesn't have subagents, some mechanics change. Here's what to adapt:

**Running test cases**: No subagents means no parallel execution. For each test case, read skill's SKILL.md, then follow its instructions yourself to complete test prompt. Do one at a time. Less rigorous than independent subagents because you wrote skill and also run it, so you have full context, but still useful sanity check. Human review step compensates. Skip baseline runs. Just use skill to complete task.

**Reviewing results**: If you cannot open browser (example Claude.ai VM no display, or remote server), skip browser reviewer. Present results directly in conversation. For each test case, show prompt and output. If output is file user must inspect (like `.docx` or `.xlsx`), save it to filesystem and tell user where it is so they can download and inspect it. Ask inline for feedback: "How does this look? Anything you'd change?"

**Benchmarking**: Skip quantitative benchmarking. It depends on baselines which are not meaningful without subagents. Focus on qualitative user feedback.

**The iteration loop**: Same as before: improve skill, rerun tests, ask feedback, repeat. Just without browser reviewer in middle. You may still organize results into iteration directories if filesystem exists.

**Description optimization**: This section requires the `claude` CLI tool (specifically `claude -p`) which is only available in Claude Code. Skip it if you're on Claude.ai.

**Blind comparison**: Needs subagents. Skip.

**Packaging**: The `package_skill.py` script works anywhere with Python and a filesystem. On Claude.ai, you can run it and the user can download the resulting `.skill` file.

**Updating an existing skill**: The user might be asking you to update an existing skill, not create a new one. In this case:
- **Preserve the original name.** Note the skill's directory name and `name` frontmatter field -- use them unchanged. E.g., if the installed skill is `research-helper`, output `research-helper.skill` (not `research-helper-v2`).
- **Copy to a writeable location before editing.** The installed skill path may be read-only. Copy to `/tmp/skill-name/`, edit there, and package from the copy.
- **If packaging manually, stage in `/tmp/` first**, then copy to the output directory -- direct writes may fail due to permissions.

---

## Cowork-Specific Instructions

If you're in Cowork, the main things to know are:

- You have subagents, so the main workflow (spawn test cases in parallel, run baselines, grade, etc.) all works. (However, if you run into severe problems with timeouts, it's OK to run the test prompts in series rather than parallel.)
- You don't have a browser or display, so when generating the eval viewer, use `--static <output_path>` to write a standalone HTML file instead of starting a server. Then proffer a link that the user can click to open the HTML in their browser.
- For whatever reason, the Cowork setup seems to disincline Claude from generating the eval viewer after running the tests, so just to reiterate: whether you're in Cowork or in Claude Code, after running tests, you should always generate the eval viewer for the human to look at examples before revising the skill yourself and trying to make corrections, using `generate_review.py` (not writing your own boutique html code). Sorry in advance but I'm gonna go all caps here: GENERATE THE EVAL VIEWER *BEFORE* evaluating inputs yourself. You want to get them in front of the human ASAP!
- Feedback works differently: since there's no running server, the viewer's "Submit All Reviews" button will download `feedback.json` as a file. You can then read it from there (you may have to request access first).
- Packaging works — `package_skill.py` just needs Python and a filesystem.
- Description optimization (`run_loop.py` / `run_eval.py`) should work in Cowork just fine since it uses `claude -p` via subprocess, not a browser, but please save it until you've fully finished making the skill and the user agrees it's in good shape.
- **Updating an existing skill**: The user might be asking you to update an existing skill, not create a new one. Follow the update guidance in the claude.ai section above.

---

## Reference files

The agents/ directory contains instructions for specialized subagents. Read them when you need to spawn the relevant subagent.

- `agents/grader.md` — How to evaluate assertions against outputs
- `agents/comparator.md` — How to do blind A/B comparison between two outputs
- `agents/analyzer.md` — How to analyze why one version beat another

The references/ directory has additional documentation:
- `references/schemas.md` — JSON structures for evals.json, grading.json, etc.

---

Repeating one more time the core loop here for emphasis:

- Figure out what skill is about
- Draft or edit skill
- Run claude-with-access-to-the-skill on test prompts
- With user, evaluate outputs:
  - Create benchmark.json and run `eval-viewer/generate_review.py` to help user review
  - Run quantitative evals
- Repeat until you and user are satisfied
- Package the final skill and return it to the user.

Please add steps to your TodoList, if you have such a thing, to make sure you don't forget. If you're in Cowork, please specifically put "Create evals JSON and run `eval-viewer/generate_review.py` so human can review test cases" in your TodoList to make sure it happens.

Good luck!