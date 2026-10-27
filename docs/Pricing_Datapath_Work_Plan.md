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

### 4.2 LANES

The ports are already `LANES` wide: `p[LANES]`, `p_valid[LANES]`. The count adds the
**number of valid lanes**, not `LANES`. On the final beat the controller masks unused lanes
so `trial_count == N_TRIALS` exactly. The lane sum is combinational for now. For 4 lanes, a
registered adder tree goes in front in Week 5 (Tyler) and adds $\lceil\log_2 \text{LANES}\rceil$
cycles.

### 4.3 Overflow cannot happen

$2^{32}$ trials × $2^{22}$ maximum payoff = $2^{54} < 2^{64}$. The flag is kept for the
contract. Its logic is tested with `SUM_WIDTH = 32`, which overflows after 1024 maximum
payoffs. A later area optimization would store 54 bits and zero-extend.

### 4.4 Adder

A plain 64-bit `+`. At 5 ns in 45 nm it closes easily, and DesignWare chooses the
structure.

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
| `tb_accumulator` | 20k + 5k cycles | sum, count, sticky flags after every edge; 32-bit run exercises overflow |

**Testing the testbenches.** Deliberately broken copies of the RTL must fail:

- Half-up rounding instead of half-even fails on 95 trials. The first version of the
  vectors caught it on only 2, which led to the large-$A$ tie cases.
- An accumulator whose `clear` loses priority fails.
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

## 8. Proposed updates to `Lane_Interface_Spec.md` (for team sign-off)

- **D-3 closed:** keep $e^{A+Bz}$, because range reduction makes $C e^{Bz}$ pointless.
- **D-6:** range reduction, `EXP_ADDR_BITS` parameter (default 10; 8 under consideration).
- **§5.4 internals:** single rounding of the fused sum, $x = \text{sat}(\text{round}((A \ll 14) + Bz))$.
- **§5.5:** `acc_overflow` is unreachable with 32-bit counts. Keep it, but note why.
- **§5.5:** sticky `sat_x` / `sat_s` live in the accumulator next to `acc_overflow`.
- **§6:** measured `LAT_DP` = `MUL_STAGES` + 5 = 6, `LAT_ACC` = 1.
- **New finding for D-5:** price bias levels off at about 0.03% from register quantization of
  $A$/$B$/$K$.

## 9. Next steps

- Swap the inline S2 rounding for Chuanqi's `round_sat` and export `LAT_DP` through
  `mc_pkg` once they are merged.
- Week 2: wire `gauss_lut -> price_dp -> accumulator` and write `model/mc_lane.py`
  (`run_lane`, `trace_lane`) from these stage functions.
- Week 3: synthesize `price_dp` with `MUL_STAGES` = 1/2 and $k$ = 8/10/12. Record area,
  critical path, and what `report_resources` chose; compare clock gating on and off.

## 10. Commands

```bash
make test                              # model unit tests (gauss + price)
python3 model/price_dp.py              # demo trace + k sweep + Black-Scholes table
make sim-iv                            # all three testbenches, Icarus, on a laptop
make sim-iv EXP_ADDR_BITS=8 MUL_STAGES=2
make sim-price                         # same under VCS (lab machines)
```
