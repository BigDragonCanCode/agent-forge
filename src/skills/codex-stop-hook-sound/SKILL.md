---
name: codex-stop-hook-sound
description: Setup/fix Codex completion sound with global Stop hook. Use skill when user want completion sound, stop-hook sound, end-of-turn sound, notification audio, or ask about `~/.codex/config.toml`, `hooks.Stop`, `ffplay`, or `play_completion_sound.sh`. Skill for wiring local audio file into Codex global Stop hook with fast fire-and-forget `ffplay` script.
---

# Codex Stop Hook Sound

Setup global Codex Stop hook. Play local sound fast with `ffplay`.

## First question

Before any change, ask if user already have sound file.

Use exact decision flow:

1. Ask if user already have sound file.
2. If not, explicitly tell user upload it to:
   - `~/.codex/formula-1-box-box.wav`
3. Also tell user can upload anywhere, then tell you full path.
4. No continue hook setup until sound file path known.

Use wording like:

```text
Do you already have the sound file? If not, please upload it to ~/.codex/formula-1-box-box.wav, or upload it anywhere you want and tell me the full path.
```

## Default paths

Use exact default locations unless user gives different audio-file path:

- Audio file: `~/.codex/formula-1-box-box.wav`
- Hook script: `~/.codex/hooks/play_completion_sound.sh`
- Codex config: `~/.codex/config.toml`

If user gives different audio-file path, keep hook script location and config location same. Only change WAV path inside script.

## Required behavior

- Prefer `ffplay`, not `powershell.exe`, for this workflow.
- Use fire-and-forget hook so Stop hook return immediately.
- Preserve unrelated config in `~/.codex/config.toml`.
- If `[[hooks.Stop]]` already exist, update only relevant command hook. Do not rewrite unrelated hook entries unless user ask full reset.
- Ensure `[features]` contains `codex_hooks = true`.
- Ensure `~/.codex/hooks` exist before writing script.
- Make hook script executable.

## Exact hook script

Write exact script below. Change only WAV path if user supplied different one:

File: `~/.codex/hooks/play_completion_sound.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
nohup ffplay -nodisp -autoexit -loglevel error "/home/coding_dragon/.codex/formula-1-box-box.wav" >/dev/null 2>&1 </dev/null &
```

If user gave custom path, substitute only this string:

```text
/home/coding_dragon/.codex/formula-1-box-box.wav
```

## Exact config snippet

Ensure `~/.codex/config.toml` contains exact Stop hook config:

```toml
[features]
codex_hooks = true

[[hooks.Stop]]

[[hooks.Stop.hooks]]
type = "command"
command = "$HOME/.codex/hooks/play_completion_sound.sh"
timeout = 15
statusMessage = "Playing completion sound"
```

Important:

- Reuse exact command path above.
- Reuse exact `statusMessage`.
- Reuse exact timeout.
- Do not remove unrelated project settings, model settings, or other hooks.

## Setup workflow

Follow this order:

1. Confirm audio-file path with user.
2. Check if `ffplay` exists.
3. Create `~/.codex/hooks` if needed.
4. Write `~/.codex/hooks/play_completion_sound.sh` with exact script above.
5. Mark script executable.
6. Update `~/.codex/config.toml` so exact Stop hook block present.
7. Manually run script once to verify it executes.
8. If user want lower latency, keep fire-and-forget version above.

## Verification

After setup:

1. Show final script path and audio-file path in use.
2. Manually run:

```bash
bash ~/.codex/hooks/play_completion_sound.sh
```

3. Ask user if they heard sound.
4. This setup known work well in this environment, so treat "did you hear it?" as primary user-facing verification.
5. Tell user if script exited successfully.
6. If needed, measure wall time and note fire-and-forget should return almost immediately.

Use wording like:

```text
I manually triggered the sound just now. Did you hear it?
```

## Troubleshooting

If script runs successfully but user hears nothing:

- Verify WAV path correct.
- Verify `ffplay` installed.
- Suspect audio-device or output-routing issue, not hook syntax.

If `ffplay` missing:

- Tell user setup depends on `ffplay`.
- Ask if they want you to install or configure it.

If user asks whether PowerShell is OK:

- Explain `powershell.exe` plus synchronous playback usually slower in this setup.
- Prefer `ffplay` backgrounded script above.

## Bundled asset

Exact script also bundled at `assets/play_completion_sound.sh`. Use as source of truth when copying hook script into `~/.codex/hooks/play_completion_sound.sh`.