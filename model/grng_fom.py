"""Application-level figure of merit for hardware Gaussian generators (research, claim C1/T5).

Any generator is described by its exact (or measured) finite output distribution: arrays
z (real values) and p (probabilities summing to 1). Every metric below is then an exact
expectation over that distribution - no Monte Carlo noise:

  body statistics   mean, variance, Kolmogorov-Smirnov distance vs N(0,1)
  tail mass         P(z > t) for t in {3, 3.5, 4}, vs the exact Gaussian tail
  European call     worst and per-option bias vs Black-Scholes through the fixed-point lane
  digital call      cash-or-nothing option P(S_T > K) at K far OTM - a pure tail probability
                    with a finite answer, which is what a rare-event / VaR-style estimator sees

Generators available here: ROM table (gauss_lut, exact), TreeGRNG 8/12/16 (RTL histograms),
and anything else that provides (z, p). Used by scripts/plot_grng_pareto.py.

    python3 model/grng_fom.py            # table for all known generators -> results/grng_fom.csv
"""
from __future__ import annotations

import csv
import math
from pathlib import Path
from statistics import NormalDist

import numpy as np

import price_dp as pd
from gauss_lut import OPTION_GRID, GaussLut, GaussLutConfig, bs_call

ROOT = Path(__file__).resolve().parents[1]
N = NormalDist()
TAILS = (3.0, 3.5, 4.0)
# digital (cash-or-nothing) calls: payoff 1 if S_T > K. S0=100, r=0.05, sigma=0.2, T=1;
# K chosen so the exercise probability is a tail event: d2 = (ln(S0/K) + (r - s^2/2) T) / (s sqrt T)
DIGITAL_K = (150.0, 180.0, 200.0)


def digital_call_bs(s0, k, r, sigma, T):
    d2 = (math.log(s0 / k) + (r - 0.5 * sigma**2) * T) / (sigma * math.sqrt(T))
    return math.exp(-r * T) * N.cdf(d2)


def digital_call_hw(z, p, s0, k, r, sigma, T):
    """Same fixed-point x = A + Bz and S_T = e^x as the lane; payoff is the indicator S_T > K."""
    a, b, kk = pd.option_to_regs(s0, k, r, sigma, T)
    zr = pd.Z_FMT.quantize(np.asarray(z))
    s_t = pd.price_dp(a, b, kk, zr)["s_t"]
    return math.exp(-r * T) * float(p[s_t > kk].sum())


def fom(z, p, name: str = "", area_um2: float | None = None) -> dict:
    z = np.asarray(z, dtype=float); p = np.asarray(p, dtype=float); p = p / p.sum()
    mean = float((z * p).sum()); var = float(((z - mean) ** 2 * p).sum())
    o = np.argsort(z)
    ks = float(np.max(np.abs(np.cumsum(p[o]) - np.array([N.cdf(v) for v in z[o]]))))
    row = dict(generator=name, area_um2=area_um2, n_outputs=int((p > 0).sum()),
               mean=mean, var=var, ks=ks, max_abs_z=float(np.abs(z[p > 0]).max()))
    for t in TAILS:
        hw = float(p[z > t].sum()); ex = 1 - N.cdf(t)
        row[f"tail_{t:g}_hw"] = hw; row[f"tail_{t:g}_exact"] = ex
        row[f"tail_{t:g}_rel_err_pct"] = 100 * (hw - ex) / ex
    worst = 0.0
    for label, *opt in OPTION_GRID:
        a, b, kk = pd.option_to_regs(*opt)
        pay = pd.price_dp(a, b, kk, pd.Z_FMT.quantize(z))["p"]
        hw = math.exp(-opt[2] * opt[4]) * float((pay * p).sum()) / pd.ST_FMT.scale
        bs = bs_call(*opt)
        key = "call_" + label.split()[0].lower() + "_" + label.split()[1][2:] + "_" + label.split()[2][2:]
        row[key + "_bias_pct"] = 100 * (hw - bs) / bs
        worst = max(worst, abs(row[key + "_bias_pct"]))
    row["call_worst_bias_pct"] = worst
    dworst = 0.0
    for k in DIGITAL_K:
        opt = (100.0, k, 0.05, 0.2, 1.0)
        bs = digital_call_bs(*opt); hw = digital_call_hw(z, p, *opt)
        row[f"digital_K{k:g}_bs"] = bs; row[f"digital_K{k:g}_hw"] = hw
        row[f"digital_K{k:g}_bias_pct"] = 100 * (hw - bs) / bs
        dworst = max(dworst, abs(row[f"digital_K{k:g}_bias_pct"]))
    row["digital_worst_bias_pct"] = dworst
    return row


# ---- known generators -----------------------------------------------------------------
def lut_dist(addr_bits: int):
    lut = GaussLut(GaussLutConfig(addr_bits, 16, 12))
    z = np.asarray(lut.all_outputs()); return z, np.full(len(z), 1 / len(z))


def hist_dist(path: Path, width: int, lsb_per_sigma: int):
    h = {int(l.split()[1]): int(l.split()[2]) for l in path.open()}
    n = sum(h.values()); codes = np.array(sorted(h)); p = np.array([h[c] / n for c in codes])
    z = np.where(codes >= (1 << (width - 1)), codes - (1 << width), codes) / lsb_per_sigma
    return z, p


def known_generators() -> list[tuple[str, float | None, np.ndarray, np.ndarray]]:
    R = ROOT / "results"
    gens = [(f"ROM LUT a={a}", area, *lut_dist(a)) for a, area in ((6, None), (8, 1618.0), (10, 4060.0), (12, 8152.0))]
    for name, f, w, s, area in (("TreeGRNG 8b", "treegrng_sim_hist.txt", 8, 32, 2144.0),
                                ("TreeGRNG 12b", "treegrng_hist_12.txt", 12, 512, 5099.0),
                                ("TreeGRNG 16b", "treegrng_hist_16.txt", 16, 8192, 8562.0)):
        if (R / f).exists():
            gens.append((name, area, *hist_dist(R / f, w, s)))
    return gens


def main():
    rows = [fom(z, p, name, area) for name, area, z, p in known_generators()]
    out = ROOT / "results" / "grng_fom.csv"
    with out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
    print(f"{'generator':<14}{'area':>6}{'KS':>8}{'P>3.5 hw':>10}{'err%':>7}{'call worst':>11}"
          f"{'dig K150':>9}{'dig K180':>9}{'dig K200':>9}  (digital-call bias %, BS price shown once below)")
    for r in rows:
        print(f"{r['generator']:<14}{(r['area_um2'] or 0):>6.0f}{r['ks']:>8.4f}{r['tail_3.5_hw']:>10.2e}"
              f"{r['tail_3.5_rel_err_pct']:>+7.0f}{r['call_worst_bias_pct']:>10.2f}%"
              + "".join(f"{r[f'digital_K{k:g}_bias_pct']:>+8.1f}%" for k in DIGITAL_K))
    print("digital-call BS prices:", "  ".join(f"K={k:g}: {digital_call_bs(100, k, .05, .2, 1):.5f}" for k in DIGITAL_K))
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
