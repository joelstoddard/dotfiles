"""Checks on the rules this repo links into ~/.claude/rules."""

import re
import unittest
from pathlib import Path

import yaml

REPO_DIR = Path(__file__).resolve().parent.parent.parent
RULES = REPO_DIR / ".claude" / "rules"
ALWAYS_ON = {"context.md"}
MOVED = re.compile(r"(?<![\w/-])core\.md|delegation\.md|guardrails:")
RETIRED = re.compile(r"\b(?:ALWAYS|NEVER)\b")


def split_frontmatter(path):
    """Return (frontmatter dict or None, body) for a markdown file."""
    text = path.read_text()
    if not text.startswith("---\n"):
        return None, text
    end = text.index("\n---\n", 4)
    return yaml.safe_load(text[4:end]), text[end + 5 :]


class Rules(unittest.TestCase):
    def test_only_context_loads_unscoped(self):
        # Claude Code silently loads a rule unscoped when its frontmatter does not parse.
        unscoped = set()
        for path in RULES.glob("*.md"):
            meta, _ = split_frontmatter(path)
            if not meta or not meta.get("paths"):
                unscoped.add(path.name)
        self.assertEqual(unscoped, ALWAYS_ON)

    def test_scoped_rule_paths_are_strings(self):
        for path in RULES.glob("*.md"):
            if path.name in ALWAYS_ON:
                continue
            with self.subTest(rule=path.name):
                meta, _ = split_frontmatter(path)
                paths = meta["paths"]
                if isinstance(paths, str):
                    paths = [p.strip() for p in paths.split(",")]
                self.assertTrue(paths)
                for glob in paths:
                    self.assertIsInstance(glob, str)
                    self.assertTrue(glob)

    def test_no_rule_names_a_file_or_skill_that_moved(self):
        for path in RULES.glob("*.md"):
            with self.subTest(rule=path.name):
                self.assertIsNone(MOVED.search(path.read_text()))

    def test_rules_use_bcp14_keywords(self):
        # guardrails' conduct.md defines BCP 14 keywords only, so ALWAYS / NEVER are undefined.
        for path in RULES.glob("*.md"):
            with self.subTest(rule=path.name):
                self.assertIsNone(RETIRED.search(path.read_text()))


if __name__ == "__main__":
    unittest.main()
