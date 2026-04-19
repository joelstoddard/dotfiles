#!/usr/bin/env python3
"""Snapshot $HOME at stow-relevant paths; diff two snapshots."""

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
MISSING = {"kind": "missing"}


def load_stow_patterns() -> list[re.Pattern]:
    if not STOW_IGNORE_FILE.exists():
        return []
    out: list[re.Pattern] = []
    for raw in STOW_IGNORE_FILE.read_text().splitlines():
        raw = raw.strip()
        if raw and not raw.startswith("#"):
            out.append(re.compile(raw))
    return out


def stowable_paths() -> list[str]:
    patterns = load_stow_patterns()
    ignored = lambda seg: any(p.search(seg) for p in patterns)
    out: list[str] = []
    for root, dirs, files in os.walk(REPO_DIR):
        rel_root = os.path.relpath(root, REPO_DIR)
        dirs[:] = [d for d in dirs if d != ".git" and not ignored(d)]
        for f in files:
            rel = f if rel_root == "." else os.path.join(rel_root, f)
            rel = rel.replace(os.sep, "/")
            if not any(ignored(seg) for seg in rel.split("/")):
                out.append(rel)
    return sorted(out)


def hash_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def entry_for(target: Path) -> dict:
    if target.is_symlink():
        return {"kind": "symlink", "target": os.readlink(target)}
    if not target.exists():
        return MISSING
    if target.is_dir():
        return {"kind": "dir"}
    return {"kind": "file", "sha256": hash_file(target)}


def capture(out_path: Path, home: Path) -> None:
    paths = stowable_paths()
    parents = {"/".join(p.split("/")[:i]) for p in paths for i in range(1, p.count("/") + 1)}
    snapshot = {rel: entry_for(home / rel) for rel in sorted(set(paths) | parents)}
    out_path.write_text(json.dumps(snapshot, indent=2, sort_keys=True) + "\n")


def diff(a_path: Path, b_path: Path) -> int:
    a = json.loads(a_path.read_text())
    b = json.loads(b_path.read_text())
    differences = [
        f"  {k}: {a.get(k, MISSING)} -> {b.get(k, MISSING)}"
        for k in sorted(set(a) | set(b))
        if a.get(k, MISSING) != b.get(k, MISSING)
    ]
    if differences:
        print(f"Snapshots differ ({len(differences)} path(s)):")
        for d in differences:
            print(d)
        return 1
    print("Snapshots equal.")
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

    args = p.parse_args()
    if args.cmd == "capture":
        capture(args.out, args.home)
        return 0
    if args.cmd == "diff":
        return diff(args.a, args.b)
    return 2


if __name__ == "__main__":
    sys.exit(main())
