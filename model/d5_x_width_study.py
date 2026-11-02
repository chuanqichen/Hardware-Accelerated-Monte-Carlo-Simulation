"""Decision D-5: width of A and x (exp input), Q5.12 (18 b) vs Q5.10 (16 b).

Exact (not Monte Carlo) price bias of the whole fixed-point chain for every x
format and Gaussian table size on the grid, isolating the x-quantisation effect:

  bias_vs_float   fixed-point lane vs the same Gaussian table with float exp
                  (= what the x/A/B/K rounding and the exp table cost)
  bias_vs_bs      fixed-point lane vs Black-Scholes (adds the table's tail bias)

Uses Eric's stage functions unchanged; only the A/x format is swept. price_dp's
exp_fx() reads the x fraction width through cfg.y_frac, so a config subclass is
enough - no change to price_dp.py or its tests.

    python3 model/d5_x_width_study.py
Writes results/d5_x_width.csv.
"""
from __future__ import annotations

import csv
from dataclasses import dataclass
from pathlib import Path

import numpy as np

import price_dp as pd
from fxp import Fxp, round_shift_even
from gauss_lut import OPTION_GRID, GaussLut, GaussLutConfig, bs_call

ROOT = Path(__file__).resolve().parents[1]
X_FORMATS = [Fxp(18, 12), Fxp(17, 11), Fxp(16, 10), Fxp(16, 11)]   # Q5.12, Q5.11, Q5.10, Q4.11
ADDR_BITS = (8, 10, 12)


@dataclass(frozen=True)
class XCfg(pd.PriceDpConfig):
    x_frac: int = 12

    @property
    def y_frac(self) -> int:              # exp_fx reads this: 2^y with y = x * log2e
        return self.x_frac + self.log2e_frac


def lane_price(s0, k, r, sigma, T, z_raw, x_fmt: Fxp, cfg: XCfg) -> float:
    """Exact expected discounted payoff over all table outputs, at x format x_fmt."""
    a_real = np.log(s0) + (r - 0.5 * sigma**2) * T
    a = int(x_fmt.quantize(a_real))                      # A shares x's format (spec Sec. 3)
    b = int(pd.B_FMT.quantize(sigma * np.sqrt(T)))
    kk = int(pd.ST_FMT.quantize(k))
    acc = (np.int64(a) << (pd.ACC_FRAC - x_fmt.frac)) + np.int64(b) * z_raw     # Q5.26 fused sum
    x, _ = x_fmt.saturate(round_shift_even(acc, pd.ACC_FRAC - x_fmt.frac))
    s_t = pd.exp_fx(x, cfg)["s_t"]
    p = pd.payoff(s_t, kk)
    return pd.price_from_sum(int(p.sum()), p.size, r, T)


def main():
    rows = []
    print(f"{'a':>2} {'x fmt':<14}" + "".join(f"{lab.split()[0]+' '+lab.split()[1]:>14}" for lab, *_ in OPTION_GRID)
          + "   (bias vs float-exp reference, %)")
    for a_bits in ADDR_BITS:
        lut = GaussLut(GaussLutConfig(a_bits, 16, 12))
        z = lut.fmt.quantize(lut.all_outputs())
        for x_fmt in X_FORMATS:
            cfg = XCfg(x_frac=x_fmt.frac)
            line = f"{a_bits:>2} {str(x_fmt):<14}"
            for label, *opt in OPTION_GRID:
                ref = lut.exact_call_price(*opt)
                bs = bs_call(*opt)
                hw = lane_price(*opt, z, x_fmt, cfg)
                rows.append(dict(addr_bits=a_bits, x_fmt=str(x_fmt), x_width=x_fmt.width, x_frac=x_fmt.frac,
                                 option=label, bs=bs, float_ref=ref, hw=hw,
                                 bias_vs_float_pct=100 * (hw - ref) / ref, bias_vs_bs_pct=100 * (hw - bs) / bs))
                line += f"{100 * (hw - ref) / ref:>+13.4f}%"
            print(line)
        print()
    out = ROOT / "results" / "d5_x_width.csv"
    with out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader(); w.writerows(rows)
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
