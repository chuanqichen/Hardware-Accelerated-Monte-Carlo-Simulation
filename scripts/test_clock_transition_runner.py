"""Exercise the PT process boundary without consuming a license."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from test_dump_waves import BASH, ROOT

FAKE_PT = '''#!/bin/bash
mkdir -p "$OUT"
for f in inputs.txt source_sha256.txt setup_clkslew_0.10.rpt setup_clkslew_0.06.rpt; do
  echo fixture > "$OUT/$f"
done
echo 'CLKSLEW 0.10 worst_endpoint D arrival 3.68 slack -0.20' > "$OUT/summary.txt"
if [[ "$FAKE_MODE" != missing_slew ]]; then
  echo 'CLKSLEW 0.06 worst_endpoint D arrival 4.76 slack 0.05' >> "$OUT/summary.txt"
fi
if [[ "$FAKE_MODE" != missing_marker ]]; then
  echo "CLKSLEW_DONE $OUT (sensitivity only)"
fi
if [[ "$FAKE_MODE" == error ]]; then echo 'Error: deliberate failure' >&2; fi
if [[ "$FAKE_MODE" == missing_report ]]; then rm "$OUT/setup_clkslew_0.06.rpt"; fi
exit 0
'''


@unittest.skipUnless(BASH, "Bash is required")
class TestClockTransitionRunner(unittest.TestCase):
    def run_fixture(self, mode, existing=False):
        with tempfile.TemporaryDirectory(prefix="slew gate ") as directory:
            root = Path(directory)
            (root / "scripts/sta").mkdir(parents=True)
            shutil.copyfile(ROOT / "scripts/sta/clock_transition.sh", root / "scripts/sta/clock_transition.sh")
            (root / "fake_bin").mkdir()
            compiler = root / "fake_bin/pt_shell"
            with compiler.open("w", newline="\n") as file:
                file.write(FAKE_PT)
            compiler.chmod(0o755)
            out = root / "reports/sta/test"
            if existing:
                out.mkdir(parents=True)
                (out / "keep.txt").write_text("prior evidence")
            env = dict(os.environ, OUT="reports/sta/test", FAKE_MODE=mode)
            result = subprocess.run([BASH, "-c", 'export PATH="$PWD/fake_bin:$PATH"; bash scripts/sta/clock_transition.sh'],
                                    cwd=root, env=env, capture_output=True, text=True, timeout=20)
            if existing:
                self.assertEqual((out / "keep.txt").read_text(), "prior evidence")
            return result

    def test_complete_negative_slack_study_is_accepted(self):
        result = self.run_fixture("pass")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_exit_zero_errors_and_incomplete_results_fail(self):
        for mode in ("error", "missing_slew", "missing_marker", "missing_report"):
            with self.subTest(mode=mode):
                self.assertNotEqual(self.run_fixture(mode).returncode, 0)

    def test_existing_evidence_is_preserved(self):
        self.assertNotEqual(self.run_fixture("pass", existing=True).returncode, 0)


if __name__ == "__main__":
    unittest.main()
