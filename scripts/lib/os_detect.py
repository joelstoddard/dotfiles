"""Detect the current operating system, distribution, and environment."""

import os
import platform
import shutil
from dataclasses import dataclass


@dataclass
class Platform:
    os: str  # "linux" | "macos"
    distro: str  # "arch" | "debian" | "ubuntu" | ""
    pkg_manager: str  # "pacman" | "apt" | "brew"
    has_gui: bool
    arch: str  # "x86_64" | "arm64"

    def __str__(self) -> str:
        parts = [f"OS: {self.os}"]
        if self.distro:
            parts.append(f"Distro: {self.distro}")
        parts.append(f"Package manager: {self.pkg_manager}")
        parts.append(f"GUI: {'yes' if self.has_gui else 'no'}")
        parts.append(f"Arch: {self.arch}")
        return ", ".join(parts)


def _read_os_release() -> dict[str, str]:
    """Parse /etc/os-release into a dict."""
    result = {}
    path = "/etc/os-release"
    if not os.path.isfile(path):
        return result
    with open(path) as f:
        for line in f:
            line = line.strip()
            if "=" in line:
                key, _, value = line.partition("=")
                result[key] = value.strip('"')
    return result


def _detect_arch() -> str:
    machine = platform.machine().lower()
    if machine in ("arm64", "aarch64"):
        return "arm64"
    return "x86_64"


def _detect_gui() -> bool:
    """Check if a GUI display server is available."""
    return bool(os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY"))


def detect() -> Platform:
    system = platform.system()
    arch = _detect_arch()

    if system == "Darwin":
        return Platform(
            os="macos",
            distro="",
            pkg_manager="brew",
            has_gui=True,
            arch=arch,
        )

    if system == "Linux":
        os_release = _read_os_release()
        distro_id = os_release.get("ID", "").lower()

        # Map distro families
        if distro_id in ("debian", "ubuntu", "linuxmint", "pop"):
            distro = "ubuntu" if distro_id == "ubuntu" else "debian"
            pkg_manager = "apt"
            has_gui = _detect_gui()
        elif distro_id == "arch":
            distro = "arch"
            pkg_manager = "pacman"
            # Arch with Omarchy typically has a GUI; detect anyway
            has_gui = _detect_gui() or shutil.which("sway") is not None
        else:
            distro = distro_id
            pkg_manager = "unknown"
            has_gui = _detect_gui()

        return Platform(
            os="linux",
            distro=distro,
            pkg_manager=pkg_manager,
            has_gui=has_gui,
            arch=arch,
        )

    raise RuntimeError(f"Unsupported operating system: {system}")
