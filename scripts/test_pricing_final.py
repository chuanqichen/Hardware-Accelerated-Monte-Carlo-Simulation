"""Exercise scripts/sim/pricing_final.sh with a fake vcs and fake python (no simulator needed).

The fixture is a scratch repo holding dummy RTL/TB/vector files, the real pricing_final.sh and
the real integrated runners (top_sim.sh, lane_bubbles_sim.sh, round_sat_sim.sh). The fake vcs
records its arguments in a fake simv, which prints the PASS line the real testbench would print
for those parameters, so a wrong parameter or vector wiring in the runner is caught too.
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
GIT_BASH = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Git/bin/bash.exe"
BASH = str(GIT_BASH) if os.name == "nt" and GIT_BASH.is_file() else shutil.which("bash")

SCRIPTS = ("pricing_final.sh", "top_sim.sh", "lane_bubbles_sim.sh", "round_sat_sim.sh")
DUMMY_FILES = (
    [f"rtl/{n}.sv" for n in ("mc_pkg", "rst_sync", "pipe", "rng_lane", "gauss_lut", "exp2_unit",
                             "round_sat", "price_dp", "accumulator", "mc_controller",
                             "mc_lane_array", "mc_top")]
    + ["rtl/generated/gauss_lut_rom.sv", "rtl/generated/exp2_rom.sv"]
    + [f"tb/{n}.sv" for n in ("tb_mc_top", "tb_mc_lane_bubbles", "tb_round_sat", "tb_accumulator",
                              "tb_exp2_unit", "tb_price_dp")]
    + ["tb/vectors/accumulator_w64.hex", "tb/vectors/accumulator_w32.hex"]
    + [f"tb/vectors/accumulator_l{l}_w{w}.hex" for l in (2, 4) for w in (64, 32)]
    + ["tb/vectors/mc_top_cases.hex", "tb/vectors/mc_top_trace.hex",
       "tb/vectors/round_sat_i34_o18_s14_s.hex", "tb/vectors/round_sat_i26_o16_s8_u.hex"]
)
COMMITTED_ROM = "// committed exp2 rom\n"

FAKE_VCS = r'''#!/bin/bash
echo "$*" >> "$CALLS"
args=("$@"); out=""; log=/dev/null
while [[ $# -gt 0 ]]; do
  case "$1" in -o) out=$2; shift ;; -l) log=$2; shift ;; esac
  shift
done
printf 'Chronologic VCS (TM)\nVersion T-2022.06_Full64 -- fake\n' > "$log"
{
  echo '#!/bin/bash'
  printf 'ARGS=('; printf '%q ' "${args[@]}"; echo ')'
  cat <<'SIM'
log=/dev/null; [[ "${1:-}" != -l ]] || log=$2
exec > "$log" 2>&1
all=" ${ARGS[*]} "
param() { local a; for a in "${ARGS[@]}"; do [[ $a == -pvalue+"$1"=* ]] && { echo "${a#*=}"; return; }; done; }
vec() { local a; for a in "${ARGS[@]}"; do [[ $a == +define+VEC_FILE=* ]] && { a=${a#*=}; a=${a#\"}; echo "${a%\"}"; return; }; done; }
tb=none
for t in tb_accumulator tb_exp2_unit tb_price_dp tb_mc_top tb_mc_lane_bubbles tb_round_sat; do
  [[ "$all" == *"/$t.sv "* || "$all" == *" $t.sv "* ]] && tb=$t
done
mode=pass
[[ -z "${FAKE_TB:-}" || "$FAKE_TB" == "$tb" ]] && mode=${FAKE_MODE:-pass}
need() { [[ -s "$1" ]] || { echo "FAIL: cannot open $1"; exit 0; }; }
case "$tb" in
  tb_accumulator)
    l=$(param tb_accumulator.LANES); w=$(param tb_accumulator.SUM_WIDTH)
    if [[ $l == 1 ]]; then need "tb/vectors/accumulator_w$w.hex"; else need "tb/vectors/accumulator_l${l}_w$w.hex"; fi
    line="PASS: tb_accumulator LANES=$l SUM_WIDTH=$w, 1000 cycles checked, 0 errors (overflow set on 0 cycles)" ;;
  tb_exp2_unit)
    k=$(param tb_exp2_unit.EXP_ADDR_BITS); need "$(vec)"
    [[ "$all" == *" rtl/generated/exp2_rom.sv "* ]] && { echo "FAIL: used committed ROM"; exit 0; }
    echo "INFO: tb_exp2_unit longest back-to-back run: in_valid=91 cycles, out_valid=91 cycles"
    line="PASS: tb_exp2_unit k=$k, 262144 checked, 0 errors, sat_s pulses 5 (expected 5)" ;;
  tb_price_dp)
    k=$(param tb_price_dp.EXP_ADDR_BITS); m=$(param tb_price_dp.MUL_STAGES); need "$(vec)"
    [[ "$all" == *" rtl/generated/exp2_rom.sv "* ]] && { echo "FAIL: used committed ROM"; exit 0; }
    echo "INFO: tb_price_dp longest back-to-back run: in_valid=46 cycles, p_valid=46 cycles"
    line="PASS: tb_price_dp k=$k MUL_STAGES=$m LAT_DP=$((m + 5)), 11449 trials checked, 0 errors" ;;
  tb_mc_top)
    line="PASS: tb_mc_top G=$(param tb_mc_top.GAUSS_LATENCY) M=$(param tb_mc_top.MUL_STAGES) cases=22 trials=26457, exact traces/results, sustained II=1" ;;
  tb_mc_lane_bubbles)
    line="PASS: tb_mc_lane_bubbles 100 exact trials, pause/resume, valid latency=6" ;;
  tb_round_sat)
    line="PASS: tb_round_sat IN=$(param tb_round_sat.IN_WIDTH) OUT=$(param tb_round_sat.OUT_WIDTH) SHIFT=$(param tb_round_sat.SHIFT) SIGNED=$(param tb_round_sat.SIGNED), 100 checked, 0 errors (sat on 3)" ;;
  *) echo "FAIL: fake vcs does not know this testbench"; exit 0 ;;
esac
case "$mode" in
  fail) echo "FAIL: deliberate failure" ;;
  silent) ;;
  nonzero) echo "$line"; exit 1 ;;
  late_fatal) echo "$line"; echo "Fatal: failure after PASS" ;;
  *) echo "$line" ;;
esac
exit 0
SIM
} > "$out"
chmod +x "$out"
'''
FAKE_PYTHON = r'''#!/bin/bash
echo "python $*" >> "$CALLS"
case "$1" in
  model/price_dp.py)
    gen=$3; k=$5; mkdir -p "$gen"
    printf '%s' "${FAKE_ROM:-// committed exp2 rom
}" > "$gen/exp2_rom.sv" ;;
  model/gen_price_vectors.py)
    k=$3; gen=$5; mkdir -p "$gen"
    echo "exp k=$k" > "$gen/exp2_k$k.hex"; echo "price k=$k" > "$gen/price_dp_k$k.hex"
    for f in accumulator_w64 accumulator_w32 accumulator_l2_w64 accumulator_l2_w32 accumulator_l4_w64 accumulator_l4_w32; do
      echo "acc" > "$gen/$f.hex"
    done ;;
  *) echo "unexpected python call: $*" >&2; exit 1 ;;
esac
'''
SHA_SHIM = '#!/bin/bash\nexec shasum -a 256 "$@"\n'


def snapshot(*dirs):
    out = {}
    for d in dirs:
        for p in sorted(Path(d).rglob("*")):
            if p.is_file():
                out[str(p)] = p.read_bytes()
    return out


@unittest.skipUnless(BASH, "Bash is required for the pricing_final runner checks")
class TestPricingFinalRunner(unittest.TestCase):
    def make_root(self):
        temp = tempfile.TemporaryDirectory(prefix="pricing final ")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        (root / "scripts/sim").mkdir(parents=True)
        for name in SCRIPTS:
            shutil.copyfile(ROOT / "scripts/sim" / name, root / "scripts/sim" / name)
        for rel in DUMMY_FILES:
            f = root / rel
            f.parent.mkdir(parents=True, exist_ok=True)
            f.write_text(COMMITTED_ROM if rel.endswith("exp2_rom.sv") else f"dummy {rel}\n")
        (root / "model").mkdir()
        (root / "fake_bin").mkdir()
        tools = {"vcs": FAKE_VCS, "fake_python": FAKE_PYTHON}
        if shutil.which("sha256sum") is None:
            tools["sha256sum"] = SHA_SHIM
        for name, body in tools.items():
            tool = root / "fake_bin" / name
            with tool.open("w", newline="\n") as f:
                f.write(body)
            tool.chmod(0o755)
        return root

    def run_fixture(self, root=None, run_id="final_test", **extra):
        root = root or self.make_root()
        env = dict(os.environ, CALLS=str(root / "calls.txt"), PYTHON=str(root / "fake_bin/fake_python"),
                   **extra)
        if run_id is None:
            env.pop("MC_SIM_RUN_ID", None)
        else:
            env["MC_SIM_RUN_ID"] = run_id
        command = 'export PATH="$PWD/fake_bin:$PATH"; bash scripts/sim/pricing_final.sh'
        result = subprocess.run([BASH, "-c", command], cwd=root, env=env,
                                capture_output=True, text=True, timeout=120)
        return root, result

    def test_happy_path_evidence(self):
        root = self.make_root()
        before = snapshot(root / "rtl", root / "tb")
        root, result = self.run_fixture(root)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        run_dir = root / "reports/sim/final_test"
        self.assertEqual(result.stdout.strip().splitlines()[-1],
                         f"Pricing final regression complete: {run_dir.resolve()} (19 runs passed)")
        self.assertEqual(before, snapshot(root / "rtl", root / "tb"))   # nothing written to tracked paths

        names = [f"acc_l{l}_w{w}" for l in (1, 2, 4) for w in (64, 32)] + ["exp2_k8", "exp2_k10"] \
            + [f"price_dp_k{k}_m{m}" for k in (8, 10) for m in (1, 2)]
        for name in names:
            self.assertTrue((run_dir / name / "compile.log").is_file(), name)
            self.assertTrue((run_dir / name / "run.log").is_file(), name)
            self.assertEqual([p.name for p in (run_dir / name).iterdir() if p.name.startswith(("csrc", "simv"))], [])
        summary = (run_dir / "summary.txt").read_text()
        for line in ("tool: Version T-2022.06_Full64 -- fake", "runs passed: 19",
                     "price_dp_k10_m2: PASS: tb_price_dp k=10 MUL_STAGES=2 LAT_DP=7, 11449 trials checked, 0 errors",
                     "exp2_k8: PASS: tb_exp2_unit k=8, 262144 checked, 0 errors",
                     "acc_l4_w32: PASS: tb_accumulator LANES=4 SUM_WIDTH=32, 1000 cycles checked, 0 errors",
                     "top: PASS: tb_mc_top G=2 M=2 cases=22 trials=26457,",
                     "bubbles: PASS: tb_mc_lane_bubbles 100 exact trials",
                     "rs: PASS: tb_round_sat IN=26 OUT=16 SHIFT=8 SIGNED=0, 100 checked, 0 errors",
                     "price_dp_k8_m1: INFO: tb_price_dp longest back-to-back run: in_valid=46 cycles, p_valid=46 cycles",
                     "exp2_k10: INFO: tb_exp2_unit longest back-to-back run: in_valid=91 cycles, out_valid=91 cycles"):
            self.assertIn(line, summary)
        for key in ("date:", "hostname:", "git:"):
            self.assertIn(key, summary)
        self.assertEqual(sum(1 for l in summary.splitlines() if ": PASS: " in l), 19)
        sha = (run_dir / "source_sha256.txt").read_text()
        for needle in ("rtl/accumulator.sv", "tb/tb_price_dp.sv", "rtl/generated/exp2_rom.sv",
                       "tb/vectors/accumulator_l4_w32.hex", "gen_k8/price_dp_k8.hex", "gen_k10/exp2_k10.hex"):
            self.assertIn(needle, sha)
        # per-k ROM and vectors live in the run dir; exhaustive exp2 vectors are deleted at the end
        self.assertEqual((run_dir / "gen_k8/exp2_rom.sv").read_text(), COMMITTED_ROM)
        self.assertTrue((run_dir / "gen_k8/price_dp_k8.hex").is_file())
        self.assertEqual(list(run_dir.glob("gen_k*/exp2_k*.hex")), [])
        self.assertEqual(list(run_dir.glob("gen_k*/accumulator_*.hex")), [])
        for child in ("top", "bubbles", "rs"):
            self.assertTrue((root / f"reports/sim/final_test_{child}").is_dir())
            self.assertEqual([p for p in (root / f"reports/sim/final_test_{child}").rglob("simv*")], [])
        calls = (root / "calls.txt").read_text().splitlines()
        vcs_calls = [c for c in calls if not c.startswith("python ")]
        self.assertEqual(len(vcs_calls), 19)
        pd = [c for c in vcs_calls if "tb_price_dp.sv" in c]
        self.assertEqual(len(pd), 4)
        for c in pd:
            self.assertNotIn(" rtl/generated/exp2_rom.sv", c)
            self.assertIn("/gen_k", c)
        self.assertIn("python model/price_dp.py --export", "\n".join(calls))

    def test_array_runner_is_included_when_present(self):
        root = self.make_root()
        (root / "scripts/prepare_array_sim.py").write_text("# stub\n")
        stub = root / "scripts/sim/array_sim.sh"
        with stub.open("w", newline="\n") as f:
            f.write('#!/bin/bash\nset -e\n[[ -d "$ARRAY_INPUTS" ]] || exit 3\n'
                    'for i in $(seq 1 "${FAKE_ARRAY_PASSES:-27}"); do d="reports/sim/$MC_SIM_RUN_ID/c$i"; '
                    'mkdir -p "$d"; echo "PASS: tb_mc_array fake $i" > "$d/run.log"; done\n')
        fake_python = root / "fake_bin/fake_python"
        body = fake_python.read_text().replace(
            '  *) echo "unexpected python call',
            '  scripts/prepare_array_sim.py) mkdir -p "$3" ;;\n  *) echo "unexpected python call')
        with fake_python.open("w", newline="\n") as f:
            f.write(body)
        _, result = self.run_fixture(root)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("(46 runs passed)", result.stdout)
        self.assertFalse((root / "reports/sim/final_test/array_inputs").exists())
        # A short array run must fail the whole regression.
        root2 = self.make_root()
        shutil.copyfile(stub, root2 / "scripts/sim/array_sim.sh")
        (root2 / "scripts/prepare_array_sim.py").write_text("# stub\n")
        with (root2 / "fake_bin/fake_python").open("w", newline="\n") as f:
            f.write(body)
        _, result = self.run_fixture(root2, FAKE_ARRAY_PASSES="26")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("expected 27 PASS lines, found 26", result.stderr)

    def test_any_failing_run_fails_the_script(self):
        for tb in ("tb_accumulator", "tb_exp2_unit", "tb_price_dp", "tb_mc_top", "tb_mc_lane_bubbles",
                   "tb_round_sat"):
            for mode in ("fail", "silent", "nonzero", "late_fatal"):
                with self.subTest(tb=tb, mode=mode):
                    root, result = self.run_fixture(FAKE_TB=tb, FAKE_MODE=mode)
                    self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertNotIn("Pricing final regression complete", result.stdout)
                    self.assertFalse((root / "reports/sim/final_test/summary.txt").exists())

    def test_existing_run_dir_is_refused(self):
        for existing in ("final_test", "final_test_top", "final_test_bubbles", "final_test_rs"):
            with self.subTest(existing=existing):
                root = self.make_root()
                keep = root / "reports/sim" / existing / "keep"
                keep.parent.mkdir(parents=True)
                keep.write_text("earlier evidence")
                root, result = self.run_fixture(root)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertIn("Run exists", result.stderr)
                self.assertEqual(keep.read_text(), "earlier evidence")
                self.assertFalse((root / "reports/sim/final_test/summary.txt").exists())
                self.assertFalse((root / "calls.txt").exists())

    def test_invalid_run_id_is_refused(self):
        for bad in ("bad id", "../escape", "-lead", ".hidden", "a/b"):
            with self.subTest(run_id=bad):
                root, result = self.run_fixture(run_id=bad)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertIn("Invalid MC_SIM_RUN_ID", result.stderr)
                self.assertFalse((root / "reports").exists())

    def test_committed_rom_mismatch_fails(self):
        root, result = self.run_fixture(FAKE_ROM="// a different rom\n")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("exp2_rom.sv differs", result.stderr)
        self.assertFalse((root / "reports/sim/final_test/summary.txt").exists())
        self.assertEqual((root / "rtl/generated/exp2_rom.sv").read_text(), COMMITTED_ROM)

    def test_default_run_id_is_timestamped(self):
        root, result = self.run_fixture(run_id=None)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        runs = [p.name for p in (root / "reports/sim").iterdir() if p.name.startswith("pricing_final_")
                and not p.name.endswith(("_top", "_bubbles", "_rs"))]
        self.assertEqual(len(runs), 1)
        self.assertTrue((root / "reports/sim" / runs[0] / "summary.txt").is_file())


if __name__ == "__main__":
    unittest.main()
