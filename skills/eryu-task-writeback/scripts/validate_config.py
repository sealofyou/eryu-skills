#!/usr/bin/env python3
"""Validate eryu-task-writeback local config without printing resource IDs."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path


MACHINES = {"laptop-win", "main-win", "macbook"}


def default_config_path() -> Path:
    return Path.home() / ".config" / "eryu-task-writeback" / "config.json"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", type=Path, default=default_config_path())
    args = parser.parse_args()

    result: dict[str, object] = {
        "config_path": str(args.config),
        "configured": False,
        "machine_id": None,
        "eryuos_root_exists": False,
        "base_token_present": False,
        "table_id_present": False,
        "identity": None,
        "errors": [],
    }

    if not args.config.is_file():
        result["errors"] = ["config file does not exist"]
        print(json.dumps(result, ensure_ascii=True, indent=2))
        return 1

    try:
        data = json.loads(args.config.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        result["errors"] = [f"cannot parse config: {exc.__class__.__name__}"]
        print(json.dumps(result, ensure_ascii=True, indent=2))
        return 1

    errors: list[str] = []
    machine_id = data.get("machine_id")
    eryuos_root = data.get("eryuos_root")
    base_token = data.get("base_token")
    table_id = data.get("table_id")
    identity = data.get("identity", "user")

    if machine_id not in MACHINES:
        errors.append("machine_id must be laptop-win, main-win, or macbook")
    if not isinstance(eryuos_root, str) or not os.path.isabs(eryuos_root):
        errors.append("eryuos_root must be an absolute path")
    if not isinstance(base_token, str) or not base_token.strip():
        errors.append("base_token is missing")
    if not isinstance(table_id, str) or not table_id.startswith("tbl"):
        errors.append("table_id is missing or malformed")
    if identity != "user":
        errors.append("identity must be user")

    result.update(
        {
            "configured": not errors,
            "machine_id": machine_id if machine_id in MACHINES else None,
            "eryuos_root_exists": isinstance(eryuos_root, str)
            and Path(eryuos_root).is_dir(),
            "base_token_present": isinstance(base_token, str) and bool(base_token.strip()),
            "table_id_present": isinstance(table_id, str) and table_id.startswith("tbl"),
            "identity": identity,
            "errors": errors,
        }
    )
    print(json.dumps(result, ensure_ascii=True, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
