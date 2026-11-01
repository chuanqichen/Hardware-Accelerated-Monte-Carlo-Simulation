from pathlib import Path
import tempfile
import unittest

from parse_reports import read_smoke


class TestSmokeReportParsing(unittest.TestCase):
    def test_violations_survive_summary(self):
        with tempfile.TemporaryDirectory() as directory:
            run = Path(directory)
            (run / "inputs.txt").write_text("top=mc_controller\ncorner_label=typical\nclock_period_ns=10.0\n")
            (run / "qor.rpt").write_text(
                "Cell Area: 3405.240777\nCritical Path Length: 5.16\nCritical Path Slack: 4.52\n"
                "Worst Hold Violation: -0.20\nNo. of Hold Violations: 102.00\n"
                "Max Cap Violations: 183\nMax Trans Violations: 0\n")
            row = read_smoke(run)
            self.assertEqual(row["result"], "mapped_with_violations")
            self.assertEqual(row["worst_hold_slack_ns"], -0.20)
            self.assertEqual(row["hold_violating_paths"], 102)
            self.assertEqual(row["max_cap_violations"], 183)
            (run / "qor.rpt").write_text("Cell Area: 3405.240777\n")
            with self.assertRaisesRegex(ValueError, "missing numeric field"):
                read_smoke(run)


if __name__ == "__main__":
    unittest.main()
