# Work plan: Gaussian lookup and fixed-point representation

_Owner: Chuanqi Chen. Started 2026-10-03, revised 2026-10-03 after the lane interface spec. Companion to `Project_Proposal.md` and `Lane_Interface_Spec.md`._

---

## 1. What this block is

The lane computes `S_T = exp(A + B*Z)`. The RNG (Shentong) produces a 32-bit uniform
word `u`; the datapath (Eric) needs a fixed-point standard-normal sample `Z`. This
block sits between them:

```
u[31:0]  ──►  gauss_lut  ──►  z : signed Q3.12 (16 bit)  ──►  A + B*z  ──►  exp  ──►  payoff
```

The responsibility has two halves:

1. **Gaussian lookup** - the inverse-CDF (quantile) table `z = Phi^-1(u)`, its RTL, its
   generator script, and the evidence that it is accurate enough for option pricing.
2. **Fixed-point representation** - the numeric formats and the single
   rounding/saturation policy for *every* quantity in the lane (`z`, `A`, `B`, `A+B*z`,
   `S_T`, payoff, accumulator). The datapath is Eric's, but the formats are a shared
   contract, and the bit-accurate Python reference must use one rounding rule
   everywhere (`model/fxp.py`).

This is also the project's **numerical tradeoff knob**: the proposal promises to vary
"lookup resolution or fixed-point width" and show accuracy vs. hardware cost. That
study is owned here.

## 2. Design (integration-first version)

Symmetric ROM addressed by the top `ADDR_BITS` of `u`:

| Step | Logic |
|---|---|
| `addr = u[31 -: ADDR_BITS]` | the top bits select a cell of width `2^-ADDR_BITS` in (0,1) |
| `p = (addr + 0.5) / 2^ADDR_BITS` | cell midpoint; never 0 or 1, so `Phi^-1` is finite |
| `sign = addr[MSB]`, `j = sign ? addr[low] : ~addr[low]` | `Phi^-1(1-p) = -Phi^-1(p)` -> store only the positive half |
| `z = sign ? +rom[j] : -rom[j]` | one conditional negate |

- Storage: `2^(ADDR_BITS-1) x OUT_WIDTH` bits (e.g. `ADDR_BITS=10`: 512 x 16 = 8 Kbit).
- Latency 1 cycle (ROM + negate) or 2 (parameter `LATENCY`), one `z` per cycle, no
  back-pressure - matches the "one trial per lane per cycle" goal.
- The ROM is emitted as a synthesizable `case` statement (`rtl/generated/gauss_lut_rom.sv`),
  not `$readmemh`, so Design Compiler maps it to logic without memory macros.

Files already in place:

| Path | Purpose |
|---|---|
| `model/fxp.py` | `Fxp(width, frac)` format; round-half-even + saturate; hex export |
| `model/gauss_lut.py` | Table generation, bit-accurate `lookup(u)`, exact stats, exact option-price bias, ROM export, parameter sweep |
| `model/gen_gauss_vectors.py` | Directed (every address) + random vectors for the testbench |
| `model/test_gauss_lut.py` | Unit tests (monotonic, odd-symmetric, midpoint exactness, rounding) |
| `rtl/gauss_lut.sv` | Parameterized RTL (`ADDR_BITS`, `OUT_WIDTH`, `FRAC_BITS`, `LATENCY`) |
| `rtl/generated/gauss_lut_rom.sv/.hex` | Generated ROM for `ADDR_BITS=10`, Q3.12 |
| `tb/tb_gauss_lut.sv` | Self-checking vector testbench |
| `rtl/mc_pkg.sv`, `rtl/round_sat.sv` | *(planned, Phase A)* shared formats/latencies and the single rounding/saturation module |
| `docs/Lane_Interface_Spec.md` | Lane-wide formats (Sec. 3), `u`/`z` contracts, open decisions |

## 3. What the model already tells us

All numbers below are **exact** properties of the finite hardware output distribution
(every possible `u` prefix enumerated), not Monte Carlo estimates. Price bias is the
error the Gaussian block alone introduces into a European call (S0=100, r=5%, T=1y),
with exact `exp` - so it isolates this block from Eric's.

| Config | ROM bits | max \|z\| | var | KS dist | RMS err | ATM bias σ=0.2 | OTM K=120 bias | OTM K=150 σ=0.6 bias |
|------------------------|-------:|------:|-------:|--------:|-------:|---------:|---------:|-----------:|
| ROM a=6,  Q3.12 | 512 | 2.42 | 0.980 | 0.0078 | 0.065 | −0.57 % | −1.83 % | −4.07 % |
| ROM a=8,  Q3.12 | 2 048 | 2.89 | 0.995 | 0.0020 | 0.028 | −0.14 % | −0.45 % | −1.17 % |
| **ROM a=10, Q3.12** | 8 192 | 3.30 | 0.9987 | 0.00054 | 0.013 | −0.03 % | −0.11 % | −0.33 % |
| ROM a=12, Q3.12 | 32 768 | 3.67 | 0.9997 | 0.00017 | 0.006 | −0.01 % | −0.03 % | −0.09 % |
| ROM a=10, Q7.8 | 8 192 | 3.30 | 0.9989 | 0.0013 | 0.013 | −0.03 % | −0.08 % | −0.30 % |
| ROM a=10, Q5.10 | 8 192 | 3.30 | 0.9987 | 0.0007 | 0.013 | −0.03 % | −0.11 % | −0.33 % |
| uniform PWL a=8, 6 interp bits | 4 096 | 2.89 | 0.996 | 0.0020 | 0.026 | −0.11 % | −0.34 % | −0.96 % |

(Regenerate with `python3 model/gauss_lut.py`.)

Conclusions that shape the rest of the work:

1. **Address bits dominate; fraction bits barely matter.** Going from Q3.12 to Q7.8
   changes nothing visible, while each +2 address bits cuts bias ~4x. So the
   tradeoff knob should be `ADDR_BITS`, and `OUT_WIDTH` can probably shrink to 12
   bits (Q3.8) to save ROM and multiplier width in Eric's `B*z`. To be confirmed by
   synthesis.
2. **The dominant error is tail truncation, not quantization.** `max|z|` is capped at
   `Phi^-1(1 - 2^-(a+1))` (2.89 for a=8, 3.30 for a=10). All price biases are
   *negative*, and grow for out-of-the-money / high-volatility options - exactly the
   cases where payoff comes from the tail. This is the headline of the tradeoff
   study and a known limitation to state in the spec.
3. **Uniform-segment linear interpolation does not fix the tails** - it improves the
   body but `max|z|` is still set by the coarse cell. A real upgrade needs
   *nonuniform* segments that refine toward `u -> 0` and `u -> 1` (de Schryver-style,
   e.g. a leading-zero count on `u` selecting the tail segment). This is the stretch
   item, not the baseline.
4. **Recommended baseline: `ADDR_BITS=10`, Q3.12 (16 b).** Bias ≤ 0.33 % on the
   worst grid case, well under Monte Carlo noise at the trial counts we will run,
   with 8 Kbit of ROM. `a=8` and `a=12` are the two other sweep points.

## 4. Interface and fixed-point contracts

The authoritative definitions now live in `Lane_Interface_Spec.md`: Section 3 (every
format in the lane, the rounding/saturation policy), Sections 5.2-5.3 (the `u` and `z`
interfaces), and Section 9 (open decisions). Summary of what this block depends on and
promises:

- **From Shentong (`u`)**: 32-bit word uniform over all $2^{32}$ values, one per cycle,
  no back-pressure. Only the top `ADDR_BITS` are consumed, so the high bits must be the
  good ones (`xoshiro128++`, not `+`).
- **To Eric (`z`)**: `signed Q3.12`, 16 bits, $|z| \le \Phi^{-1}(1 - 2^{-(a+1)})$ = 3.30
  at `ADDR_BITS = 10`; `z_valid` = `u_valid` delayed by `LATENCY`. This bound sizes the
  $A + Bz$ range and therefore the `exp` table domain.
- **To everyone**: `mc_pkg.sv` (widths, formats, `LAT_*` parameters) and `round_sat.sv`
  with its Python twin in `fxp.py`; **round-half-to-even then saturate, no silent
  truncation**, applied at every narrowing in the lane.

Decisions in the spec that need numbers from this block before the team can close them:

| Decision | What this block must supply |
|---------|------------------------------------------------------------|
| D-3 `exp(A+Bz)` vs `C e^{Bz}` | exp-table input range and size under each form, with the `|z|` bound; co-owned with Eric |
| D-4 `z` width 16 vs 12 bits | synthesized area of `gauss_lut` and of Eric's `B*z` multiplier at both widths |
| D-5 `A`/`x` width 18 vs 16 bits | exact price bias with `x` at `Q5.12` vs `Q5.10` (extend `gauss_lut.py` sweep to quantize `x`) |

## 5. Tasks

### Phase A - model, contracts, shared infrastructure (now -> Oct 10)
- [x] Bit-accurate ROM model, exact stats, exact price-bias metric, sweep
- [x] RTL skeleton + generated ROM + vectors + testbench
- [x] Draft `Lane_Interface_Spec.md` Section 3 (formats) and `u`/`z` interfaces
- [ ] Walk the team through spec Section 9; record decisions D-3/D-4/D-5 with dates
- [ ] `rtl/mc_pkg.sv`: format widths, `LAT_*` localparams, status-flag bit positions
- [ ] `rtl/round_sat.sv` + `fxp.round_sat()` twin + unit test (ties, signs, saturation
      both directions); Eric's datapath instantiates it
- [ ] Run `tb_gauss_lut` on the lab VCS flow (no simulator on the laptop); fix lint
- [ ] Contribute `gauss_lut(u_raw) -> z_raw` to `model/mc_lane.py` (spec Section 7)

### Phase B - standalone synthesis and first numbers (Oct 10 -> Oct 24)
- [ ] Synthesize `gauss_lut` alone for `ADDR_BITS = {8, 10, 12}` x `OUT_WIDTH = {12, 16}`
      with Tyler's DC script; record area, Fmax, power -> `results/gauss_lut_ppa.csv`
- [ ] Extend the sweep so `x`, `S_T`, `p` are quantized too (exact bias of the whole
      fixed-point chain with float `exp`) -> closes D-5, feeds the exp-table study
- [ ] With Eric: exp-table range/precision study using the same exact-bias method;
      decide D-3 and D-6
- [ ] Help finish `model/mc_lane.py` so the integrated testbench has its golden model

### Phase C - one-lane integration (Oct 24 -> Nov 10, interim update)
- [ ] `gauss_lut` integrated in the one-lane top; end-to-end RTL vs. Python bit-exact
- [ ] Option-price check against Black-Scholes on the 5-case grid, several seeds
- [ ] Interim slides: block description, exact-bias table, standalone PPA

### Phase D - numerical tradeoff study (Nov 10 -> Nov 24)
- [ ] Full-lane PPA for `ADDR_BITS = {8, 10, 12}` at `LANES = 1` (and 4 if flow time allows)
- [ ] Plot: price bias / KS distance vs. ROM area and lane energy per trial
- [ ] Stretch: nonuniform tail-refined segmented LUT (`mode="pwl"` rewritten with
      leading-zero-count segment select); include only if bit-exact and synthesized
- [ ] Result freeze Nov 24

### Phase E - documentation (Nov 24 -> Dec 9)
- [ ] Spec/design/user/test sections for this block; fixed-point section; tradeoff
      section of the report

## 6. Test plan for this block

| Level | Test | Pass criterion |
|---|---|---|
| Model | `python3 -m unittest model/test_gauss_lut.py` | monotonic in `u`, odd-symmetric, zero mean, midpoint entries within 1 LSB of `Phi^-1`, round-half-even |
| Model | `python3 model/gauss_lut.py` | sweep reproduces the Section 3 table |
| RTL | `tb_gauss_lut` with `gen_gauss_vectors.py` output | every address exercised, corners (`0`, `0xFFFFFFFF`, `0x7FFFFFFF`, `0x80000000`), 10 000 random words: 0 mismatches at `LATENCY = 1` and `2` |
| RTL | assertion in `gauss_lut.sv` | half-table entry never sets the sign bit |
| Integration | one-lane RTL vs. full Python reference | bit-exact payoff sum and trial count |
| System | price vs. Black-Scholes | mean relative error within MC confidence interval; bias sign/magnitude consistent with the exact-bias table |
| Synthesis | DC reports | ROM area and Fmax per config recorded in `results/gauss_lut_ppa.csv` |

## 7. Risks specific to this block

| Risk | Mitigation |
|---|---|
| Tail truncation biases OTM / high-σ prices | Known and quantified exactly; choose `a=10`, state the supported range in the spec, make tail-refined LUT the stretch |
| `a=12` case-ROM is large/slow in DC | Measure early (Phase B); if >25 % of lane area, drop `a=12` from the layout config and keep it synthesis-only |
| Latency mismatch with Eric's pipeline | `LATENCY` parameter + `out_valid`; integrate with explicit valid chaining, not fixed delays |
| RNG low bits weak | Only the top bits are consumed; confirm `xoshiro128++` with Shentong |
| Format churn after integration | Freeze `Lane_Interface_Spec.md` Section 3 before Phase C; any change regenerates ROM + vectors from the scripts, never by hand |

## 8. How to get started (commands)

```bash
make sweep                       # model sweep (exact stats + option-price bias)
make test                        # model unit tests
make gen ADDR_BITS=10 FRAC_BITS=12   # regenerate ROM RTL + testbench vectors
make sim ADDR_BITS=10 LATENCY=1  # RTL test under VCS (lab machines)
make docs                        # this document as PDF
```

Underlying scripts: `model/gauss_lut.py --export`, `model/gen_gauss_vectors.py`,
`tb/tb_gauss_lut.sv` (see the Makefile).
