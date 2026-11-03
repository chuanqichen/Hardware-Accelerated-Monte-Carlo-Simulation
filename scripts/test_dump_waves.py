"""Exercise waveform success/failure gates without a VCS license."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
GIT_BASH = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Git/bin/bash.exe"
BASH = str(GIT_BASH) if os.name == "nt" and GIT_BASH.is_file() else shutil.which("bash")
FAKE_VCS = r'''#!/bin/bash
while [[ $# -gt 0 ]]; do
  if [[ "$1" == -o ]]; then shift; output=$1; fi
  shift
done
cat > "$output" <<'SIM'
#!/bin/bash
block=${0##*/simv_}
for arg in "$@"; do
  [[ "$arg" != +vcd=* ]] || vcd=${arg#+vcd=}
done
mode=pass
[[ "$block" != "$FAKE_BLOCK" ]] || mode=$FAKE_MODE
[[ "$mode" == missing_vcd ]] || printf 'test waveform\n' > "$vcd"
case "$mode" in
  fail) echo 'FAIL: deliberate failure'; exit 0 ;;
  fatal) echo 'Fatal: deliberate failure'; exit 0 ;;
  no_marker) echo 'simulation ended'; exit 0 ;;
  zero)
    echo 'PASS: 0 checked, 0 errors'
    echo 'PASS rng_lane: 0 cycles, 0 valid words'
    echo 'PASS: tb_price_dp k=10 MUL_STAGES=1 LAT_DP=6, 0 trials checked, 0 errors'
    exit 0 ;;
  errors) echo 'PASS: 10 checked, 1 errors'; exit 0 ;;
  nonzero) exit 1 ;;
esac
case "$block" in
  gauss_lut) echo 'PASS: 10 checked, 0 errors' ;;
  rng_lane) echo 'PASS rng_lane: 10 cycles, 8 valid words' ;;
  price_dp) echo 'PASS: tb_price_dp k=10 MUL_STAGES=1 LAT_DP=6, 10 trials checked, 0 errors' ;;
esac
[[ "$mode" != late_fatal ]] || echo 'Fatal: failure after PASS'
exit 0
SIM
chmod +x "$output"
'''


@unittest.skipUnless(BASH, "Bash is required for waveform runner checks")
class TestWaveformRunner(unittest.TestCase):
    def run_fixture(self, block="none", mode="pass"):
        temp = tempfile.TemporaryDirectory(prefix="wave gate ")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        (root / "scripts/sim").mkdir(parents=True)
        shutil.copyfile(ROOT / "scripts/sim/dump_waves.sh", root / "scripts/sim/dump_waves.sh")
        (root / "fake_bin").mkdir()
        compiler = root / "fake_bin/vcs"
        with compiler.open("w", newline="\n") as f:
            f.write(FAKE_VCS)
        compiler.chmod(0o755)
        waves = root / "reports/waves"
        waves.mkdir(parents=True)
        for name in ("gauss_lut", "rng_lane", "price_dp"):
            (waves / f"{name}.vcd").write_text("previous waveform")
        (root / "csrc").mkdir()
        (root / "csrc/keep").write_text("unrelated build")
        env = dict(os.environ, MC_SIM_RUN_ID="gate_test", FAKE_BLOCK=block, FAKE_MODE=mode)
        command = 'export PATH="$PWD/fake_bin:$PATH"; bash scripts/sim/dump_waves.sh'
        result = subprocess.run([BASH, "-c", command], cwd=root, env=env,
                                capture_output=True, text=True, timeout=30)
        return root, result

    def test_success_publishes_all_waveforms_and_preserves_other_builds(self):
        root, result = self.run_fixture()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("PASS: waveform run", result.stdout)
        for name in ("gauss_lut", "rng_lane", "price_dp"):
            self.assertEqual((root / f"reports/waves/{name}.vcd").read_text(), "test waveform\n")
        self.assertTrue((root / "csrc/keep").is_file())

    def test_failures_cannot_publish_waveforms(self):
        for block in ("gauss_lut", "rng_lane", "price_dp"):
            for mode in ("fail", "fatal", "no_marker", "zero", "errors", "nonzero",
                         "missing_vcd", "late_fatal"):
                with self.subTest(block=block, mode=mode):
                    root, result = self.run_fixture(block, mode)
                    self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                    for name in ("gauss_lut", "rng_lane", "price_dp"):
                        self.assertEqual((root / f"reports/waves/{name}.vcd").read_text(), "previous waveform")
                    self.assertTrue((root / "csrc/keep").is_file())


if __name__ == "__main__":
    unittest.main()
