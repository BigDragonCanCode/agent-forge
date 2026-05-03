#!/usr/bin/env bash
#===========================================================
# add downloaded skill from .claude/ ./agents to src/skills/
#
# Usage: ./vendor-skill.sh <repo> <skill-name>
#===========================================================
set -e #stop on error

REPO=$1
SKILL_NAME=$2

if [ -z "$REPO" ] || [ -z "$SKILL_NAME" ]; then
    echo "Usage: $0 <repo> <skill-name>"
    echo "Example: $0 anthropics/skills skill-creator"
    exit 1
fi

echo "Fetching skill '$SKILL_NAME' from repo '$REPO'..."

if [ "$SKILL_NAME" = "all" ]; then
    echo "Vendoring all skills from repo '$REPO'..."
    npx skills add "$REPO" --all --agent claude-code --yes
    exit 0
else
    echo "Vendoring skill '$SKILL_NAME' from repo '$REPO'..."
    npx skills add "$REPO" --skill "$SKILL_NAME" --agent claude-code --yes
fi

SOURCE=".claude/skills/$SKILL_NAME"
echo "Vendoring skill '$SKILL_NAME' to src/skills/$SKILL_NAME..."
mkdir -p src/skills #create skills directory if it doesn't exist

for d in .claude/skills/*; do [ -d "$d" ] || continue; mv "$d" "src/skills/"; done
echo "Skill '$SKILL_NAME' has been vendored successfully!"

rm -rf .claude/
echo "Cleaned up temporary skill files from .claude/skills/"
