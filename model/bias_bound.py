"""Analytical bias of a truncated/quantised inverse-CDF table for a European call (claim C2/T4).

A uniform table with a address bits maps every u beyond the last cell onto that cell's
midpoint, z_max = Phi^-1(1 - 2^-(a+1)). For a call, price = e^{-rT} E[max(S_T - K, 0)] with
S_T = exp(A + B z). Replacing the upper tail z > z_edge (z_edge = Phi^-1(1 - 2^-a), the cell's
lower edge) by the point z_max loses

   tail_bias = e^{-rT} ( integral_{z_edge}^{inf} pay(z) phi(z) dz  -  2^-a * pay(z_max) )

(the lower tail contributes nothing for a call). The body contributes the midpoint-quantisation
term, second order in the cell width and small; it is estimated by exact enumeration of the
body cells and reported separately. The bound is checked against the exact enumerated prices.

    python3 model/bias_bound.py
"""
from __future__ import annotations

import math
from statistics import NormalDist

import numpy as np

import price_dp as pd
from gauss_lut import OPTION_GRID, GaussLut, GaussLutConfig, bs_call

N = NormalDist()


def _pay(z, s0, k, r, sigma, T):
    a = math.log(s0) + (r - 0.5 * sigma**2) * T; b = sigma * math.sqrt(T)
    return np.maximum(np.exp(a + b * z) - k, 0.0)


def tail_bias(a_bits: int, s0, k, r, sigma, T, n_quad: int = 20000) -> float:
    """Price lost by collapsing the upper tail onto the last cell midpoint (absolute, in price units)."""
    t = 2.0 ** -a_bits                                  # mass of the last cell
    z_edge = N.inv_cdf(1 - t); z_max = N.inv_cdf(1 - t / 2)
    z = np.linspace(z_edge, 9.0, n_quad)
    phi = np.exp(-0.5 * z**2) / math.sqrt(2 * math.pi)
    exact_tail = np.trapz(_pay(z, s0, k, r, sigma, T) * phi, z)
    table_tail = t * float(_pay(np.array([z_max]), s0, k, r, sigma, T)[0])
    return math.exp(-r * T) * (table_tail - exact_tail)   # negative: table under-prices


def main():
    print(f"{'a':>3} {'option':<18}{'exact bias%':>12}{'tail bound%':>12}{'residual%':>11}")
    for a_bits in (6, 8, 10, 12):
        lut = GaussLut(GaussLutConfig(a_bits, 16, 12))
        for label, *opt in OPTION_GRID:
            bs = bs_call(*opt)
            exact = lut.exact_call_price(*opt)             # same table, float exp: isolates the table
            exact_bias = 100 * (exact - bs) / bs
            bound = 100 * tail_bias(a_bits, *opt) / bs
            print(f"{a_bits:>3} {label:<18}{exact_bias:>+12.4f}{bound:>+12.4f}{exact_bias - bound:>+11.4f}")
        print()
    print("tail bound ~ exact table bias to within the residual column (midpoint quantisation of the body);")
    print("bias scales as the tail mass 2^-a times the payoff growth, i.e. ~4x per 2 address bits.")


if __name__ == "__main__":
    main()
