# TreeGRNG vs ROM inverse-CDF table: tail bias on a matched flow (2026-11-21)

One-afternoon feasibility check for the research question in `research_plan.md`: does the
state-of-the-art low-cost GRNG (TreeGRNG, Crols et al., DATE 2024) pay for its area in
**option-pricing bias**, which the GRNG literature never measures?

## Setup - same flow, same metric

- TreeGRNG example design (`rtl/third_party/treegrng/`, upstream commit `0bb20793`, unmodified
  except `topgrng8_8_int.sv`, a generated copy with the real-valued threshold parameters
  replaced by the integers the simulator truncates them to - DC does not accept real parameters).
- Synthesised with the shared `scripts/syn/dc_synth.tcl` + `constraints/lane_5ns.sdc` on
  gscl45nm, typical corner: `reports/syn/treegrng_int8_5ns/`.
- Output distribution measured from the **actual RTL** under VCS: 4,194,304 cycles,
  `tb/tb_treegrng_hist.sv` -> `results/treegrng_sim_hist.txt` (256-code histogram).
- Pricing bias: the histogram-weighted expected payoff through our fixed-point `price_dp`
  model (TreeGRNG's INT8 `z = int8/32` fed into the same `Q3.12` port), vs Black-Scholes,
  exactly as for our LUT. `model/treegrng_study.py` -> `results/treegrng_vs_lut.csv`.

## Results

### Distribution quality

| Generator | Output | max \|z\| | mean | var | K-S vs N(0,1) |
|---|---|---:|---:|---:|---:|
| TreeGRNG INT8 (RTL, 4M cycles) | 8 b, 32 LSB/sigma | 4.00 | **-0.018** | 0.997 | **0.0144** (paper: 0.0082) |
| ROM LUT a=8 (exact) | Q3.12 | 2.89 | 0 | 0.995 | 0.0020 |
| ROM LUT a=10 (exact) | Q3.12 | 3.30 | 0 | 0.9987 | 0.00054 |
| ROM LUT a=12 (exact) | Q3.12 | 3.67 | 0 | 0.9997 | 0.00017 |

The simulated mean of -0.018 sigma is 36 standard errors from zero (SE = 1/sqrt(4M) = 0.0005):
the example design has a small systematic offset (LFSR p-bits are not exactly uniform and the
offset-binary code is not symmetric). The paper's K-S figure is not reproduced by its own
example RTL.

### Price bias (the metric that matters here)

| Option | TreeGRNG (RTL hist.) | LUT a=8 | LUT a=10 | LUT a=12 |
|---|---:|---:|---:|---:|
| ITM K=80 s=0.2 | **-1.41 %** | -0.02 % | +0.00 % | +0.02 % |
| ATM K=100 s=0.2 | **-2.21 %** | -0.08 % | -0.01 % | +0.03 % |
| OTM K=120 s=0.2 | **-3.49 %** | -0.37 % | -0.09 % | +0.03 % |
| ATM K=100 s=0.6 | **-3.02 %** | -0.56 % | -0.19 % | -0.08 % |
| OTM K=150 s=0.6 | **-4.33 %** | -1.18 % | -0.38 % | -0.14 % |

### Cost on the same flow (5 ns, gscl45nm)

| Generator | Area um^2 | Flops | Power (default activity) | Slack |
|---|---:|---:|---:|---:|
| TreeGRNG INT8 | **2,144** | 68 | 0.49 mW | +1.08 ns |
| ROM LUT a=8 | 1,618 | 17 | 0.18 mW | met |
| ROM LUT a=10 | 4,060 | 17 | 0.34 mW | met |
| ROM LUT a=12 | 8,152 | 17 | 0.64 mW | met |

(TreeGRNG includes its 8 LFSRs - its own uniform source; the LUT numbers exclude `rng_lane`,
~2k um^2 shared by the lane. Like-for-like, TreeGRNG at 2.1k um^2 sits between LUT a=8 and a=10.)

## Conclusion of the feasibility check

- **The tail-bias gap is real and large.** At comparable area, TreeGRNG's pricing bias is
  **10-30x** that of the ROM table (1.4-4.3 % vs 0.01-0.38 % at a=10), and it misses the 1 %
  target on every option on the grid - while its K-S distance (0.014) would be considered
  perfectly acceptable by the GRNG literature's own standard.
- K-S ranks the generators in the same order as pricing bias here, but the **ratio** is wildly
  different: K-S says TreeGRNG is 26x worse than LUT a=10; pricing bias says 10-30x at the
  tails and - critically - K-S cannot tell you that a=8 passes and TreeGRNG fails the 1 %
  criterion. A body-dominated statistic is the wrong figure of merit for this application.
- This is enough to write the abstract. Caveats before any paper: (i) the example design is
  INT8 with 32 LSB/sigma; the paper's method allows wider outputs and tuned thresholds - the
  fair comparison needs a TreeGRNG regenerated for 16-bit output (their `makeVerilogCode.py`),
  (ii) the -0.018 mean offset should be separated from the tail truncation (|z| <= 4) in the
  bias decomposition, (iii) closed-form enumeration of the tree's distribution (in the script,
  marked WIP) does not yet reproduce the RTL histogram - the histogram is the evidence used.

## Reproduce

```bash
# peach, login shell, module load syn/2022
vcs -sverilog -full64 -timescale=1ns/1ps rtl/third_party/treegrng/{lfsr,comparator,simpledecisiontree8,topgrng8_8}.sv \
    tb/tb_treegrng_hist.sv -o simv_tg && ./simv_tg | grep HIST > results/treegrng_sim_hist.txt
DESIGN=compGRNG_int RTL_FILES="rtl/third_party/treegrng/lfsr.sv rtl/third_party/treegrng/comparator.sv \
  rtl/third_party/treegrng/simpledecisiontree8.sv rtl/third_party/treegrng/topgrng8_8_int.sv" \
  TAG=treegrng_int8_5ns dc_shell -f scripts/syn/dc_synth.tcl
python3 model/treegrng_study.py          # laptop
```

## Update 2026-11-21 (prototype step 1, claim T1): matched output width

TreeGRNG regenerated with the authors' `makeVerilogCode.py` at 12 and 16 bits
(`scripts/research/gen_treegrng.py`; `rtl/third_party/treegrng/gen/`), same flow, 4M-cycle RTL
histograms (`results/treegrng_hist_{12,16}.txt`), `reports/syn/treegrng_int{12,16}_5ns/`.

| Generator | Area um^2 | K-S | P(z > 3.5) (true 2.3e-4) | Worst bias |
|---|---:|---:|---:|---:|
| Tree 8 b (32/sigma) | 2,144 | 0.0144 | 1.6e-4 | 4.33 % |
| Tree 12 b (512/sigma) | 5,099 | 0.0008 | 1.9e-4 | 0.81 % |
| Tree 16 b (8192/sigma) | 8,562 | 0.0004 | 1.9e-4 | **0.37 %** |
| LUT a=8 | 1,618 | 0.0020 | **0** | 1.18 % |
| LUT a=10 | 4,060 | 0.0005 | **0** | **0.38 %** |
| LUT a=12 | 8,152 | 0.0002 | 2.4e-4 | 0.14 % |

**T1 go-criterion not met**: at 16 bits the tree passes the 1 % target. The INT8 failure was a
width artefact and must be labelled as such. What the matched data shows instead:

1. The ROM table still dominates the Pareto front by ~2x: equal bias costs the tree 2.1x the
   area (8,562 vs 4,060); equal area buys the ROM 2.6x lower bias (0.14 vs 0.37 %).
2. **Complementary failure modes that K-S cannot see.** The ROM has an exact body and *zero*
   tail mass beyond |z|max (P(z>3.5) = 0 for a <= 10: a rare-event estimator returns exactly 0);
   the tree keeps tail mass (1.9e-4) but distorts the body. K-S ranks Tree-16 and LUT-10 as
   equal (0.0004 vs 0.0005) and is blind to the ROM's missing tail.
3. This is the motivation for the tail-refined segmented table: exact body *and* tails at
   ROM-class area. The design (claim C3) becomes the centre of the paper; the FoM is the lens.

Reframed thesis: *body-dominated metrics hide complementary tail failures in table and tree
GRNGs; an application-level FoM exposes them; a tail-refined segmented table fixes both.*

## Update 2026-11-21 (prototype step 3, claim T5): second workload

`model/grng_fom.py` -> `results/grng_fom.csv`. Digital (cash-or-nothing) calls at K = 150 / 180 /
200 (exercise probability 2.9 % / 0.25 % / 0.04 %) are pure tail probabilities through the same
fixed-point lane.

| Generator | K-S | European worst | Digital K=180 | Digital K=200 |
|---|---:|---:|---:|---:|
| ROM a=10 | 0.0005 | 0.38 % | +11 % | **-100 % (returns exactly 0)** |
| ROM a=12 | 0.0002 | 0.14 % | +1.6 % | +6.8 % |
| Tree 16 b | 0.0004 | 0.37 % | -0.3 % | -9.0 % |

The ranking flips with the workload; K-S (equal for ROM-10 and Tree-16) predicts neither column.
ROM: exact body, no tail beyond |z|max. Tree: tail present, body distorted. Neither baseline is
acceptable on both workloads -> the segmented table (steps 4-5) is the paper's design centre.
