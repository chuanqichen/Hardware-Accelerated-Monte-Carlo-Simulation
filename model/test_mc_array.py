"""Check total-N partition and host seed policy against stream prefixes."""
import unittest

from mc_array import array_seeds, run_array
from mc_lane import trace_lane, run_lane
from price_dp import option_to_regs
from price_study import jump
from rng_lane import pack_state

ROOT_SEED = (0x12345678, 0x9abcdef0, 0x0f1e2d3c, 0x4b5a6978)
REGS = option_to_regs(100, 100, .05, .2, 1)


class TestArray(unittest.TestCase):
    def test_host_seed_words_use_canonical_jump(self):
        seeds = array_seeds(pack_state(ROOT_SEED), 4)
        state = ROOT_SEED
        for seed in seeds:
            self.assertEqual(seed, pack_state(state))
            state = jump(state)
        self.assertEqual(len(set(seeds)), 4)

    def test_one_lane_is_unchanged(self):
        self.assertEqual(run_array(*REGS, ROOT_SEED, 100, 1), run_lane(*REGS, ROOT_SEED, 100))

    def test_round_robin_prefix_includes_partial_beats(self):
        for lanes in (2, 4):
            streams = [trace_lane(*REGS, seed, 32) for seed in array_seeds(ROOT_SEED, lanes)]
            for n in (1, 2, 3, 4, 5, 31, 63):
                expected = sum(int(streams[i % lanes]["p"][i // lanes]) for i in range(n))
                result = run_array(*REGS, ROOT_SEED, n, lanes)
                self.assertEqual(result["payoff_sum"], expected, (lanes, n))
                self.assertEqual(result["trial_count"], n)

    def test_hardware_input_bounds(self):
        for lanes in (0, 3, 8):
            with self.assertRaises(ValueError):
                array_seeds(ROOT_SEED, lanes)
        for n in (0, -1, 1 << 32):
            with self.assertRaises(ValueError):
                run_array(*REGS, ROOT_SEED, n, 4)
        with self.assertRaises(ValueError):
            array_seeds(0, 4)


if __name__ == "__main__":
    unittest.main()
