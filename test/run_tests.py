#!/usr/bin/env python3
"""Build and run test containers for each supported OS."""

import subprocess
import sys
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parent.parent
TEST_DIR = REPO_DIR / "test"

TARGETS = ["debian", "ubuntu", "arch"]


def main() -> int:
    targets = sys.argv[1:] or TARGETS
    unknown = [t for t in targets if t not in TARGETS]
    if unknown:
        print(f"Unknown target(s): {', '.join(unknown)}. Valid: {', '.join(TARGETS)}")
        return 2

    failures = []

    for target in targets:
        dockerfile = TEST_DIR / f"Dockerfile.{target}"
        if not dockerfile.exists():
            print(f"[skip] {target}: Dockerfile not found")
            continue

        tag = f"dotfiles-test-{target}"
        print(f"\n{'='*60}")
        print(f"Testing: {target}")
        print(f"{'='*60}\n")

        # Build
        result = subprocess.run(
            ["docker", "build", "-f", str(dockerfile), "-t", tag, str(REPO_DIR)],
            capture_output=False,
        )
        if result.returncode != 0:
            print(f"[FAIL] {target}: build failed")
            failures.append(target)
            continue

        print(f"[pass] {target}")

    print(f"\n{'='*60}")
    if failures:
        print(f"Failed: {', '.join(failures)}")
        return 1
    else:
        print("All tests passed.")
        return 0


if __name__ == "__main__":
    sys.exit(main())
