#!/usr/bin/env python3
"""Detect cycles in Terraform DOT graphs."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Iterable


EDGE_RE = re.compile(r'^\s*"((?:\\.|[^"\\])*)"\s*->\s*"((?:\\.|[^"\\])*)"')
NODE_RE = re.compile(r'^\s*"((?:\\.|[^"\\])*)"\s*(?:\[|;)')


def parse_dot(path: Path) -> tuple[set[str], set[tuple[str, str]]]:
    if not path.exists():
        raise ValueError(f"{path} does not exist")

    text = path.read_text(encoding="utf-8")
    if "digraph" not in text:
        raise ValueError(f"{path} does not look like a DOT digraph")

    nodes: set[str] = set()
    edges: set[tuple[str, str]] = set()

    for line in text.splitlines():
        edge = EDGE_RE.match(line)
        if edge:
            source, target = edge.groups()
            nodes.add(source)
            nodes.add(target)
            edges.add((source, target))
            continue

        node = NODE_RE.match(line)
        if node:
            nodes.add(node.group(1))

    return nodes, edges


def strongly_connected_components(nodes: Iterable[str], edges: Iterable[tuple[str, str]]) -> list[list[str]]:
    adjacency = {node: [] for node in nodes}
    for source, target in edges:
        adjacency.setdefault(source, []).append(target)
        adjacency.setdefault(target, [])

    index = 0
    stack: list[str] = []
    on_stack: set[str] = set()
    indexes: dict[str, int] = {}
    lowlinks: dict[str, int] = {}
    components: list[list[str]] = []

    def visit(node: str) -> None:
        nonlocal index
        indexes[node] = index
        lowlinks[node] = index
        index += 1
        stack.append(node)
        on_stack.add(node)

        for target in adjacency.get(node, []):
            if target not in indexes:
                visit(target)
                lowlinks[node] = min(lowlinks[node], lowlinks[target])
            elif target in on_stack:
                lowlinks[node] = min(lowlinks[node], indexes[target])

        if lowlinks[node] == indexes[node]:
            component: list[str] = []
            while True:
                item = stack.pop()
                on_stack.remove(item)
                component.append(item)
                if item == node:
                    break
            components.append(sorted(component))

    for node in sorted(adjacency):
        if node not in indexes:
            visit(node)

    return components


def find_cycles(nodes: set[str], edges: set[tuple[str, str]]) -> list[dict[str, object]]:
    cycles: list[dict[str, object]] = []

    for component in strongly_connected_components(nodes, edges):
        if len(component) > 1:
            cycles.append({"type": "strongly_connected_component", "nodes": component})

    for source, target in sorted(edges):
        if source == target:
            cycles.append({"type": "self_loop", "nodes": [source]})

    return cycles


def build_report(dot_file: Path) -> dict[str, object]:
    nodes, edges = parse_dot(dot_file)
    cycles = find_cycles(nodes, edges)
    return {
        "dot_file": str(dot_file),
        "node_count": len(nodes),
        "edge_count": len(edges),
        "cycle_count": len(cycles),
        "cycles": cycles,
    }


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: tf_graph_cycles.py <graph.dot>", file=sys.stderr)
        return 2

    try:
        report = build_report(Path(argv[1]))
    except Exception as exc:  # noqa: BLE001 - command-line tool should report any parse failure.
        print(f"error: {exc}", file=sys.stderr)
        return 2

    print(json.dumps(report, indent=2, sort_keys=True))
    return 1 if report["cycle_count"] else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
