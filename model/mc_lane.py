"""Bit-accurate one-lane reference: rng_lane -> gauss_lut -> price_dp -> accumulator.

Golden model for the integrated RTL (mc_top / tb_mc_top). It only chains the
block owners' pure functions; nothing is re-implemented here:

  u    = xoshiro128++ stream          rng_lane.next_word          (Shentong)
  z    = Phi^-1 table lookup          gauss_lut.GaussLut.lookup   (Chuanqi)
  p    = max(e^(A + B z) - K, 0)      price_dp.price_dp           (Eric)
  sum  = sum p, count, sticky flags   price_dp.accumulate         (Eric)

API (docs/Lane_Interface_Spec.md Sec. 7):
  run_lane(a, b, k, seed_state, n_trials, cfg)   -> {"payoff_sum", "trial_count", "sat_x", "sat_s", "acc_overflow"}
  trace_lane(a, b, k, seed_state, n_trials, cfg) -> per-trial raw ints: u, z, acc, x, sat_x, s_t, sat_s, p

`seed_state` is the 128-bit bus {s3,s2,s1,s0} or a (s0,s1,s2,s3) tuple. Zero is
illegal (the controller flags bad_cfg); here it raises.

    python3 model/mc_lane.py              # 10^5-trial run vs exact and Black-Scholes
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass, field

import numpy as np

import price_dp as pd
from gauss_lut import OPTION_GRID, GaussLut, GaussLutConfig, bs_call
from rng_lane import LAT_RNG, next_word, normalize_state, unpack_state

LAT_ACC = 1


@dataclass(frozen=True)
class LaneConfig:
    """Compile-time parameters of one lane (mirrors rtl/mc_pkg.sv lat_total)."""
    gauss: GaussLutConfig = field(default_factory=lambda: GaussLutConfig(10, 16, 12))
    gauss_latency: int = 1                 # gauss_lut LATENCY parameter (1 | 2)
    dp: pd.PriceDpConfig = field(default_factory=pd.PriceDpConfig)
    lanes: int = 1

    @property
    def lat_tree(self) -> int:
        return int(np.ceil(np.log2(self.lanes))) if self.lanes > 1 else 0

    @property
    def lat_total(self) -> int:
        return LAT_RNG + self.gauss_latency + self.dp.lat_dp + self.lat_tree + LAT_ACC


def _state(seed_state) -> tuple:
    st = unpack_state(seed_state) if isinstance(seed_state, int) else normalize_state(seed_state)
    if not any(st):
        raise ValueError("all-zero xoshiro state is illegal (controller sets bad_cfg)")
    return st


def rng_stream(seed_state, n: int) -> np.ndarray:
    """First n xoshiro128++ words from seed_state, as uint32 (= rng_lane u with run held high)."""
    st = _state(seed_state)
    out = np.empty(n, dtype=np.uint64)
    for i in range(n):
        out[i], st = next_word(st)
    return out


def gauss_stage(u, lut: GaussLut) -> np.ndarray:
    """gauss_lut block: uint32 words -> raw Q3.12 z (int64)."""
    return lut.lookup(u)


def trace_lane(a, b, k, seed_state, n_trials: int, cfg: LaneConfig = LaneConfig(),
               lut: GaussLut | None = None) -> dict:
    """Per-trial raw values at every block boundary, for diffing against a waveform."""
    lut = lut or GaussLut(cfg.gauss)
    u = rng_stream(seed_state, n_trials)
    z = gauss_stage(u, lut)
    t = pd.price_dp(a, b, k, z, cfg.dp)
    return dict(u=u.astype(np.int64), z=z, acc=t["acc"], x=t["x"], sat_x=t["sat_x"],
                s_t=t["s_t"], sat_s=t["sat_s"], p=t["p"])


def run_lane(a, b, k, seed_state, n_trials: int, cfg: LaneConfig = LaneConfig(),
             lut: GaussLut | None = None) -> dict:
    """Result registers after `done` (what tb_mc_top compares against)."""
    t = trace_lane(a, b, k, seed_state, n_trials, cfg, lut)
    s, cnt, ovf, sx, ss = pd.accumulate(t["p"], np.ones(n_trials, bool),
                                        sat_x=t["sat_x"], sat_s=t["sat_s"])[-1]
    return dict(payoff_sum=s, trial_count=cnt, acc_overflow=ovf, sat_x=sx, sat_s=ss)


def run_option(s0, k, r, sigma, T, seed_state, n_trials: int, cfg: LaneConfig = LaneConfig(),
               lut: GaussLut | None = None) -> dict:
    """Host view: option parameters in, Monte Carlo price out (plus the raw result)."""
    a, b, kk = pd.option_to_regs(s0, k, r, sigma, T)
    res = run_lane(a, b, kk, seed_state, n_trials, cfg, lut)
    res["price"] = pd.price_from_sum(res["payoff_sum"], res["trial_count"], r, T)
    res["regs"] = dict(a=a, b=b, k=kk)
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--trials", type=int, default=100_000)
    ap.add_argument("--seed", type=lambda s: int(s, 0), default=0x0123456789abcdef0fedcba987654321)
    args = ap.parse_args()
    cfg = LaneConfig()
    lut = GaussLut(cfg.gauss)
    print(f"lane: gauss {cfg.gauss.name}, exp {cfg.dp.name}, LAT_TOTAL = {cfg.lat_total}")
    print(f"{'option':<18} {'BS':>9} {'exact hw':>9} {'MC hw':>9} {'MC-exact':>9} {'flags'}")
    for label, *opt in OPTION_GRID:
        res = run_option(*opt, args.seed, args.trials, cfg, lut)
        ex = pd.exact_price(*opt, cfg.dp, lut)
        flags = ",".join(f for f in ("sat_x", "sat_s", "acc_overflow") if res[f]) or "-"
        print(f"{label:<18} {bs_call(*opt):>9.4f} {ex:>9.4f} {res['price']:>9.4f} "
              f"{100 * (res['price'] - ex) / ex:>+8.3f}% {flags}")


if __name__ == "__main__":
    main()
