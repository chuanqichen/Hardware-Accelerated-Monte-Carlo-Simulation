# Research plan: from course project to a publishable result (2026-11-21)

Inputs: `literature_2026-11-21.md` (what exists), `treegrng_study.md` (one-afternoon
feasibility measurement), and the project's own results (Gaussian work plan Sec. 6-6.3,
`results/`). Three candidate questions were ranked on novelty after the literature check,
evidence already in hand, remaining effort, and venue fit.

## Ranking

| Rank | Question | Novelty after lit. check | Evidence in hand | Effort to paper | Venue |
|---|---|---|---|---|---|
| **1** | **Tail-aware figure of merit for hardware GRNGs**: evaluate generator *architectures* by exact option-pricing bias per unit area/energy on one standard-cell flow, not by K-S/chi-square | High. Giles et al. analyse approximate-normal bias mathematically and remove it with nested MLMC; no paper compares hardware GRNG architectures by downstream pricing bias on a matched ASIC flow | Strong: exact-bias method, LUT a=8/10/12 curve (LUT and lane level), TreeGRNG measured on the same flow: **10-30x more bias at comparable area, fails the 1 % target while K-S = 0.014 looks fine** | 4-6 weeks: 16-bit TreeGRNG regeneration, Box-Muller/CLT baseline, segmented LUT point, activity-based energy, writing | DATE / ISCAS / ARITH short paper; TCAS-II brief |
| 2 | **Tail-refined segmented inverse-CDF with a pricing-bias bound** | Medium. Piecewise approximations of Phi^-1 are in Giles & Sheridan-Methven 2020; nonuniform (leading-zero-count) segmentation for hardware tables exists in the FPGA GRNG literature (Thomas & Luk). The *bound on pricing bias from tail truncation* and the design-space point are the new parts | Medium: model has a `pwl` mode; bias ~ 4x per 2 address bits measured; a=12 at 8.2k um^2 is the point to beat | 3-4 weeks RTL + analysis; best folded into #1 as the "proposed design" section | Section of #1, or FPL/FPT if standalone |
| 3 | **State-shared vs replicated RNG in ASIC** (the proposal's RQ5) | Medium-high; ThundeRiNG's claim is FPGA-specific and untested on standard cells. But it is a different paper (RNG microarchitecture, not Gaussian accuracy) | Weak: only the replicated side exists; needs a second frontend + 2/4/8 lanes | 8+ weeks | FCCM/FPL/TRETS if the ASIC-vs-FPGA angle is kept |

**Decision: pursue #1 with #2 as its design contribution. Park #3 as future work.**

## Paper 1 - working title

*"Judge the tails: an application-level figure of merit for hardware Gaussian random number
generators, with a matched 45 nm comparison of table, comparator-tree and arithmetic generators"*

### Claims (each already has or can get a number)

1. Global statistics (K-S, moments) do not predict option-pricing error; the exact finite-table
   enumeration does, with no Monte Carlo noise. *(Have: LUT a=8/10/12 bias vs K-S; TreeGRNG
   K-S 0.014 yet 1.4-4.3 % bias.)*
2. On one standard-cell flow and one constraint set, the ROM inverse-CDF table dominates the
   comparator-tree GRNG on the bias-vs-area Pareto front for this workload. *(Have: a=10 LUT
   4.1k um^2 / 0.38 %, TreeGRNG 2.1k um^2 / 4.3 %; need: 16-bit TreeGRNG, a Box-Muller or
   CLT point, energy with real activity.)*
3. A tail-refined segmented table moves the front: a=12 accuracy near a=8 area. *(Need: the
   design; the model's `pwl` mode is the starting point; bound derivation.)*
4. A library-characterisation defect (`DFFPOSX1` setup table) distorts every timing number on
   this PDK; we show how to detect and correct it. *(Have: PR #12 evidence; method note.)*

### Work plan (after the Dec 9 course deadline)

| Week | Task | Output |
|---|---|---|
| 1 | Regenerate TreeGRNG for 16-bit output with `makeVerilogCode.py`; finish the closed-form tree enumeration so bias is exact, not histogram-based | Tree point(s) on the Pareto plot |
| 1 | Box-Muller or CLT (12-uniform sum) GRNG baseline in RTL, same flow | Third architecture |
| 2 | Activity-based power (VCD/SAIF) for all generators; energy/sample and energy/trial | Energy axis |
| 2-3 | Segmented tail-refined LUT RTL + bit-exact model; bound on pricing bias from truncation at \|z\|max | Claim 3 |
| 3 | Read Giles & Sheridan-Methven 2012.09715 / 2102.08164 and Haas & Giles 2502.07123 in full; position vs nested MLMC (cost of a correction level vs cost of a bigger table) | Related-work section, one comparison figure |
| 4 | Write; 4-page DATE/ISCAS format; figures from `make figures` | Draft |
| - | Ask the TA/professor about co-authorship and the FreePDK45 library fix | - |

### Risks

- Giles' 2020 analysis may already contain the piecewise-constant tail bound -> claim 3 becomes
  "hardware realisation of" rather than "new bound". The architecture comparison (claims 1-2)
  stands regardless.
- TreeGRNG's authors could argue INT8 was never meant for finance. Answer with the 16-bit
  regeneration: if the gap persists at matched output width, the point is made; if it closes,
  that is a result too.
- All PPA is pre-layout on an academic PDK with a known-defective flop model. Say so; the
  comparison is matched, which is what matters.

## What the course report should say now

- Future-work paragraph: items #1-#3 above, one sentence each, with the TreeGRNG measurement
  as the teaser ("a published low-cost GRNG that passes K-S fails our 1 % pricing criterion
  by 1.4-4.3x on the same flow").
- Nothing in `rtl/third_party/` is part of the production design.
