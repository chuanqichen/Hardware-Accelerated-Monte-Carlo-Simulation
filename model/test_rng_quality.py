"""Check quality measurements against constructed streams and corrupt input."""
from pathlib import Path
import tempfile
import unittest
import numpy as np

from rng_canonical_reference import canonical_next
from rng_quality import analyze_words, model_stream, read_stream, correlation, run_study


class TestQualityMeasurements(unittest.TestCase):
    def test_known_bins_and_bit_counts(self):
        words = np.tile(np.array([0, 1 << 30, 2 << 30, 3 << 30], dtype=np.uint32), 32)
        summary, bins, ones, lags = analyze_words(words, addr_bits=2, lags=(1, 2))
        np.testing.assert_array_equal(bins, [32] * 4)
        self.assertEqual(ones[30], 64)
        self.assertEqual(ones[31], 64)
        self.assertEqual(ones[0], 0)
        self.assertEqual(summary["chi2"], 0)
        self.assertAlmostEqual(summary["mean"], 0.375)
        self.assertFalse(summary["screening_pass"])
        self.assertEqual([row["lag"] for row in lags], [1, 2])

    def test_constant_and_alternating_streams_fail(self):
        for words in (np.zeros(20480, dtype=np.uint32),
                      np.tile(np.array([0, 0xffffffff], dtype=np.uint32), 10240)):
            summary, _, _, _ = analyze_words(words)
            self.assertFalse(summary["screening_pass"])
        self.assertAlmostEqual(correlation([1, 2, 3], [3, 2, 1]), -1)

    def test_duplicated_streams_fail_cross_stream_screen(self):
        import csv
        import json
        seed = (1, 2, 3, 4)
        words = model_stream(seed, 32768)
        with tempfile.TemporaryDirectory() as directory:
            prefix = Path(directory) / "fixture"
            self.assertFalse(run_study([words, words], [seed, seed], "test_fixture", prefix))
            with (Path(directory) / "fixture_cross_stream.csv").open() as data:
                row = next(csv.DictReader(data))
            self.assertEqual(row["screening_pass"], "False")
            manifest = json.loads((Path(directory) / "fixture_manifest.json").read_text())
            self.assertEqual(manifest["origin"], "test_fixture")
            self.assertFalse(manifest["screening_pass"])

    def test_invalid_data_rejected(self):
        for words in ([1], [1.5, 2.5], [-1, 2], [0, 2**32], [[1, 2], [3, 4]]):
            with self.subTest(words=words), self.assertRaises(ValueError):
                analyze_words(words, addr_bits=2, lags=(1,))

    def test_generator_matches_independent_oracle_and_repeats(self):
        seed = (1, 2, 3, 4)
        actual, expected, state = model_stream(seed, 1024), [], seed
        for _ in range(1024):
            word, state = canonical_next(state)
            expected.append(word)
        np.testing.assert_array_equal(actual, expected)
        np.testing.assert_array_equal(actual, model_stream(seed, 1024))


class TestStreamImport(unittest.TestCase):
    def test_exact_stream_and_corruption(self):
        seed = (1, 2, 3, 4)
        expected = model_stream(seed, 32)
        good = "".join(f"{int(word):08x}\n" for word in expected)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "stream.hex"
            path.write_text(good, encoding="ascii")
            np.testing.assert_array_equal(read_stream(path, 32, seed), expected)
            for bad in (good.rsplit("\n", 2)[0] + "\n", good + "00000000\n",
                        "garbage!\n" + good, "00000000\n" + good.split("\n", 1)[1]):
                path.write_text(bad, encoding="ascii")
                with self.subTest(bad=bad[:20]), self.assertRaises(ValueError):
                    read_stream(path, 32, seed)


if __name__ == "__main__":
    unittest.main()
