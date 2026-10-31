"""RNG algorithm, control policy, and generated artifact regression tests."""
from pathlib import Path
import random
import unittest

from rng_canonical_reference import canonical_next
from rng_lane import LAT_RNG, MASK32, RngLane, next_word, pack_state, unpack_state
from gen_rng_vectors import vector_text


class TestRngAlgorithm(unittest.TestCase):
    def test_seed_bus_order_and_validation(self):
        state = (0x01234567, 0x89ABCDEF, 0x76543210, 0xFEDCBA98)
        packed = 0xFEDCBA987654321089ABCDEF01234567
        self.assertEqual(pack_state(state), packed)
        self.assertEqual(unpack_state(packed), state)
        for state in [(1, 2, 3), (-1, 0, 0, 0), (1 << 32, 0, 0, 0)]:
            with self.assertRaises(ValueError):
                next_word(state)
        for packed in [-1, 1 << 128]:
            with self.assertRaises(ValueError):
                unpack_state(packed)

    def test_canonical_first_word_and_transition(self):
        self.assertEqual(next_word((1, 2, 3, 4)),
                         (0x281, (7, 0, 0x402, 0x3000)))
        # Both output additions must wrap before/after rotation respectively.
        self.assertEqual(next_word((MASK32,) * 4)[0], 0xFFFFFF7E)
        self.assertEqual(next_word((0, 0, 0, 0)), (0, (0, 0, 0, 0)))

    def test_independent_canonical_sequences(self):
        rng = random.Random(128)
        seeds = [(1, 2, 3, 4), (MASK32,) * 4]
        seeds += [tuple((1 << bit) if i == word else 0 for i in range(4))
                  for word in range(4) for bit in range(32)]
        seeds += [tuple(rng.getrandbits(32) for _ in range(4)) for _ in range(64)]
        for seed in seeds:
            state = reference = seed
            for _ in range(256):
                got, state = next_word(state)
                expected, reference = canonical_next(reference)
                self.assertEqual((got, state), (expected, reference))
        state = reference = (1, 2, 3, 4)
        for _ in range(10000):
            got, state = next_word(state)
            expected, reference = canonical_next(reference)
            self.assertEqual((got, state), (expected, reference))


class TestRngControl(unittest.TestCase):
    def setUp(self):
        self.lane = RngLane()
        self.seed = (1, 2, 3, 4)
        self.packed = pack_state(self.seed)

    def test_continuous_one_stage(self):
        self.assertEqual(LAT_RNG, 1)
        self.assertEqual(self.lane.tick(seed_load=True, seed_state=self.packed), (False, 0))
        state = self.seed
        for _ in range(1000):
            expected, state = canonical_next(state)
            self.assertEqual(self.lane.tick(run=True), (True, expected))
            self.assertEqual(self.lane.state, state)

    def test_pause_resume_and_ignored_seed_bus(self):
        self.lane.tick(seed_load=True, seed_state=self.packed)
        self.lane.tick(run=True)
        saved_state, saved_u = self.lane.state, self.lane.u
        for _ in range(20):
            self.assertEqual(self.lane.tick(seed_state=(1 << 128) - 1), (False, saved_u))
            self.assertEqual(self.lane.state, saved_state)
        expected, state = canonical_next(saved_state)
        self.assertEqual(self.lane.tick(run=True, seed_state=0), (True, expected))
        self.assertEqual(self.lane.state, state)

    def test_reseed_and_load_priority(self):
        for _ in range(2):
            self.assertEqual(self.lane.tick(seed_load=True, run=True, seed_state=self.packed), (False, 0))
            self.assertEqual(self.lane.state, self.seed)
            self.assertEqual(self.lane.tick(run=True), (True, 0x281))
            for _ in range(8):
                self.lane.tick(run=True)
        other = (MASK32, 0x80000000, 3, 4)
        self.lane.tick(seed_load=True, run=True, seed_state=pack_state(other))
        self.assertEqual(self.lane.state, other)
        self.assertEqual(self.lane.tick(run=True)[1], canonical_next(other)[0])

    def test_reset_priority_and_recovery(self):
        self.lane.tick(seed_load=True, seed_state=self.packed)
        self.lane.tick(run=True)
        self.assertEqual(self.lane.tick(rst_n=False, seed_load=True,
                                       run=True, seed_state=self.packed), (False, 0))
        self.assertEqual(self.lane.state, (0, 0, 0, 0))
        self.assertEqual(self.lane.tick(run=True), (False, 0))
        self.lane.tick(seed_load=True, seed_state=self.packed)
        self.lane.tick(run=True)
        self.lane.reset()  # asynchronous assertion without a clock step
        self.assertEqual((self.lane.state, self.lane.u, self.lane.u_valid),
                         ((0, 0, 0, 0), 0, False))

    def test_zero_seed_inhibits_and_replaces_active_state(self):
        self.assertEqual(self.lane.tick(run=True), (False, 0))
        self.lane.tick(seed_load=True, seed_state=self.packed)
        self.lane.tick(run=True)
        self.assertEqual(self.lane.tick(seed_load=True, run=True, seed_state=0), (False, 0))
        for _ in range(20):
            self.assertEqual(self.lane.tick(run=True), (False, 0))
            self.assertEqual(self.lane.state, (0, 0, 0, 0))
        self.lane.tick(seed_load=True, seed_state=self.packed)
        self.assertEqual(self.lane.tick(run=True), (True, 0x281))

    def test_generated_vectors_against_independent_scoreboard(self):
        text = vector_text()
        path = Path(__file__).resolve().parents[1] / "tb/vectors/rng_lane.hex"
        self.assertEqual(path.read_text(encoding="ascii"), text,
                         "regenerate RNG vectors with make rng-gen")
        state, held_u = (0, 0, 0, 0), 0
        n_valid = 0
        for row in text.splitlines():
            rst_n, load, run, seed, valid, u, packed_state = [int(v, 16) for v in row.split()]
            want_valid = 0
            if not rst_n:
                state, held_u = (0, 0, 0, 0), 0
            elif load:
                # Independent seed bus extraction, without unpack_state().
                state = tuple((seed >> (i * 32)) & 0xFFFFFFFF for i in range(4))
                held_u = 0
            elif run and state != (0, 0, 0, 0):
                held_u, state = canonical_next(state)
                want_valid = 1
            n_valid += want_valid
            self.assertEqual((valid, u), (want_valid, held_u))
            want_state = state[0] | state[1] << 32 | state[2] << 64 | state[3] << 96
            self.assertEqual(packed_state, want_state)
        self.assertGreater(n_valid, 1000)


if __name__ == "__main__":
    unittest.main()
