"""Tests for scripts/lib/os_detect.py."""

import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

REPO_DIR = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_DIR))

from scripts.lib import os_detect  # noqa: E402

FIXTURES = Path(__file__).parent / "fixtures"


def _read_fixture(name: str) -> dict:
    result: dict[str, str] = {}
    for line in (FIXTURES / name).read_text().splitlines():
        line = line.strip()
        if "=" in line:
            k, _, v = line.partition("=")
            result[k] = v.strip('"')
    return result


class DetectMacOS(unittest.TestCase):
    def test_returns_brew_platform(self):
        with patch("platform.system", return_value="Darwin"), \
             patch("platform.machine", return_value="arm64"):
            p = os_detect.detect()
        self.assertEqual(p.os, "macos")
        self.assertEqual(p.pkg_manager, "brew")
        self.assertEqual(p.arch, "arm64")
        self.assertTrue(p.has_gui)
        self.assertEqual(p.distro, "")

    def test_x86_macos(self):
        with patch("platform.system", return_value="Darwin"), \
             patch("platform.machine", return_value="x86_64"):
            p = os_detect.detect()
        self.assertEqual(p.arch, "x86_64")


class DetectLinux(unittest.TestCase):
    def _detect_with(self, fixture: str, env: dict | None = None,
                     which_returns=None):
        env = env or {}
        data = _read_fixture(fixture)
        clean_env = {k: v for k, v in os.environ.items()
                     if k not in ("DISPLAY", "WAYLAND_DISPLAY")}
        clean_env.update(env)
        with patch("platform.system", return_value="Linux"), \
             patch("platform.machine", return_value="x86_64"), \
             patch.object(os_detect, "_read_os_release", return_value=data), \
             patch.dict(os.environ, clean_env, clear=True), \
             patch("shutil.which", return_value=which_returns):
            return os_detect.detect()

    def test_arch(self):
        p = self._detect_with("os-release-arch")
        self.assertEqual(p.os, "linux")
        self.assertEqual(p.distro, "arch")
        self.assertEqual(p.pkg_manager, "pacman")
        self.assertFalse(p.has_gui)

    def test_debian(self):
        p = self._detect_with("os-release-debian")
        self.assertEqual(p.distro, "debian")
        self.assertEqual(p.pkg_manager, "apt")

    def test_ubuntu(self):
        p = self._detect_with("os-release-ubuntu")
        self.assertEqual(p.distro, "ubuntu")
        self.assertEqual(p.pkg_manager, "apt")

    def test_linux_with_display_has_gui(self):
        p = self._detect_with("os-release-debian", env={"DISPLAY": ":0"})
        self.assertTrue(p.has_gui)

    def test_linux_with_wayland_has_gui(self):
        p = self._detect_with("os-release-debian",
                              env={"WAYLAND_DISPLAY": "wayland-0"})
        self.assertTrue(p.has_gui)

    def test_arch_with_sway_has_gui(self):
        p = self._detect_with("os-release-arch", which_returns="/usr/bin/sway")
        self.assertTrue(p.has_gui)


class DetectUnsupported(unittest.TestCase):
    def test_raises_on_unknown_system(self):
        with patch("platform.system", return_value="FreeBSD"):
            with self.assertRaises(RuntimeError):
                os_detect.detect()


if __name__ == "__main__":
    unittest.main()
