"""Fetch latest release assets from GitHub."""

import fnmatch
import json
import urllib.request
from urllib.error import HTTPError


def fetch_latest_asset(repo: str, asset_pattern: str) -> str:
    """Query GitHub Releases API and return the download URL for a matching asset.

    Args:
        repo: GitHub repository in "owner/repo" format.
        asset_pattern: Glob pattern to match against asset filenames (e.g. "*.deb", "nvim-linux-x86_64.tar.gz").

    Returns:
        The browser_download_url for the first matching asset.

    Raises:
        RuntimeError: If no matching asset is found or the API request fails.
    """
    url = f"https://api.github.com/repos/{repo}/releases/latest"
    req = urllib.request.Request(url, headers={"Accept": "application/vnd.github+json"})

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read())
    except HTTPError as e:
        raise RuntimeError(f"GitHub API request failed for {repo}: {e}") from e

    for asset in data.get("assets", []):
        name = asset.get("name", "")
        if fnmatch.fnmatch(name, asset_pattern):
            return asset["browser_download_url"]

    available = [a["name"] for a in data.get("assets", [])]
    raise RuntimeError(
        f"No asset matching '{asset_pattern}' in {repo} latest release. "
        f"Available: {available}"
    )
