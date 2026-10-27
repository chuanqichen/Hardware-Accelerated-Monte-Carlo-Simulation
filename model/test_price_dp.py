"""Unit tests for the pricing datapath + accumulator model.  Run: make test"""
import math
import unittest

import numpy as np

import price_dp as pd
from fxp import round_shift_even
from gauss_lut import OPTION_GRID, GaussLut, GaussLutConfig, bs_call

CFG = pd.PriceDpConfig()


class TestRounding(unittest.TestCase):
    def test_round_shift_even_signed(self):
        x = np.array([2, 6, 3, 7, -2, -6, -3, -7, 5, -5])
        self.assertEqual(round_shift_even(x, 2).tolist(), [0, 2, 1, 2, 0, -2, -1, -2, 1, -1])

    def test_fused_rounding_tie_with_odd_a(self):
        # B*z = 1.5 LSB of x (a tie), A = 1 LSB. Single rounding of 2.5 -> 2 (even);
        # the spec's two-step round(1.5) + 1 would give 3. This block defines 2.
        a, b, z = 1, 0x6000, 1
        x, sat = pd.round_x(pd.mac(a, b, z))
        self.assertEqual(int(x), 2)
        self.assertFalse(bool(sat))

    def test_sat_x_both_ends(self):
        x, sat = pd.round_x(pd.mac(pd.A_FMT.max_raw, pd.B_FMT.max_raw, pd.Z_FMT.max_raw))
        self.assertEqual((int(x), bool(sat)), (pd.X_FMT.max_raw, True))
        x, sat = pd.round_x(pd.mac(pd.A_FMT.min_raw, pd.B_FMT.max_raw, pd.Z_FMT.min_raw))
        self.assertEqual((int(x), bool(sat)), (pd.X_FMT.min_raw, True))

    def test_bz_alone_never_saturates(self):
        # |B*z| < 4 * 8 = 32: only A can push x over the edge (why fusing is safe).
        acc = pd.mac(0, pd.B_FMT.max_raw, np.array([pd.Z_FMT.min_raw, pd.Z_FMT.max_raw]))
        self.assertFalse(np.any(pd.round_x(acc)[1]))


class TestExp(unittest.TestCase):
    def setUp(self):
        self.x = np.arange(pd.X_FMT.min_raw, pd.X_FMT.max_raw + 1, dtype=np.int64)

    def test_rom_range(self):
        for k in (6, 10, 12):
            rom = pd.exp_rom(pd.PriceDpConfig(exp_addr_bits=k))
            self.assertEqual(rom.size, 1 << k)
            self.assertTrue(np.all((rom >= 1 << 16) & (rom < 1 << 17)))

    def test_error_bound_vs_k(self):
        # midpoint table: worst relative error ~ ln2 * 2^-(k+1), plus small constant terms
        for k in (8, 10, 12):
            e = pd.exp_error(pd.PriceDpConfig(exp_addr_bits=k))
            self.assertLess(e["max_rel"], math.log(2) * 2.0 ** -(k + 1) + 6e-5, k)

    def test_monotonic_and_in_range(self):
        s_t = pd.exp_fx(self.x, CFG)["s_t"]
        self.assertTrue(np.all(np.diff(s_t) >= 0), "e^x must never decrease")
        self.assertTrue(np.all((s_t >= 0) & (s_t <= pd.ST_FMT.max_raw)))

    def test_overflow_edge(self):
        e = pd.exp_fx(self.x, CFG)
        self.assertTrue(np.array_equal(e["sat_s"], e["n"] >= 14))
        first = int(np.argmax(e["sat_s"]))
        self.assertGreater(math.exp(pd.X_FMT.to_real(self.x[first])), 2**14 * 0.999)
        self.assertLess(math.exp(pd.X_FMT.to_real(self.x[first - 1])), 2**14 * 1.001)
        self.assertEqual(int(e["s_t"][-1]), pd.ST_FMT.max_raw)

    def test_underflow_to_zero_without_flag(self):
        e = pd.exp_fx(np.array([pd.X_FMT.min_raw, pd.X_FMT.quantize(-7.0)]), CFG)
        self.assertEqual(e["s_t"].tolist(), [0, 0])
        self.assertFalse(np.any(e["sat_s"]))
        # e^-5 = 0.00674 = 1.72 LSB -> 2
        self.assertEqual(int(pd.exp_fx(pd.X_FMT.quantize(-5.0), CFG)["s_t"]), 2)


class TestPayoffAndBlock(unittest.TestCase):
    def test_payoff(self):
        self.assertEqual(pd.payoff([100, 101, 99, 50], [100, 100, 100, 0]).tolist(), [0, 1, 0, 50])

    def test_worked_example(self):
        a, b, k = pd.option_to_regs(100, 100, 0.05, 0.2, 1.0)
        t = pd.price_dp(a, b, k, pd.Z_FMT.quantize(1.0))
        s_t = pd.ST_FMT.to_real(t["s_t"])
        self.assertAlmostEqual(float(s_t), math.exp(math.log(100) + 0.03 + 0.2), delta=0.05)
        self.assertEqual(int(t["p"]), int(t["s_t"]) - k)

    def test_option_to_regs_round_trip(self):
        a, b, k = pd.option_to_regs(100, 120, 0.05, 0.6, 2.0)
        self.assertAlmostEqual(pd.A_FMT.to_real(a), math.log(100) + (0.05 - 0.18) * 2, delta=pd.A_FMT.lsb)
        self.assertAlmostEqual(pd.B_FMT.to_real(b), 0.6 * math.sqrt(2), delta=pd.B_FMT.lsb)
        self.assertEqual(k, 120 * 256)

    def test_latency(self):
        self.assertEqual(pd.PriceDpConfig().lat_dp, 6)
        self.assertEqual(pd.PriceDpConfig(mul_stages=2).lat_dp, 7)

    def test_end_to_end_bias_under_1pct(self):
        lut = GaussLut(GaussLutConfig(10, 16, 12))
        for label, *args in OPTION_GRID:
            ref = bs_call(*args)
            self.assertLess(abs(pd.exact_price(*args, CFG, lut) - ref) / ref, 0.01, label)


class TestAccumulator(unittest.TestCase):
    def test_gaps_and_clear_priority(self):
        p = [5, 7, 9, 11, 13]
        v = [1, 0, 1, 1, 1]
        c = [0, 0, 0, 1, 0]          # clear on cycle 3 wins over that cycle's valid
        out = pd.accumulate(p, v, c)
        self.assertEqual([o[:2] for o in out], [(5, 1), (5, 1), (14, 2), (0, 0), (13, 1)])

    def test_lanes_popcount(self):
        p = [[1, 2, 3, 4], [10, 20, 30, 40]]
        v = [[1, 1, 1, 1], [1, 1, 0, 0]]   # last beat masks lanes 2-3
        s, n, *_ = pd.accumulate(p, v)[-1]
        self.assertEqual((s, n), (10 + 30, 6))

    def test_overflow_sticky(self):
        cycles = 1100                       # 1100 * (2^22-1) > 2^32
        out = pd.accumulate([pd.ST_FMT.max_raw] * cycles, [1] * cycles, sum_width=32)
        first = next(i for i, o in enumerate(out) if o[2])
        self.assertEqual(first, (1 << 32) // pd.ST_FMT.max_raw)
        self.assertTrue(all(o[2] for o in out[first:]))

    def test_sat_flags_need_valid(self):
        out = pd.accumulate([0, 0], [0, 1], sat_x=[1, 0], sat_s=[0, 1])
        self.assertEqual(out[0][3:], (False, False))
        self.assertEqual(out[1][3:], (False, True))


if __name__ == "__main__":
    unittest.main()
