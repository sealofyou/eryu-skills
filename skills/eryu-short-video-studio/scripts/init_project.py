#!/usr/bin/env python3
"""Initialize a reviewable short-video project from the bundled template."""

from __future__ import annotations

import argparse
import datetime as dt
import re
import shutil
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--slug", required=True)
    parser.add_argument(
        "--mode",
        choices=("plan", "produce", "publish", "full"),
        default="produce",
    )
    parser.add_argument("--platform", default="douyin")
    parser.add_argument(
        "--review-mode",
        choices=("fast", "standard", "high-control"),
        default="standard",
    )
    parser.add_argument("--duration-target-seconds", type=int, default=60)
    parser.add_argument("--aspect-ratio", default="9:16")
    parser.add_argument("--force", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", args.slug):
        raise SystemExit("--slug must use lowercase ASCII letters, digits, and hyphens")
    if args.duration_target_seconds <= 0:
        raise SystemExit("--duration-target-seconds must be greater than zero")

    skill_root = Path(__file__).resolve().parent.parent
    template = skill_root / "assets" / "project-template"
    output = Path(args.output).expanduser().resolve()
    if output.exists() and not output.is_dir():
        raise SystemExit(f"Output path is not a directory: {output}")
    if output.exists() and any(output.iterdir()):
        if not args.force:
            raise SystemExit(f"Output directory is not empty: {output}")
        shutil.rmtree(output)

    output.mkdir(parents=True, exist_ok=True)
    for source in template.iterdir():
        target = output / source.name
        if source.is_dir():
            if target.exists():
                shutil.rmtree(target)
            shutil.copytree(source, target)
        else:
            shutil.copy2(source, target)

    now = dt.datetime.now(dt.timezone.utc).astimezone()
    project_id = f"{now:%Y%m%d}-{args.slug}"
    replacements = {
        "{{PROJECT_ID}}": project_id,
        "{{TITLE}}": args.title,
        "{{SLUG}}": args.slug,
        "{{MODE}}": args.mode,
        "{{PLATFORM}}": args.platform,
        "{{REVIEW_MODE}}": args.review_mode,
        "{{DURATION_TARGET_SECONDS}}": str(args.duration_target_seconds),
        "{{ASPECT_RATIO}}": args.aspect_ratio,
        "{{CREATED_AT}}": now.isoformat(timespec="seconds"),
    }
    for path in output.rglob("*"):
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for old, new in replacements.items():
            text = text.replace(old, new)
        path.write_text(text, encoding="utf-8")

    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
