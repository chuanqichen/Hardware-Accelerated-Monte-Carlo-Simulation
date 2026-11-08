# RNG milestone 1: xoshiro128++ lane

Implemented 2026-10-13; control choices below are proposed for team review.
Scope follows Project_Proposal.md: one single-step pricing lane first; no second
RNG frontend. The algorithm is xoshiro128++ 1.0, David Blackman and Sebastiano
Vigna (2019): https://prng.di.unimi.it/xoshiro128plusplus.c . Their canonical
source is public domain (CC0). This milestone implements next(), not jump().

## Algorithm and interface

Python state order is `(s0,s1,s2,s3)`; the RTL seed bus is
`seed_state={s3,s2,s1,s0}`. The output is
`rotl32((s0+s3) mod 2^32,7)+s0 mod 2^32`, using the pre-transition state.
The state uses the canonical XOR/shift updates and rotate-left by 11.
Every operation is unsigned modulo 2^32. Fixed-point saturation does not apply.

`rng_lane` has `clk`, `rst_n`, `seed_load`, `seed_state[127:0]`, `run`,
`u[31:0]`, and `u_valid`. The exported localparam `LAT_RNG` aliases
`mc_pkg::LAT_RNG` (one cycle); compile `rtl/mc_pkg.sv` before `rtl/rng_lane.sv`.
A run accepted at a rising edge produces the registered word/valid after that
edge; a downstream register consumes it at the following rising edge. One word per cycle, no back-pressure.

## Proposed control contract

Priority is **reset > seed_load > run > hold**.

- Reset asserts asynchronously and clears all state, u, and u_valid. Deassertion
  must be synchronized by the future mc_top; rng_lane does not synchronize it.
- A seed_load edge copies all four words, clears u/u_valid, and does not advance
  or generate even when run is high. First sample uses the loaded state on the
  next run edge. Repeated seed loads repeatedly replace the state.
- A run edge with nonzero state registers the canonical output and next state.
- Pause (`run=0`) preserves state and u but clears u_valid. Resume continues at
  the next unconsumed sample, with no skipped RNG transitions.
- Reset leaves the lane unseeded. An all-zero seed is illegal: loading it replaces
  old state with zero, clears u, and inhibits valid output until a nonzero seed
  load. No automatic seed substitution, saturation, or lane error port is added.
  The future controller must reject zero seeds and set bad_cfg as specified.
- Thus u_valid is delayed accepted run, qualified by reset/load/nonzero state;
  it is not an unconditional delayed copy of raw run on exceptional edges.

## Verification and commands

`model/rng_lane.py` uses simultaneous next-state equations. The independent
`model/rng_canonical_reference.py` directly transcribes the canonical sequential
C assignments with ctypes.c_uint32 conversions, imports no production helper,
and validates output AND state. This is a Python transcription, not a compiled
execution of the original C. Tests compare all 128 one-hot seeds, all-ones and
random seeds for 256 steps, plus a 10,000-word stream. Directed tests exercise
packing, wraparound, controls, zero seeds, and reset recovery.

`model/gen_rng_vectors.py` emits deterministic per-edge vectors with seed 382,
directed cases plus 4096 randomized control cycles. Rows contain:
`rst_n seed_load run seed_state u_valid u state_after` (all hexadecimal).
The unit tests verify the checked-in artifact against both its generator and an
independent canonical/control scoreboard.

`tb/tb_rng_lane.sv` drives at falling edges and checks after rising-edge NBA
updates. It checks every cycle's valid, u (including held values), and internal
state; mismatches, missing/malformed/empty input, or timeout are fatal. A separate
check asserts reset between clock edges during an active stream while load/run
are high. The optional `+STREAM_FILE=...` writes valid vector-driven u words as
hex lines for future stream analysis; it excludes the reset preamble.

```bash
make rng-gen       # regenerate tb/vectors/rng_lane.hex
make rng-test      # Python RNG-only regression
make test          # all Python tests, including Gaussian regression
make rng-sim       # VCS compile/run (lab machines)
make rng-lint      # Verilator --lint-only
# Optional stream export (after rng-sim has built the executable):
./simv_rng +STREAM_FILE=reports/rng_stream.hex
```

Gaussian gen/sim/lint targets retain their existing inputs and defaults. RNG
simulation uses simv_rng and its own build directory. No tool install is assumed.

## Local validation results (2026-10-13)

- Python 3.13 / NumPy 2.3.3: `python -B -m unittest -v` from model/ passed
  all 17 tests (9 RNG, 8 existing Gaussian).
- Independent canonical output/state comparison passed 59,664 algorithm steps.
- All 4,440 generated vector cycles (1,763 valid words) passed the independent
  canonical/control scoreboard and artifact reproducibility check.
- Python AST checks and source whitespace checks passed; `git diff --check`
  passed. Existing Gaussian Make recipes were compared against HEAD and preserved.
- Make, VCS, Verilator, Icarus, GCC, and Clang were not found on PATH. Make targets,
  SystemVerilog simulation/lint, and compiled canonical C validation could not
  run here. No synthesis, timing closure, or RNG statistical battery is claimed.
- Changes remain local and uncommitted for review.

## Milestone 1 follow-up list (historical)

- Run VCS and Verilator on a machine with those tools; synthesize to measure II,
  timing and area (one stage is a structural design, not a timing-closure claim).
- Add software jump-separated seeding and reproducible seed manifests for 2/4
  lanes; keep jump hardware outside the lane.
- Add stream statistics/export analysis, RNG-to-Gaussian integration, and mc_top
  bad_cfg checks. Algorithm equivalence is not a statistical-quality battery.

## RNG validation evidence and lab handoff (2026-11-08)

The weekly plan assigns Shentong RNG timing/area and stream-quality evidence.
The baseline RTL and one-lane integration already have historical VCS logs:
`reports/vcs_regression_2026-10-31.txt`,
`reports/integration_validation_2026-11-01.txt`, and
`reports/pr8_fix_validation_2026-11-02.txt`.
Those runs predate the shared-latency alias change. Shentong subsequently
reported a completed current-source validation run on Mario; the supplied
manifest and synthesis measurements are recorded below.

### Current checklist

- [x] Use `mc_pkg::LAT_RNG` as the source for the exported block latency;
  compile the package first in standalone RNG and waveform commands.
- [x] Implement reproducible model stream screening, output tables, seed/source
  manifest and a plot; malformed or noncanonical imported streams are rejected.
- [x] Run three jump-separated model streams of 1,048,576 words each.
- [x] Local regression: 85 model tests passed; 13 flow tests passed and two
  existing Bash-dependent waveform tests skipped on Windows.
- [x] Re-run standalone RNG and integrated one-lane VCS (reported runner PASS).
- [x] Check long, uninterrupted RTL streams against the independent oracle;
  confirm II=1, retain a short waveform and analyze the exported RTL words.
- [x] Run standalone RNG DC synthesis and report area, setup slack, critical-path
  endpoints and remaining hold/electrical violations.
- [x] Record supplied PPA measurements and run/source manifest for the checkpoint.
- [ ] Transfer raw VCS/DC logs, RTL stream statistics, VCDs and synthesis reports.
- [ ] Review 516 max-capacitance violations with Tyler using the raw reports;
  document the resolution or the limitation.

### Local model evidence

Reproduce from the repository root (Python with NumPy and Matplotlib):

```bash
python -B model/rng_quality.py --words 1048576 --streams 3 --out-prefix results/rng_model --plot
# Equivalent default configuration:
make rng-study
```

All streams use the canonical xoshiro128++ transition. Seed 0 is packed
`0123456789abcdef0fedcba987654321` in `{s3,s2,s1,s0}` order; seeds 1 and 2
are successive canonical `jump()` states, each 2^64 transitions apart.
The precise seeds and source SHA-256 hashes are in
`results/rng_model_manifest.json`.

| Stream | Mean of u/2^32 | Sample variance | Largest absolute bit-balance z | Top-10-bit chi-square |
|---|---:|---:|---:|---:|
| 0 | 0.500033596 | 0.083285271 | 2.375 | 1002.664 |
| 1 | 0.500200825 | 0.083386228 | 2.191 | 943.355 |
| 2 | 0.499751902 | 0.083441460 | 2.238 | 987.801 |

Each 1,024-bin histogram has an expected count of 1,024 per bin and 1,023
degrees of freedom. Predeclared engineering screens use:
absolute mean/bit z <= 6; chi-square <= df + 6*sqrt(2*df) = 1294.396;
and absolute correlation <= 6/sqrt(number of paired words).
Serial lags are 1, 2, 4, 8 and 16. Variance is reported descriptively.

All screens passed. Largest absolute serial correlation was 0.0015553;
largest absolute cross-stream correlation was 0.0015552, against a limit of
about 0.0058594. These are heuristic screens, not calibrated significance
tests, a statistical test battery, or proof of independent random streams.
These are **Python model results**, not measured RTL streams.

Artifacts:
`results/rng_model_{summary,histogram,bits,lags,cross_stream}.csv`,
`results/rng_model_manifest.json`, and
`results/rng_model_quality.png`.

### Supplied RTL and synthesis evidence

Run: `rng_20261108_231630` on Mario. The supplied terminal output reports
`PASS RNG lab validation`, and the supplied manifest records
`status=validation_completed` with three streams of 1,048,576 words each.
The runner requires explicit PASS markers and canonical stream comparison
before accepting these stages.

| Metric | Reported result |
|---|---|
| Design / library | `rng_lane` / `gscl45nm.db` |
| Clock constraint | 5 ns (200 MHz) |
| Setup slack | +0.00604582 ns (+6.04582 ps) |
| Cell area | 5,274.931992 um^2 |
| Cells / registers | 1,568 / 161 |
| Critical path | `s0_reg[0]` -> `u_reg[31]` |
| Hold / max-transition violations | 0 / 0 reported |
| Max-capacitance violations | **516** |
| Synthesis result | **mapped_with_violations** |
| Slack-derived Fmax estimate | 200.24212557 MHz, pre-layout only |
| Total power estimate | 1.1657 mW, unannotated activity |

The reported setup result supports the 200 MHz constraint with a small margin.
At II=1 this corresponds to 200 million RNG words/second at the constrained
clock; it does not establish whole-design or post-route throughput.
Electrical violations remain. The unannotated power estimate does not support
an activity-based energy-per-trial claim.

Recorded evidence:
- `results/rng_20261108_231630_ppa.csv`
- `reports/rng_validation/rng_20261108_231630/manifest.json`
- `reports/rng_validation/rng_20261108_231630/terminal_ppa_manifest.txt`
- `reports/rng_validation/rng_20261108_231630/evidence_note.md`

All **79 input hashes match the local runtime files of commit 6aa595f**.
The source-export provenance is therefore traceable even though the run did
not have a Git checkout. Raw VCS/DC logs, RTL screening tables and waveforms,
synthesis inputs/library hash and timing/constraint reports still need to be
transferred. Their contents have not been independently inspected here.

### Transfer the remaining lab evidence

From the extracted project root on Mario, package the reports, logs, short VCDs
and analyzed RTL tables. Exclude compiled products and the large, reproducible
raw stream captures:

```bash
RUN_TAG=rng_20261108_231630
tar -czf "$HOME/rng_validation_evidence_$RUN_TAG.tar.gz" \
  --exclude=csrc --exclude=work --exclude='simv*' --exclude='*.daidir' \
  --exclude='stream_*.hex' \
  "reports/rng_validation/$RUN_TAG" \
  "reports/sim/${RUN_TAG}_sim-top" \
  "reports/sim/${RUN_TAG}_sim-lane-bubbles" \
  results/${RUN_TAG}_* SOURCE_MANIFEST.json
```

Then, from Windows PowerShell in the local repository:

```powershell
scp sz23492@mario.ece.utexas.edu:~/rng_validation_evidence_rng_20261108_231630.tar.gz build/
```

Keep the archive intact for inspection and selective import. The original
stream hex files remain on Mario; their SHA-256 hashes are in the quality
manifest. Review raw violations before changing drive/load constraints or RTL.

### Reproduce the lab validation

The supplied `scripts/run_rng_validation.py` performs all of these steps:

1. Run every model unit test.
2. Run the existing RNG VCS regression, requiring a nonempty PASS.
3. Run all four integrated Gaussian/multiplier pipeline configurations and the
   real one-lane pause/resume test.
4. Compile `tb/tb_rng_stream.sv` and check three continuous streams, including
   every output word, internal state, valid cycle, load priority and final pause.
   This testbench has an independent sequential canonical scoreboard.
5. Export each stream, independently check it again in Python, and write
   stream-quality CSVs/plot. VCD capture stops after the first 32 words.
6. Synthesize `rng_lane` using the shared 5 ns SDC and parse the PPA reports.

The runner rejects nonzero exits, explicit failure/error diagnostics and absent
PASS markers. Each run has a new tag and source hashes; old run directories
cannot be overwritten. Synthesis completion does not imply timing closure:
the CSV retains hold/electrical violations and power-activity qualifications.

Lab account confirmed by Shentong: `sz23492@mario.ece.utexas.edu`, using password
login. Shentong ran the validation interactively. Codex imported the supplied
terminal evidence and verified source hashes; it did not independently run VCS/DC.

The source snapshot used for the recorded validation is available locally as
`build/rng_validation_sources.zip`. This avoids requiring a commit or modifying an
existing lab checkout. Its `SOURCE_MANIFEST.json` records all packaged file
hashes. Transfer it from Windows PowerShell:

```powershell
scp build/rng_validation_sources.zip sz23492@mario.ece.utexas.edu:~/
ssh sz23492@mario.ece.utexas.edu
```

After login, extract into a **fresh writable directory**. The confirmed home
directory is `/home/ecelrc/students/sz23492`; the previously suggested
`/home/work/sz23492` does not exist for this account.

```bash
RNG_WORK="$HOME/rng_validation_sources_$(date -u +%Y%m%d_%H%M%S)"
mkdir "$RNG_WORK" && unzip ~/rng_validation_sources.zip -d "$RNG_WORK" && cd "$RNG_WORK"
module load synopsys/2022
source "$HOME/.venvs/monte_carlo/bin/activate"
python --version
python -c 'import numpy, matplotlib; print(numpy.__version__, matplotlib.__version__)'
python -B scripts/run_rng_validation.py
```

The recorded Mario flow used `synopsys/2022`; use `module avail` if the module
name differs. Mario defaults to Python 3.6.8. The working environment was
created with `/usr/bin/python3.11 -m venv "$HOME/.venvs/monte_carlo"` and
`python -m pip install numpy matplotlib` after activation. The runner passes
that same interpreter to Make.

Raw logs, source hashes, RTL streams, short VCDs and synthesis reports go under
`reports/rng_validation/<tag>/`; analyzed tables and plot go under
`results/<tag>_*`, including `results/<tag>_ppa.csv`.
Large raw stream hex files and build products are gitignored.
The source bundle works without a Git checkout; the evidence records that fact.

For an intentional simulation-only run:
`python3 -B scripts/run_rng_validation.py --skip-synth`.
Its manifest explicitly records that synthesis was skipped; this does not
complete the timing/area task. Use `--help` for sample counts and tags.

### Checkpoint handoff

The supplied PPA CSV has been reviewed. Transfer and inspect the raw timing
and constraint reports before completing the evidence review.
Record the measured area, constrained clock, setup slack, critical-path
endpoints, hold/electrical violations and the RTL screening results.
Report measured evidence without treating a pre-layout Fmax estimate as
post-route timing. Multi-lane hardware and physical implementation remain later
milestones; the current RNG deliverable is one RNG block plus the one-lane
integration evidence.
