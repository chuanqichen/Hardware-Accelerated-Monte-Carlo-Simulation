"""Reject PrimeTime exit-zero command errors without consuming a license."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from test_dump_waves import BASH, ROOT

FAKE_PT = '''#!/bin/bash
mkdir -p "reports/sta/$STA_TAG"
if [[ "$FAKE_MODE" != no_summary ]]; then
  echo 'setup_slack_ns=-0.2' > "reports/sta/$STA_TAG/summary.txt"
fi
if [[ "$FAKE_MODE" != no_marker ]]; then
  echo "STA_DONE $STA_TAG (pre-layout)"
fi
if [[ "$FAKE_MODE" == error ]]; then
  echo 'Error: deliberate command failure' >&2
fi
exit 0
'''


@unittest.skipUnless(BASH, "Bash is required for STA runner checks")
class TestPrelayoutRunner(unittest.TestCase):
    def run_fixture(self, mode):
        with tempfile.TemporaryDirectory(prefix="STA gate ") as directory:
            root = Path(directory)
            (root / "scripts/sta").mkdir(parents=True)
            shutil.copyfile(ROOT / "scripts/sta/prelayout.sh", root / "scripts/sta/prelayout.sh")
            (root / "fake_bin").mkdir()
            compiler = root / "fake_bin/pt_shell"
            with compiler.open("w", newline="\n") as file:
                file.write(FAKE_PT)
            compiler.chmod(0o755)
            env = dict(os.environ, STA_TAG="test_sta", FAKE_MODE=mode)
            return subprocess.run([BASH, "-c", 'export PATH="$PWD/fake_bin:$PATH"; bash scripts/sta/prelayout.sh'],
                                  cwd=root, env=env, capture_output=True, text=True, timeout=20)

    def test_completed_analysis_accepts_negative_slack(self):
        result = self.run_fixture("pass")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_exit_zero_error_on_stderr_is_rejected_after_done(self):
        result = self.run_fixture("error")
        self.assertNotEqual(result.returncode, 0)

    def test_missing_completion_evidence_is_rejected(self):
        for mode in ("no_marker", "no_summary"):
            with self.subTest(mode=mode):
                result = self.run_fixture(mode)
                self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
