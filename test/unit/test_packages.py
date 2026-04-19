"""Tests for scripts/lib/packages.py resolution and dispatch logic."""

import unittest
from unittest.mock import patch

from scripts.lib import packages
from scripts.lib.os_detect import Platform

from . import FIXTURES


def _platform(os_: str, distro: str, pkg_manager: str) -> Platform:
    return Platform(
        os=os_, distro=distro, pkg_manager=pkg_manager,
        has_gui=False, arch="x86_64",
    )


class Load(unittest.TestCase):
    def test_parses_fixture(self):
        data = packages.load(FIXTURES / "packages-small.yaml")
        self.assertIn("core", data)
        self.assertIn("git", data["core"])


class Resolve(unittest.TestCase):
    def test_skips_packages_missing_for_platform(self):
        data = packages.load(FIXTURES / "packages-small.yaml")
        macos = _platform("macos", "", "brew")
        resolved = packages.resolve(data, macos)
        keys = [s.key for s in resolved.get("core", [])]
        self.assertIn("git", keys)
        self.assertIn("ripgrep", keys)
        self.assertNotIn("linux-only-tool", keys)

    def test_includes_platform_matching_packages(self):
        data = packages.load(FIXTURES / "packages-small.yaml")
        arch = _platform("linux", "arch", "pacman")
        resolved = packages.resolve(data, arch)
        keys = [s.key for s in resolved.get("core", [])]
        self.assertIn("git", keys)
        self.assertIn("ripgrep", keys)
        self.assertIn("linux-only-tool", keys)

    def test_tilde_defaults_to_key_as_name(self):
        data = packages.load(FIXTURES / "packages-small.yaml")
        arch = _platform("linux", "arch", "pacman")
        resolved = packages.resolve(data, arch)
        git_spec = next(s for s in resolved["core"] if s.key == "git")
        self.assertEqual(git_spec.name, "git")
        self.assertEqual(git_spec.install_type, "default")

    def test_dict_entry_with_type_default(self):
        data = packages.load(FIXTURES / "packages-small.yaml")
        debian = _platform("linux", "debian", "apt")
        resolved = packages.resolve(data, debian)
        rg = next(s for s in resolved["core"] if s.key == "ripgrep")
        self.assertEqual(rg.name, "ripgrep")
        self.assertEqual(rg.install_type, "default")


class InstallAll(unittest.TestCase):
    def test_dry_run_does_not_invoke_subprocess(self):
        data = packages.load(FIXTURES / "packages-small.yaml")
        arch = _platform("linux", "arch", "pacman")
        resolved = packages.resolve(data, arch)
        with patch("subprocess.run") as mock_run, \
             patch("scripts.lib.packages.is_installed", return_value=False):
            result = packages.install_all(
                resolved, arch,
                selected=["core"], excluded=[], dry_run=True,
            )
        mock_run.assert_not_called()
        self.assertEqual(len(result.failed), 0)
        self.assertGreater(len(result.installed), 0)

    def test_skips_already_installed_packages(self):
        data = packages.load(FIXTURES / "packages-small.yaml")
        arch = _platform("linux", "arch", "pacman")
        resolved = packages.resolve(data, arch)
        with patch("subprocess.run"), \
             patch("scripts.lib.packages.is_installed", return_value=True):
            result = packages.install_all(
                resolved, arch,
                selected=["core"], excluded=[], dry_run=False,
            )
        self.assertEqual(len(result.installed), 0)
        self.assertEqual(len(result.failed), 0)
        self.assertGreater(len(result.skipped), 0)


if __name__ == "__main__":
    unittest.main()
