#!/usr/bin/env python3
"""Post-install verification script.

Checks that dotfiles are correctly symlinked, key binaries are available,
and configs are valid.
"""

import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

REPO_DIR = Path(__file__).resolve().parent.parent
HOME = Path.home()


class Verifier:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.warnings = 0

    def check(self, description: str, condition: bool) -> None:
        if condition:
            print(f"  [pass] {description}")
            self.passed += 1
        else:
            print(f"  [FAIL] {description}")
            self.failed += 1

    def warn(self, description: str) -> None:
        print(f"  [warn] {description}")
        self.warnings += 1

    def summary(self) -> int:
        print(f"\n  Results: {self.passed} passed, {self.failed} failed, {self.warnings} warnings")
        return 1 if self.failed > 0 else 0


def main() -> int:
    v = Verifier()

    print("=== Verifying symlinks ===")
    symlinks = [
        ".zshrc",
        ".config/git/config",
        ".config/git/ignore",
        ".config/git/template",
        ".config/tmux/tmux.conf",
        ".config/oh-my-posh/theme.yaml",
        ".config/alacritty/alacritty.toml",
    ]
    for rel in symlinks:
        target = HOME / rel
        is_link = target.is_symlink()
        v.check(f"{rel} is symlink", is_link)
        if is_link:
            resolved = target.resolve()
            in_repo = str(resolved).startswith(str(REPO_DIR))
            v.check(f"{rel} points to repo", in_repo)

    print("\n=== Verifying binaries ===")
    binaries = ["zsh", "tmux", "nvim", "oh-my-posh", "git", "stow"]
    for binary in binaries:
        v.check(f"{binary} on PATH", shutil.which(binary) is not None)

    print("\n=== Verifying configs ===")

    # zshrc syntax
    zshrc = HOME / ".zshrc"
    if zshrc.exists():
        result = subprocess.run(["zsh", "-n", str(zshrc)], capture_output=True)
        v.check(".zshrc syntax valid", result.returncode == 0)
    else:
        v.warn(".zshrc not found")

    # oh-my-posh YAML
    omp_config = HOME / ".config" / "oh-my-posh" / "theme.yaml"
    if omp_config.exists():
        try:
            import yaml
            with open(omp_config) as f:
                yaml.safe_load(f)
            v.check("oh-my-posh theme.yaml is valid YAML", True)
        except Exception:
            v.check("oh-my-posh theme.yaml is valid YAML", False)
    else:
        v.warn("oh-my-posh theme.yaml not found")

    # Alacritty os.toml symlink
    os_toml = HOME / ".config" / "alacritty" / "os.toml"
    if os_toml.exists():
        v.check("alacritty os.toml exists", True)
        v.check("alacritty os.toml is symlink", os_toml.is_symlink())
    else:
        v.warn("alacritty os.toml not found (run installer to create)")

    # Colors.toml exists
    colors_toml = HOME / ".config" / "alacritty" / "colors.toml"
    v.check("alacritty colors.toml exists", colors_toml.exists())

    # Zsh plugins
    print("\n=== Verifying zsh plugins ===")
    plugins = [
        ".local/share/zsh/plugins/zsh-completions",
        ".local/share/zsh/plugins/zsh-autosuggestions",
    ]
    for rel in plugins:
        v.check(f"{rel} exists", (HOME / rel).is_dir())

    return v.summary()


if __name__ == "__main__":
    sys.exit(main())
