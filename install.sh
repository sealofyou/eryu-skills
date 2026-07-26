#!/usr/bin/env bash
set -euo pipefail

profile="${1:-core}"
case "$profile" in
  core|content|slides|design|tools|media|all) ;;
  *) echo "Unknown profile: $profile" >&2; exit 2 ;;
esac

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest="$root/skills.sources.csv"
target_root="${ERYU_SKILLS_TARGET_ROOT:-$HOME/.codex/skills}"
cache_root="${ERYU_SKILLS_CACHE_ROOT:-$HOME/.cache/eryu-skills/repos}"
mkdir -p "$target_root" "$cache_root"

selected() {
  local row_profile="$1"
  [[ "$profile" == "all" || "$row_profile" == "core" || "$row_profile" == "$profile" ]]
}

platform_selected() {
  local row_platform="${1:-all}"
  case "$row_platform" in
    ""|all) return 0 ;;
    macos) [[ "$(uname -s)" == "Darwin" ]] ;;
    linux) [[ "$(uname -s)" == "Linux" ]] ;;
    windows) return 1 ;;
    *) echo "Unknown source platform: $row_platform" >&2; exit 7 ;;
  esac
}

copy_skill() {
  local source="$1"
  local target="$2"
  case "$target" in
    "$target_root"/*) ;;
    *) echo "Refusing to replace target outside $target_root: $target" >&2; exit 3 ;;
  esac
  [[ -f "$source/SKILL.md" ]] || { echo "Skill source has no SKILL.md: $source" >&2; exit 4; }
  rm -rf "$target"
  mkdir -p "$target"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude '.git' "$source/" "$target/"
  else
    cp -R "$source/." "$target/"
    rm -rf "$target/.git"
  fi
}

prepared_keys="|"

while IFS=',' read -r name row_profile kind cache_key repo ref subpath row_platform; do
  [[ "$name" == "name" || -z "$name" ]] && continue
  selected "$row_profile" || continue
  platform_selected "${row_platform:-all}" || continue

  if [[ "$kind" == "local" ]]; then
    source="$root/$subpath"
  elif [[ "$kind" == "git" ]]; then
    cache="$cache_root/$cache_key"
    if [[ "$prepared_keys" != *"|$cache_key|"* ]]; then
      if [[ -d "$cache/.git" ]]; then
        [[ -z "$(git -C "$cache" status --porcelain)" ]] || {
          echo "Managed cache has local changes: $cache" >&2
          exit 5
        }
        git -C "$cache" fetch origin "$ref"
        git -C "$cache" checkout "$ref"
        git -C "$cache" pull --ff-only origin "$ref"
      else
        git clone --depth 1 --branch "$ref" "$repo" "$cache"
      fi
      prepared_keys="${prepared_keys}${cache_key}|"
    fi
    if [[ "$subpath" == "." ]]; then
      source="$cache"
    else
      source="$cache/$subpath"
    fi
  else
    echo "Unknown source kind: $kind" >&2
    exit 6
  fi

  copy_skill "$source" "$target_root/$name"
  echo "Installed $name"
done < "$manifest"

echo "Done. Restart Codex or the agent session to reload skills."
