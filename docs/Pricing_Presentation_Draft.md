# Presentation draft: pricing datapath (Eric)

Draft for the December 1/3 team presentation. Five slides, about four minutes. Each
slide lists what goes on the slide and what to say. Numbers are from
`Final_Pricing_Contribution.md`; figures are in `docs/figures/`.

## Slide 1 - From a random number to a payoff

On the slide:

- $x = A + Bz$, $S_T = e^{x}$, $p = \max(S_T - K, 0)$, sum the payoffs
- One trial per clock, per lane
- Host does the logarithm, square root and division once per run

Figure: `lane_block_diagram.png`, with `price_dp` and the accumulator highlighted.

Say: The Gaussian block hands me a sample $z$ every cycle. My block turns it into a
stock price and a payoff, and the accumulator adds them up. Everything expensive that
happens once per run is done by the host, so the hardware only multiplies, adds, looks
up and shifts.

## Slide 2 - Six stages, one result per clock

On the slide:

- Fused multiply-add: $A$ rides inside the multiplier, one adder not two
- $e^x = 2^{x \log_2 e}$: integer part is a shift, fraction is a 1,024-entry table
- Valid bit travels with the data

Figure: `wave_price_dp.png`.

Say: Six pipeline stages. The multiply and the add are fused, so there is one slow
carry-propagate adder, not two. For the exponential I change base to 2. The integer
part of the exponent is a barrel shift, and only the fraction needs a table. A direct
table would need about 65,000 entries; this needs 1,024.

## Slide 3 - How we know it is right

On the slide:

- Bit-accurate Python model first, RTL compared value for value
- Every one of 262,144 exponential inputs checked
- 8,192 back-to-back trials: a result on every clock
- 1, 2 and 4 real lanes match the model: 50 of 50 runs pass

Say: The model came first and the RTL has to match it bit for bit. The exponential is
checked on every possible input. A continuous run of 8,192 trials shows a result on
every clock with no gaps. We also broke the RTL on purpose in several ways, and each
time the test that should catch it did. The exhaustive test found one real bug on
its first run.

## Slide 4 - A smaller table costs nothing in accuracy

On the slide:

- Exp table 1,024 -> 256 entries: 27% less `price_dp` area
- Worst price error: 0.38% -> 0.36%
- Accuracy is set by the Gaussian table, not this one

Figure: `pricing_exp_table_tradeoff.png`.

Say: This is our numerical tradeoff for this block. Left: area against the exponential
table size. Right: worst pricing error against Black-Scholes for three Gaussian table
sizes. The lines are flat. Shrinking my table four times saves about a quarter of the
block and does not move the error; the Gaussian table is what sets accuracy. So we
recommend the 256-entry table.

If asked why the error does not fall with a bigger table: the remaining 0.02 to 0.05%
from my block is rounding of the three constants to their register widths, not the
table.

## Slide 5 - Cost of more lanes, and what is not proven yet

On the slide:

- `price_dp` 13,777 um^2, about 42% of a lane
- Pricing area for 1 / 2 / 4 lanes: 1.00x / 1.85x / 3.56x
- Blocks close 5 ns, and 4 ns, in synthesis
- Not yet shown: routed timing, measured power

Figures: `pricing_lane_scaling.png`, `pricing_area_vs_clock.png` if there is room.

Say: Each lane needs its own datapath, but the accumulator is shared, so area grows a
little slower than the lane count. On their own these blocks meet the 5 nanosecond
clock with room to spare. That is synthesis, before layout, for the blocks alone. The
whole lane does not yet pass independent timing analysis, so 200 megahertz is our
target, not a result.

## Likely questions

- **Why not a CORDIC or a polynomial for $e^x$?** CORDIC needs about 16 adder stages;
  a polynomial trades ROM for multipliers. Range reduction needs one constant multiply,
  one small table and a shifter.
- **Does one result per clock hold with several lanes?** Yes per lane. The accumulator
  tree adds one cycle of latency per doubling of lanes, not a lower rate.
- **What happens when the price overflows?** The value saturates and a sticky status
  flag is set, so a run that clipped is visible to the host.
- **Is Monte Carlo even needed here?** For one asset and one time step the expected
  payoff over the Gaussian table is a 1,024-term sum. The architecture is the point:
  the same lanes extend to path-dependent payoffs where no closed form exists.
