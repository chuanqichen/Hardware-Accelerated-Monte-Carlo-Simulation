"""Unit tests for fxp.round_sat, the Python twin of rtl/round_sat.sv.  Run: make test

Each directed case is chosen so that a specific wrong implementation fails it:
round-half-up, round-half-away-from-zero, truncation toward zero, or saturating
before rounding.
"""
import unittest

import numpy as np

from fxp import Fxp, round_sat, round_shift_even

X_FMT = Fxp(18, 12)                 # price_dp S2 target: Q5.12
ST_FMT = Fxp(22, 8, signed=False)   # UQ14.8


def ref(x, shift, fmt):
    """Independent float reference: np.rint is round-half-to-even."""
    r = np.rint(np.asarray(x, dtype=np.float64) / 2.0 ** shift).astype(np.int64)
    return np.clip(r, fmt.min_raw, fmt.max_raw), (r < fmt.min_raw) | (r > fmt.max_raw)


class TestRoundHalfEven(unittest.TestCase):
    # shift = 2: x / 4; dropped bits are x[1:0], half = 0b10
    def check(self, x, expect, shift=2, fmt=Fxp(8, 0)):
        out, sat = round_sat(x, shift, fmt)
        self.assertEqual(int(out), expect, f"x={x}")
        self.assertFalse(bool(sat), f"x={x} must not saturate")

    def test_below_half_rounds_down(self):
        self.check(5, 1)      # 1.25 -> 1

    def test_above_half_rounds_up(self):
        self.check(7, 2)      # 1.75 -> 2

    def test_tie_even_quotient_stays(self):
        self.check(10, 2)     # 2.5 -> 2   (half-up would give 3)

    def test_tie_odd_quotient_rounds_up(self):
        self.check(6, 2)      # 1.5 -> 2   (half-down would give 1)

    def test_negative_tie_even_quotient(self):
        self.check(-10, -2)   # -2.5 -> -2 (half-away-from-zero would give -3)

    def test_negative_tie_odd_quotient(self):
        self.check(-6, -2)    # -1.5 -> -2

    def test_negative_above_half_floors_then_rounds(self):
        self.check(-7, -2)    # -1.75 -> -2 (truncation toward zero would give -1)

    def test_negative_below_half(self):
        self.check(-5, -1)    # -1.25 -> -1

    def test_shift_one_tie(self):
        # shift = 1: half is the only dropped bit. 3/2 = 1.5 -> 2, 5/2 = 2.5 -> 2
        self.check(3, 2, shift=1)
        self.check(5, 2, shift=1)
        self.check(-3, -2, shift=1)

    def test_shift_zero_is_identity(self):
        x = np.array([-128, -1, 0, 1, 127])
        self.assertEqual(round_shift_even(x, 0).tolist(), x.tolist())


class TestSaturation(unittest.TestCase):
    def test_round_up_carries_into_saturation(self):
        # (max * 4) + 3 = max + 0.75 -> rounds to max + 1 -> clamp. Saturating the
        # input before rounding would miss this (input < max*4 + 4).
        x = X_FMT.max_raw * 4 + 3
        out, sat = round_sat(x, 2, X_FMT)
        self.assertEqual((int(out), bool(sat)), (X_FMT.max_raw, True))

    def test_exactly_max_does_not_saturate(self):
        out, sat = round_sat(X_FMT.max_raw * 4, 2, X_FMT)
        self.assertEqual((int(out), bool(sat)), (X_FMT.max_raw, False))

    def test_max_plus_half_tie_stays_at_max(self):
        # max is odd (2^17 - 1), so max + 0.5 ties up to max + 1 -> saturate
        out, sat = round_sat(X_FMT.max_raw * 4 + 2, 2, X_FMT)
        self.assertEqual((int(out), bool(sat)), (X_FMT.max_raw, True))

    def test_below_min_saturates(self):
        out, sat = round_sat(X_FMT.min_raw * 4 - 4, 2, X_FMT)
        self.assertEqual((int(out), bool(sat)), (X_FMT.min_raw, True))

    def test_exactly_min_does_not_saturate(self):
        out, sat = round_sat(X_FMT.min_raw * 4, 2, X_FMT)
        self.assertEqual((int(out), bool(sat)), (X_FMT.min_raw, False))

    def test_min_minus_half_tie_stays_at_min(self):
        # min is even, so min - 0.5 ties to min: no saturation
        out, sat = round_sat(X_FMT.min_raw * 4 - 2, 2, X_FMT)
        self.assertEqual((int(out), bool(sat)), (X_FMT.min_raw, False))

    def test_unsigned_negative_input_clamps_to_zero(self):
        # -1/4 = -0.25 rounds to 0: in range, no flag. -4/4 = -1 and -1000/4 = -250
        # are below 0 and must clamp with the flag set.
        out, sat = round_sat(np.array([-1, -4, -1000]), 2, ST_FMT)
        self.assertEqual(out.tolist(), [0, 0, 0])
        self.assertEqual(sat.tolist(), [False, True, True])

    def test_unsigned_overflow(self):
        out, sat = round_sat((ST_FMT.max_raw + 1) << 8, 8, ST_FMT)
        self.assertEqual((int(out), bool(sat)), (ST_FMT.max_raw, True))

    def test_shift_zero_pure_saturate(self):
        x = np.array([X_FMT.min_raw - 1, X_FMT.min_raw, 0, X_FMT.max_raw, X_FMT.max_raw + 1])
        out, sat = round_sat(x, 0, X_FMT)
        self.assertEqual(out.tolist(), [X_FMT.min_raw, X_FMT.min_raw, 0, X_FMT.max_raw, X_FMT.max_raw])
        self.assertEqual(sat.tolist(), [True, False, False, False, True])


class TestAgainstReference(unittest.TestCase):
    def test_random_signed_price_dp_s2(self):
        # The real instance: Q5.26 (34 b) -> Q5.12 (18 b), shift 14
        rng = np.random.default_rng(382)
        x = rng.integers(-(1 << 33), 1 << 33, size=100_000, dtype=np.int64)
        out, sat = round_sat(x, 14, X_FMT)
        r_out, r_sat = ref(x, 14, X_FMT)
        np.testing.assert_array_equal(out, r_out)
        np.testing.assert_array_equal(sat, r_sat)
        self.assertTrue(sat.any() and not sat.all())

    def test_random_near_saturation_boundaries(self):
        rng = np.random.default_rng(7)
        for edge in (X_FMT.max_raw, X_FMT.min_raw):
            x = (edge << 14) + rng.integers(-(1 << 16), 1 << 16, size=20_000, dtype=np.int64)
            out, sat = round_sat(x, 14, X_FMT)
            r_out, r_sat = ref(x, 14, X_FMT)
            np.testing.assert_array_equal(out, r_out)
            np.testing.assert_array_equal(sat, r_sat)

    def test_random_unsigned(self):
        rng = np.random.default_rng(11)
        x = rng.integers(-(1 << 20), 1 << 31, size=100_000, dtype=np.int64)
        out, sat = round_sat(x, 8, ST_FMT)
        r_out, r_sat = ref(x, 8, ST_FMT)
        np.testing.assert_array_equal(out, r_out)
        np.testing.assert_array_equal(sat, r_sat)

    def test_scalar_and_array_agree(self):
        xs = [-7, -6, -5, 5, 6, 7, 10, -10]
        vec_out, vec_sat = round_sat(np.array(xs), 2, X_FMT)
        for x, vo, vs in zip(xs, vec_out, vec_sat):
            so, ss = round_sat(x, 2, X_FMT)
            self.assertEqual((int(so), bool(ss)), (int(vo), bool(vs)))


if __name__ == "__main__":
    unittest.main()
