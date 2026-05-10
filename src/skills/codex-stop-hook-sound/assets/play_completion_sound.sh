#!/usr/bin/env bash
set -euo pipefail
nohup ffplay -nodisp -autoexit -loglevel error "/home/coding_dragon/.codex/formula-1-box-box.wav" >/dev/null 2>&1 </dev/null &
