#!/usr/bin/env python3
"""Generate tool-specific color configs from the central palette.yaml.

Produces:
  - .config/alacritty/colors.toml
  - .config/btop/themes/ash-plus.theme
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
    """Generate Alacritty TOML color scheme.

    ANSI palette is intentionally monochrome (ash-style). Tools that want
    color signals (git, oh-my-posh segments, etc.) override via explicit
    hex in their own configs — the terminal's default palette stays quiet.
    """
    base = palette.get("base", {})

    return f"""\
# Generated from theme/palette.yaml — do not edit manually
# Regenerate with: make generate-theme

[colors.primary]
background = "{base.get('bg', '#121212')}"
foreground = "{base.get('fg', '#e0e0e0')}"

[colors.cursor]
cursor = "{base.get('fg', '#e0e0e0')}"
text = "{base.get('bg', '#121212')}"

[colors.selection]
background = "{base.get('bg-soft', '#1a1a1a')}"
foreground = "{base.get('fg-bright', '#ffffff')}"

[colors.normal]
black   = "{base.get('bg', '#121212')}"
red     = "{base.get('muted', '#8a8a8a')}"
green   = "{base.get('dim', '#626262')}"
yellow  = "{base.get('muted', '#8a8a8a')}"
blue    = "{base.get('dim', '#626262')}"
magenta = "{base.get('muted', '#8a8a8a')}"
cyan    = "{base.get('dim', '#626262')}"
white   = "{base.get('fg', '#e0e0e0')}"

[colors.bright]
black   = "{base.get('muted', '#8a8a8a')}"
red     = "{base.get('fg', '#e0e0e0')}"
green   = "{base.get('dim', '#626262')}"
yellow  = "{base.get('fg', '#e0e0e0')}"
blue    = "{base.get('dim', '#626262')}"
magenta = "{base.get('muted', '#8a8a8a')}"
cyan    = "{base.get('fg', '#e0e0e0')}"
white   = "{base.get('fg-bright', '#ffffff')}"
"""


def generate_btop_theme(palette: dict) -> str:
    """Generate btop theme from palette. Monochrome chrome; accents only on load."""
    b, a = palette["base"], palette["accent"]
    bg, fg, fg_br, muted, dim = b["bg"], b["fg"], b["fg-bright"], b["muted"], b["dim"]
    red, orange = a["red"], a["orange"]

    # Non-gradient UI chrome, all from the grayscale base.
    chrome = {
        "main_bg": bg, "main_fg": fg, "title": fg_br, "hi_fg": fg_br,
        "selected_bg": b["bg-soft"], "selected_fg": fg_br, "inactive_fg": dim,
        "graph_text": muted, "meter_bg": b["bg-soft"], "proc_misc": muted,
        "div_line": dim,
        "cpu_box": muted, "mem_box": muted, "net_box": muted, "proc_box": muted,
    }
    # Gradients: (name, start, mid, end). btop interpolates linearly through
    # the three stops. Load signals (cpu/used/temp/process) stay flat gray
    # until the upper half of the range and only fade to red near max.
    # Network peaks at orange. free/available/cached stay monochrome.
    gradients = [
        ("cpu",       muted, muted, red),
        ("used",      muted, muted, red),
        ("temp",      muted, muted, red),
        ("process",   muted, muted, red),
        ("download",  dim,   muted, orange),
        ("upload",    dim,   muted, orange),
        ("free",      dim,   muted, fg),
        ("available", dim,   muted, fg),
        ("cached",    dim,   muted, fg),
    ]

    lines = ["# Generated from theme/palette.yaml - do not edit manually",
             "# Regenerate with: make generate-theme", ""]
    lines += [f'theme[{k}]="{v}"' for k, v in chrome.items()]
    for name, start, mid, end in gradients:
        lines += [f'theme[{name}_start]="{start}"',
                  f'theme[{name}_mid]="{mid}"',
                  f'theme[{name}_end]="{end}"']
    return "\n".join(lines) + "\n"


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

    # Generate btop theme
    btop_out = REPO_DIR / ".config" / "btop" / "themes" / "ash-plus.theme"
    btop_out.parent.mkdir(parents=True, exist_ok=True)
    btop_out.write_text(generate_btop_theme(palette))
    print(f"  Generated: {btop_out}")

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
