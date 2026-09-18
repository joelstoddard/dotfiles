"""Tests for the clean filter that keeps session state out of user-settings.json.

Each test wires a throwaway repo with the real .gitattributes and the real
installer function, so the two cannot drift apart unnoticed.
"""

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from scripts.install import configure_settings_filter

REPO_DIR = Path(__file__).resolve().parent.parent.parent
GITATTRIBUTES = REPO_DIR / ".gitattributes"
TRACKED = ".claude/user-settings.json"


def git(repo: Path, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", "-C", str(repo), *args], capture_output=True, text=True
    )


class SettingsCleanFilter(unittest.TestCase):
    def setUp(self):
        if shutil.which("jq") is None:
            self.skipTest("jq not installed")
        self.repo = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.repo, ignore_errors=True)
        git(self.repo, "init", "-q")
        shutil.copy(GITATTRIBUTES, self.repo / ".gitattributes")
        configure_settings_filter(repo=self.repo)
        self.settings = self.repo / TRACKED
        self.settings.parent.mkdir(parents=True)
        git(self.repo, "add", ".gitattributes")
        self.commit()

    def stage(self, payload: dict) -> str:
        """Write payload, stage it, and return the blob git actually stored."""
        self.settings.write_text(json.dumps(payload, indent=2))
        git(self.repo, "add", TRACKED)
        return git(self.repo, "show", f":{TRACKED}").stdout

    def commit(self):
        git(self.repo, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", "seed")

    def test_model_is_stripped_from_the_staged_blob(self):
        staged = json.loads(self.stage({"model": "opus", "effortLevel": "xhigh"}))
        self.assertNotIn("model", staged)
        self.assertEqual(staged["effortLevel"], "xhigh")

    def test_the_working_file_keeps_its_model(self):
        self.stage({"model": "opus"})
        self.assertEqual(json.loads(self.settings.read_text())["model"], "opus")

    def test_keys_are_sorted_so_a_rewrite_is_not_a_diff(self):
        blob = self.stage({"tui": "fullscreen", "effortLevel": "xhigh", "agent": "x"})
        keys = list(json.loads(blob).keys())
        self.assertEqual(keys, sorted(keys))

    def test_switching_model_leaves_nothing_to_commit(self):
        self.stage({"model": "opus", "effortLevel": "xhigh"})
        self.commit()
        self.settings.write_text(
            json.dumps({"model": "sonnet", "effortLevel": "xhigh"}, indent=2)
        )
        self.assertEqual(git(self.repo, "diff", "--", TRACKED).stdout, "")

    def test_switching_model_records_nothing_in_history(self):
        """The guarantee that matters: a model switch cannot reach a commit.

        `git status` still lists the file — it decides from stat alone and does
        not run the filter — so the tree looks dirty even though `git diff` is
        empty. Committing is what proves the point.
        """
        self.stage({"model": "opus", "effortLevel": "xhigh"})
        self.commit()
        before = git(self.repo, "rev-parse", "HEAD^{tree}").stdout
        self.settings.write_text(
            json.dumps({"model": "sonnet", "effortLevel": "xhigh"}, indent=2)
        )
        self.assertIn(TRACKED, git(self.repo, "status", "--porcelain").stdout)
        git(self.repo, "add", "-A")
        self.commit()
        self.assertEqual(git(self.repo, "rev-parse", "HEAD^{tree}").stdout, before)

    def test_reordering_keys_leaves_nothing_to_commit(self):
        self.stage({"effortLevel": "xhigh", "tui": "fullscreen"})
        self.commit()
        self.settings.write_text(
            json.dumps({"tui": "fullscreen", "effortLevel": "xhigh"}, indent=2)
        )
        self.assertEqual(git(self.repo, "diff", "--", TRACKED).stdout, "")

    def test_a_real_setting_change_still_shows_up(self):
        """The filter must not swallow edits that matter."""
        self.stage({"model": "opus", "effortLevel": "xhigh"})
        self.commit()
        self.settings.write_text(
            json.dumps({"model": "opus", "effortLevel": "low"}, indent=2)
        )
        self.assertIn("effortLevel", git(self.repo, "diff", "--", TRACKED).stdout)


if __name__ == "__main__":
    unittest.main()
