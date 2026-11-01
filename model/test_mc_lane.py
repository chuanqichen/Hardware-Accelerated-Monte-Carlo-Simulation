"""Unit tests for the integrated one-lane reference (mc_lane.py).  Run: make test"""
import math
import unittest

import numpy as np

import mc_lane as ml
import price_dp as pd
from gauss_lut import GaussLut
from rng_lane import RngLane, pack_state

SEED = (0x12345678, 0x9ABCDEF0, 0x0F1E2D3C, 0x4B5A6978)
OPT = (100.0, 100.0, 0.05, 0.2, 1.0)          # S0, K, r, sigma, T  (ATM)


class TestStreams(unittest.TestCase):
    def test_rng_stream_matches_lane_control_model(self):
        # Pure stream == RngLane ticked with run held high after one seed_load.
        n = 200
        lane = RngLane()
        lane.tick(seed_load=True, seed_state=pack_state(SEED))
        expect = []
        for _ in range(n):
            v, u = lane.tick(run=True)
            self.assertTrue(v)
            expect.append(u)
        self.assertEqual(ml.rng_stream(SEED, n).tolist(), expect)

    def test_seed_accepts_tuple_and_packed_bus(self):
        a = ml.rng_stream(SEED, 16)
        b = ml.rng_stream(pack_state(SEED), 16)
        np.testing.assert_array_equal(a, b)

    def test_zero_seed_rejected(self):
        with self.assertRaises(ValueError):
            ml.rng_stream((0, 0, 0, 0), 1)
        with self.assertRaises(ValueError):
            ml.run_lane(0, 0, 0, 0, 1)

    def test_gauss_stage_is_the_block_lookup(self):
        cfg = ml.LaneConfig()
        lut = GaussLut(cfg.gauss)
        u = ml.rng_stream(SEED, 1000)
        np.testing.assert_array_equal(ml.gauss_stage(u, lut), lut.lookup(u))


class TestLane(unittest.TestCase):
    def setUp(self):
        self.cfg = ml.LaneConfig()
        self.a, self.b, self.k = pd.option_to_regs(*OPT)

    def test_trace_is_consistent_with_blocks(self):
        n = 500
        t = ml.trace_lane(self.a, self.b, self.k, SEED, n, self.cfg)
        self.assertEqual(set(t), {"u", "z", "acc", "x", "sat_x", "s_t", "sat_s", "p"})
        for v in t.values():
            self.assertEqual(v.shape, (n,))
        ref = pd.price_dp(self.a, self.b, self.k, t["z"], self.cfg.dp)
        for key in ("acc", "x", "sat_x", "s_t", "sat_s", "p"):
            np.testing.assert_array_equal(t[key], ref[key], key)

    def test_run_equals_trace_sum(self):
        n = 1000
        t = ml.trace_lane(self.a, self.b, self.k, SEED, n, self.cfg)
        r = ml.run_lane(self.a, self.b, self.k, SEED, n, self.cfg)
        self.assertEqual(r["payoff_sum"], int(t["p"].sum()))
        self.assertEqual(r["trial_count"], n)
        self.assertEqual(r["sat_x"], bool(t["sat_x"].any()))
        self.assertEqual(r["sat_s"], bool(t["sat_s"].any()))
        self.assertFalse(r["acc_overflow"])

    def test_run_is_deterministic(self):
        r1 = ml.run_lane(self.a, self.b, self.k, SEED, 300, self.cfg)
        r2 = ml.run_lane(self.a, self.b, self.k, SEED, 300, self.cfg)
        self.assertEqual(r1, r2)

    def test_payoff_sum_is_prefix_additive(self):
        # Trials n..m of one run are trials 0..m-n of the same stream advanced: the
        # hardware sum after m trials is the sum after n plus the next m-n payoffs.
        t = ml.trace_lane(self.a, self.b, self.k, SEED, 400, self.cfg)
        r_full = ml.run_lane(self.a, self.b, self.k, SEED, 400, self.cfg)
        r_part = ml.run_lane(self.a, self.b, self.k, SEED, 250, self.cfg)
        self.assertEqual(r_full["payoff_sum"] - r_part["payoff_sum"], int(t["p"][250:].sum()))

    def test_no_saturation_for_grid_options(self):
        for _, *opt in ml.OPTION_GRID:
            a, b, k = pd.option_to_regs(*opt)
            r = ml.run_lane(a, b, k, SEED, 2000, self.cfg)
            self.assertFalse(r["sat_x"] or r["sat_s"], opt)

    def test_monte_carlo_converges_to_exact_hw_price(self):
        # 2^16 trials: MC standard error of the ATM call is ~0.06 (0.6%). Require
        # the estimate within 5 SE of the exact finite-table expectation.
        n = 1 << 16
        res = ml.run_option(*OPT, SEED, n, self.cfg)
        t = ml.trace_lane(self.a, self.b, self.k, SEED, n, self.cfg)
        disc = math.exp(-OPT[2] * OPT[4])
        se = disc * float(pd.ST_FMT.to_real(t["p"]).std(ddof=1)) / math.sqrt(n)
        exact = pd.exact_price(*OPT, self.cfg.dp, GaussLut(self.cfg.gauss))
        self.assertLess(abs(res["price"] - exact), 5 * se, (res["price"], exact, se))

    def test_lat_total_matches_mc_pkg(self):
        self.assertEqual(ml.LaneConfig().lat_total, 9)                                # 1+1+6+0+1
        self.assertEqual(ml.LaneConfig(gauss_latency=2, lanes=4).lat_total, 12)      # 1+2+6+2+1
        self.assertEqual(ml.LaneConfig(dp=pd.PriceDpConfig(mul_stages=2)).lat_total, 10)


if __name__ == "__main__":
    unittest.main()
