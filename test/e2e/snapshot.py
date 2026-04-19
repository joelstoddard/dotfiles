#!/usr/bin/env python3
"""Snapshot $HOME at stow-relevant paths; diff two snapshots.

Used by e2e tests to verify uninstall.sh restores the pre-install state.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parent.parent.parent
STOW_IGNORE_FILE = REPO_DIR / ".stow-local-ignore"

# Top-level repo entries that .stow-local-ignore does not list but which stow
# also does not manage in practice: agent-tooling, editor caches, etc. Treat as
# ignored so snapshot diffs focus on user-facing dotfiles.
EXTRA_SKIP = {".claude", ".worktrees", ".DS_Store"}


def _load_stow_ignore() -> list[str]:
    if not STOW_IGNORE_FILE.exists():
        return []
    patterns: list[str] = []
    for raw in STOW_IGNORE_FILE.read_text().splitlines():
        raw = raw.strip()
        if not raw or raw.startswith("#"):
            continue
        patterns.append(raw)
    return patterns


def _is_ignored(first_segment: str, patterns: list[str]) -> bool:
    for p in patterns:
        stripped = p.lstrip("^").rstrip("$").replace("\\.", ".")
        if first_segment == stripped:
            return True
    return False


def _stowable_paths() -> list[str]:
    """Enumerate repo-root-relative paths that stow would link into $HOME."""
    patterns = _load_stow_ignore()
    out: list[str] = []
    for root, dirs, files in os.walk(REPO_DIR):
        rel_root = os.path.relpath(root, REPO_DIR)
        if rel_root == ".":
            dirs[:] = [
                d for d in dirs
                if not _is_ignored(d, patterns)
                and d != ".git"
                and d not in EXTRA_SKIP
            ]
        for f in files:
            rel = f if rel_root == "." else os.path.join(rel_root, f)
            rel = rel.replace(os.sep, "/")
            first = rel.split("/", 1)[0]
            if _is_ignored(first, patterns) or first in EXTRA_SKIP:
                continue
            out.append(rel)
    return sorted(out)


def _hash_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def _entry_for(target: Path) -> dict:
    if target.is_symlink():
        return {"kind": "symlink", "target": os.readlink(target)}
    if not target.exists():
        return {"kind": "missing"}
    if target.is_dir():
        return {"kind": "dir"}
    return {"kind": "file", "sha256": _hash_file(target)}


def capture(out_path: Path, home: Path) -> None:
    snapshot: dict[str, dict] = {}
    for rel in _stowable_paths():
        snapshot[rel] = _entry_for(home / rel)
    parents: set[str] = set()
    for rel in snapshot:
        parts = rel.split("/")
        for i in range(1, len(parts)):
            parents.add("/".join(parts[:i]))
    for p in sorted(parents):
        if p not in snapshot:
            snapshot[p] = _entry_for(home / p)
    out_path.write_text(json.dumps(snapshot, indent=2, sort_keys=True) + "\n")


def diff(a_path: Path, b_path: Path, exclude: list[str]) -> int:
    a = json.loads(a_path.read_text())
    b = json.loads(b_path.read_text())
    excluded = set(exclude)
    keys = sorted(set(a) | set(b))
    differences: list[str] = []
    for k in keys:
        if k in excluded:
            continue
        av = a.get(k, {"kind": "missing"})
        bv = b.get(k, {"kind": "missing"})
        if av != bv:
            differences.append(f"  {k}: {av} -> {bv}")
    if differences:
        print(f"Snapshots differ ({len(differences)} path(s)):")
        for d in differences:
            print(d)
        return 1
    print("Snapshots equal (after exclusions).")
    return 0


def main() -> int:
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)

    cap = sub.add_parser("capture")
    cap.add_argument("out", type=Path)
    cap.add_argument("--home", type=Path, default=Path.home())

    d = sub.add_parser("diff")
    d.add_argument("a", type=Path)
    d.add_argument("b", type=Path)
    d.add_argument("--exclude", type=str, default="")

    args = p.parse_args()
    if args.cmd == "capture":
        capture(args.out, args.home)
        return 0
    if args.cmd == "diff":
        exclude = [e for e in args.exclude.split(",") if e]
        return diff(args.a, args.b, exclude)
    return 2


if __name__ == "__main__":
    sys.exit(main())
