#!/usr/bin/env python3
"""Snapshot $HOME at stow-relevant paths; diff two snapshots.

Used by e2e tests to verify uninstall.sh restores the pre-install state.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parent.parent.parent
STOW_IGNORE_FILE = REPO_DIR / ".stow-local-ignore"


def _load_stow_patterns() -> list[re.Pattern]:
    """Parse .stow-local-ignore into compiled regexes.

    Per stow(1): each non-blank line is a Perl regex applied to every path
    segment. A path is ignored if any segment matches any pattern.
    """
    if not STOW_IGNORE_FILE.exists():
        return []
    out: list[re.Pattern] = []
    for raw in STOW_IGNORE_FILE.read_text().splitlines():
        raw = raw.strip()
        if not raw or raw.startswith("#"):
            continue
        out.append(re.compile(raw))
    return out


def _segment_ignored(segment: str, patterns: list[re.Pattern]) -> bool:
    return any(p.search(segment) for p in patterns)


def _path_ignored(relpath: str, patterns: list[re.Pattern]) -> bool:
    return any(_segment_ignored(seg, patterns) for seg in relpath.split("/"))


def _stowable_paths() -> list[str]:
    """Enumerate repo-root-relative paths that stow would link into $HOME."""
    patterns = _load_stow_patterns()
    out: list[str] = []
    for root, dirs, files in os.walk(REPO_DIR):
        rel_root = os.path.relpath(root, REPO_DIR)
        # Prune ignored directories so we don't descend into them.
        dirs[:] = [
            d for d in dirs
            if d != ".git" and not _segment_ignored(d, patterns)
        ]
        for f in files:
            rel = f if rel_root == "." else os.path.join(rel_root, f)
            rel = rel.replace(os.sep, "/")
            if _path_ignored(rel, patterns):
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
