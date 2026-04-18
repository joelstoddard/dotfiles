"""Package resolution and installation from packages.yaml."""

import shutil
import subprocess
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

import yaml

from .github import fetch_latest_asset
from .os_detect import Platform


@dataclass
class PackageSpec:
    key: str
    category: str
    install_type: str  # "default" | "yay" | "cask" | "tap" | "script" | "github-release" | "npm" | "cargo" | "apt-repo" | "git"
    name: str
    check: Optional[str] = None
    repo: Optional[str] = None
    asset: Optional[str] = None
    install_cmd: Optional[str] = None
    url: Optional[str] = None
    setup: Optional[str] = None
    tap: Optional[str] = None
    target: Optional[str] = None


@dataclass
class InstallResult:
    installed: list[str] = field(default_factory=list)
    skipped: list[str] = field(default_factory=list)
    failed: list[str] = field(default_factory=list)

    def summary(self) -> str:
        lines = []
        if self.installed:
            lines.append(f"Installed ({len(self.installed)}): {', '.join(self.installed)}")
        if self.skipped:
            lines.append(f"Skipped ({len(self.skipped)}): {', '.join(self.skipped)}")
        if self.failed:
            lines.append(f"Failed ({len(self.failed)}): {', '.join(self.failed)}")
        return "\n".join(lines)


def load(yaml_path: Path) -> dict:
    """Load packages.yaml and return raw data."""
    with open(yaml_path) as f:
        return yaml.safe_load(f)


def resolve(data: dict, platform: Platform) -> dict[str, list[PackageSpec]]:
    """Resolve all packages for the current platform.

    Returns a dict of {category: [PackageSpec, ...]}.
    """
    os_key = platform.distro if platform.distro else platform.os
    # For macOS, the key in packages.yaml is "macos"
    if platform.os == "macos":
        os_key = "macos"

    categories: dict[str, list[PackageSpec]] = {}

    for category, packages in data.items():
        if not isinstance(packages, dict):
            continue
        specs = []
        for key, pkg_data in packages.items():
            if not isinstance(pkg_data, dict):
                continue
            if os_key not in pkg_data:
                continue

            raw = pkg_data[os_key]
            spec = _resolve_spec(key, category, raw, package_check=pkg_data.get("check"))
            if spec:
                specs.append(spec)
        if specs:
            categories[category] = specs

    return categories


def _resolve_spec(key: str, category: str, raw, package_check: Optional[str] = None) -> Optional[PackageSpec]:
    """Resolve a single OS entry into a PackageSpec.

    package_check is the top-level check from the package dict, used as a fallback
    when the per-OS entry doesn't specify its own check.
    """
    if raw is None:
        # ~ means default package manager, name = key
        return PackageSpec(key=key, category=category, install_type="default", name=key, check=package_check)

    if isinstance(raw, str):
        # Bare string means default package manager, custom name
        return PackageSpec(key=key, category=category, install_type="default", name=raw, check=package_check)

    if isinstance(raw, dict):
        install_type = raw.get("type", "default")
        if install_type == "apt":
            install_type = "default"
        return PackageSpec(
            key=key,
            category=category,
            install_type=install_type,
            name=raw.get("name", key),
            check=raw.get("check", package_check),
            repo=raw.get("repo"),
            asset=raw.get("asset"),
            install_cmd=raw.get("install"),
            url=raw.get("url"),
            setup=raw.get("setup"),
            tap=raw.get("tap"),
            target=raw.get("target"),
        )

    return None


def is_installed(spec: PackageSpec) -> bool:
    """Check if a package is already installed."""
    if spec.check:
        # Custom check command
        try:
            subprocess.run(
                spec.check, shell=True,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                check=True,
            )
            return True
        except subprocess.CalledProcessError:
            return False

    # Default: check if binary with same name as key is on PATH
    return shutil.which(spec.key) is not None


def install_package(spec: PackageSpec, platform: Platform, dry_run: bool = False) -> bool:
    """Install a single package. Returns True on success."""
    cmd = _build_install_command(spec, platform)
    if cmd is None:
        print(f"  [skip] {spec.key}: no install command for type '{spec.install_type}'")
        return False

    if dry_run:
        print(f"  [dry-run] {spec.key}: {cmd}")
        return True

    print(f"  [install] {spec.key}...")
    try:
        # Run setup commands first (e.g., adding apt repos)
        if spec.setup:
            subprocess.run(spec.setup, shell=True, check=True)

        if isinstance(cmd, str):
            subprocess.run(cmd, shell=True, check=True)
        else:
            subprocess.run(cmd, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, OSError) as e:
        print(f"  [error] {spec.key}: {e}")
        return False


def _build_install_command(spec: PackageSpec, platform: Platform):
    """Build the shell command to install a package."""
    match spec.install_type:
        case "default":
            match platform.pkg_manager:
                case "pacman":
                    return ["sudo", "pacman", "-S", "--noconfirm", "--needed", spec.name]
                case "apt":
                    return ["sudo", "apt", "install", "-y", spec.name]
                case "brew":
                    return ["brew", "install", spec.name]
                case _:
                    return None

        case "yay":
            # AUR packages often fetch sources from third-party origins that
            # can be transiently unreachable (e.g. the sipcalc PKGBUILD pulls
            # from routemeister.net). yay's own retries are ~3s apart, too
            # tight for brief origin outages; an outer loop with 30s backoff
            # covers a wider window.
            return (
                f'for i in 1 2 3; do '
                f'yay -S --noconfirm --needed {spec.name} && break; '
                f'[ "$i" -eq 3 ] && echo "yay install of {spec.name} failed after 3 attempts" && exit 1; '
                f'echo "yay install of {spec.name} failed (attempt $i), retrying in 30s..."; '
                f'sleep 30; '
                f'done'
            )

        case "cask":
            return ["brew", "install", "--cask", spec.name]

        case "tap":
            tap_cmd = f"brew tap {spec.tap} && brew install {spec.name}" if spec.tap else f"brew install {spec.name}"
            return tap_cmd

        case "script":
            if not spec.url:
                return None
            # Special cases for known installers
            if spec.key == "rust":
                return f"curl --proto '=https' --tlsv1.2 -sSf {spec.url} | sh -s -- -y"
            elif spec.key == "nvm":
                return f"curl -o- {spec.url} | bash"
            else:
                return f"curl -fsSL {spec.url} | bash -s"

        case "github-release":
            if not spec.repo or not spec.asset:
                return None
            try:
                url = fetch_latest_asset(spec.repo, spec.asset)
            except RuntimeError as e:
                print(f"  [error] {spec.key}: {e}")
                return None

            # --fail turns HTTP errors into non-zero exits (otherwise we'd write
            # a 5xx HTML body to disk and fail later with a confusing downstream
            # error). Retries handle transient 5xx from GitHub Releases.
            curl = 'curl --fail --retry 3 --retry-delay 5 --retry-all-errors -sSL'

            if spec.install_cmd:
                # Download to temp, then run install command
                return f'tmpfile=$(mktemp) && {curl} "{url}" -o "$tmpfile" && {spec.install_cmd.replace("{asset}", "$tmpfile")} && rm -f "$tmpfile"'
            elif url.endswith(".deb"):
                return f'tmpfile=$(mktemp --suffix=.deb) && {curl} "{url}" -o "$tmpfile" && sudo dpkg -i "$tmpfile"; sudo apt-get install -f -y && rm -f "$tmpfile"'
            elif url.endswith(".tar.gz"):
                return f'{curl} "{url}" | sudo tar -xzf - -C /usr/local/bin'
            else:
                return None

        case "npm":
            return ["npm", "install", "-g", spec.name]

        case "cargo":
            return ["cargo", "install", spec.name]

        case "apt-repo":
            # Setup is run separately, then install via apt
            return ["sudo", "apt", "install", "-y", spec.name]

        case "git":
            if not spec.repo or not spec.target:
                return None
            target = spec.target.replace("$HOME", "\"$HOME\"")
            return f'mkdir -p "$(dirname {target})" && git clone --no-tags https://github.com/{spec.repo} {target}'

        case _:
            return None


def install_all(
    categories: dict[str, list[PackageSpec]],
    platform: Platform,
    selected: list[str] | None = None,
    excluded: list[str] | None = None,
    dry_run: bool = False,
) -> InstallResult:
    """Install all packages from selected categories."""
    result = InstallResult()

    for category, specs in categories.items():
        if selected and category not in selected:
            continue
        if excluded and category in excluded:
            continue

        print(f"\n=== {category} ===")
        for spec in specs:
            if is_installed(spec):
                print(f"  [ok] {spec.key} (already installed)")
                result.skipped.append(spec.key)
                continue

            if install_package(spec, platform, dry_run=dry_run):
                result.installed.append(spec.key)
            else:
                result.failed.append(spec.key)

    return result
