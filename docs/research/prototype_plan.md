# Prototype plan: de-risk the paper before the proposal goes out (2026-11-21)

Goal: replace the two weakest statements in `paper_proposal_2027.md` - "TreeGRNG *INT8*
fails" (unfair width) and "a segmented table *should* reach 12-bit accuracy at 8-bit area"
(unbuilt) - with measured numbers, and produce the one figure the proposal needs: a
**bias-vs-area Pareto plot with at least five generator points on one flow**. Everything runs
on tooling that already exists (exact-bias model, `dc_synth.tcl` + `lane_5ns.sdc`, VCS
histogram TB). Branch `research/tail-aware-grng` only; no team PRs.

## Claims under test and their go/no-go

| # | Claim | Prototype step | Go | No-go (still publishable, reframed) |
|---|---|---|---|---|
| T1 | The tail gap is not an INT8 artefact | Regenerate TreeGRNG at 12- and 16-bit output with the authors' `makeVerilogCode.py`; VCS histogram; same bias pipeline; DC | 16-bit tree still > 1 % worst-case bias at >= uniform-ROM-a=10 area | Gap closes -> paper becomes "how to size comparator trees for tails"; FoM claim unchanged |
| T2 | The FoM is exact, not sampled, for *every* architecture | Finish closed-form enumeration of the tree (match the 4M-cycle histogram to < 1e-4 per code) | Match | Fall back to 2^26-cycle histograms (SE ~ 1e-4) - weaker but acceptable |
| T3 | A tail-refined segmented ROM moves the Pareto front | Model: LZC-segmented inverse-CDF, 4-6 segments, bit-exact; sweep segment count/width; then RTL + DC | a=12 bias (<= 0.15 % worst) at <= 1.3x a=8 area (~2.1k um^2) | Even "a=12 bias at a=10 area" is a result; if no gain, drop C3 and keep C1/C2/C4 |
| T4 | The bias bound predicts the tables | Derive bias of E[max(S_T-K,0)] from tail truncation at z_max (integral of payoff tail) + quantisation (Jensen term); compare to exact tables for a = 6..12 and all 5 options | Within 10 % for a >= 8 | Report as empirical law with partial explanation |
| T5 | The ranking generalises beyond one payoff | Second workload through the same enumeration: rare-event probability P(z > 3.5) (hardware vs 2.3e-4) and a digital (cash-or-nothing) option | Same ranking of generators | Finance-only paper; still ICCAD-viable |
| T6 | Baseline set is credible | CLT-12 (sum of 12 uniforms) generator RTL + exact model; DC on the same flow | Point on the plot | - |

Optional if time allows: activity-based power (SAIF from the histogram TB) for each generator ->
energy per sample axis.

## Steps, in order (each leaves a committed artefact)

| Step | Work | Artefact | Est. |
|---|---|---|---|
| 1 | **TreeGRNG 12/16-bit**: read `makeVerilogCode.py`, generate `topgrng12`, `topgrng16`; integer-threshold copies; VCS 4M-cycle histograms; DC runs | `rtl/third_party/treegrng/gen/`, `results/treegrng_hist_{8,12,16}.txt`, `reports/syn/treegrng_int{12,16}_5ns/` | 1 session |
| 2 | **Tree enumeration fix**: derive mux/reverser bit order from the generator script rather than guessing; assert vs histogram | `model/treegrng_study.py` exact mode passes; `test_treegrng_study.py` | 0.5 |
| 3 | **Second workload + K-S table**: add `rare_event()` and `digital_call()` to the bias pipeline; one table for all generators | `model/grng_fom.py` (generic: any {z, p} -> all metrics), `results/grng_fom.csv` | 0.5 |
| 4 | **Segmented LUT model**: `GaussLutConfig(mode="seg")`: segment k covers u in [2^-(k+1), 2^-k) with its own uniform sub-table; LZC selects segment; sweep (segments, bits/segment); exact bias and ROM bits | `model/gauss_lut.py` seg mode, `results/seg_lut_sweep.csv`, plot | 1 |
| 5 | **Segmented LUT RTL**: LZC + per-segment case-ROM generator, LATENCY 1/2, bit-exact TB vectors; DC at the chosen point(s) | `rtl/gauss_lut_seg.sv`, `rtl/generated/gauss_lut_seg_rom.sv`, `tb/tb_gauss_lut_seg.sv`, `reports/syn/gauss_lut_seg_*` | 1.5 |
| 6 | **CLT-12 baseline**: 12 x 12-bit LFSR/xoshiro words summed, scaled to Q3.12; exact distribution by convolution; RTL; DC | `model/clt_grng.py`, `rtl/clt_grng.sv`, `reports/syn/clt12_5ns/` | 1 |
| 7 | **Bias bound**: derive, implement `bias_bound(z_max, lsb, option)`, compare | `docs/research/bias_bound.md`, `model/bias_bound.py`, figure | 1 |
| 8 | **The figure**: Pareto plot, worst-case bias (log) vs area, all points: uniform ROM a=6..12, segmented ROM (2-3 points), TreeGRNG 8/12/16, CLT-12; K-S annotated to show it mis-ranks | `scripts/plot_grng_pareto.py`, `docs/figures/grng_pareto.png` | 0.5 |
| 9 | **Update proposal** with measured numbers; 1-page PDF for the professor | `paper_proposal_2027.md`, `proposal.pdf` | 0.5 |

Total ~8 sessions (one session = one focused block of a few hours with peach access).
Steps 1-3 are the ones that could kill the thesis; do them first, re-assess, then 4-8.

## Decision point after step 3

- If T1 holds (16-bit tree still fails 1 %) and T5 holds (ranking stable), the proposal's hook
  is safe -> proceed to the design (4-5) and theory (7).
- If T1 fails, stop and rewrite the proposal around the FoM + sizing-rule story before doing
  steps 4-8; tell the professor that version instead.

## What we will *not* do yet

P&R, FPGA implementations, activity-based energy for the lane, the library HSPICE fix - all
post-proposal. The prototype is about the accuracy axis and matched synthesis area.
