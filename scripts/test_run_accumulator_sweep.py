"""Exercise the accumulator synthesis sweep runner with a fake dc_shell (no license)."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
GIT_BASH = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Git/bin/bash.exe"
BASH = str(GIT_BASH) if os.name == "nt" and GIT_BASH.is_file() else shutil.which("bash")
FAKE_DC = r'''#!/bin/bash
[[ "$TAG" != *"$FAKE_FAIL_TAG" || -z "$FAKE_FAIL_TAG" ]] || { echo "Error: deliberate failure"; exit 1; }
mkdir -p "$REPORT_DIR"
echo "$DESIGN $PARAMS rtl=$RTL_FILES clk=${CLK_PERIOD_NS-unset}" >> "$CALLS"
echo "SYNTH_DONE $TAG"
'''
FAKE_PYTHON = r'''#!/bin/bash
echo "parse $*" >> "$CALLS"
'''


@unittest.skipUnless(BASH, "Bash is required for sweep runner checks")
class TestAccumulatorSweepRunner(unittest.TestCase):
    def run_fixture(self, args="", fail_tag="", extra_env=None):
        temp = tempfile.TemporaryDirectory(prefix="acc_sweep_")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        (root / "scripts/syn").mkdir(parents=True)
        shutil.copyfile(ROOT / "scripts/syn/run_accumulator_sweep.sh", root / "scripts/syn/run_accumulator_sweep.sh")
        (root / "fake_bin").mkdir()
        for name, body in (("dc_shell", FAKE_DC), ("fake_python", FAKE_PYTHON)):
            tool = root / "fake_bin" / name
            with tool.open("w", newline="\n") as f:
                f.write(body)
            tool.chmod(0o755)
        env = dict(os.environ, BATCH="t", SCRATCH=str(root / "scratch"), CALLS=str(root / "calls.txt"),
                   PYTHON=str(root / "fake_bin/fake_python"), FAKE_FAIL_TAG=fail_tag, **(extra_env or {}))
        command = f'export PATH="$PWD/fake_bin:$PATH"; bash scripts/syn/run_accumulator_sweep.sh {args}'
        result = subprocess.run([BASH, "-c", command], cwd=root, env=env,
                                capture_output=True, text=True, timeout=30)
        calls = (root / "calls.txt").read_text().splitlines() if (root / "calls.txt").exists() else []
        return root, result, calls

    def test_default_lanes_and_parse(self):
        root, result, calls = self.run_fixture()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(len(calls), 3 + 1)
        for call, lanes in zip(calls, (1, 2, 4)):
            self.assertEqual(call, f"accumulator LANES={lanes},REGISTER_TREE={int(lanes > 1)} rtl=rtl/accumulator.sv clk=unset")
        self.assertEqual(calls[-1], "parse scripts/parse_reports.py --syn reports/syn --filter t_accumulator_ "
                                    "--out results/accumulator_ppa_t.csv")
        self.assertTrue((root / "reports/syn/t_accumulator_l4/dc.log.txt").is_file())

    def test_positional_list_clock_passthrough_and_stop_on_failure(self):
        _, result, calls = self.run_fixture('"4 8"', extra_env={"CLK_PERIOD_NS": "5.0"})
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(calls[:2], ["accumulator LANES=4,REGISTER_TREE=1 rtl=rtl/accumulator.sv clk=5.0",
                                     "accumulator LANES=8,REGISTER_TREE=1 rtl=rtl/accumulator.sv clk=5.0"])
        _, result, calls = self.run_fixture('"1 2 4"', fail_tag="l2")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("FAILED", result.stdout)
        self.assertEqual(calls, ["accumulator LANES=1,REGISTER_TREE=0 rtl=rtl/accumulator.sv clk=unset"])

    def test_invalid_batch_rejected(self):
        root, _, _ = self.run_fixture()
        env = dict(os.environ, BATCH="bad batch", SCRATCH=str(root / "scratch"))
        result = subprocess.run([BASH, "scripts/syn/run_accumulator_sweep.sh"], cwd=root, env=env,
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 2)


if __name__ == "__main__":
    unittest.main()
