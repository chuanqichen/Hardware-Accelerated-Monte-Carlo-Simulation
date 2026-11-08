"""A zero simulator exit code must not hide a failed regression."""
from pathlib import Path
import sys
import tempfile
import unittest
from run_rng_validation import run_logged


class TestRngRunnerEvidence(unittest.TestCase):
    def test_only_explicit_success_is_accepted(self):
        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "run.log"
            run_logged([sys.executable, "-c", "print('PASS checked=5')"], log,
                       markers=(r"^PASS checked=5$",))
            for message in ("FAIL: bad data", "Fatal: after PASS", "Error-[compile]"):
                with self.subTest(message=message), self.assertRaises(RuntimeError):
                    run_logged([sys.executable, "-c",
                                f"print('PASS checked=5'); print({message!r})"], log,
                               markers=(r"^PASS checked=5$",))
            with self.assertRaises(RuntimeError):
                run_logged([sys.executable, "-c", "print('nothing checked')"], log,
                           markers=(r"^PASS checked=5$",))
            with self.assertRaises(RuntimeError):
                run_logged([sys.executable, "-c", "raise SystemExit(1)"], log)
