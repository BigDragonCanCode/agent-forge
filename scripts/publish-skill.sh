#!/usr/bin/env bash
#===========================================================
# copy skill from src/skills to .agent/ or .claude/ or .codex/
# Usage: ./publish-skill.sh <skill-name> <agent-name>
#===========================================================
set -e

SKILL_NAME="${1:-}"
AGENT_NAME="${2:-}"

if [ -z "$SKILL_NAME" ] || [ -z "$AGENT_NAME" ]; then
  echo "Usage: $0 <skill-name> <agent-name>"
  echo "Example: $0 skill-creator claude-code"
  exit 1
fi

SOURCE_DIR="src/skills/$SKILL_NAME"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Skill not found: $SOURCE_DIR"
  exit 1
fi

if [ "$AGENT_NAME" = "claude-code" ]; then
  TARGET_ROOT=".claude"
elif [ "$AGENT_NAME" = "codex" ]; then
  TARGET_ROOT=".codex"
else
  TARGET_ROOT=".agent"
fi

TARGET_DIR="$TARGET_ROOT/skills/$SKILL_NAME"

mkdir -p "$TARGET_ROOT/skills"
rm -rf "$TARGET_DIR"
cp -R "$SOURCE_DIR" "$TARGET_DIR"

echo "Copied '$SKILL_NAME' to '$TARGET_DIR' for agent '$AGENT_NAME'."
