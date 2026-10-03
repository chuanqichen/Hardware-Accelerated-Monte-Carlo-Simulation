# Hardware-Accelerated Monte Carlo Option Pricing

**ECE 382M-7 VLSI I: Project Proposal** (revised)
**Team:** Tyler Haverlah, Chuanqi Chen, Eric Goode, and Shentong Zhong

> Source of record: the team's shared Google Doc
> (<https://docs.google.com/document/d/1yOYhe20KvzNS3t6aRMNNAdOsmYu0npHtoIdUJCS3r18/edit?usp=sharing>).
> This file mirrors it so the proposal is versioned alongside the code. If the two
> disagree, update this file from the Google Doc.

---

## Project overview

We propose a digital IP block that estimates the price of a European call option by
simulating many possible stock prices at one fixed maturity. The project will
emphasize the VLSI design: how much throughput can be gained by processing
independent trials in parallel, and what the additional area and power cost. We will
complete a small working design first, then compare one, two, and four parallel
simulation lanes. *(Implementation focus.)*

## Design plan

Each lane will generate a pseudorandom value, convert it to an approximately Gaussian
value `Z`, compute a possible final stock price

```
S_T = exp(A + B * Z)
```

and accumulate the call payoff `max(S_T - K, 0)`. Software will precompute `A` and
`B` from the option parameters. The IP block will return the payoff sum and trial
count; software will perform the final average and discounting.

Our initial implementation will use a compact xoshiro pseudorandom generator, a small
inverse-normal lookup table, fixed-point arithmetic, and a bounded lookup-based
exponential approximation. A simple start/configuration/result interface will set the
parameters, seeds, and number of trials. The one-lane version is the minimum complete
design; the same lane will be replicated for the scaling study.

**Out of core scope:** multi-step paths, additional option types, a second RNG
architecture, and advanced variance reduction.

### Lane dataflow

```mermaid
flowchart LR
    rng[xoshiro RNG<br/>32-bit uniform] --> gauss[Inverse-normal LUT<br/>fixed-point Z]
    gauss --> lin[A + B*Z<br/>fixed-point MAC]
    lin --> expu[Bounded exp LUT<br/>S_T]
    expu --> payoff[max(S_T - K, 0)]
    payoff --> acc[Payoff accumulator<br/>+ trial counter]
```

The lane is replicated `LANES = {1, 2, 4}` times behind one controller and one
reduction/accumulation stage.

## Verification and evaluation

- Compare RTL outputs with a **bit-accurate Python reference**.
- Check the estimated option price against the **analytical Black-Scholes** result over
  several seeds and representative option inputs.
- Test **random-number streams** and **lookup accuracy** separately from the full
  pipeline.
- For the one-, two-, and four-lane designs, report **area, maximum clock frequency,
  power, trials per second, and energy per trial** using the same implementation flow.
- Vary **one numerical design choice** (lookup resolution or fixed-point width) to show
  the accuracy-vs-hardware tradeoff.
- Throughput goal: **one completed trial per lane per cycle** after pipeline fill, if
  timing allows.

## Team responsibilities (proposed)

| Member | Primary responsibility |
|---|---|
| Tyler Haverlah | Top-level integration, synthesis, and physical-design flow |
| Chuanqi Chen | Gaussian lookup and fixed-point representation |
| Eric Goode | Stock-price, payoff, and accumulation datapath |
| Shentong Zhong | Random-number generator and stream tests |

All four members will review the integrated RTL, verification results, and final
comparisons. These assignments can be adjusted by the team.

## Milestones and deliverables

1. Establish the Python model, interface, and tool flow.
2. Simulate an integrated one-lane RTL design.
3. **Intermediate update:** correct one-lane implementation and initial synthesis
   results.
4. Extend to two and four lanes; complete the numerical tradeoff study.
5. Take at least one representative design through layout.
6. **Final submission:** specification, design and user documentation, test and
   optimization results, SystemVerilog and Python sources, and layout evidence
   required by the course.

Course dates (from the project brief): outline due 2026-09-29, intermediate results
2026-11-10, presentations 2026-12-01/03, final report 2026-12-09.

## Selected references

1. ECE 382M-7, "Final Project Information," Fall 2026 (course assignment).
2. AMD/Xilinx, [Vitis Quantitative Finance Library](https://github.com/Xilinx/Vitis_Libraries/tree/2024.2/quantitative_finance)
   (architecture and RNG reference; branch `2024.2` is the last with the library).
3. H. Tan et al., ["ThundeRiNG: Generating Multiple Independent Random Number Sequences on FPGAs,"](https://doi.org/10.1145/3447818.3461664)
   ICS 2021 (parallel-stream reference).

---

## Relationship to the 2026-09-20 deep-research plan

`Hardware_Accelerated_Monte_Carlo_Project_Plan.md` in this directory is the earlier,
broader plan. It remains useful as background (literature, verification methodology,
course requirement mapping, risk register), but **this proposal supersedes it on
scope**. The main narrowing decisions:

| Topic | 2026-09-20 plan | Revised proposal |
|---|---|---|
| Research question | Replicated xoshiro vs. ThundeRiNG-style shared-state RNG | Lane-parallel throughput vs. area/power scaling |
| RNG frontends | Two, compile-time selectable | One (xoshiro) |
| Path model | Multi-step Euler GBM, `num_steps` up to 64, path contexts | Single-step terminal price `S_T = exp(A + B*Z)` |
| Exponential | Avoided (precomputed factors) | Bounded LUT-based `exp` in hardware |
| Lane counts | 1, 2, 4, 8 (+16) | 1, 2, 4 |
| Variance reduction | Antithetic paths required | Out of scope |
| Statistical tests | TestU01 SmallCrush/Crush, PractRand, cross-stream | Stream tests scoped by RNG owner |
| Numeric study | Two fixed-point configs + mapper 8/10 bits | One numerical knob (LUT resolution or width) |
