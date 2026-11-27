# Presentation draft: integration, verification and physical flow (Tyler)

Draft for the team's final presentation: five slides, about four minutes. Each slide
lists what goes on it and what to say. Numbers come from
`Final_Integration_Contribution.md`. Figures are in `results/` and `docs/figures/`.

Updated 2026-11-27: slides 2 to 4 explain the archived baseline/closure2 study.
Slide 5 gives the newer PR #27 candidate, including the two-lane physical ECO.
The candidate and its physical evidence require team integration before being
presented as merged main. See `RNG_Physical_Validation.md` for exact provenance.

## Slide 1 - From one lane to four, verified end to end

On the slide:

- A configuration bus and controller around the RNG, Gaussian lookup, pricing
  datapath and accumulator
- 1, 2 or 4 real lanes, a registered reduction tree and jump-separated seeds
- RTL: 88 cases / 105,828 trials for one lane; 35 VCS configurations, 24 of them
  real arrays, when the 1/2/4-lane PR merged
- Gate level: mapped and routed replays of 81 cases / 82,489 trials per matrix

Figure: `docs/figures/lane_block_diagram.png`.

Say: I connected the four blocks behind one controller, then replicated the lane and
added a reduction tree so one, two or four lanes run the same workload. Every step
is checked against the Python model trial by trial: first the RTL, then the
synthesized netlist, then the routed netlist.

## Slide 2 - The baseline layout was not closed

On the slide:

- PR #22 baseline at 5 ns: PrimeTime hold -26 / -28 / -26 ps
- 33 / 98 / 186 hold rows and 160 / 255 / 483 max-fanout rows
- At four lanes Innovus also fails: setup -19 ps, hold -22 ps
- Causes:
  - a 0.10 ns uncertainty on short register loops
  - placement deleting synthesis buffer trees
  - a library with no fanout load
  - seven pins with a zero capacitance limit

Say: The corrected-library baseline routes and replays correctly, but it is not
closed. Hold fails at every lane count because the clock uncertainty also applies to
hold on short loops. Fanout fails because Innovus deletes the synthesis buffer trees
and cannot see the fanout limit in this library.

## Slide 3 - Archived closure2: closing hold and fanout

On the slide:

- Four opt-in Innovus settings: hold target 0.08 ns, keep the synthesis buffers,
  clock fanout 16 and fanout repair
- No SDC, RTL or library change. Closed means PrimeTime and Innovus both pass.
- Setup / hold slack (ns):

| Lanes | PrimeTime | Innovus |
|---:|---:|---:|
| 1 | +0.355 / +0.021 | +0.058 / +0.080 |
| 2 | +0.283 / +0.018 | +0.002 / +0.033 |
| 4 | +0.260 / +0.033 | -0.006 / +0.006 |

Say: These settings change only how Innovus implements the design. Every hold and
fanout row is gone in PrimeTime at all three lane counts, and both tools pass for one
and two lanes. At four lanes, one RNG path still misses Innovus setup by 6 ps.

## Slide 4 - What closure cost

On the slide:

- Routed signal-cell area: +12.6% / +11.1% / +13.2%
- 499 / 932 / 2,865 hold cells added
- Power +8% / +8% / +11%; energy 54.6 / 49.2 / 48.6 pJ per trial
- Synthesis area, floorplan and cycle count unchanged

Figure: `results/multilane_closure_v1.png`, panels c and d. Panel a is synthesis
area, which is the same before and after, so quote the routed area from the table.

Say: Fixing hold is not free. Innovus adds hold buffers, and keeping the synthesis
buffer trees costs area. The design still finishes the workload in the same number
of cycles. Energy per trial falls with more lanes because power grows more slowly
than the lane count while the workload time halves.

## Slide 5 - RNG follow-up passes timing, with limits

On the slide:

- Shentong's carry-select look-ahead sum preserves the exact stream and latency
- Final candidate setup / hold (ns):

| Lanes | PrimeTime | Innovus |
|---:|---:|---:|
| 1 | +0.866 / +0.015 | +0.400 / +0.069 |
| 2 | +0.696 / +0.015 | +0.182 / +0.005 |
| 4 | +0.542 / +0.013 | +0.146 / +0.018 |

- Two lanes required one hold buffer and filler rebuilding; both replay matrices
  pass 81 cases / 82,489 trials, and geometry/connectivity are clean
- Zero-limit capacitance rows remain unresolved: 4,564 / 8,280 / 15,732
- One typical corner, native RC, incomplete coverage and a 5 ps hold margin remain
  limits. No full signoff or rated maximum frequency.

Figure: `results/multilane_rng_lookahead.png`, or the four-lane layout
`docs/figures/rng_lookahead_l4.png`. The candidate PPA is 10.8 / 19.3 / 36.1 mW
and 54.6 / 49.5 / 47.6 pJ per trial. Keep it separate from slide 4's archived study.

Say: The RTL timing change belongs to Shentong. I validated the complete tops with
the same constraints and closure policy. One two-lane short path needed a local
buffer ECO, including rebuilding fillers so physical checks stayed clean. Both
timers now pass at all lane counts. The smallest hold margin is only 5 ps, and the
zero-capacitance-limit rows remain unresolved, so this is still model-based evidence.

## Likely questions

- **Why not lower the clock?** Hold does not depend on the clock period, and the
  comparisons are matched at 5 ns. The follow-up preserves that target and latency.
- **Which tool is right?** Neither establishes signoff. The archived RNG path
  comparison differed by 0.260 ns over identical arcs, below the library table
  range. The new layouts pass both tools while retaining the modelling limits.
- **Why did the area go up?** The archived closure-policy cost was mostly hold
  buffers plus retained synthesis trees. The newer RNG adds about 4 to 5% mapped
  area; its routed area changes by +2.2% / +2.2% / -1.1% versus closure2.
- **Why not fix the capacitance rows?** Their library limit is zero, so any load
  violates. Changing the limit would be another library approximation, which needs
  course-staff approval.
- **Does the design run at 200 MHz?** The final candidate passes both timers at
  5 ns for all three lane counts. Target-rate throughput is calculated from
  simulation cycles, and electrical/model/coverage limits still prevent signoff
  or a rated silicon-frequency claim.
