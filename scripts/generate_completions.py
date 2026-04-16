#!/usr/bin/env python3
"""Generate zsh completions for installed tools.

Writes completion files to ~/.local/share/zsh/completions/ which is
added to fpath by .zshrc.
"""

import shutil
import subprocess
from pathlib import Path

COMPLETIONS_DIR = Path.home() / ".local" / "share" / "zsh" / "completions"

# tool -> (check_binary, completion_command, output_filename)
TOOLS = [
    ("kubectl",   ["kubectl", "completion", "zsh"],                  "_kubectl"),
    ("helm",      ["helm", "completion", "zsh"],                     "_helm"),
    ("gh",        ["gh", "completion", "-s", "zsh"],                 "_gh"),
    ("docker",    ["docker", "completion", "zsh"],                   "_docker"),
    ("tailscale", ["tailscale", "completion", "zsh"],                "_tailscale"),
    ("terraform", ["terraform", "-install-autocomplete"],             None),  # Self-installing
    ("uv",        ["uv", "generate-shell-completion", "zsh"],        "_uv"),
]


def main() -> None:
    COMPLETIONS_DIR.mkdir(parents=True, exist_ok=True)

    for binary, cmd, output_file in TOOLS:
        if not shutil.which(binary):
            continue

        if output_file is None:
            # Self-installing completion (terraform)
            try:
                subprocess.run(cmd, capture_output=True)
                print(f"  [ok] {binary} (self-installed)")
            except subprocess.CalledProcessError:
                pass
            continue

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            out_path = COMPLETIONS_DIR / output_file
            out_path.write_text(result.stdout)
            print(f"  [ok] {binary} -> {output_file}")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print(f"  [skip] {binary} (completion command failed)")


if __name__ == "__main__":
    main()
