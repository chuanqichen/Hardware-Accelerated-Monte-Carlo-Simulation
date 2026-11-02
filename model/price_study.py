"""Accuracy study: hardware Monte Carlo price vs. Black-Scholes, with confidence intervals.

Answers the professor's "define accuracy criteria" request with numbers the team
can defend. For each option on OPTION_GRID the bit-accurate lane model is run over
SEEDS independent xoshiro128++ streams of N_TRIALS each (streams separated by the
canonical jump(), so they never overlap - spec D-1). Reported per option:

  bs          Black-Scholes closed form (the answer key)
  exact_hw    the price the finite-table hardware converges to (no sampling noise)
  mc_mean     mean of the SEEDS Monte Carlo estimates
  mc_se       standard error of one estimate (std over seeds)
  ci95_lo/hi  mc_mean +- 1.96 * mc_se / sqrt(SEEDS)   (CI of the mean of the seeds)
  bias_pct    (exact_hw - bs) / bs                    deterministic approximation bias
  noise_pct   mc_se / bs                              sampling error of one run of N_TRIALS
  coverage    fraction of the SEEDS runs whose own 95% CI (from the per-trial
              sample variance, what the host computes from payoff_sum / sq_sum)
              contains exact_hw

Pass criteria (weekly plan): |bias| <= 1% on the grid; coverage close to 0.95.

    python3 model/price_study.py                     # 100 seeds x 2^20 trials (~50 s)
    python3 model/price_study.py --seeds 8 --trials 65536
Writes results/price_vs_bs.csv and docs/figures/price_vs_bs.png.
"""
from __future__ import annotations

import argparse
import csv
import math
from pathlib import Path

import numpy as np

import price_dp as pd
from gauss_lut import OPTION_GRID, GaussLut, bs_call
from mc_lane import LaneConfig
from rng_lane import MASK32, normalize_state

ROOT = Path(__file__).resolve().parents[1]

# xoshiro128++ jump polynomial (Blackman/Vigna): advances a state by 2^64 steps.
JUMP = (0x8764000b, 0xf542d2d3, 0x6fa035c3, 0x77f2db5b)


def _rotl(x, k):
    return ((x << k) | (x >> (32 - k))) & MASK32


def _next_state(s):
    s0, s1, s2, s3 = s
    t = (s1 << 9) & MASK32
    s2 ^= s0; s3 ^= s1; s1 ^= s2; s0 ^= s3
    s2 ^= t
    s3 = _rotl(s3, 11)
    return (s0, s1, s2, s3)


def jump(state):
    """Canonical xoshiro128++ jump(): state 2^64 outputs ahead."""
    s = normalize_state(state)
    acc = [0, 0, 0, 0]
    for word in JUMP:
        for b in range(32):
            if word & (1 << b):
                acc = [a ^ v for a, v in zip(acc, s)]
            s = _next_state(s)
    return tuple(acc)


def lane_seeds(root, n):
    """n independent streams: root, jump(root), jump^2(root), ..."""
    seeds, s = [], normalize_state(root)
    for _ in range(n):
        seeds.append(s)
        s = jump(s)
    return seeds


def xoshiro_streams(seeds, n):
    """Vectorised xoshiro128++: [len(seeds), n] uint64 outputs, all streams in lockstep."""
    st = np.array(seeds, dtype=np.uint64)          # [S, 4]
    out = np.empty((st.shape[0], n), dtype=np.uint64)
    m = np.uint64(MASK32)
    for i in range(n):
        s0, s1, s2, s3 = st[:, 0], st[:, 1], st[:, 2], st[:, 3]
        r = ((s0 + s3) & m)
        r = (((r << np.uint64(7)) | (r >> np.uint64(25))) & m)
        out[:, i] = (r + s0) & m
        t = (s1 << np.uint64(9)) & m
        s2 = s2 ^ s0; s3 = s3 ^ s1; s1 = s1 ^ s2; s0 = s0 ^ s3
        s2 = s2 ^ t
        s3 = ((s3 << np.uint64(11)) | (s3 >> np.uint64(21))) & m
        st = np.stack([s0, s1, s2, s3], axis=1)
    return out


def study(seeds: int, trials: int, root, cfg: LaneConfig):
    lut = GaussLut(cfg.gauss)
    u = xoshiro_streams(lane_seeds(root, seeds), trials)        # [S, N]
    z = lut.lookup(u.ravel()).reshape(seeds, trials)
    rows = []
    for label, s0, k, r, sigma, T in OPTION_GRID:
        a, b, kk = pd.option_to_regs(s0, k, r, sigma, T)
        p = pd.price_dp(a, b, kk, z.ravel(), cfg.dp)["p"].reshape(seeds, trials)
        disc = math.exp(-r * T) / pd.ST_FMT.scale
        est = disc * p.sum(axis=1) / trials                      # one MC price per seed
        se_each = disc * p.std(axis=1, ddof=1) / math.sqrt(trials)  # host's own SE per run
        bs = bs_call(s0, k, r, sigma, T)
        exact = pd.exact_price(s0, k, r, sigma, T, cfg.dp, lut)
        mean, se = est.mean(), est.std(ddof=1)
        covered = np.abs(est - exact) <= 1.96 * se_each
        rows.append(dict(option=label, s0=s0, k=k, r=r, sigma=sigma, T=T, seeds=seeds, trials=trials,
                         bs=bs, exact_hw=exact, mc_mean=mean, mc_se=se,
                         ci95_lo=mean - 1.96 * se / math.sqrt(seeds), ci95_hi=mean + 1.96 * se / math.sqrt(seeds),
                         bias_pct=100 * (exact - bs) / bs, noise_pct=100 * se / bs,
                         mc_vs_bs_pct=100 * (mean - bs) / bs, coverage=covered.mean(),
                         se_host_mean=se_each.mean()))
    return rows


def plot(rows, path: Path):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, (a1, a2) = plt.subplots(1, 2, figsize=(10.5, 3.8), gridspec_kw=dict(width_ratios=[3, 2]))
    x = np.arange(len(rows))
    labels = [r["option"] for r in rows]
    bias = [r["bias_pct"] for r in rows]
    mc = [r["mc_vs_bs_pct"] for r in rows]
    err = [1.96 * r["noise_pct"] for r in rows]
    a1.axhline(0, color="#999", lw=0.8)
    a1.axhspan(-1, 1, color="#e8f4e8", zorder=0, label="target: |bias| <= 1 %")
    a1.bar(x - 0.18, bias, 0.36, color="#4c72b0", label="deterministic bias (exact HW vs BS)")
    a1.errorbar(x + 0.18, mc, yerr=err, fmt="o", color="#c44e52", capsize=4,
                label=f"one MC run of 2^{int(math.log2(rows[0]['trials']))} trials, 95 % interval")
    a1.set_xticks(x); a1.set_xticklabels(labels, rotation=20, ha="right", fontsize=8)
    a1.set_ylabel("relative error vs Black-Scholes [%]")
    a1.set_title("Hardware price error: bias vs sampling noise", fontsize=10)
    a1.legend(fontsize=7.5, loc="lower left")

    cov = [r["coverage"] for r in rows]
    a2.axhline(0.95, color="#999", lw=0.8, ls="--")
    a2.bar(x, cov, 0.6, color="#55a868")
    a2.set_ylim(0.6, 1.02)
    a2.set_xticks(x); a2.set_xticklabels(labels, rotation=20, ha="right", fontsize=8)
    a2.set_ylabel("fraction of runs whose 95 % CI covers exact HW")
    a2.set_title(f"CI coverage over {rows[0]['seeds']} independent seeds", fontsize=10)
    fig.tight_layout(); fig.savefig(path, dpi=200, bbox_inches="tight"); plt.close(fig)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seeds", type=int, default=100)
    ap.add_argument("--trials", type=int, default=1 << 20)
    ap.add_argument("--root", type=lambda s: int(s, 0), default=0x0123456789abcdef0fedcba987654321)
    ap.add_argument("--csv", type=Path, default=ROOT / "results" / "price_vs_bs.csv")
    ap.add_argument("--fig", type=Path, default=ROOT / "docs" / "figures" / "price_vs_bs.png")
    a = ap.parse_args()
    cfg = LaneConfig()
    root = tuple((a.root >> (32 * i)) & MASK32 for i in range(4))
    rows = study(a.seeds, a.trials, root, cfg)

    a.csv.parent.mkdir(parents=True, exist_ok=True)
    with a.csv.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader(); w.writerows(rows)
    a.fig.parent.mkdir(parents=True, exist_ok=True)
    plot(rows, a.fig)

    print(f"lane {cfg.gauss.name} / {cfg.dp.name}; {a.seeds} seeds x {a.trials} trials")
    print(f"{'option':<18}{'BS':>9}{'exact HW':>10}{'bias%':>8}{'MC mean':>9}{'SE 1run':>9}{'noise%':>8}{'coverage':>9}")
    for r in rows:
        print(f"{r['option']:<18}{r['bs']:>9.4f}{r['exact_hw']:>10.4f}{r['bias_pct']:>+8.3f}{r['mc_mean']:>9.4f}"
              f"{r['mc_se']:>9.4f}{r['noise_pct']:>8.3f}{r['coverage']:>9.2f}")
    print(f"wrote {a.csv} and {a.fig}")


if __name__ == "__main__":
    main()
