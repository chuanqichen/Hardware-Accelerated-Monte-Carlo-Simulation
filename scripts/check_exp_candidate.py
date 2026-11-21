"""Enumerate all reachable Gaussian outputs for k8 versus the k10 baseline.

This checks deterministic bias on OPTION_GRID, not Monte Carlo confidence or RTL.
No sampling, generated ROM changes, or default changes are involved.
"""
import argparse
import csv
from pathlib import Path
import sys

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "model"))
import price_dp as pd
from gauss_lut import OPTION_GRID, GaussLut, GaussLutConfig, bs_call


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=ROOT / "results/exp_k8_candidate.csv")
    args = parser.parse_args()
    lut = GaussLut(GaussLutConfig(10, 16, 12))
    z = lut.fmt.quantize(lut.all_outputs())
    rows = []
    for label, *option in OPTION_GRID:
        regs = pd.option_to_regs(*option)
        baseline = pd.price_dp(*regs, z, pd.PriceDpConfig(exp_addr_bits=10))
        ref = bs_call(*option)
        price10 = pd.exact_price(*option, pd.PriceDpConfig(exp_addr_bits=10), lut)
        for bits in (10, 8):
            cfg = pd.PriceDpConfig(exp_addr_bits=bits)
            result = pd.price_dp(*regs, z, cfg)
            price = pd.exact_price(*option, cfg, lut)
            delta = result["p"] - baseline["p"]
            rows.append(dict(scenario=label, gauss_addr_bits=10, exp_addr_bits=bits,
                             black_scholes=ref, exact_price=price, bias_pct=100*(price-ref)/ref,
                             price_delta_k10=price-price10, reachable_outputs=len(z),
                             changed_payoffs=int(np.count_nonzero(delta)), max_abs_raw_payoff_delta=int(np.max(np.abs(delta))),
                             changed_sat_x=int(np.count_nonzero(result["sat_x"] != baseline["sat_x"])),
                             changed_sat_s=int(np.count_nonzero(result["sat_s"] != baseline["sat_s"]))))
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=list(rows[0]))
        writer.writeheader(); writer.writerows(rows)
    worst = max(abs(r["bias_pct"]) for r in rows)
    print(f"Exact grid bias maximum={worst:.9f}% (limit 1%); wrote {args.out}")
    if worst > 1:
        raise SystemExit("FAIL: deterministic grid bias exceeds 1%")


if __name__ == "__main__":
    main()
