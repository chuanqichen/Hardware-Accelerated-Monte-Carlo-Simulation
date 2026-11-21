# Literature check: hardware Gaussian generation and option-pricing accuracy (2026-11-21)

Purpose: before investing in a paper, find out whether anyone already evaluates hardware
Gaussian random-number generators (GRNGs) by their **application-level pricing bias**
rather than by global distribution statistics, and what the Verhelst group did after
TreeGRNG. Sources: arXiv Atom API (queries below), existing `docs/references/`.

## Queries run

| Query | Hits 2023+ |
|---|---|
| `"Gaussian random number generator" AND (hardware OR FPGA OR ASIC)` | 5 |
| `au:Verhelst AND (Gaussian OR random number OR Bayesian neural)` | 25 (group output; 3 relevant) |
| `"Monte Carlo" AND option AND (FPGA OR hardware OR accelerator)` | 14 (mostly quantum; 1 relevant) |
| `("inverse CDF" OR "tail accuracy") AND Gaussian AND (hardware OR FPGA)` | 3 |
| `au:Sheridan-Methven OR (au:Giles AND approximate random)` | 7 |

## What exists

### Closest prior art - must be cited and positioned against

| Ref | What it does | Relation to us |
|---|---|---|
| **Giles & Sheridan-Methven, arXiv 2012.09715 (2020)** *Approximating inverse cumulative distribution functions to produce approximate random variables* | Piecewise-polynomial approximations of $\Phi^{-1}$ with analysis of the resulting error in Monte Carlo estimates. | Our ROM LUT is the degenerate (piecewise-constant) case. Their error analysis is the mathematical frame our exact-bias tables sit in. |
| **Sheridan-Methven & Giles, arXiv 2012.09739 (2020)** *Rounding error using low precision approximate random variables* | Fixed-point / low-precision random variables in SDE simulation; rounding-error model. | Overlaps our D-4/D-5 fixed-point study (Q3.12 `z`, Q5.12 `x`). |
| **Giles & Sheridan-Methven, arXiv 2102.08164 (2021)** *Analysis of nested MLMC using approximate Normal random variables* | Removes the bias of approximate normals with a nested MLMC correction level. | Their answer to our tail bias is "correct it statistically"; ours is "engineer it in hardware". Complementary, and the comparison is itself a question. |
| **Haas & Giles, arXiv 2502.07123 (Feb 2025, under review)** *A nested MLMC framework for efficient simulations on FPGAs* | Approximate normal increments + optimised fixed-point bit-widths per MLMC level on FPGA; rounding-error model sets bit-widths. | Closest to the whole project. Differences: FPGA not ASIC; MLMC not single-level; they choose precision from an error model, we measure exact bias of a finite table. |

### TreeGRNG lineage (Verhelst / MICAS and others)

| Ref | What it does | Relation |
|---|---|---|
| Crols, Paim, Zhao, Verhelst, DATE 2024 (arXiv 2606.16599 posted 2026-06) *TreeGRNG* | Comparator-tree GRNG, INT8, 45 nm: 1,020 NAND2-eq, 3 GSa/s, K-S 0.0082, 3.7x energy/sample, 5.8x throughput/area vs Hadamard. Open source. | The candidate low-cost frontend; judged on K-S only. |
| Zhao et al., arXiv 2507.12935 (2025) *MC^2A: MCMC accelerator co-design* | Roofline-style MCMC accelerator framework. | Group moved to MCMC systems; no GRNG tail work. |
| Pei et al., DAC 2026 (arXiv 2607.02465) *Probabilistic Memory*; Davis et al., TCAS-I 2026 (arXiv 2606.07439) 16.3 fJ/sample CIM GRNG | GRNG folded into memory / compute-in-memory for Bayesian NN inference; metrics are GSa/s/mm^2 and fJ/sample. | Confirms the field's figure of merit is throughput/energy, **not tail fidelity**. |
| Soto et al., arXiv 2404.02251 (2024) | CLT over binary sequences; mentions "tail accuracy" as a requirement but evaluates moments. | Same pattern. |

### Finance-side hardware MC
Nothing new on ASIC trial-based pricers 2024-26 on arXiv beyond Haas & Giles; the rest is quantum
option pricing. Vitis Quantitative Finance (Xilinx) remains the open FPGA reference (already in
`docs/references/`).

## The gap, stated precisely

1. **Every hardware GRNG paper found evaluates with body-dominated statistics** (K-S, chi-square,
   moments, GSa/s/mm^2). None reports the error of a tail-sensitive downstream quantity.
2. **The approximate-normal literature (Giles et al.) analyses bias mathematically and removes it
   with MLMC**, on CPUs/FPGAs with piecewise-polynomial approximations. It does not compare
   *hardware generator architectures* (ROM, segmented ROM, comparator tree, CLT) on a matched
   ASIC flow by pricing bias per unit area/energy.
3. Our contribution candidates sit in the intersection: an **exact (enumerated) pricing-bias
   figure of merit** applied to **several GRNG hardware architectures on one standard-cell flow**,
   with the Giles-style error analysis as the theory and TreeGRNG as the SoTA low-cost baseline.

## Risks to the claim

- Giles & Sheridan-Methven may already contain a piecewise-constant (table) bound that makes our
  "bias ~ 4x per 2 address bits" a corollary; read 2012.09715 fully before claiming novelty of
  any bound. The *measurement methodology* (enumerating the finite distribution) and the
  *architecture comparison* remain ours regardless.
- The MLMC camp can argue tail bias is irrelevant if corrected statistically. The answer is
  cost: a nested correction level costs samples and a second datapath; we should quantify both
  sides on the same flow.
- Check IEEE Xplore (TCAS, TVLSI, FPL/FPT/FCCM 2024-26) - arXiv coverage of this area is thin.
  Thomas & Luk's FPGA GRNG survey line (2007-2010) is the classic reference set.
