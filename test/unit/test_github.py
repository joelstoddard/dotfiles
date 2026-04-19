"""Tests for scripts/lib/github.py release asset resolution."""

import json
import unittest
from io import BytesIO
from unittest.mock import MagicMock, patch

from scripts.lib import github


SAMPLE_RELEASE = {
    "tag_name": "v1.2.3",
    "assets": [
        {"name": "tool-1.2.3-x86_64-linux.tar.gz",
         "browser_download_url": "https://example.com/linux.tar.gz"},
        {"name": "tool-1.2.3-aarch64-macos.tar.gz",
         "browser_download_url": "https://example.com/macos.tar.gz"},
        {"name": "tool_1.2.3_amd64.deb",
         "browser_download_url": "https://example.com/pkg.deb"},
    ],
}


def _mock_urlopen(body: dict):
    cm = MagicMock()
    cm.__enter__ = MagicMock(return_value=BytesIO(json.dumps(body).encode()))
    cm.__exit__ = MagicMock(return_value=False)
    return cm


class FetchLatestAsset(unittest.TestCase):
    def test_resolves_linux_asset(self):
        with patch("urllib.request.urlopen", return_value=_mock_urlopen(SAMPLE_RELEASE)):
            url = github.fetch_latest_asset("example/tool", "*linux*")
        self.assertEqual(url, "https://example.com/linux.tar.gz")

    def test_resolves_deb_asset(self):
        with patch("urllib.request.urlopen", return_value=_mock_urlopen(SAMPLE_RELEASE)):
            url = github.fetch_latest_asset("example/tool", "*.deb")
        self.assertEqual(url, "https://example.com/pkg.deb")

    def test_raises_when_no_asset_matches(self):
        with patch("urllib.request.urlopen", return_value=_mock_urlopen(SAMPLE_RELEASE)):
            with self.assertRaises(RuntimeError) as cm:
                github.fetch_latest_asset("example/tool", "*windows*")
        self.assertIn("No asset matching", str(cm.exception))

    def test_glob_picks_first_match(self):
        with patch("urllib.request.urlopen", return_value=_mock_urlopen(SAMPLE_RELEASE)):
            url = github.fetch_latest_asset("example/tool", "*.tar.gz")
        self.assertEqual(url, "https://example.com/linux.tar.gz")

    def test_adds_auth_header_when_token_present(self):
        captured = {}

        def fake_urlopen(req, timeout=None):
            captured["headers"] = dict(req.header_items())
            return _mock_urlopen(SAMPLE_RELEASE)

        with patch.dict("os.environ", {"GITHUB_TOKEN": "t0ken"}, clear=False), \
             patch("urllib.request.urlopen", side_effect=fake_urlopen):
            github.fetch_latest_asset("example/tool", "*linux*")

        self.assertIn("Authorization", captured["headers"])
        self.assertEqual(captured["headers"]["Authorization"], "Bearer t0ken")


if __name__ == "__main__":
    unittest.main()
