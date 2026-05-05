#!/usr/bin/env python3
"""Summarize Terraform DOT graph shape."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from tf_graph_cycles import find_cycles, parse_dot


MODULE_RE = re.compile(r"module\.[A-Za-z0-9_-]+")


def module_scope(node: str) -> tuple[str, ...]:
    modules = MODULE_RE.findall(node)
    return tuple(modules) if modules else ("root",)


def cross_module_edge_count(edges: set[tuple[str, str]]) -> int:
    return sum(1 for source, target in edges if module_scope(source) != module_scope(target))


def main(argv: list[str]) -> int:
    if len(argv) not in (2, 3):
        print("usage: tf_graph_summary.py <graph.dot> [fixture]", file=sys.stderr)
        return 2

    dot_file = Path(argv[1])
    fixture = argv[2] if len(argv) == 3 else dot_file.stem.replace(".plan", "")

    try:
        nodes, edges = parse_dot(dot_file)
    except Exception as exc:  # noqa: BLE001 - command-line tool should report any parse failure.
        print(f"error: {exc}", file=sys.stderr)
        return 2

    cycles = find_cycles(nodes, edges)
    report = {
        "fixture": fixture,
        "terraform_graph_type": "plan",
        "nodes": len(nodes),
        "node_count": len(nodes),
        "edges": len(edges),
        "edge_count": len(edges),
        "cycle_count": len(cycles),
        "cross_module_edges": cross_module_edge_count(edges),
        "generated_from": "terraform graph -type=plan -draw-cycles",
    }
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
