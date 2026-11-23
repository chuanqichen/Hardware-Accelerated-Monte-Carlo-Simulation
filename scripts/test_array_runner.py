"""Exercise integrated regression completion gates without a VCS license."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from test_dump_waves import BASH, ROOT

FAKE_VCS = r'''#!/bin/bash
lanes=1; gauss=1; mul=1; bits=10
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) shift; output=$1;;
    -l) shift; compile_log=$1;;
    -top) shift; top=$1;;
    -pvalue+tb_mc_array.LANES=*) lanes=${1##*=};;
    -pvalue+tb_mc_array.GAUSS_LATENCY=*) gauss=${1##*=};;
    -pvalue+tb_mc_array.MUL_STAGES=*) mul=${1##*=};;
    -pvalue+tb_mc_array.EXP_ADDR_BITS=*) bits=${1##*=};;
    -pvalue+tb_accumulator_tree.LANES=*) lanes=${1##*=};;
  esac
  shift
done
echo 'Compiler fixture' > "$compile_log"
case "$top" in
  tb_mc_array)
    case $lanes in 1) trials=27492;; 2) trials=27495;; 4) trials=27502;; esac
    message="PASS: tb_mc_array L=$lanes G=$gauss M=$mul A=10 K=$bits cases=$((26+(lanes>1)+(lanes>2))) trials=$trials";;
  tb_accumulator_tree) message="PASS: tb_accumulator_tree L=$lanes cycles=1109, masks bubbles clear overflow";;
  tb_mc_top) message='PASS: tb_mc_top G=1 M=1 cases=22 trials=26457, exact traces/results, sustained II=1';;
esac
printf '#!/bin/bash\nmessage=%q\ntop=%q\n' "$message" "$top" > "$output"
cat >> "$output" <<'SIM'
while [[ $# -gt 0 ]]; do
  if [[ "$1" == -l ]]; then shift; log=$1; fi
  shift
done
if [[ "$FAKE_MODE" == no_marker && "$top" == "$FAKE_TARGET" ]]; then
  echo 'No comparisons completed' | tee "$log"
else
  echo "$message" | tee "$log"
fi
if [[ "$FAKE_MODE" == late_fatal && "$top" == "$FAKE_TARGET" ]]; then
  echo 'Fatal: deliberate failure after PASS' | tee -a "$log"
fi
SIM
chmod +x "$output"
'''


@unittest.skipUnless(BASH, "Bash is required")
class TestArrayRunner(unittest.TestCase):
    def run_fixture(self, mode="pass", target="tb_mc_array", empty=False):
        with tempfile.TemporaryDirectory(prefix="array runner ") as directory:
            root = Path(directory)
            for relative in ("scripts/sim/array_sim.sh", "rtl/mc_top.f"):
                dest = root / relative
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / relative, dest)
            for source in (ROOT / "rtl/mc_top.f").read_text().split() + ["tb/tb_mc_array.sv", "tb/tb_accumulator_tree.sv", "tb/tb_mc_top.sv"]:
                dest = root / source
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_text("source fixture\n")
            inputs = root / "inputs"
            (inputs / "k8").mkdir(parents=True)
            (inputs / "k8/exp2_rom.sv").write_text("ROM fixture\n")
            for bits in (10, 8):
                for lanes in (1, 2, 4):
                    (inputs / f"mc_array_l{lanes}_k{bits}.hex").write_text("" if empty else "fixture\n")
            (root / "fake_bin").mkdir()
            compiler = root / "fake_bin/vcs"
            with compiler.open("w", newline="\n") as file:
                file.write(FAKE_VCS)
            compiler.chmod(0o755)
            env = dict(os.environ, ARRAY_INPUTS="inputs", MC_SIM_RUN_ID="fixture", FAKE_MODE=mode, FAKE_TARGET=target)
            return subprocess.run([BASH, "-c", 'export PATH="$PWD/fake_bin:$PATH"; bash scripts/sim/array_sim.sh'],
                                  cwd=root, env=env, capture_output=True, text=True, timeout=30)

    def test_complete_matrix_is_accepted(self):
        result = self.run_fixture()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("ARRAY_DONE fixture", result.stdout)

    def test_exit_zero_failures_after_pass_are_rejected_at_each_phase(self):
        for target in ("tb_mc_array", "tb_accumulator_tree", "tb_mc_top"):
            with self.subTest(target=target):
                self.assertNotEqual(self.run_fixture("late_fatal", target).returncode, 0)

    def test_empty_corpus_and_missing_marker_are_rejected(self):
        self.assertNotEqual(self.run_fixture(empty=True).returncode, 0)
        self.assertNotEqual(self.run_fixture("no_marker").returncode, 0)


if __name__ == "__main__":
    unittest.main()
