"""Exercise the price_dp synthesis sweep runner with a fake dc_shell (no license)."""
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
echo "$DESIGN $PARAMS retime=$RETIME rtl=$RTL_FILES" >> "$CALLS"
echo "SYNTH_DONE $TAG"
'''
FAKE_PYTHON = r'''#!/bin/bash
if [[ "$1" == model/price_dp.py ]]; then
  gen=$3; mkdir -p "$gen"; echo "// rom $5" > "$gen/exp2_rom.sv"
else
  echo "parse $*" >> "$CALLS"
fi
'''


@unittest.skipUnless(BASH, "Bash is required for sweep runner checks")
class TestPriceSweepRunner(unittest.TestCase):
    def run_fixture(self, args="", fail_tag=""):
        temp = tempfile.TemporaryDirectory(prefix="price_sweep_")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        (root / "scripts/syn").mkdir(parents=True)
        shutil.copyfile(ROOT / "scripts/syn/run_price_sweep.sh", root / "scripts/syn/run_price_sweep.sh")
        (root / "fake_bin").mkdir()
        for name, body in (("dc_shell", FAKE_DC), ("fake_python", FAKE_PYTHON)):
            tool = root / "fake_bin" / name
            with tool.open("w", newline="\n") as f:
                f.write(body)
            tool.chmod(0o755)
        env = dict(os.environ, BATCH="t", SCRATCH=str(root / "scratch"), CALLS=str(root / "calls.txt"),
                   PYTHON=str(root / "fake_bin/fake_python"), FAKE_FAIL_TAG=fail_tag)
        command = f'export PATH="$PWD/fake_bin:$PATH"; bash scripts/syn/run_price_sweep.sh {args}'
        result = subprocess.run([BASH, "-c", command], cwd=root, env=env,
                                capture_output=True, text=True, timeout=30)
        calls = (root / "calls.txt").read_text().splitlines() if (root / "calls.txt").exists() else []
        return root, result, calls

    def test_default_grid_isolated_rom_and_parse(self):
        root, result, calls = self.run_fixture()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(len(calls), 12 + 1)
        self.assertEqual(calls[-1], "parse scripts/parse_reports.py --syn reports/syn --filter t_price_dp_ "
                                    "--out results/price_dp_ppa_t.csv")
        self.assertIn("price_dp EXP_ADDR_BITS=8,MUL_STAGES=1 retime=0 ", calls[0])
        self.assertIn("price_dp EXP_ADDR_BITS=12,MUL_STAGES=2 retime=1 ", calls[11])
        gen = root / "scratch/t_price_dp_k12_m2_r1/generated/exp2_rom.sv"
        self.assertEqual(gen.read_text(), "// rom 12\n")
        self.assertIn(f"rtl/mc_pkg.sv rtl/round_sat.sv rtl/pipe.sv {gen} rtl/exp2_unit.sv rtl/price_dp.sv", calls[11])
        self.assertTrue((root / "reports/syn/t_price_dp_k10_m1_r0/dc.log.txt").is_file())
        self.assertFalse((root / "rtl").exists())

    def test_positional_lists_and_stop_on_failure(self):
        _, result, calls = self.run_fixture('"2" "10" "1"')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(len(calls), 2)
        _, result, calls = self.run_fixture('"1 2" "10" "0"', fail_tag="m1_r0")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("FAILED", result.stdout)
        self.assertEqual(calls, [])

    def test_invalid_batch_rejected(self):
        root, _, _ = self.run_fixture()
        env = dict(os.environ, BATCH="bad batch", SCRATCH=str(root / "scratch"))
        result = subprocess.run([BASH, "scripts/syn/run_price_sweep.sh"], cwd=root, env=env,
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 2)


if __name__ == "__main__":
    unittest.main()
