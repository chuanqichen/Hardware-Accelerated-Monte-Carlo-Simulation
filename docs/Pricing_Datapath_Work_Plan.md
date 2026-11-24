# Work plan: pricing datapath and accumulator

_Owner: Eric Goode. Started 2026-10-22. Companion to `Project_Proposal.md`,
`Lane_Interface_Spec.md` and `Gaussian_Lookup_Work_Plan.md`. Every design decision is
written down with its reason so this file doubles as the design rationale for the report._

---

## 1. What these blocks are

The lane turns one Gaussian sample $z$ into one option payoff per clock cycle, and the
accumulator adds the payoffs up:

$$
x = A + Bz, \qquad S_T = e^{x}, \qquad p = \max(S_T - K,\,0), \qquad
\texttt{payoff\_sum} = \sum p .
$$

### 1.1 Where the formula comes from

The project models the stock price with geometric Brownian motion. Its value at maturity is

$$
S_T = S_0 \exp\!\Big(\big(r - \tfrac12\sigma^2\big)T + \sigma\sqrt{T}\,Z\Big),\qquad Z \sim \mathcal N(0,1).
$$

The host collapses the five option parameters into two constants before the run,
$A = \ln S_0 + (r - \tfrac12\sigma^2)T$ and $B = \sigma\sqrt T$, so the hardware never needs
`ln` or `sqrt`. A call option pays $\max(S_T - K, 0)$ at maturity, where $K$ is the strike
price. The fair price is the discounted average payoff, which the host computes once after
the run:

$$
\text{price} = e^{-rT}\,\frac{\texttt{payoff\_sum}}{256 \cdot \texttt{trial\_count}}
$$

The 256 undoes the 8 fraction bits of the payoff format. The Black-Scholes closed form is
**not** computed by the hardware. It is the answer key that the Monte Carlo estimate is
checked against.

### 1.2 What runs where

| Where | Work | How often |
|---|---|---|
| Host, before | $A$, $B$, $K$ to fixed point; write registers | once per run |
| `price_dp` | $x$, $e^x$, payoff | every trial (1 per cycle) |
| `accumulator` | sum, count, sticky flags | every trial |
| Host, after | divide, discount | once per run |

## 2. Formats

| Signal | Format | Width | Notes |
|---|---|---|---|
| `z` | Q3.12 | 16 | from `gauss_lut` |
| `A` | Q5.12 | 18 | static register |
| `B` | UQ2.14 | 16 | static register |
| `acc` | Q5.26 | 34 | internal: $(A \ll 14) + Bz$ |
| `x` | Q5.12 | 18 | saturating; `sat_x` |
| `S_T`, `K`, `p` | UQ14.8 | 22 | `sat_s` when $S_T \ge 2^{14}$ |
| `payoff_sum` | UQ46.8 | 64 | cannot overflow in practice (see 4.3) |

**Lining up binary points.** To add two fixed-point numbers, their binary points must line
up. $B$ has 14 fraction bits and $z$ has 12, so $Bz$ has $14 + 12 = 26$. $A$ has 12, so
$A$ is shifted left by $26 - 12 = 14$. That changes its scale, not its value.

## 3. `price_dp` design

### 3.1 Pipeline

A chain of multiply, round, exp and subtract is too slow to finish in one 5 ns clock
(200 MHz, 45 nm target). Registers between stages cut it into short pieces. A trial moves
one stage per clock, and a new trial enters every clock:

```
cycle:    1   2   3   4   5   6   7   8
trial 1:  S1  S2  S3  S4  S5  S6 -> p
trial 2:      S1  S2  S3  S4  S5  S6 -> p
trial 3:          S1  S2  S3  S4  S5  S6 -> p
```

Latency is 6 cycles (one trial start to finish). Throughput is 1 trial per cycle
(initiation interval II = 1). Six trials are in flight at once.

| Stage | Work | Register holds |
|---|---|---|
| S1 (`MUL_STAGES`) | $(A \ll 14) + Bz$ | `acc`, Q5.26 |
| S2 | round-half-even, saturate, `sat_x` | `x`, Q5.12 |
| S3 | $y = x\log_2 e$; split $n$, `addr` | `n`, `addr` |
| S4 | $2^f$ ROM | `rom`, UQ1.16 |
| S5 | shift by $n$, round, clamp, `sat_s` | `S_T` |
| S6 | $S_T - K$, clamp at 0 | `p` |

$\texttt{LAT\_DP} = \texttt{MUL\_STAGES} + 5$. The defaults give 6.

**Valid travels with the data.** `z_valid` passes through its own chain of flip-flops, so
`p_valid` comes out exactly `LAT_DP` cycles later. `rtl/pipe.sv` is a reusable N-cycle
delay line for side signals such as `sat_x`. If a stage is added, one parameter changes
and every side signal follows, so valid can never drift a cycle away from its data.
That drift is the most common pipeline bug.

**Static configuration.** $A$, $B$ and $K$ are latched on `start` and never change during a
run, so they are not carried down the pipeline. Pipelining $K$ to S6 would cost about 110
flip-flops that do nothing.

### 3.2 Fused multiply-add (S1, S2)

A multiplier works in three steps:

1. Make the partial products, roughly one row per Booth digit of $z$.
2. A Wallace tree of 3:2 compressors (full adders with no carry propagation) squeezes those
   rows down to two.
3. One carry-propagate adder (CPA) adds the last two rows. This is the slow step.

A separate `+ A` afterwards would cost a second slow CPA. Instead, $A \ll 14$ goes into the
tree as **one more row**. The tree compresses one extra row (about one full-adder level)
and the second CPA disappears. In RTL this is just `(A <<< 14) + B*z`. Design Compiler
recognizes a sum of products and builds a single tree; `report_resources` shows it.

**Rounding semantics (a deliberate change to the spec).** The spec describes two steps:
round $Bz$, then add $A$. With round-half-even that differs from rounding the fused sum by 1
LSB on exact ties when $A$ is odd. Example: $Bz$ = 1.5 LSB and $A$ = 1 LSB. Two-step:
round(1.5) = 2, + 1 = 3. Fused: round(2.5) = 2. This block defines **one rounding of the
whole sum**. It is truly fused and slightly more accurate, since it rounds once instead of
twice. The model implements the same rule, and `test_fused_rounding_tie_with_odd_a` pins
it down.

Saturation of $Bz$ alone is impossible: $|Bz| < 4 \times 8 = 32$. So clamping only the final
$x$ is exact.

**Pipelining the multiplier.** `MUL_STAGES` registers follow the product. With
`compile_ultra -retime`, Design Compiler slides them backwards **into** the multiplier
tree until the delay between registers is balanced. A register at the output of some
logic is equivalent to a register on each of its inputs, and retiming uses that identity.
The answer is bit-identical, only `MUL_STAGES` cycles later. If timing fails, raise
`MUL_STAGES` and re-synthesize. Nothing is rewritten.

**Behavioral arithmetic.** `*` and `+` are left to DesignWare (`DW02_mult`, `DW01_add`).
It picks ripple, carry-lookahead or parallel-prefix (Kogge-Stone class) adders, and a
Booth/Wallace multiplier, based on the timing constraint. `report_resources` after
`compile` lists what was chosen.

### 3.3 The exponential: range reduction (S3 to S5)

$e^x$ is hard in hardware, but multiplying by a power of two is just a shift. So:

1. **Change of base:** $e^x = 2^y$ with $y = x \log_2 e$. Multiplying by a constant needs no
   real multiplier. Synthesis turns it into a few shifted adds.
2. **Split:** $n = \lfloor y \rfloor$ (integer), $f = y - n \in [0,1)$.
3. **Look up** $2^f \in [1,2)$ in a ROM addressed by the top $k$ bits of $f$, with $k$ =
   `EXP_ADDR_BITS`. Each entry is the value at its cell's **midpoint**, which halves the
   worst-case error compared with the cell's left edge.
4. **Shift** by $n$ (a barrel shifter), round half-even to 8 fraction bits, and clamp.

Worked example: $x = 4.835$, $y = 6.9755$, $n = 6$, $f = 0.9755$, $2^f = 1.9663$, shifted left
6 (×64) = **125.85**, which is $e^{4.835}$.

| $n$ | Meaning | Hardware |
|---|---|---|
| $\ge 14$ | $S_T \ge 2^{14}$ does not fit | clamp to max, `sat_s` |
| 8..13 | exact left shift | `rom << (n-8)` |
| $< 8$ | right shift, round half-even | shift capped at 18 (all round to 0) |

$S_T$ only matters for $x \in [-6.2, 9.7]$. Below that $e^x$ rounds to 0, and above it
overflows. A direct table on $x$ at full resolution would need about 65k entries. Range
reduction needs $2^k$ entries ($2^{10}$ = 1024) plus a constant multiply and a shifter.

**Why not the alternatives.**

- A direct table is too large.
- Splitting $e^{x_{hi}} e^{x_{lo}}$ needs a second real multiplier.
- Piecewise polynomials trade ROM for multipliers.
- Pipelined CORDIC needs about 16 adder stages.
- $C e^{Bz}$ (decision D-3) only helps a direct table. With range reduction it adds a
  multiplier and loses the fused $A$, so $e^{A+Bz}$ is kept.

`rtl/exp2_unit.sv` is the hand-written logic. `rtl/generated/exp2_rom.sv` is the
table, generated by `model/price_dp.py` and never hand-edited. They are separate files so
the table can be regenerated for a new $k$ without touching the logic.

### 3.4 Payoff (S6)

$p = S_T > K \;?\; S_T - K : 0$. The comparison is free: it is the borrow out of the
subtractor. $S_T$ and $K$ share a format, so the subtraction is exact and needs no rounding.

### 3.5 Flags

Fixed point has hard limits. When a value crosses one, the hardware **saturates** (clamps to
the largest value it can hold). The answer is then wrong, but nothing visibly breaks. The
flags make it visible:

- `sat_x`: $x$ was clamped at ±32. Unreachable for sensible inputs, since it needs
  $|A| > 18$.
- `sat_s`: $e^x > 16384$ and $S_T$ was clamped. The payoff is under-counted, so the price
  comes out quietly low. This one is reachable with a large $S_0$ or a high $\sigma$.

Both are one-cycle pulses qualified by `p_valid`. The accumulator makes them sticky
(status bits). Underflow to 0 is exact behavior for this format and sets no flag. Event
**counts** are kept by the testbenches and the Python model, not in hardware, so there are
no extra counters in the synthesized area.

### 3.6 Power

Data registers load only when their stage is valid (`always_ff ... if (valid)`). Design
Compiler can turn that enable into clock gating (`insert_clock_gating`), saving clock and
register power during fill, drain and idle. Valid bits are reset; data registers are not,
as the spec allows.

## 4. `accumulator` design

### 4.1 Behavior

- `clear` zeroes everything and wins over a same-cycle add.
- On any valid beat:
  - `payoff_sum += Σ valid p`
  - `trial_count += popcount(p_valid)`
  - `acc_overflow |= carry`
  - `sat_*_seen |= any valid lane's pulse`
- Latency is 1 cycle.

### 4.2 LANES: registered reduction tree

The ports are `LANES` wide: `p[LANES]`, `p_valid[LANES]`. The count adds the **number of
valid lanes**, not `LANES`. On the final beat the controller masks unused lanes so
`trial_count == N_TRIALS` exactly.

With `REGISTER_TREE = 0` (the default, and what one lane uses) the lanes are summed
combinationally in front of the result registers. For two and four lanes the lane array
sets `REGISTER_TREE = 1`, which puts a **registered pairwise tree** in front instead.
The tree RTL is Tyler's (final-integration work); this section records how it behaves
and how it is verified.

```
lane0 --+
        +--> [reg] --+
lane1 --+            +--> [reg] --> + payoff_sum (64-bit result register)
lane2 --+            |
        +--> [reg] --+
lane3 --+
```

- Each level adds pairs and registers the result, so a cycle never holds more than one
  small adder, or the 64-bit accumulate. There are $\lceil\log_2 \text{LANES}\rceil$
  levels: 1 for two lanes, 2 for four (`mc_pkg::lat_tree`). Power-of-two lane counts only.
- Every tree register carries the partial sum, the number of valid lanes below it and
  the OR of their `sat_x` / `sat_s` pulses. An invalid lane contributes 0 to all of them.
- Latency from `p_valid` to the updated outputs is $1 + \lceil\log_2 \text{LANES}\rceil$
  cycles. Throughput is still one beat (`LANES` trials) per cycle.
- **`clear` also empties the tree.** A beat still in the tree when `clear` arrives, or
  presented in the same cycle, is dropped, so trials of one run cannot leak into the next.
- `model/price_dp.py accumulate()` models this with its `tree_lat` argument.

### 4.3 Overflow cannot happen

$2^{32}$ trials × $2^{22}$ maximum payoff = $2^{54} < 2^{64}$. The flag is kept for the
contract. Its logic is tested with `SUM_WIDTH = 32`, which overflows after 1024 maximum
payoffs. A later area optimization would store 54 bits and zero-extend.

### 4.4 Adder

A plain 64-bit `+`, with DesignWare choosing the structure.

### 4.5 Synthesis results (2026-11-22)

Design Compiler T-2022.03-SP2, gscl45nm typical, the shared `constraints/lane_5ns.sdc`,
pre-layout. `scripts/syn/run_accumulator_sweep.sh` synthesizes the accumulator alone at
each lane count (`REGISTER_TREE = 1` above one lane). All nine runs are in
`results/accumulator_ppa.csv`; raw reports for the 5 ns runs and the 4-lane 4.75 ns run
are in `reports/syn/v2_p500_accumulator_*` and `reports/syn/v2_p475_accumulator_l4`.

| `LANES` | Area at 5 ns | Registers | Power (unannotated) | 4.75 ns | 4.00 ns |
|---|---|---|---|---|---|
| 1 | 3,123 um^2 | 99 | 0.62 mW | met | met |
| 2 | 3,700 um^2 | 126 | 0.81 mW | met | met |
| 4 | 5,123 um^2 | 182 | 1.19 mW | met | met |

Four lanes cost 1.6 times the area of one, not 4 times, because the 64-bit result
registers and adder are shared and only the small tree grows. All three sizes have
separately optimized mappings that meet setup at 4 ns. A timing-margin claim at
5 ns requires analysis of one fixed netlist under the common constraints. Synthesis
stops improving a path once its constraint is met and then recovers area.

## 5. Accuracy results (model, exact, no Monte Carlo noise)

Because $z$ takes only $2^{10}$ equally likely values, the price the hardware converges to
can be computed **exactly**: average $p$ over every table value. This separates systematic
bias from Monte Carlo noise. Run `python3 model/price_dp.py`.

**exp table size ($k$) sweep.** The max and mean relative error of $e^x$ is measured over
every $x$ with $S_T \ge 64$. The per-option columns are the price bias caused by `price_dp`
alone: the same Gaussian table with float math versus the full fixed-point datapath,
including $A$/$B$/$K$ register rounding.

| $k$ | ROM bits | max rel | mean rel | ITM 80 | ATM 100 | OTM 120 | ATM σ.6 | OTM 150 σ.6 |
|---|---|---|---|---|---|---|---|---|
| 6 | 1088 | 5.5e-3 | 2.7e-3 | −0.002% | +0.006% | −0.029% | −0.027% | −0.036% |
| 8 | 4352 | 1.4e-3 | 6.8e-4 | +0.014% | +0.023% | +0.018% | −0.025% | −0.026% |
| 10 | 17408 | 3.9e-4 | 1.7e-4 | +0.016% | +0.024% | +0.014% | −0.036% | −0.050% |
| 12 | 69632 | 1.3e-4 | 5.0e-5 | +0.022% | +0.035% | +0.049% | −0.031% | −0.044% |

What this shows:

- The exp error halves with every extra bit of $k$, matching the theory
  $\ln 2 \cdot 2^{-(k+1)}$.
- The **price bias does not improve beyond $k \approx 8$**. It levels off at about 0.02 to
  0.05%, set by rounding $A$, $B$ and $K$ to their register formats, not by the table. That
  is evidence for decision D-5 (A/x width). A smaller $k$ (8) may be enough. The decision
  waits on synthesis area numbers in Week 3.

**End to end against Black-Scholes** at $k = 10$, Gaussian ADDR_BITS = 10. This includes
the Gaussian table's bias.

| Option | Black-Scholes | Hardware | Bias |
|---|---|---|---|
| ITM K=80 σ=0.2 | 24.5888 | 24.5893 | +0.002% |
| ATM K=100 σ=0.2 | 10.4506 | 10.4496 | −0.009% |
| OTM K=120 σ=0.2 | 3.2475 | 3.2444 | −0.094% |
| ATM K=100 σ=0.6 | 25.5232 | 25.4747 | −0.190% |
| OTM K=150 σ=0.6 | 11.9470 | 11.9014 | −0.381% |

All are inside the proposed 1% target. The larger high-volatility biases come from the
Gaussian table's clipped tails (Chuanqi's block), not from this datapath.

**Discussion point for the report.** For a given run, $z$ has only 1024 possible values. So
the exact expected payoff is a 1024-term average, which is numerical quadrature. Random
sampling only adds noise on top of it. Production Monte Carlo engines use effectively
continuous Gaussians, and Monte Carlo pays off for multi-step, path-dependent or
many-asset problems where quadrature explodes. A precomputed 1024 × 22 payoff table was
considered and rejected: the same II = 1, about 22k flip-flops per lane without an SRAM
macro, and it would turn the project away from a datapath-replication study.

## 6. Verification

Python first, then RTL. Each RTL block is checked bit for bit against vectors generated by
the Python model before the next block is written.

| Layer | File | What it proves |
|---|---|---|
| Model unit tests | `model/test_price_dp.py` (18 tests) | half-even ties incl. fused odd-A case, both saturation ends, exp error bound vs $k$, $e^x$ monotonic, overflow/underflow edges, payoff boundary, worked example, latency, accumulator clear/gaps/popcount/overflow/flag gating, end-to-end bias < 1% |
| Vectors | `model/gen_price_vectors.py` | exhaustive exp; 11,449 price trials (directed + random); accumulator streams |
| `tb_exp2_unit` | exhaustive | all 262,144 values of $x$, random valid gaps, latency 3 on every output |
| `tb_price_dp` | directed + random | p, flags and exact latency per trial; sat counts vs Python (547 `sat_x`, 2683 `sat_s`); no flag without valid |
| `tb_accumulator` | `LANES` 1/2/4 x `SUM_WIDTH` 64/32 | sum, count, sticky flags after every edge against Python vectors; 32-bit runs exercise overflow; multi-lane vectors include random per-lane valid and clears, runs of N = 101, 1001 and 10003 trials with a masked last beat (`trial_count == N`), and 2,000 back-to-back full beats |

**Testing the testbenches.** Deliberately broken copies of the RTL must fail:

- Half-up rounding instead of half-even fails on 95 trials. The first version of the
  vectors caught it on only 2, which led to the large-$A$ tie cases.
- An accumulator whose `clear` loses priority fails.
- Four-lane tree: not gating invalid lanes out of the sum, not emptying the tree on
  `clear`, and counting `LANES` instead of the valid lanes each fail on thousands of cycles.
- `>=` instead of `>` in the payoff passes. That is correct: the two are
  equivalent, since $S_T = K$ gives 0 either way.

The exhaustive exp test also caught a real bug on its first run. A rounding constant
($2^{17}$) did not fit the 17-bit variable it was declared in.

Parameters: everything passes at `EXP_ADDR_BITS = 8` with `MUL_STAGES = 2` (LAT_DP = 7) as
well as at the defaults.

## 7. Files

| File | Role |
|---|---|
| `model/price_dp.py` | bit-accurate reference, per-trial trace, sweep, ROM export |
| `model/fxp.py` | `round_shift_even`, `Fxp.saturate` (shared helpers) |
| `model/test_price_dp.py` | unit tests (`make test`) |
| `model/gen_price_vectors.py` | testbench vectors |
| `rtl/price_dp.sv` | S1, S2, S6 + instantiation of exp2_unit |
| `rtl/exp2_unit.sv` | S3 to S5 |
| `rtl/generated/exp2_rom.sv` | generated $2^f$ table |
| `rtl/accumulator.sv` | sum, count, sticky flags |
| `rtl/pipe.sv` | N-cycle delay line |
| `tb/tb_*.sv` | self-checking testbenches (Icarus and VCS) |

## 8. Updates to `Lane_Interface_Spec.md`

The updates proposed here in October are all in the spec now: D-3 and D-6 closed,
the single rounding of the fused sum (Section 5.4), the `acc_overflow` note and the
sticky flags in the accumulator (Section 5.5), and the measured `LAT_DP` and `LAT_ACC`
(Section 6).

Added on 2026-11-22 from the work in Sections 4, 11 and 12 of this plan:

- Section 5.4, S1: one multiplier stage without retiming closes the clock.
- Section 5.5: `clear` empties the accumulator tree; the model and testbench that check it.
- Section 6: the multi-lane replay result.
- Section 9, D-4: the `B*z` multiplier area for a 12-bit `z` (decision still open).
- Section 9, D-6: agreement with $k$ = 8 and what switching the default involves.

## 9. Next steps

- Done 2026-11-12: S2 uses the shared `round_sat`; `LAT_DP` comes from `mc_pkg::lat_dp`.
- Done 2026-11-12: standalone synthesis sweep (Section 11).
- Done 2026-11-22: the registered accumulator tree (Tyler's RTL) is checked against the
  model vectors and synthesized (Sections 4.2, 4.5).
- Done 2026-11-12: $k$ = 8 against 10, multiplier area for D-4, and the pricing rows of
  configurations A to E (Section 12). Both choices need team sign-off.

## 10. Commands

```bash
make test                              # model unit tests (gauss + price)
python3 model/price_dp.py              # demo trace + k sweep + Black-Scholes table
make sim-iv                            # all three testbenches, Icarus, on a laptop
make sim-iv EXP_ADDR_BITS=8 MUL_STAGES=2
make sim-price                         # same under VCS (lab machines)
make sim-pricing-final                 # full VCS regression with archived evidence (lab machines)
make pricing-study                     # accuracy vs area, configuration and throughput tables
make pricing-figures                   # report figures from those tables (needs matplotlib)
scripts/syn/run_price_sweep.sh         # Design Compiler sweep (lab machines)
CLK_PERIOD_NS=4.75 BATCH=p475 scripts/syn/run_price_sweep.sh "1 2" "8 10" "0 1"
```


## 11. Synthesis results (2026-11-12)

Design Compiler T-2022.03-SP2, gscl45nm typical 1.1 V / 27 C, the shared
`constraints/lane_5ns.sdc` (30% I/O budgets, 0.1 ns uncertainty), pre-layout with an ideal
clock. `price_dp` alone, after the `round_sat` change. All 36 runs are in
`results/price_dp_ppa.csv`. Raw reports are committed for the seven runs cited here
(`reports/syn/u1a_price_dp_*`, `u1_p475_*`, `u1_p400_*`); the rest can be reproduced with
`scripts/syn/run_price_sweep.sh`.

### 11.1 Area at 5 ns

| $k$ | `MUL_STAGES` = 1 | `MUL_STAGES` = 2 | registers (1 / 2) |
|---|---|---|---|
| 8 | 10,035 um^2 | 10,543 um^2 | 149 / 184 |
| 10 | 13,777 um^2 | 14,242 um^2 | 151 / 186 |
| 12 | 23,942 um^2 | 24,411 um^2 | 153 / 188 |

The exp ROM dominates the differences: $k$ = 8 saves 27% of the block against $k$ = 10,
and $k$ = 12 costs 74% more. A second multiplier stage adds 35 flip-flops and about 3 to 5%.

### 11.2 Timing margin

Every run meets its setup constraint with slack near zero. That is not a measure of
margin. Design Compiler stops improving a path once it meets the constraint, and the script then runs
`optimize_netlist -area`, which spends leftover slack on smaller cells. To compare mappings
under tighter constraints, the sweep was repeated at shorter clock periods (the I/O budgets
scale with the period, since they are 30% of it):

| Period | $k$ = 10, `MUL_STAGES` = 1 | $k$ = 8, `MUL_STAGES` = 1 |
|---|---|---|
| 5.00 ns | met, 13,777 um^2 | met, 10,035 um^2 |
| 4.75 ns | met, 13,791 um^2 | met, 10,079 um^2 |
| 4.50 ns | met, 13,943 um^2 | met, 10,251 um^2 |
| 4.00 ns | met, 14,160 um^2 | met, 10,492 um^2 |

All 24 shorter-period runs met setup timing, including `MUL_STAGES` = 2 and retiming on.
At 4 ns, the one-stage mapping costs 2.8% more area for $k$ = 10 and 4.6% more for $k$ = 8
than its 5 ns counterpart. Each row is a separately optimized netlist. The 0.25 ns
margin goal still requires timing analysis of one fixed netlist under the common
constraints. The shortest period that meets setup was not searched for.

### 11.3 Decisions

- **`MUL_STAGES` stays 1.** One stage closes at 4 ns. A second stage costs area and one
  cycle of latency and buys nothing at the target clock.
- **Retiming stays off.** `RETIME=1` (new opt-in switch in `scripts/syn/dc_synth.tcl`)
  changed area by at most 1.04% and setup slack by at most 0.022 ns in the paired runs.
  With it off, the registers in the netlist are the registers in the RTL, so simulated latency is the synthesized
  latency. Section 3.2 assumed retiming would be needed; at this clock it is not.
- **No pipeline change.** The plan allowed for an extra register in `exp2_unit`; it is
  not needed.

### 11.4 Critical path and what was built

- At 5 ns, the worst path starts at input `b` (or `z`), goes through the fused
  multiply-add and ends at `acc_r_reg[0]` (stage S1). It is the same endpoint as the
  one-lane top's critical path (`active_b_reg` to `u_price/acc_r_reg`). At tighter
  constraints the critical path can move into the exponential or payoff stages.
  For example, the [4 ns, $k$ = 10, one-stage report](../reports/syn/u1_p400_price_dp_k10_m1_r0/timing.rpt)
  runs from `u_exp/n4_reg[0]` to `u_exp/s_t_reg[13]`.
- `resources.rpt` shows one datapath block `DP_OP` holding both `mult_41` and `add_41`,
  so the multiply and the `+ (A << 14)` were fused as Section 3.2 intended. The multiplier
  is radix-4 Booth (`benc_radix4_mux`). The payoff compare and subtract use the
  area-optimized `DW_cmp` and `DW01_sub`.
- **Flip-flop setup time.** On these paths the library charges 1.2 to 1.44 ns of setup
  time at `DFFPOSX1` for a rising data edge, against 0.09 to 0.13 ns at other endpoints
  (for example `DFFSR` in the RNG). The one-lane top report shows the same thing (1.22 ns
  on `acc_r_reg`). The [setup-table investigation](PDK_Setup_Investigation.md)
  records four outlying `DFFPOSX1` entries and the proposed project-local
  approximation. The team's clock-transition check is a sensitivity experiment;
  it does not establish corrected-library margins under the original constraints.
  This study retains the library's reported setup
  times on affected paths; each configuration's slack remains the value in its timing
  report.
- Each run is labelled `mapped_with_violations` by the parser because of hold violations
  (worst -0.04 ns, 41 to 104 paths) and max-capacitance violations, as in the team's
  one-lane result. Hold is left to place and route in the shared flow. The capacitance
  violations were not investigated.

## 12. Tradeoff study (2026-11-12)

`make pricing-study` (`model/pricing_tradeoff.py`) joins the model's exact price bias
with the synthesis areas and writes `results/pricing_accuracy_vs_area.csv` and
`results/pricing_ppa_configs.csv`. Every number comes from the model or from a
synthesis CSV; none is typed in.

### 12.1 exp table size: $k$ = 8 is enough

Worst price bias against Black-Scholes over the five benchmark options, by Gaussian
table address bits $g$ and exp table address bits $k$, with the `price_dp` area at 5 ns:

| | $k$ = 8 | $k$ = 10 | $k$ = 12 |
|---|---|---|---|
| $g$ = 8 | 1.17% | 1.18% | 1.21% |
| $g$ = 10 | 0.36% | 0.38% | 0.38% |
| $g$ = 12 | 0.15% | 0.14% | 0.14% |
| `price_dp` area | 10,035 um^2 | 13,777 um^2 | 23,942 um^2 |

- The exp table does not set the accuracy. Moving from $k$ = 10 to $k$ = 8 changes the
  worst bias by at most 0.03 percentage points in either direction, while the Gaussian
  table moves it from 1.2% to 0.14%.
- $k$ = 8 saves 3,742 um^2 per lane, 27% of `price_dp`.
- **Recommendation: $k$ = 8.** The team lists $k$ = 8 as a candidate with the default
  left at 10 "pending Eric's agreement and matching-ROM RTL replay"
  (`Gaussian_Lookup_Work_Plan.md` Section 6). This study is that agreement from the
  datapath side. RTL replay with the matching ROM: `tb_exp2_unit` and `tb_price_dp` pass
  at $k$ = 8 (Section 13), and the multi-lane array replay of `tyler/final-integration`
  passed its twelve $k$ = 8 configurations on 2026-11-22. The default is not changed
  here; switching it also means regenerating the committed ROM and top-level vectors.
- With $g$ = 8 (configuration D) the worst case, OTM K=150 at $\sigma$ = 0.6, is 1.18%,
  outside the proposed 1% target. That comes from the Gaussian table, not this block.

### 12.2 z width (decision D-4)

`scripts/syn/study/price_dp_zstudy.sv` is a synthesis-only wrapper that ties the low
`Z_DROP` bits of `z` to zero, so Design Compiler builds the narrower multiplier.
Reports: `reports/syn/u3_price_dp_zstudy_d0` and `_d4`; table:
`results/price_dp_zwidth_ppa.csv`.

| `z` | `price_dp` area | Registers | Power (unannotated) |
|---|---|---|---|
| 16 bits (Q3.12) | 13,789 um^2 | 151 | 1.65 mW |
| 12 bits (Q3.8) | 13,066 um^2 | 147 | 1.48 mW |

The narrower `z` saves 722 um^2 here (5%). With the Gaussian table's own saving in
`results/gauss_lut_ppa.csv` (4,060 against 2,572 um^2 at 10 address bits) the total is
about 2,210 um^2 per lane, roughly 7% of the one-lane top. The accuracy side of D-4 was
not re-run here. This is the multiplier-area input the decision was waiting for; the
decision itself is shared with Chuanqi.

### 12.3 Pricing rows for configurations A to E

Pricing blocks only (`price_dp` per lane plus one accumulator), $k$ = 10, 5 ns. These are
**sums of standalone block syntheses, not a synthesized multi-lane top**, and power is
the tool's unannotated estimate. Accumulator numbers are for the registered tree
(Section 4.5).

| Config | Lanes | $g$ | Pricing area | Registers | Accumulator latency | Trials/s at 200 MHz | Worst bias |
|---|---|---|---|---|---|---|---|
| A | 1 | 10 | 16,900 um^2 | 250 | 1 | 2.0e8 | 0.38% |
| B | 2 | 10 | 31,254 um^2 | 428 | 2 | 4.0e8 | 0.38% |
| C | 4 | 10 | 60,230 um^2 | 786 | 3 | 8.0e8 | 0.38% |
| D | 1 | 8 | 16,900 um^2 | 250 | 1 | 2.0e8 | 1.18% |
| E | 1 | 12 | 16,900 um^2 | 250 | 1 | 2.0e8 | 0.14% |

Pricing area grows 1.85 times for two lanes and 3.56 times for four, slightly under
linear because the accumulator is shared. D and E differ from A only in the Gaussian
table, whose area is not in these rows.

**Agreement with the team's tables.** The worst-case bias values here equal those in
`results/accuracy_vs_area.csv` (1.178 / 0.381 / 0.142 % at $g$ = 8 / 10 / 12) and
`results/exp_k8_candidate.csv` (0.357 % at $g$ = 10, $k$ = 8). The whole-lane synthesis in
`results/lane_addr_bits_ppa.csv` shows $k$ = 8 saving 3,670 um^2 of the
33,016 um^2 lane (11.1%), against the 3,742 um^2 measured on
`price_dp` alone in Section 12.1.

### 12.4 Clock gating: not measured

Section 3.6 expects Design Compiler to turn the stage enables into clock gates. The
shared synthesis script has no clock-gating option, and adding one would be a second
change to a shared file, so the on/off comparison was not run.

## 13. Final regression (2026-11-22)

`make sim-pricing-final` (`scripts/sim/pricing_final.sh`) runs every testbench of these
blocks under VCS at $k$ = 8 and 10 and `MUL_STAGES` = 1 and 2, the accumulator at 1, 2
and 4 lanes, then the one-lane top, the bubbles test, `round_sat` and, when it is in the
tree, the multi-lane array replay (`scripts/sim/array_sim.sh`). A run counts only if its
log has the exact PASS line and no failure line. The 2026-11-22 run passed 46 of 46; the
summary is `reports/pricing_final_validation_2026-11-22.txt`.

That run is the first end-to-end simulation of two and four real lanes with this
datapath: 24 array configurations (1/2/4 lanes, both Gaussian and multiplier latencies,
$k$ = 10 and 8) match the Python model on sum, count and status.

`results/pricing_throughput.csv` lists trials per second for 1, 2 and 4 lanes at each
clock period where both `price_dp` and the accumulator met timing (5.00, 4.75, 4.00 ns).
These are pre-layout block results, conditional on the lane closing timing after layout.

**One result per clock.** `tb_price_dp` has a second mode, `NO_GAPS = 1`, run on
`tb/vectors/price_dp_stream_k<k>.hex`: 8,192 trials of the at-the-money benchmark option
with Gaussian samples drawn through the real table, driven with `z_valid` high on every
cycle. Every payoff, flag and latency is checked, and the test fails unless `p_valid` is
high for 8,192 consecutive cycles. It passes at $k$ = 8 and 10 and `MUL_STAGES` = 1 and 2
under VCS (run `pricing_final_20261122_stream`, 50 of 50 with the stream cases added).
A deliberately broken copy of `price_dp` that corrupts a result only after 100
back-to-back valid cycles passes the older gapped test (its longest run is 46 cycles)
and fails this one.

Limits of the evidence: `tb_exp2_unit` still inserts random idle cycles (longest
back-to-back run 91 cycles). The stream test is one option configuration with no
saturation events; saturation and configuration changes are covered by the gapped test.
