#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$HOME/.codex/skills"

for name in gpt-image2-ppt-skills guizang-ppt-skill lark-shared lark-slides; do
  if [ -d "$ROOT/$name" ]; then
    rsync -a --delete \
      --exclude '.git' \
      --exclude '.env' --exclude '*.env' --exclude '*.local' \
      --exclude 'node_modules' --exclude '.venv' --exclude 'venv' \
      --exclude '__pycache__' --exclude '.pytest_cache' \
      --exclude 'dist' --exclude 'build' --exclude 'output' --exclude 'outputs' --exclude 'results' --exclude 'logs' \
      "$ROOT/$name/" "$HOME/.codex/skills/$name/"
  fi
done

echo "Installed PPT/deck skills to ~/.codex/skills. Restart Codex / agent sessions to reload."