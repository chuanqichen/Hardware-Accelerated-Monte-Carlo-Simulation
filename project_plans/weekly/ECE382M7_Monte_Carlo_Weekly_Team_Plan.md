# ECE 382M-7 — Weekly Team Execution Plan

**Project:** Hardware-Accelerated Monte Carlo Option Pricing  
**Dates:** October 18–December 9, 2026  
**Intermediate checkpoint:** November 10, 2026  
**Presentations:** December 1 and 3, 2026  
**Final submission:** December 9, 2026

> This is a proposed execution plan based on the revised project proposal, lane interface draft, and professor's feedback. Confirm tool availability and course-specific requirements with the teaching staff.

## Project goals and success criteria

Professor feedback emphasizes (1) defining accuracy criteria and (2) demonstrating throughput feasibility. Our team will:

- Verify all RTL results against a bit-accurate Python reference (zero unexplained mismatches).
- Compare option-price estimates against Black–Scholes, separating deterministic approximation bias from Monte Carlo sampling error. Proposed systematic-bias target: at most 1% across a team-approved benchmark grid, with absolute-error criteria when option price is near zero; also report 95% confidence intervals.
- Demonstrate sustained initiation interval **II = 1** per lane in RTL and substantiate clock feasibility using synthesis and post-route timing.
- Compare 1-, 2-, and 4-lane implementations using consistent constraints and report area, frequency, power, trials/sec, and energy/trial.

## Team ownership

| Member | Responsibility | Deliverables |
|---|---|---|
| Tyler Haverlah | Integration, synthesis, physical design | `mc_top`, controller, SDC, DC/P&R scripts, PPA and layout evidence |
| Chuanqi Chen | Gaussian LUT, fixed-point | `gauss_lut`, `round_sat`, `mc_pkg`, numerical study and Gaussian synthesis |
| Eric Goode | Stock price, exponential, payoff, accumulation | Pricing datapath, exp LUT, accumulator, reference model |
| Shentong Zhong | RNG, stream testing | xoshiro128++ RTL, seed policy, stream tests |

## Tools

| Tool | Purpose |
|---|---|
| Git / GitHub | Feature branches, PRs, issues, documentation |
| Python 3 / NumPy / Matplotlib | Golden model, accuracy, test vectors, plots |
| Synopsys VCS and DVE/Verdi | RTL simulation and waveform debug |
| Verilator | RTL lint |
| Synopsys Design Compiler | Standard-cell synthesis, area and timing |
| SDC | Clock and I/O constraints |
| Course-supported place-and-route tool (e.g., Innovus) | Placement, CTS, routing; confirm actual availability |
| STA and power tools | Timing and energy analysis |
| Pandoc / LaTeX | PDF reports |

## Phase I: Intermediate checkpoint

### Week 1 — October 18–24: Standalone modules and interface freeze

**Chuanqi:** Run `make test`, `make sweep`, `make gen ADDR_BITS=10 OUT_WIDTH=16 FRAC_BITS=12`, and VCS at `LATENCY=1,2`. Implement `rtl/round_sat.sv` and `rtl/mc_pkg.sv`; test ties-to-even, negative numbers, and saturation. Agree with Eric on fixed-point formats and exponential domain. The baseline is 10 **address** bits and 16-bit Q3.12 output; 8/12 address bits are experiments.

**Shentong:** Implement `rng_lane.sv` with xoshiro128++, reset, seed load, run/valid, reference-sequence comparisons, high-bit tests, and one word per cycle.

**Eric:** Implement fixed-point `B*z`, `A+Bz`, bounded exp LUT, payoff, accumulation, pipeline/valid latency, and saturation cases.

**Tyler:** Finalize `mc_top` interface/controller skeleton, synthesis script, standard-cell library/corner, and SDC; run synthesis smoke test.

**Exit criteria:** Interface signoff, tested standalone modules, and working synthesis setup.

### Week 2 — October 25–31: Integrated one-lane design

**Chuanqi:** Integrate `u_valid/u` to Gaussian and `z_valid/z` to pricing; check valid/bubble alignment; contribute Gaussian lookup to `model/mc_lane.py`.

**Shentong:** Integrate RNG and verify repeatability and continuous stream.

**Eric:** Complete pricing and accumulator; produce per-trial Python trace (`u,z,bz,x,S_T,p`); verify directed corners.

**Tyler:** Connect one-lane `mc_top`, config, ISSUE/DRAIN/DONE controller, cycle counter and integrated self-checking testbench.

**Tests:** 100, 1,000 and 10,000 trials; exact sum/count/status, reset/restart, bubbles, continuous valid, and no unknown values on valid-qualified buses.

**Exit criteria:** Bit-exact one-lane RTL vs Python with zero unexplained mismatches.

### Week 3 — November 1–7: Accuracy and synthesis evidence

**Chuanqi:** Synthesize Gaussian `ADDR_BITS={8,10,12}` (optional `OUT_WIDTH={12,16}`); save results in `results/gauss_lut_ppa.csv`; extend bias study through quantized `x,S_T,p`.

**Shentong:** Report RNG timing/area and stream quality.

**Eric:** Synthesize pricing datapath, identify multiplier/exp critical paths, pipeline without losing II=1.

**Tyler:** Synthesize one lane, measure critical path and area, establish feasible clock methodology.

**Accuracy:** Compare quantized expected option prices with Black–Scholes across ATM/ITM/OTM/high-volatility cases. Use independent seeds to estimate Monte Carlo uncertainty separately.

**Throughput:** Show consecutive valid outputs after fill and timing evidence at target frequency.

### Week 4 — November 8–10: Checkpoint

- [ ] One-lane architecture and spec
- [ ] RTL vs Python pass logs
- [ ] Gaussian/RNG accuracy evidence
- [ ] Initial synthesis area, timing, critical path
- [ ] II=1 demonstration and throughput calculation
- [ ] Risks and scaling plan

**Presentation ownership:** Tyler—architecture/PPA; Shentong—RNG; Chuanqi—Gaussian/precision; Eric—pricing/integration.

## Phase II: Final implementation

### Week 5 — November 11–17: 2/4-lane scaling

**Tyler:** Parameterize `LANES=1,2,4`, reduction tree, masking and drain. **Chuanqi:** Multi-lane Gaussian output and valid alignment. **Eric:** Multi-lane payoff reduction, count and overflow. **Shentong:** Independent seeds and stream verification.

Test `N_TRIALS=101,1001,10003` for nonmultiples of lane count. Verify exact Python output per configuration and sustained II=1/lane.

### Week 6 — November 18–24: PPA and numerical tradeoff

| Config | Lanes | Gaussian address bits | Purpose |
|---|---:|---:|---|
| A | 1 | 10 | Baseline |
| B | 2 | 10 | Scaling |
| C | 4 | 10 | Scaling |
| D | 1 | 8 | Smaller LUT |
| E | 1 | 12 | Higher accuracy |

Hold library, corner, clock constraint and activity assumptions constant. Record cell area, critical path, achieved timing, power, trials/sec, energy/trial and accuracy. Chuanqi produces accuracy-versus-area plots. **Freeze numerical and synthesis results November 24.**

### Week 7 — November 25–30: Physical implementation

**Tyler:** Import gate-level netlist; floorplan, power plan, placement, CTS, routing, extraction, physical checks, post-route timing/power. Prioritize one representative configuration for complete evidence.

**Chuanqi:** Final Gaussian/fixed-point analysis. **Eric:** Final pricing/throughput tests. **Shentong:** RNG stream evidence.

If routed timing fails, report the violation; do not present synthesis timing as post-route timing.

### Week 8 — December 1–6: Presentation and final documentation

Present on **December 1/3**: correctness, II=1, 1/2/4-lane scaling, area/power/accuracy tradeoffs. Tyler covers architecture/physical design; Shentong RNG; Chuanqi Gaussian precision; Eric pricing. Avoid major RTL changes after presentation unless fixing demonstrated defects.

### Week 9 — December 7–9: Final submission

- [ ] Specification, design/user/test documentation
- [ ] RTL, generated ROM, Python model and test vectors
- [ ] Testbenches, passing logs, synthesis/SDC/P&R scripts
- [ ] Raw tool reports and canonical CSVs/plots
- [ ] Accuracy and 95% confidence-interval analysis
- [ ] 1/2/4-lane PPA and throughput comparison
- [ ] Representative layout and post-route evidence
- [ ] Final report, presentation, reproducibility instructions

## Weekly coordination

- **Monday (20–30 minutes):** Assign tasks, freeze interfaces, identify blockers.
- **Thursday (30–45 minutes):** Demonstrate tests, review pull requests, merge validated changes.
- **Sunday (asynchronous):** Update GitHub issues and upload results.

A module present in GitHub is not automatically verified; completion requires reproducible test evidence.

## Risk and fallback plan

| Risk | Mitigation |
|---|---|
| Exp LUT takes too long | Use simpler correct bounded implementation |
| Interface mismatch | Compare raw intermediate values against Python trace |
| Timing fails | Pipeline while maintaining II=1, or report feasible lower frequency |
| Four lanes too costly | Preserve working one/two-lane results and document limits |
| Physical-design delay | Complete one representative layout first |
| Numerical bias too high | Constrain supported inputs or adjust LUT resolution |

## Chuanqi: October 19–25 checklist

- [ ] Mon Oct 19: Gaussian Python and VCS tests at both latencies.
- [ ] Tue Oct 20: Implement/test `round_sat.sv`.
- [ ] Wed Oct 21: Complete `mc_pkg.sv` and agree Q-formats with Eric.
- [ ] Thu Oct 22: Baseline Gaussian DC synthesis with Tyler.
- [ ] Fri Oct 23: Compare 8/10/12-bit Gaussian configurations.
- [ ] Weekend Oct 24–25: Submit Gaussian integration PR and measured results.

## Repository references

- `docs/Project_Proposal.md` — revised scope and deadlines.
- `docs/Lane_Interface_Spec.md` — draft interface and numeric contract.
- `docs/Gaussian_Lookup_Work_Plan.md` — Gaussian owner plan.
- `README.md`, `Makefile` — repository commands.
