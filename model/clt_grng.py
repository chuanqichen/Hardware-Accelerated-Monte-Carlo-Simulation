"""CLT-12 Gaussian generator baseline (research, claim T6): z = (sum of 12 uniform W-bit words
- 6*2^W) / 2^W, which has mean 0, variance 1, and support |z| <= 6. Exact distribution by
repeated convolution of the uniform pmf; output quantised to Q3.12 like the other generators.
RTL: rtl/research/clt_grng.sv (12 words from a 384-bit xoshiro-free LFSR bank in the TB; the
synthesised block is the adder tree + scaling, which is the architecture-specific cost).

    python3 model/clt_grng.py            # FoM row + exact distribution
"""
from __future__ import annotations

import numpy as np

from fxp import Fxp

W = 12
Z_FMT = Fxp(16, 12)


def distribution(w: int = W):
    """Exact pmf of S = sum of 12 iid uniform integers in [0, 2^w). z = (S - 6*2^w) / 2^w."""
    pmf = np.full(1 << w, 1.0 / (1 << w))
    s = pmf.copy()
    for _ in range(11):
        s = np.convolve(s, pmf)
    S = np.arange(len(s))
    z = (S - 6 * (1 << w)) / (1 << w)
    # quantise to Q3.12 (saturating at +-8; |z| <= 6 so never saturates) and merge equal codes
    zq = Z_FMT.to_real(Z_FMT.quantize(z))
    codes, inv = np.unique(zq, return_inverse=True)
    p = np.zeros(len(codes)); np.add.at(p, inv, s)
    return codes, p


if __name__ == "__main__":
    import grng_fom
    z, p = distribution()
    r = grng_fom.fom(z, p, "CLT-12 (W=12)")
    print(f"CLT-12: outputs {len(z)}  KS {r['ks']:.4f}  var {r['var']:.4f}  P(z>3.5) err {r['tail_3.5_rel_err_pct']:+.1f}%  "
          f"call worst {r['call_worst_bias_pct']:.3f}%  digital K180 {r['digital_K180_bias_pct']:+.1f}%  K200 {r['digital_K200_bias_pct']:+.1f}%")
