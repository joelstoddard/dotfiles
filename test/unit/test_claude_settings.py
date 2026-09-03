"""Tests for the ~/.claude/settings.json link the installer manages."""

import shutil
import tempfile
import unittest
from pathlib import Path

from scripts.install import setup_claude_settings_symlink
from scripts.uninstall import remove_claude_settings_symlink

REPO_DIR = Path(__file__).resolve().parent.parent.parent
TARGET = REPO_DIR / ".claude" / "user-settings.json"


class ClaudeSettingsLink(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.link = self.tmp / ".claude" / "settings.json"

    def test_creates_link_when_absent(self):
        setup_claude_settings_symlink(home=self.tmp)
        self.assertTrue(self.link.is_symlink())
        self.assertEqual(self.link.resolve(), TARGET.resolve())

    def test_idempotent(self):
        setup_claude_settings_symlink(home=self.tmp)
        setup_claude_settings_symlink(home=self.tmp)
        self.assertEqual(self.link.resolve(), TARGET.resolve())

    def test_backs_up_an_existing_real_file(self):
        self.link.parent.mkdir(parents=True)
        self.link.write_text('{"keep": "me"}')
        setup_claude_settings_symlink(home=self.tmp)
        backup = self.link.with_name("settings.json.bak-pre-symlink")
        self.assertEqual(backup.read_text(), '{"keep": "me"}')
        self.assertTrue(self.link.is_symlink())

    def test_uninstall_leaves_a_real_file_alone(self):
        self.link.parent.mkdir(parents=True)
        self.link.write_text('{"mine": true}')
        remove_claude_settings_symlink(home=self.tmp)
        self.assertEqual(self.link.read_text(), '{"mine": true}')

    def test_install_then_uninstall_leaves_no_trace(self):
        setup_claude_settings_symlink(home=self.tmp)
        remove_claude_settings_symlink(home=self.tmp)
        self.assertFalse(self.link.exists())
        self.assertFalse(self.link.is_symlink())


if __name__ == "__main__":
    unittest.main()
