"""Tests for scripts/lib/stow.py against a real stow binary."""

import shutil
import tempfile
import unittest
from pathlib import Path

from scripts.lib import stow


@unittest.skipIf(shutil.which("stow") is None, "stow not installed")
class StowLifecycle(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.repo = self.tmp / "repo"
        self.home = self.tmp / "home"
        self.repo.mkdir()
        self.home.mkdir()
        (self.repo / ".zshrc").write_text("# test\n")
        (self.repo / ".config").mkdir()
        (self.repo / ".config" / "foo").mkdir()
        (self.repo / ".config" / "foo" / "bar.conf").write_text("x=1\n")

    def test_apply_creates_symlinks(self):
        stow.apply(self.repo, target=self.home)
        self.assertTrue((self.home / ".zshrc").is_symlink())
        self.assertEqual(
            (self.home / ".zshrc").resolve(),
            (self.repo / ".zshrc").resolve(),
        )
        self.assertEqual(
            (self.home / ".config" / "foo" / "bar.conf").resolve(),
            (self.repo / ".config" / "foo" / "bar.conf").resolve(),
        )

    def test_remove_deletes_symlinks(self):
        stow.apply(self.repo, target=self.home)
        stow.remove(self.repo, target=self.home)
        self.assertFalse((self.home / ".zshrc").exists())
        self.assertFalse((self.home / ".config" / "foo" / "bar.conf").exists())

    def test_apply_then_remove_leaves_no_symlinks(self):
        stow.apply(self.repo, target=self.home)
        stow.remove(self.repo, target=self.home)
        for p in self.home.rglob("*"):
            self.assertFalse(p.is_symlink(), f"stray symlink: {p}")


if __name__ == "__main__":
    unittest.main()
