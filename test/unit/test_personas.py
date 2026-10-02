"""Consistency checks between the persona agents, their rules, and the guardrails plugin."""

import json
import re
import unittest
from pathlib import Path

import yaml

REPO_DIR = Path(__file__).resolve().parent.parent.parent
AGENTS = REPO_DIR / ".claude" / "agents"
RULES = REPO_DIR / ".claude" / "rules"
PLUGIN = REPO_DIR / ".claude" / "marketplace" / "plugins" / "guardrails"
ALWAYS_ON = {"core.md", "delegation.md"}
SKILL_REF = re.compile(r"\bguardrails:([a-z][a-z0-9-]*)")


def split_frontmatter(path):
    """Return (frontmatter dict or None, body) for a markdown file."""
    text = path.read_text()
    if not text.startswith("---\n"):
        return None, text
    end = text.index("\n---\n", 4)
    return yaml.safe_load(text[4:end]), text[end + 5 :]


def agent_files():
    return sorted(AGENTS.glob("*.md"))


class PersonaAgents(unittest.TestCase):
    def test_agents_exist(self):
        self.assertTrue(agent_files(), "no agent files")

    def test_every_agent_declares_name_description_and_tools(self):
        for path in agent_files():
            with self.subTest(agent=path.name):
                meta, _ = split_frontmatter(path)
                self.assertIsNotNone(meta, "missing frontmatter")
                self.assertEqual(meta.get("name"), path.stem)
                self.assertTrue(meta.get("description"))
                tools = [t.strip() for t in meta.get("tools", "").split(",")]
                self.assertIn("Skill", tools)

    def test_report_hook_matcher_lists_exactly_the_agents(self):
        hooks = json.loads((PLUGIN / "hooks" / "hooks.json").read_text())["hooks"]
        matchers = [
            entry["matcher"]
            for entry in hooks.get("SubagentStop", [])
            if any("persona-report.sh" in h["command"] for h in entry["hooks"])
        ]
        self.assertEqual(len(matchers), 1)
        self.assertEqual(set(matchers[0].split("|")), {p.stem for p in agent_files()})


class PersonaRules(unittest.TestCase):
    def test_only_core_and_delegation_load_unscoped(self):
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


class SkillReferences(unittest.TestCase):
    def test_every_guardrails_skill_named_exists(self):
        for path in [*agent_files(), *RULES.glob("*.md")]:
            for name in SKILL_REF.findall(path.read_text()):
                with self.subTest(file=path.name, skill=name):
                    self.assertTrue((PLUGIN / "skills" / name / "SKILL.md").is_file())


if __name__ == "__main__":
    unittest.main()
