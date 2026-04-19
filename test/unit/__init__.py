import sys
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parent.parent.parent
FIXTURES = Path(__file__).parent / "fixtures"

sys.path.insert(0, str(REPO_DIR))
