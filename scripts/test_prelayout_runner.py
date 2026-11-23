"""Reject STA/physical runner false completions without consuming a license."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from test_dump_waves import BASH, ROOT

FAKE_PT = '''#!/bin/bash
phase=${FAKE_PHASE:-sta}
tag=$STA_TAG; marker=STA_DONE; error=Error
if [[ "$phase" == pnr ]]; then
  tag=$PNR_TAG; marker=PNR_DONE; error='**ERROR'
  echo 'Error Limit = 1000; Warning Limit = 50'
fi
mkdir -p "reports/$phase/$tag"
if [[ "$FAKE_MODE" != no_summary ]]; then
  echo 'setup_slack_ns=-0.2' > "reports/$phase/$tag/summary.txt"
fi
if [[ "$FAKE_MODE" != no_marker ]]; then
  echo "$marker $tag (fixture)"
fi
if [[ "$FAKE_MODE" == error ]]; then
  echo "$error: deliberate command failure" >&2
fi
if [[ "$FAKE_MODE" == exit_error ]]; then exit 3; fi
exit 0
'''


@unittest.skipUnless(BASH, "Bash is required for STA runner checks")
class TestPrelayoutRunner(unittest.TestCase):
    def run_fixture(self, mode, phase="sta"):
        with tempfile.TemporaryDirectory(prefix="STA gate ") as directory:
            root = Path(directory)
            relative = f"scripts/{phase}/" + ("prelayout.sh" if phase == "sta" else "implement.sh")
            (root / f"scripts/{phase}").mkdir(parents=True)
            shutil.copyfile(ROOT / relative, root / relative)
            (root / "fake_bin").mkdir()
            compiler = root / "fake_bin" / ("pt_shell" if phase == "sta" else "innovus")
            with compiler.open("w", newline="\n") as file:
                file.write(FAKE_PT)
            compiler.chmod(0o755)
            env = dict(os.environ, STA_TAG="test_sta", PNR_TAG="test_pnr", FAKE_MODE=mode, FAKE_PHASE=phase)
            return subprocess.run([BASH, "-c", f'export PATH="$PWD/fake_bin:$PATH"; bash {relative}'],
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

    def test_physical_runner_completion_gates(self):
        for mode in ("pass", "error", "exit_error", "no_marker", "no_summary"):
            with self.subTest(mode=mode):
                result = self.run_fixture(mode, phase="pnr")
                self.assertEqual(result.returncode == 0, mode == "pass", result.stdout + result.stderr)

    @unittest.skipUnless(shutil.which("tclsh"), "Tcl shell required")
    def test_invalid_spef_is_rejected_before_analysis(self):
        with tempfile.TemporaryDirectory() as directory:
            netlist = Path(directory) / "mapped.v"
            sdc = Path(directory) / "mapped.sdc"
            netlist.write_text("// fixture\n")
            sdc.write_text("# fixture\n")
            for spef in ("", str(Path(directory) / "missing.spef")):
                with self.subTest(spef=spef):
                    env = dict(os.environ, NETLIST=str(netlist), MAPPED_SDC=str(sdc), SPEF=spef)
                    result = subprocess.run(["tclsh", str(ROOT / "scripts/sta/prelayout.tcl")],
                                            env=env, capture_output=True, text=True, timeout=20)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn("SPEF must name", result.stderr)


if __name__ == "__main__":
    unittest.main()
