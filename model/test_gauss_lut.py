"""Unit tests for the Gaussian LUT model.  Run: python3 -m unittest model/test_gauss_lut.py"""
import unittest

import numpy as np

import gauss_lut as g
from fxp import Fxp


class TestFxp(unittest.TestCase):
    def test_round_half_even_and_saturate(self):
        f = Fxp(8, 4)
        self.assertEqual(f.quantize(0.03125), 0)       # 0.5 LSB -> even (0)
        self.assertEqual(f.quantize(0.09375), 2)       # 1.5 LSB -> even (2)
        self.assertEqual(f.quantize(100.0), f.max_raw)
        self.assertEqual(f.quantize(-100.0), f.min_raw)
        with self.assertRaises(OverflowError):
            f.quantize(100.0, saturate=False)

    def test_hex(self):
        f = Fxp(16, 12)
        self.assertEqual(f.to_hex(-5), "fffb")
        self.assertEqual(f.to_hex(0x34c1), "34c1")


class TestGaussLut(unittest.TestCase):
    def _check(self, cfg):
        lut = g.GaussLut(cfg)
        z = lut.all_outputs()
        self.assertTrue(np.all(np.diff(z) >= 0), "z must be monotonic in u")
        self.assertTrue(np.allclose(z, -z[::-1]), "z must be odd-symmetric")
        self.assertAlmostEqual(z.mean(), 0.0)
        self.assertLess(abs(z.var() - 1.0), 0.03)

    def test_rom_configs(self):
        for a in (6, 8, 10, 12):
            self._check(g.GaussLutConfig(a, 16, 12))

    def test_pwl_config(self):
        self._check(g.GaussLutConfig(8, 16, 12, "pwl", 6))

    def test_rom_matches_exact_quantile_at_midpoints(self):
        cfg = g.GaussLutConfig(10, 16, 12)
        lut = g.GaussLut(cfg)
        n = 1 << cfg.addr_bits
        u = (np.arange(n, dtype=np.uint64) << np.uint64(22)) | np.uint64(1 << 21)   # cell midpoints
        exact = g._inv_cdf((np.arange(n) + 0.5) / n)
        self.assertLess(np.abs(lut.lookup_real(u) - exact).max(), lut.fmt.lsb)

    def test_only_top_bits_matter_in_rom_mode(self):
        lut = g.GaussLut(g.GaussLutConfig(8, 16, 12))
        base = np.uint64(0xABCD0000)
        self.assertEqual(lut.lookup(base), lut.lookup(base | np.uint64(0x00FFFFFF)))

    def test_bs_price_sanity(self):
        # textbook value: S0=100, K=100, r=5%, sigma=20%, T=1 -> 10.4506
        self.assertAlmostEqual(g.bs_call(100, 100, 0.05, 0.2, 1.0), 10.4506, places=4)

    def test_round_shift_even(self):
        self.assertTrue(np.array_equal(g._round_shift_even(np.array([2, 6, 3, 7, -2, -6]), 2), [0, 2, 1, 2, 0, -2]))


if __name__ == "__main__":
    unittest.main()
