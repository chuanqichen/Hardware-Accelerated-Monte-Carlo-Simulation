# Four-lane RNG setup path: diagnostic handoff

For Shentong, who owns RNG optimization. Tyler prepared this from the merged
reference implementation, `tyler_closure2_20261123`. It describes the remaining
setup failure and lists options. It changes no RTL, constraint or library value,
and the choice and implementation of any RNG change stay with the RNG owner.

## Summary

- The only remaining Innovus setup failure in the reference is at four lanes:
  `u_lanes/g_lane_3__u_rng/s0_reg_5_` to `u_reg_31_/D`, -0.006 ns with SI-aware
  delay calculation. PrimeTime times the same pins and transitions at +0.280 ns.
- The RNG output register's top bits are the worst setup endpoints at every lane
  count in both tools, and every lane's `u_reg_31_` is close to the limit. This is
  the block's critical path, not a lane-3 placement accident. The November 8
  standalone RNG synthesis in [RNG_Work_Plan.md](RNG_Work_Plan.md) already had only
  +0.006 ns at 5 ns on `s0_reg[0]` to `u_reg[31]`. That run used the original
  library, so it is historical context, not the matched baseline for an RNG change.
- The path is the xoshiro128++ output function: two chained 32-bit ripple-carry
  additions in one cycle. Each addition takes 2.1 to 2.3 ns of the 5 ns period.
- Taking one addition out of the `u` register's cycle, without changing `LAT_RNG`
  or the output sequence, would recover far more than the tool disagreement or the
  SI sensitivity. The worst non-RNG endpoints have +0.26 to +0.33 ns in Innovus.

## Endpoints

Worst setup endpoint per lane count (Innovus top-50 post-route report and PT top
paths, routed `tyler_closure2_20261123`):

| Lanes | Innovus worst endpoint | Innovus (ns) | PT worst endpoint | PT (ns) | Innovus worst other endpoint (ns) |
|---:|---|---:|---|---:|---|
| 1 | `u_rng/u_reg_30_`, `u_reg_31_` | +0.058 | `u_rng/u_reg_29_` | +0.355 | `u_price/acc_r_reg_0__32_`, +0.327 |
| 2 | `g_lane_1__u_rng/u_reg_31_` | +0.002 | `g_lane_1__u_rng/u_reg_30_` | +0.283 | `g_lane_1__u_price/acc_r_reg_0__32_`, +0.259 |
| 4 | `g_lane_3__u_rng/u_reg_31_` | **-0.006** | `g_lane_3__u_rng/u_reg_31_` | +0.260 | `u_controller/state_reg_0_`, +0.277 |

At four lanes, every lane's `u_reg_31_` is near the limit:

| Lane | Innovus (ns) | PT (ns) |
|---:|---:|---:|
| 0 (`u_rng`) | +0.065 | +0.338 |
| 1 | +0.071 | +0.417 |
| 2 | +0.136 | +0.409 |
| 3 | -0.006 | +0.260 |

## Logic

[`rtl/rng_lane.sv`](../rtl/rng_lane.sv) computes the output from the old state at
each accepted run edge:

```systemverilog
assign sum03  = s0 + s3;
assign result = {sum03[24:0], sum03[31:25]} + s0;     // rotl(s0 + s3, 7) + s0
...
end else if (run && (|{s3, s2, s1, s0})) begin
  u <= result;                                       // LAT_RNG = 1
  s0 <= s0 ^ xor31;  s1 <= s1 ^ xor20;  s2 <= xor20 ^ shifted1;
  s3 <= {xor31[20:0], xor31[31:21]};
```

`seed_state` comes from `mc_top`'s `active_seeds` registers. DC maps both
additions as chains of `FAX1` full adders plus an `AOI22X1`/`OR2X2` carry chain.
The worst route enters the first addition at `s0[5]` and leaves at sum bit 30.
After the 7-bit rotation that bit is operand bit 5 of the second addition (cell
`U849` combines `s0[5]` with it), whose carry then ripples to bit 31.

## Both tools on the same path

[`reports/sta/tyler_rngdiag_20261124_l4/`](../reports/sta/tyler_rngdiag_20261124_l4/)
re-times the committed routed netlist, SPEF and consumed SDC in PT with the
reference settings. It forces the Innovus worst path pin by pin, all 150 data
pins with the same rise/fall transitions:

| Segment | Cells | PT (ns) | Innovus SI on (ns) |
|---|---|---:|---:|
| Clock to launch `s0_reg_5_/CLK` | clock tree | 0.583 | 0.623 |
| Clock to Q | `DFFSR` | 0.130 | 0.131 |
| `s0 + s3`, bit 5 to sum bit 30 | 25 `FAX1`, 3 others | 2.199 | 2.275 |
| `rotl(sum, 7) + s0`, bit 5 to bit 31 | 16 `AOI22X1`, 9 `OR2X2`, 9 `FAX1`, 11 others | 2.090 | 2.273 |
| Output select | `OAI21X1` | 0.023 | 0.025 |
| Data arrival | | 5.025 | 5.327 |
| Capture clock at `u_reg_31_/CLK` | clock tree | 0.535 | 0.548 |
| Setup time + 0.10 ns uncertainty | | 0.230 | 0.227 |
| Slack | | **+0.280** | **-0.006** |

Innovus's data path is 0.260 ns (5.9%) slower on the same arcs. `AOI22X1` stages
account for 0.171 ns of that (+33% over 17 stages), while the 34 `FAX1` stages
differ by only 0.035 ns (+1%). With SI-aware delay calculation off, Innovus's worst
path to the endpoint starts at `s3_reg_5_` and fails by 0.056 ns. PT passes those
pins at +0.261 ns, and the gap grows to 0.311 ns (7.0%), with `AOI22X1` 0.135 ns
and `FAX1` 0.113 ns.

## Modelling assumptions

- Both tools use the same routed netlist and SPEF (native RC estimate, no QRC
  file), the typical corner, the `setup_fixed_v1` library pair, propagated clocks
  and the 5 ns clock with 0.10 ns setup uncertainty. Nothing is derated.
- Innovus analyses in on-chip-variation mode with clock-path pessimism removal
  off (`setAnalysisMode -analysisType onChipVariation -cppr none` in
  `scripts/pnr/implement.tcl`). With SI on, it times the shared `clk` input net
  late for launch (0.048 ns) and early for capture (0.028 ns). That leaves
  0.024 ns of shared-path pessimism in this check. With SI off there is no such
  split, but the data delays rise and the endpoint fails by 0.056 ns. Neither
  setting closes the path robustly.
- PrimeTime runs without SI analysis. Its pessimism removal is on, but its shared
  clock delays are identical, so it credits nothing.
- Every pin on the path has a PT transition below 0.06 ns (median 0.032 ns, maximum
  0.052 ns), and the data nets load 7.2 fF median and 30 fF maximum. Every cell arc
  is therefore evaluated below the first library table index (0.06 ns, 0.1 pF).
  `AOI22X1/Y` is also one of the seven output pins with a zero `max_capacitance`
  limit. Attributing the `AOI22X1` gap to table extrapolation would need a
  fixed-slew/load cell comparison.

## Latency-preserving options

These keep `LAT_RNG = 1` and the exact output stream. They are listed for the RNG
owner to evaluate; none has been implemented or timed.

1. **Look-ahead sum register.** Chuanqi first proposed registering `s0 + s3` in
   [PR #12](https://github.com/chuanqichen/Hardware-Accelerated-Monte-Carlo-Simulation/pull/12).
   This option specifies its update rules. Add a 32-bit register `t` that always
   holds `s0 + s3` of the current state, and compute `u <= rotl(t, 7) + s0`. Update
   `t` with the state: zero on reset, `seed_state[31:0] + seed_state[127:96]` on
   `seed_load`, `s0_next + s3_next` on an accepted run edge, where
   `s0_next = s0 ^ s3 ^ s1` and `s3_next = rotl(s3 ^ s1, 11)`, and hold otherwise.
   The `u` path then has one addition instead of two. The new `t` path has two XOR
   levels, an operand select and one addition, and the seed addition is register
   to register. The cost is 32 more flip-flops per lane (161 to 193) and one more
   adder, or a shared adder with selected operands.
2. **Faster addition structures without new state.** Write one or both additions
   as carry-select or parallel-prefix adders. For example, the 25 upper result bits
   can be computed for both carry-in values while the 7 low bits, which need the
   first sum's top bits, finish, then selected by their carry. This costs area and
   gains less than option 1, because both additions stay in one cycle.
3. **Avoid** an extra output register (`LAT_RNG = 2` changes the lane latency
   contract) and DC retiming (the matched comparisons use no retiming).

Physical options need no RNG change and stay with Tyler: targeted sizing of the
lane-3 carry-chain cells, useful skew on the `u` capture clocks with a hold
re-check, or a team decision on Innovus pessimism removal. The two unsuccessful
optimizer-target trials do not rule these out. Each would act on a residual that
is smaller than the disagreement between the tools.

## Acceptance checks for an RNG change

These match the request sent to the RNG owner on 2026-11-24.

1. **Function (RNG owner).**
   - The stream matches the canonical xoshiro128++ model exactly: `make rng-test`,
     `make rng-sim` and the three long streams in `scripts/run_rng_validation.py`.
   - `LAT_RNG` stays 1, and `u` and `u_valid` change on the same edges as now.
   - The priority stays reset, then `seed_load`, then run, then hold. A load
     produces no word and initializes `t`.
   - The first accepted run after a seed produces the canonical first word.
   - A pause holds the state, `t` and `u`, clears `u_valid` and skips no samples.
   - Asynchronous reset clears the state, `t`, `u` and `u_valid`. A new legal seed
     is required.
   - State checks assert `t == (s0 + s3) mod 2^32` after reset, seed loading,
     accepted runs and pauses.
2. **Standalone synthesis screen (RNG owner).** Synthesize the unchanged RNG and the
   prototype with the DC step of `scripts/run_rng_validation.py`, `lane_5ns.sdc` at
   5 ns and the default `setup_fixed_v1` library pair, under fresh tags. Report
   setup slack, critical paths, area, register counts and retained violations.
   About +0.3 ns of standalone slack is a screening target for useful margin, not a
   guarantee of routed closure. Compare the gain with the freshly synthesized
   unchanged block, not with the November 8 result.
3. **Integration (Tyler), only after checks 1 and 2.** One matched 1/2/4-lane
   implementation with the `tyler_closure2` policy and fresh tags passes only if:
   - setup and hold pass in both PT and Innovus at 1, 2 and 4 lanes
   - there are no fanout, transition or reset violations
   - nothing violates a positive capacitance limit
   - geometry and connectivity checks are clean
   - mapped and routed replays pass 81 cases and 82,489 trials

   Area and power are reported against `tyler_closure2`. Zero-limit capacitance rows
   stay separately reported and unresolved. They are not waived, so a pass is not
   full electrical signoff.

## Evidence

- Same-path PT check, script and input hashes:
  [`reports/sta/tyler_rngdiag_20261124_l4/`](../reports/sta/tyler_rngdiag_20261124_l4/).
  Rerun from the repository root with `RNGDIAG_SPEF` set to a decompressed copy of
  `reports/pnr/tyler_closure2_20261123_l4/mc_top.routed.spef.gz`:
  `pt_shell -f reports/sta/tyler_rngdiag_20261124_l4/rng_path_diagnostic.tcl`.
  It rewrites the committed reports in place, so `git diff` shows whether they
  reproduce, apart from their date lines.
- Innovus SI-on/off reports for the endpoint:
  [`reports/pnr/tyler_closure2_20261123_l4/diagnostics_si/`](../reports/pnr/tyler_closure2_20261123_l4/diagnostics_si/).
- Innovus top-50 setup paths: `reports/pnr/tyler_closure2_20261123_l{1,2,4}/postroute/mc_top_all.tarpt.gz`.
- PT reference reports: `reports/sta/tyler_closure2_20261123_l{1,2,4}_routed_final/setup.rpt`.
- Closure method and limits: [Timing_Electrical_Closure.md](Timing_Electrical_Closure.md).
