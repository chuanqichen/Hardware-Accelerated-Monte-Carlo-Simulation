"""Unit tests for the D-5 x-width study.  Run: make test"""
import unittest

import d5_x_width_study as d5
import price_dp as pd
from fxp import Fxp
from gauss_lut import OPTION_GRID, GaussLut, GaussLutConfig


class TestD5(unittest.TestCase):
    def test_baseline_format_reproduces_price_dp_exact_price(self):
        # At Q5.12 the study must be bit-identical to Eric's reference path.
        lut = GaussLut(GaussLutConfig(10, 16, 12))
        z = lut.fmt.quantize(lut.all_outputs())
        for _, *opt in OPTION_GRID:
            mine = d5.lane_price(*opt, z, Fxp(18, 12), d5.XCfg(x_frac=12))
            ref = pd.exact_price(*opt, pd.PriceDpConfig(), lut)
            self.assertAlmostEqual(mine, ref, places=12, msg=opt)

    def test_xcfg_y_frac_tracks_x_frac(self):
        self.assertEqual(d5.XCfg(x_frac=10).y_frac, 26)
        self.assertEqual(d5.XCfg(x_frac=12).y_frac, pd.PriceDpConfig().y_frac)

    def test_q4_11_equals_q5_11_on_grid(self):
        # The grid never leaves [-6.2, 9.7] in x, so the extra integer bit of Q5 is idle.
        lut = GaussLut(GaussLutConfig(10, 16, 12))
        z = lut.fmt.quantize(lut.all_outputs())
        for _, *opt in OPTION_GRID:
            self.assertEqual(d5.lane_price(*opt, z, Fxp(16, 11), d5.XCfg(x_frac=11)),
                             d5.lane_price(*opt, z, Fxp(17, 11), d5.XCfg(x_frac=11)))


if __name__ == "__main__":
    unittest.main()
