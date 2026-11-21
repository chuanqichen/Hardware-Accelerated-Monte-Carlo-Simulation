# Paper proposal: tail-aware design of hardware Gaussian random number generators

_Draft 2026-11-21. Primary target ICCAD 2027 (ASIC); alternative FPL 2027 (FPGA track, with an
FPGA implementation leveraging the post-placement optimisation flow from our DAC 2027 submission)._

## Working title

**Judge the Tails: An Application-Level Figure of Merit and a Tail-Refined Table Generator for
Hardware Gaussian Random Numbers**

## One-paragraph abstract (draft)

Hardware Gaussian random number generators (GRNGs) are evaluated with body-dominated statistics -
Kolmogorov-Smirnov distance, moments, samples per second per mm^2 - yet their consumers (Monte
Carlo option pricing, rare-event estimation, Bayesian-neural-network uncertainty) are governed by
the tails. We show that these metrics are not predictive: on a matched 45 nm standard-cell flow, a
published comparator-tree GRNG with K-S 0.014 carries 1.4-4.3 % systematic bias on a European
option grid and fails a 1 % accuracy criterion on every case, while a 10-bit inverse-CDF table of
twice its area carries 0.01-0.38 %. We propose (i) an **exact, noise-free figure of merit**: enumerate
the finite output distribution of any GRNG and propagate it through the fixed-point consumer to
obtain the downstream bias in closed form; (ii) a **bias bound** relating table tail truncation and
quantisation to the error of a convex payoff, which predicts the measured 4x-per-two-address-bits
law and lets a designer size a generator from an accuracy target; (iii) a **tail-refined segmented
inverse-CDF generator** using leading-zero-count addressing that reaches 12-bit-table accuracy at
8-bit-table area; and (iv) a **matched comparison** of four architectures (uniform ROM, segmented
ROM, comparator tree, CLT/Box-Muller) with post-layout area, timing and activity-based energy,
including the disclosure and correction of a flip-flop setup-table defect in the FreePDK45
library that distorts every published timing number on that PDK. Two workloads - option pricing
and rare-event probability estimation - reproduce the same ranking. All RTL, bit-exact models,
flow scripts and the corrected library are released.

## Contributions and their evidence status

| # | Contribution | Status (Nov 2026) | Remaining |
|---|---|---|---|
| C1 | Exact application-level FoM (enumerate finite distribution -> downstream bias, no MC noise) | **Done** for LUT (model) and TreeGRNG (RTL histogram, 4M cycles) | Closed-form tree enumeration; second workload |
| C2 | Bias bound: truncation at \|z\|max + LSB quantisation -> bias of convex payoff; explains "4x per 2 bits" | Empirical law measured | Derivation; verify vs tables within 10 %; position vs Giles & Sheridan-Methven 2020-21 |
| C3 | Tail-refined segmented inverse-CDF (LZC segment select), bit-exact, synthesised | Design sketched (work plan Sec. 3.4); uniform-PWL variant modelled | RTL + model + DC; target a=12 bias at <= a=8 area |
| C4 | Matched comparison: 4 architectures, gscl45nm, same SDC, post-layout, energy with activity | Uniform ROM (3 sizes) and TreeGRNG INT8 synthesised; lane-level A/D/E done | 16-bit TreeGRNG, CLT/Box-Muller RTL, Innovus P&R, SAIF power |
| C5 | Library defect disclosure + HSPICE re-measured correction | Detected, isolated (PT sensitivity), TA asked | HSPICE bisection of 4 entries; `lc_shell` recompile; before/after |
| C6 | Open-source release | Repo exists | Clean-room research branch, corrected `.lib`, README |

## Why it is publishable (positioning)

- **Novelty vs the GRNG literature** (TreeGRNG DATE'24, CIM/p-MEM GRNGs DAC'26/TCAS'26, Thomas &
  Luk FPGA GRNGs): they optimise K-S and GSa/s/mm^2; we show those metrics mis-rank generators for
  tail-sensitive consumers and give the metric that does not.
- **Novelty vs the approximate-normal MC literature** (Giles & Sheridan-Methven 2020-21; Haas &
  Giles 2025 FPGA MLMC): they analyse the bias of cheap approximate normals and *remove it
  statistically* with a nested MLMC level; we *engineer it in hardware* and compare generator
  architectures on one flow. We quantify the crossover: cost of an MLMC correction level vs cost of
  a bigger/segmented table. Complementary, and a direct comparison nobody has made.
- **Rigor reviewers reward**: exact (not sampled) accuracy numbers; one library, one SDC, one flow for
  every design point; post-layout; a reproducible library-defect correction.

## Target A - ICCAD 2027 (ASIC)

| Milestone | Date (approx.; confirm on CFP, usually posted Jan) |
|---|---|
| Theory (C2) + fair baselines (16-bit TreeGRNG, CLT) | Dec 10 - Jan 15 |
| Segmented LUT RTL + model + DC (C3) | Jan 15 - Feb 15 |
| Second workload; P&R + SAIF energy (C4); library fix (C5) | Feb 15 - Mar 20 |
| Full draft | Mar 20 |
| **Abstract / paper deadline** | **~mid / late April 2027** |
| Notification | ~late July 2027 |
| Conference | ~Oct/Nov 2027 |
| Fallback | TCAS-I submission Aug 2027 (full length) or DATE 2028 (Sept 2027 deadline) |

Format: 8 pages ACM/IEEE double column. Angle: CAD methodology (the FoM and sizing bound) + a
design that uses it.

## Target B - FPL 2027 (FPGA track) - alternative or companion

Rationale: the FPGA GRNG lineage (Thomas & Luk; Haas & Giles 2025 on MLMC) is where the
approximate-normal conversation already lives, and our DAC 2027 submission gives us a
post-placement optimisation flow that makes an FPGA implementation cheap and differentiated.

Additional content over Target A:
- Implement the four generators on an AMD/Xilinx device (Vitis/Vivado 2022–2023 on peach): the
  uniform and segmented ROMs map to BRAM/LUTRAM, TreeGRNG to LUT6 comparators, CLT to DSP/LUT
  adders - a different cost landscape, which is exactly the point about FPGA-specific wins
  (ThundeRiNG, TreeGRNG) not transferring to ASIC and vice versa.
- Apply the DAC'27 post-placement optimisation to the generator + pricing lane and report
  Fmax/LUT/FF/BRAM/DSP and energy before/after - a reuse of our own method on a new workload.
- Direct engagement with Haas & Giles: same device class, same application; our table vs their
  approximate normals + nested MLMC at matched accuracy.

| Milestone | Date (approx.; FPL CFP usually out Dec/Jan) |
|---|---|
| Vivado implementations of the four generators + lane | Jan - Feb 2027 |
| Post-placement optimisation pass (DAC'27 flow) | Feb - early Mar |
| **Abstract / paper deadline** | **~early / mid March 2027** |
| Notification | ~late May / June 2027 |
| Conference | ~Sept 2027 |

Choice: FPL comes **before** ICCAD, so the FPGA paper could be the first submission with the ASIC
paper six weeks later - but two papers from one study invites "salami" criticism. Cleaner options:
(a) one ICCAD paper with the FPGA results as a cross-platform section (strongest single paper);
(b) FPL for the FPGA-plus-post-placement contribution (where the DAC'27 method is the novelty) and
ICCAD/TCAS-I for the metric-plus-ASIC-design contribution, with clearly disjoint claims.
Recommendation: **(a) unless the FPGA results carry a contribution of their own** (e.g., the
post-placement flow changes the generator ranking), in which case (b).

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Giles' analysis already contains the table bound | Cite and extend to hardware form; the architecture comparison and the generator (C3, C4) stand |
| TreeGRNG at 16 bits closes the gap | Then the paper's result is "how to size comparator trees for tails" - still a contribution; the FoM is unchanged |
| Academic PDK, pre-silicon | Matched flow; post-layout; library correction documented |
| Team/credit | Course project origin; agree authorship with the professor and teammates early (flow: Tyler; datapath: Eric; RNG: Shentong) |

## Immediate next actions (before Dec 9, low effort)

1. Confirm ICCAD 2027 and FPL 2027 dates when CFPs post (Jan).
2. Read Giles & Sheridan-Methven 2012.09715 and 2102.08164; note what the bound already covers.
3. Regenerate TreeGRNG at 16-bit output with `makeVerilogCode.py`; run the same histogram + bias.
4. Ask the professor about co-authorship and the FreePDK45 library fix.
