# Presentation draft: integration, verification and physical flow (Tyler)

Draft for the team's final presentation: five slides, about four minutes. Each slide
lists what goes on it and what to say. Numbers come from
`Final_Integration_Contribution.md`. Figures are in `results/` and `docs/figures/`.

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

## Slide 3 - Closing hold and fanout without touching constraints

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

## Slide 5 - What is not closed yet

On the slide:

- Four lanes: Innovus -6 ps with SI on and -56 ps with SI off on the RNG output path;
  PrimeTime +280 ps on the same pins
- A setup-target trial was unsuccessful: two-lane setup -10 ps, four-lane hold -23 ps
- 4,491 / 8,139 / 15,596 rows on seven pins whose library capacitance limit is zero;
  we are asking the course staff how to treat them
- Estimated RC, one corner and zero-delay activity. No DRC/LVS, IR/EM or SDF signoff,
  and no rated frequency.
- Next: a look-ahead register proposed to the RNG owner, not yet implemented

Say: Four lanes are 6 ps short in Innovus. That is less than Innovus's own swing when
crosstalk modelling is switched off, and far less than the gap between the two tools.
Tuning the optimizer only moved the miss around, so the real fix is more margin in the
RNG adder path, without adding latency. All of these numbers are tool estimates on an
extrapolated library, not signoff.

## Likely questions

- **Why not lower the clock?** Hold does not depend on the clock period, and the
  comparisons are matched at 5 ns. A slower clock would hide the four-lane miss
  rather than explain it.
- **Which tool is right?** Neither is signoff. On the four-lane path they differ by
  0.260 ns over identical arcs, with every arc evaluated below the library's first
  table index, so we require both to pass.
- **Why did the area go up?** Mostly hold buffers, plus the synthesis buffer trees
  that the baseline flow deleted.
- **Why not fix the capacitance rows?** Their library limit is zero, so any load
  violates. Changing the limit would be another library approximation, which needs
  course-staff approval.
- **Does the design run at 200 MHz?** Under these models, one and two lanes pass both
  tools at 5 ns. Four lanes do not yet, and none of this is signoff.
