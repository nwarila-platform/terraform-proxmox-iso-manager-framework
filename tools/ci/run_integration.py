#!/usr/bin/env python3
"""Assemble and verify an ephemeral Terraform integration workspace."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path


IGNORED_DIRS = {".terraform", ".synthetic-output", ".tflint.d", "__pycache__"}
IGNORED_FILES: set[str] = set()
IGNORED_SUFFIXES = (".tfstate", ".tfstate.backup", ".tfplan")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=".", help="Repository root. Defaults to cwd.")
    parser.add_argument("--config", default="tools/ci/config.toml", help="Path to CI config.")
    parser.add_argument("--case", default=None, help="Integration case name.")
    parser.add_argument("--framework-source", default=None, help="Override framework source for runner cases.")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    config = load_config(repo_root, args.config)
    case = select_case(config, args.case)
    workspace = reset_workspace(repo_root, config, case)

    role = config["repo_role"]
    if role == "framework":
        assemble_framework(repo_root, workspace, case)
    elif role == "runner":
        assemble_runner(repo_root, workspace, config, case, args.framework_source)
    else:
        raise ValueError(f"unsupported repo_role: {role}")

    run_terraform_gates(repo_root, workspace, config, case)
    return 0


def load_config(repo_root: Path, config_path: str) -> dict:
    with (repo_root / config_path).resolve().open("rb") as fh:
        return tomllib.load(fh)


def select_case(config: dict, requested: str | None) -> dict:
    name = requested or config.get("default_case")
    for case in config.get("cases", []):
        if case["name"] == name:
            return case
    raise ValueError(f"integration case not found: {name}")


def reset_workspace(repo_root: Path, config: dict, case: dict) -> Path:
    artifact_root = (repo_root / config.get("artifact_root", ".tmp/ci/integration")).resolve()
    workspace = (artifact_root / case["name"]).resolve()
    workspace.relative_to(artifact_root)

    artifact_root.mkdir(parents=True, exist_ok=True)
    if workspace.exists():
        shutil.rmtree(workspace)
    workspace.mkdir(parents=True)
    print(f"integration workspace: {workspace}", flush=True)
    return workspace


def assemble_framework(repo_root: Path, workspace: Path, case: dict) -> None:
    copy_contents(repo_root / case.get("module_source", "terraform"), workspace)
    copy_tfvars(repo_root, workspace, case)


def assemble_runner(
    repo_root: Path,
    workspace: Path,
    config: dict,
    case: dict,
    framework_source_override: str | None,
) -> None:
    copy_contents(repo_root / case["overlay_dir"], workspace)

    framework_source = framework_source_override or os.environ.get("FRAMEWORK_SOURCE") or config.get("framework_source")
    if not framework_source:
        raise ValueError("runner integration requires framework_source or --framework-source")

    framework_path = Path(framework_source)
    if not framework_path.is_absolute():
        framework_path = repo_root / framework_path
    framework_path = framework_path.resolve()
    if (framework_path / "terraform").is_dir():
        framework_path = framework_path / "terraform"
    if not (framework_path / "versions.tf").is_file():
        raise FileNotFoundError(f"framework Terraform module not found: {framework_path}")

    copy_contents(framework_path, workspace / case.get("module_path", "modules/framework"))
    copy_tfvars(repo_root, workspace, case)


def copy_tfvars(repo_root: Path, workspace: Path, case: dict) -> None:
    if tfvars_source := case.get("tfvars_source"):
        shutil.copy2(repo_root / tfvars_source, workspace / "terraform.tfvars")


def copy_contents(source: Path, destination: Path) -> None:
    if not source.exists():
        raise FileNotFoundError(source)
    destination.mkdir(parents=True, exist_ok=True)
    for child in source.iterdir():
        if should_ignore_name(child.name):
            continue
        target = destination / child.name
        if child.is_dir():
            shutil.copytree(child, target, dirs_exist_ok=True, ignore=ignore_names)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(child, target)


def ignore_names(_directory: str, names: list[str]) -> set[str]:
    return {name for name in names if should_ignore_name(name)}


def should_ignore_name(name: str) -> bool:
    return name in IGNORED_DIRS or name in IGNORED_FILES or name.endswith(IGNORED_SUFFIXES)


def run_terraform_gates(repo_root: Path, workspace: Path, config: dict, case: dict) -> None:
    terraform = os.environ.get("TERRAFORM", "terraform")
    tflint = os.environ.get("TFLINT", "tflint")

    run([terraform, f"-chdir={workspace}", "fmt", "-check", "-recursive"])
    run(
        [
            terraform,
            f"-chdir={workspace}",
            "init",
            "-backend=false",
            "-input=false",
        ]
    )
    run([terraform, f"-chdir={workspace}", "validate"])

    if case.get("tflint", False):
        configured_tflint = config.get("tflint_config")
        if not configured_tflint:
            raise SystemExit("case enabled tflint but tflint_config is not set")
        tflint_config = (repo_root / configured_tflint).resolve()
        run([tflint, "--init", "--config", str(tflint_config)])
        run([tflint, "--config", str(tflint_config), "--chdir", str(workspace)])

    plan_args = [terraform, f"-chdir={workspace}", "plan", "-input=false", "-out=.ci-plan.tfplan"]
    if (workspace / "terraform.tfvars").is_file():
        plan_args.append("-var-file=terraform.tfvars")
    run(plan_args)

    test_args = [terraform, f"-chdir={workspace}", "test"]
    if case.get("test_var_file", False) and (workspace / "terraform.tfvars").is_file():
        test_args.append("-var-file=terraform.tfvars")
    run(test_args)


def run(command: list[str]) -> None:
    print("+ " + " ".join(command), flush=True)
    subprocess.run(command, check=True)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as exc:
        sys.exit(exc.returncode)
    except Exception as exc:
        print(f"run_integration.py: {exc}", file=sys.stderr)
        sys.exit(1)
