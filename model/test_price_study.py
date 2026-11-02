"""Unit tests for price_study.py helpers.  Run: make test"""
import unittest

import numpy as np

import price_study as ps
from mc_lane import rng_stream
from rng_lane import next_word

SEED = (0x12345678, 0x9ABCDEF0, 0x0F1E2D3C, 0x4B5A6978)


class TestStreams(unittest.TestCase):
    def test_vectorised_stream_matches_reference(self):
        n = 300
        got = ps.xoshiro_streams([SEED], n)[0]
        np.testing.assert_array_equal(got, rng_stream(SEED, n))

    def test_two_streams_are_independent_rows(self):
        other = (1, 2, 3, 4)
        got = ps.xoshiro_streams([SEED, other], 100)
        np.testing.assert_array_equal(got[0], rng_stream(SEED, 100))
        np.testing.assert_array_equal(got[1], rng_stream(other, 100))

    def test_jump_is_a_state_advance(self):
        # jump() must map onto the same orbit: the jumped state, stepped forward,
        # stays a valid xoshiro state (nonzero) and differs from the root sequence.
        j = ps.jump(SEED)
        self.assertNotEqual(j, SEED)
        self.assertTrue(any(j))
        a = rng_stream(SEED, 64)
        b = rng_stream(j, 64)
        self.assertFalse(np.array_equal(a, b))

    def test_jump_linear_in_state(self):
        # jump is a linear map over GF(2): jump(x ^ y) == jump(x) ^ jump(y).
        x, y = SEED, (0xDEADBEEF, 0x01234567, 0x89ABCDEF, 0x0F0F0F0F)
        xy = tuple(a ^ b for a, b in zip(x, y))
        jx, jy, jxy = ps.jump(x), ps.jump(y), ps.jump(xy)
        self.assertEqual(jxy, tuple(a ^ b for a, b in zip(jx, jy)))

    def test_jump_step_function_is_the_lane_transition(self):
        # jump() iterates the canonical state transition; it must be exactly the
        # one rng_lane.next_word implements, or the jumped streams are not on the
        # hardware's orbit.
        s = SEED
        for _ in range(50):
            self.assertEqual(ps._next_state(s), next_word(s)[1])
            s = next_word(s)[1]

    def test_lane_seeds_distinct(self):
        seeds = ps.lane_seeds(SEED, 8)
        self.assertEqual(len(set(seeds)), 8)
        self.assertEqual(seeds[0], SEED)
        self.assertEqual(seeds[2], ps.jump(ps.jump(SEED)))


class TestStudy(unittest.TestCase):
    def test_small_study_runs_and_is_sane(self):
        rows = ps.study(seeds=4, trials=4096, root=SEED, cfg=ps.LaneConfig())
        self.assertEqual(len(rows), 5)
        for r in rows:
            self.assertGreater(r["mc_se"], 0)
            self.assertLess(abs(r["bias_pct"]), 1.0)
            self.assertLess(abs(r["mc_mean"] - r["exact_hw"]), 6 * r["mc_se"])
            self.assertTrue(0 <= r["coverage"] <= 1)


if __name__ == "__main__":
    unittest.main()
