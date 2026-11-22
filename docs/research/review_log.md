# Proposal review loop (2026-11-21): three rounds, five referee personas

Personas: R1 ICCAD TPC / CAD methodology; R2 numerical analyst (Giles school); R3 GRNG hardware
architect; R4 quantitative-finance application expert; R5 VLSI circuits / sign-off. Each round the
referees saw the revised proposal plus their own previous review, and were instructed not to
inflate for responsiveness. Stop rule: no score below 4 and mean >= 4.5, or three rounds.

## Scores (OVERALL, 1-5)

| Round | Proposal | R1 | R2 | R3 | R4 | R5 | Mean |
|---|---|---:|---:|---:|---:|---:|---:|
| 1 | v3 | 3 | 2 | 2 | 2 | 2 | 2.2 |
| 2 | v4 | 3 | 3 | 3 | 3 | 3 | 3.0 |
| 3 | v5 | 3 | 3 | 3 | 3 | 3 | 3.0 |

Sub-scores in round 3: Novelty 3-4, Soundness 3, Evidence 3, Clarity 4, Significance 3.

## What each round changed

- **v3 -> v4** (cheap + two measurements): two-sided discrete K-S; exact-vs-histogram labelling;
  "near-equal" wording; both generator-only and source-inclusive area; degrees-of-freedom-matched
  PWL comparison (withdrew "L2-optimal is not bias-optimal" as a general claim); library-defect
  sensitivity re-synthesis (<= 4.7 % area shift, no ranking change); latency/throughput
  paragraph; C2 relabelled a decomposition; application claims narrowed; "silicon" -> pre-layout.
- **v4 -> v5** (three more measurements): 48-option workload grid (production uniform a=10 table
  fails the 1 % budget at 2.46 %; dyadic table 0.50 %); finite-run RMS error 2^16-2^24 trials
  (uniform table bias-limited at 2^24: 0.39 % vs 0.10 %); payoff-weighted PWL fits (no
  improvement); CLT source as five `rng_lane`s; 1 % rationale restated; abstract wording.

## Why it plateaus at 3, unanimously

Every referee's "what would make this a 5" lists the same items, all of which are weeks of work,
not edits:

| Item | Asked by | Effort |
|---|---|---|
| Innovus P&R + SAIF energy per sample for the principal points, source-inclusive, matched throughput | R1 R3 R5 | 2 wk |
| C2 as a theorem with explicit constants (G&S-M lemmas 2.1-2.2) | R1 R2 R5 | 1 wk |
| Nested-MLMC correction vs table refinement at matched RMSE on the lane | R1 R2 | 1 wk |
| Direct bias-objective PWL fit (not a weighted-L2 surrogate) | R2 | 2-3 d |
| Exact enumeration of 12/16-bit trees; uncertainty intervals on histogram-derived tail biases | R1 R3 R4 | 3-4 d |
| Box-Muller baseline; broader, documented tree tuning | R3 | 1 wk |
| Application-grounded tolerance (not "1.5x one run's half-width"); reproducible 48-grid points with uncertainty; finite-run curve with intervals | R4 | 3-4 d |
| Sensitivity re-synthesis for all fifteen configurations; two-stage table PPA | R5 | 1-2 d |

Remaining cheap wording items (to fold into v6 with the above): scope the abstract's "do not
predict pricing error" to the tested generators and grid; state CLT source seeding/independence
assumptions; publish the 48-grid points in `results/`.

## Assessment

The loop converted a 2.2 into a stable 3.0 by fixing every claim that was overstated and adding
five measurements; the referees' remaining objections are the proposal's own Sec. 5 work plan.
A unanimous 3 ("borderline, credible, validation promised not demonstrated") is the correct
verdict for a proposal whose expensive evidence is scheduled. The path to 4-5 is the plan above
(~6-7 weeks), which matches the ICCAD 2027 timeline in the proposal.
