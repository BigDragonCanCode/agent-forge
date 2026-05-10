---
name: codex-stop-hook-sound
description: Set up or repair a Codex completion sound using the global Stop hook. Use this skill whenever the user wants a completion sound, stop-hook sound, end-of-turn sound, notification audio, or asks about `~/.codex/config.toml`, `hooks.Stop`, `ffplay`, or `play_completion_sound.sh`. This skill is specifically for wiring a local audio file into Codex's global Stop hook with a fast fire-and-forget `ffplay` script.
---

# Codex Stop Hook Sound

Set up a global Codex Stop hook that plays a local sound file quickly with `ffplay`.

## First question

Before making any changes, ask whether the user already has the sound file.

Use this exact decision flow:

1. Ask whether they already have the sound file.
2. If they do not have it, explicitly ask them to upload it to:
   - `~/.codex/formula-1-box-box.wav`
3. Also tell them they can upload it anywhere they want and just tell you the full path instead.
4. Do not continue with hook setup until you know the sound file path.

Use wording equivalent to:

```text
Do you already have the sound file? If not, please upload it to ~/.codex/formula-1-box-box.wav, or upload it anywhere you want and tell me the full path.
```

## Default paths

Use these exact default locations unless the user gives a different audio-file path:

- Audio file: `~/.codex/formula-1-box-box.wav`
- Hook script: `~/.codex/hooks/play_completion_sound.sh`
- Codex config: `~/.codex/config.toml`

If the user provides a different audio-file path, keep the hook script location and config location the same, and only change the WAV path inside the script.

## Required behavior

- Prefer `ffplay` over `powershell.exe` for this workflow.
- Use a fire-and-forget hook so the Stop hook returns immediately.
- Preserve unrelated config in `~/.codex/config.toml`.
- If `[[hooks.Stop]]` already exists, update only the relevant command hook instead of rewriting unrelated hook entries unless the user asks for a full reset.
- Ensure `[features]` contains `codex_hooks = true`.
- Ensure `~/.codex/hooks` exists before writing the script.
- Make the hook script executable.

## Exact hook script

Write this exact script, changing only the WAV path if the user supplied a different one:

File: `~/.codex/hooks/play_completion_sound.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
nohup ffplay -nodisp -autoexit -loglevel error "/home/coding_dragon/.codex/formula-1-box-box.wav" >/dev/null 2>&1 </dev/null &
```

If the user gave a custom path, substitute only this string:

```text
/home/coding_dragon/.codex/formula-1-box-box.wav
```

## Exact config snippet

Ensure `~/.codex/config.toml` contains this exact Stop hook configuration:

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

- Reuse the exact command path above.
- Reuse the exact `statusMessage`.
- Reuse the exact timeout.
- Do not remove unrelated project settings, model settings, or other hooks.

## Setup workflow

Follow this order:

1. Confirm the audio-file path with the user.
2. Check whether `ffplay` exists.
3. Create `~/.codex/hooks` if needed.
4. Write `~/.codex/hooks/play_completion_sound.sh` using the exact script above.
5. Mark the script executable.
6. Update `~/.codex/config.toml` to ensure the exact Stop hook block is present.
7. Manually run the script once to verify that it executes.
8. If the user wants lower latency, keep the fire-and-forget version above.

## Verification

After setup:

1. Show the final script path and the audio-file path in use.
2. Manually run:

```bash
bash ~/.codex/hooks/play_completion_sound.sh
```

3. Ask the user whether they heard the sound.
4. Since this setup is known to work well in this environment, treat "did you hear it?" as the primary user-facing verification step.
5. Tell the user whether the script exited successfully.
6. If needed, measure the wall time and note that fire-and-forget should return almost immediately.

Use wording equivalent to:

```text
I manually triggered the sound just now. Did you hear it?
```

## Troubleshooting

If the script runs successfully but the user hears nothing:

- Verify the WAV path is correct.
- Verify `ffplay` is installed.
- Suspect audio-device or output-routing issues rather than hook syntax.

If `ffplay` is missing:

- Tell the user the setup depends on `ffplay`.
- Ask whether they want you to install or configure it.

If the user asks whether PowerShell is OK:

- Explain that `powershell.exe` plus synchronous playback is usually slower in this setup.
- Prefer the `ffplay` backgrounded script above.

## Bundled asset

The exact script is also bundled at `assets/play_completion_sound.sh`. Use it as the source of truth when copying the hook script into `~/.codex/hooks/play_completion_sound.sh`.
