#!/usr/bin/env python3
"""Generate tool-specific color configs from the central palette.yaml.

Produces:
  - .config/alacritty/colors.toml
  - Validates oh-my-posh and git configs use matching palette colors (warns on mismatch)
"""

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import yaml

REPO_DIR = Path(__file__).resolve().parent.parent
PALETTE_PATH = REPO_DIR / "theme" / "palette.yaml"


def load_palette() -> dict:
    with open(PALETTE_PATH) as f:
        return yaml.safe_load(f)


def flatten_palette(palette: dict) -> dict[str, str]:
    """Flatten nested palette into {name: hex} pairs."""
    flat = {}
    for section in ("base", "accent", "semantic"):
        if section in palette:
            for key, value in palette[section].items():
                flat[f"{section}.{key}"] = value
                flat[key] = value  # Also store without prefix
    return flat


def generate_alacritty_colors(palette: dict) -> str:
    """Generate Alacritty TOML color scheme."""
    base = palette.get("base", {})
    accent = palette.get("accent", {})

    return f"""\
# Generated from theme/palette.yaml — do not edit manually
# Regenerate with: make generate-theme

[colors.primary]
background = "{base.get('bg', '#282828')}"
foreground = "{base.get('fg', '#ebdbb2')}"

[colors.cursor]
cursor = "{base.get('fg', '#ebdbb2')}"
text = "{base.get('bg', '#282828')}"

[colors.selection]
background = "{base.get('bg-soft', '#32302f')}"
foreground = "{base.get('fg-bright', '#fbf1c7')}"

[colors.normal]
black   = "{base.get('bg', '#282828')}"
red     = "{accent.get('red', '#AC4242')}"
green   = "{accent.get('green', '#90A959')}"
yellow  = "{accent.get('orange', '#F79625')}"
blue    = "{accent.get('blue', '#326CE5')}"
magenta = "{accent.get('purple', '#AA759F')}"
cyan    = "{base.get('muted', '#a89984')}"
white   = "{base.get('fg', '#ebdbb2')}"

[colors.bright]
black   = "{base.get('muted', '#a89984')}"
red     = "{accent.get('red', '#AC4242')}"
green   = "{accent.get('green', '#90A959')}"
yellow  = "{accent.get('yellow', '#FFDE57')}"
blue    = "{accent.get('blue', '#326CE5')}"
magenta = "{accent.get('purple', '#AA759F')}"
cyan    = "{base.get('fg', '#ebdbb2')}"
white   = "{base.get('fg-bright', '#fbf1c7')}"
"""


def validate_config_colors(flat: dict[str, str]) -> list[str]:
    """Check that oh-my-posh and git configs use colors from the palette.

    Returns a list of warnings for mismatched colors.
    """
    warnings = []
    palette_colors = {v.lower() for v in flat.values()}

    # Check oh-my-posh theme
    omp_path = REPO_DIR / ".config" / "oh-my-posh" / "theme.yaml"
    if omp_path.exists():
        content = omp_path.read_text()
        hex_colors = set(re.findall(r'#[0-9A-Fa-f]{6}', content))
        for color in hex_colors:
            if color.lower() not in palette_colors:
                warnings.append(f"oh-my-posh: {color} not in palette")

    # Check git config
    git_path = REPO_DIR / ".config" / "git" / "config"
    if git_path.exists():
        content = git_path.read_text()
        hex_colors = set(re.findall(r'#[0-9A-Fa-f]{6}', content))
        for color in hex_colors:
            if color.lower() not in palette_colors:
                warnings.append(f"git config: {color} not in palette")

    return warnings


def main() -> None:
    palette = load_palette()
    flat = flatten_palette(palette)

    # Generate Alacritty colors
    alacritty_out = REPO_DIR / ".config" / "alacritty" / "colors.toml"
    alacritty_out.parent.mkdir(parents=True, exist_ok=True)
    alacritty_out.write_text(generate_alacritty_colors(palette))
    print(f"  Generated: {alacritty_out}")

    # Validate other configs
    warnings = validate_config_colors(flat)
    if warnings:
        print("\n  Palette warnings:")
        for w in warnings:
            print(f"    - {w}")
    else:
        print("  All config colors match palette.")


if __name__ == "__main__":
    main()
