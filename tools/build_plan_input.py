#!/usr/bin/env python3
"""Build compact OPA input from `terraform show -json` plan output."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def read_json(path: Path | None) -> dict[str, Any]:
    if path is None:
        return json.load(sys.stdin)
    with path.open(encoding="utf-8") as fh:
        return json.load(fh)


def planned_values(change: dict[str, Any]) -> dict[str, Any]:
    after = change.get("after")
    if isinstance(after, dict):
        return after
    before = change.get("before")
    if isinstance(before, dict):
        return before
    return {}


def include_resource(change: dict[str, Any]) -> bool:
    if change.get("mode") != "managed":
        return False
    actions = change.get("change", {}).get("actions", [])
    return actions not in (["delete"], ["no-op"])


def normalize_resource(
    change: dict[str, Any], config_resources: dict[str, dict[str, Any]]
) -> dict[str, Any]:
    change_detail = change.get("change", {})
    config = config_resources.get(change["address"], {})
    return {
        "address": change["address"],
        "mode": change["mode"],
        "type": change["type"],
        "name": change["name"],
        "actions": change_detail.get("actions", []),
        "lifecycle": config.get("lifecycle", {}),
        "references": expression_references(config),
        "values": planned_values(change_detail),
    }


def collect_config_resources(module: dict[str, Any] | None) -> dict[str, dict[str, Any]]:
    """Index configuration resources by absolute Terraform address."""
    if not isinstance(module, dict):
        return {}

    resources: dict[str, dict[str, Any]] = {}
    for resource in module.get("resources", []):
        if isinstance(resource, dict) and isinstance(resource.get("address"), str):
            resources[resource["address"]] = resource

    for child in module.get("child_modules", []):
        resources.update(collect_config_resources(child))

    for call in module.get("module_calls", {}).values():
        if isinstance(call, dict):
            resources.update(collect_config_resources(call.get("module")))

    return resources


def expression_references(config: dict[str, Any]) -> dict[str, list[str]]:
    references: dict[str, list[str]] = {}
    expressions = config.get("expressions", {})
    if not isinstance(expressions, dict):
        return references
    for name, expression in expressions.items():
        if not isinstance(name, str) or not isinstance(expression, dict):
            continue
        refs = expression.get("references", [])
        if isinstance(refs, list):
            references[name] = [ref for ref in refs if isinstance(ref, str)]
    return references


def build_input(plan: dict[str, Any]) -> dict[str, Any]:
    config_resources = collect_config_resources(
        plan.get("configuration", {}).get("root_module")
    )
    return {
        "format_version": plan.get("format_version"),
        "terraform_version": plan.get("terraform_version"),
        "resources": [
            normalize_resource(change, config_resources)
            for change in plan.get("resource_changes", [])
            if include_resource(change)
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--plan-json",
        type=Path,
        default=None,
        help="Path to `terraform show -json` output. Defaults to stdin.",
    )
    args = parser.parse_args()

    json.dump(build_input(read_json(args.plan_json)), sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
