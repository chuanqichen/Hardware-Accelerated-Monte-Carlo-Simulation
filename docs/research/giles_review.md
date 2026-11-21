# Prior-art review: Giles & Sheridan-Methven (2026-11-21)

Read in full: arXiv 2012.09715v2 (Dec 2022), *Approximating inverse cumulative distribution
functions to produce approximate random variables*; skimmed 2102.08164, *Analysis of nested MLMC
using approximate Normal random variables*. Purpose: answer the three questions behind risk 1 of
`paper_proposal_v2.md`.

## Answers

| Question | Answer | Where |
|---|---|---|
| Do they analyse a *piecewise-constant table*? | **Yes.** Sec. 2.2, Theorem 2.3: piecewise constant on 2^q equal intervals, midpoint values - exactly our uniform ROM. Bound on the L^p error ‖Z - Z̃‖_p with the final (tail) interval handled separately via Jensen and their tail lemmas 2.1-2.2. | p. 4-5 |
| Do they use *geometric/dyadic intervals dense at the tails, indexed by a leading-zero / exponent read*? | **Yes.** Sec. 2.3, Theorem 2.5: piecewise **linear** on intervals I_k = [r^k/2, r^{k-1}/2) with r = 1/2 ("dyadic rate"), last interval absorbs the singularity; Sec. 4-5 implement the index by reading the float exponent bits (Table 1, code listing). This is the mathematical construction behind our segmented table. | p. 5-6, 12-13 |
| Do they bound a *convex-payoff bias* (weak error) or decompose tail vs body? | **No.** All bounds are strong (L^p) errors of the random variable; the application error is then removed by nested MLMC (2102.08164 analyses the variance of the correction level). No weak-error / option-bias statement, no tail-vs-body decomposition of the bias, no hardware cost. | throughout |

## What this does to our claims

| Claim | Before | After reading |
|---|---|---|
| C1 exact application-level FoM for hardware GRNGs | novel | **unchanged** - they never evaluate generators by downstream bias, nor compare architectures |
| C2 bias bound | "new bound" | **re-scope**: the *weak-error* (payoff-bias) counterpart of their strong-error Theorem 2.3, with the sharp tail-term decomposition verified to 10 % against exact tables. For Lipschitz payoffs their L^1 bound implies a loose bias bound; ours is the tight, decomposed one. Cite Thm 2.3 and lemmas 2.1-2.2 directly (our tail integral uses the same z_q = Φ^-1(1 - 2^-q)). |
| C3 segmented table | "new design" | **re-scope to hardware realisation**: (a) they use piecewise *linear* per dyadic interval -> needs a multiply-add per sample; ours is piecewise *constant* with 2^B sub-cells per band -> pure ROM, no multiplier (in our lane a 16x16 multiplier is ~2x the whole segmented table); (b) ours is a synthesised, bit-exact, area-measured standard-cell block with an LZC on a 31-bit integer rather than float exponent bits; (c) evaluated by application bias on two workloads. The paper must say "the dyadic-interval idea is Giles & Sheridan-Methven's; we show the multiplier-free hardware form dominates uniform ROM, comparator-tree and CLT generators on silicon area and tail bias." |
| C4 matched comparison | novel | **unchanged** |
| C5 library defect | novel | unchanged |

## Opportunities the reading opens

1. **Add their piecewise-linear dyadic approximation as a hardware baseline** (K intervals, slope +
   intercept ROM, one multiplier): a direct, fair comparison of *their* construction vs *our*
   multiplier-free one on the same flow. Likely result: comparable bias at larger area/power, or
   better bias at the cost of the multiplier - either way a genuine tradeoff nobody has measured.
2. **Position against nested MLMC honestly**: cost of a correction level (second datapath, extra
   samples) vs cost of a better table; we can quantify both on the lane.
3. Use their lemma 2.1 (bounds on z_q φ(z_q)) to turn our numerical tail integral into a closed form.

## Verdict on risk 1

Materialised in part - the *table construction* is prior art; the *figure of merit*, the *hardware
realisation without multipliers*, the *matched silicon comparison* and the *weak-error decomposition*
are not. The paper is still publishable but must be framed as hardware-evaluation-and-realisation,
not as a new approximation scheme. Update `paper_proposal_v2.md` Sec. 1, 3, 6 accordingly.
