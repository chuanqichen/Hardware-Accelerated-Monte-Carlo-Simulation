from pathlib import Path
import tempfile
import unittest

from parse_smoke_reports import read_smoke
from parse_reports import parse_qor


class TestSmokeReportParsing(unittest.TestCase):
    def test_violations_survive_summary(self):
        with tempfile.TemporaryDirectory() as directory:
            run = Path(directory)
            (run / "inputs.txt").write_text("top=mc_controller\ncorner_label=typical\nclock_period_ns=10.0\n")
            (run / "qor.rpt").write_text(
                "Cell Area: 3405.240777\nCritical Path Length: 5.16\nCritical Path Slack: 4.52\n"
                "Worst Hold Violation: -0.20\nNo. of Hold Violations: 102.00\n"
                "Max Cap Violations: 183\nMax Trans Violations: 0\n")
            self.assertEqual(parse_qor(run / "qor.rpt")["result"], "mapped_with_violations")
            row = read_smoke(run)
            self.assertEqual(row["result"], "mapped_with_violations")
            self.assertEqual(row["worst_hold_slack_ns"], -0.20)
            self.assertEqual(row["hold_violating_paths"], 102)
            self.assertEqual(row["max_cap_violations"], 183)
            (run / "qor.rpt").write_text("Cell Area: 3405.240777\n")
            with self.assertRaisesRegex(ValueError, "missing numeric field"):
                read_smoke(run)




class TestReportDirectorySelection(unittest.TestCase):
    def test_single_run_excludes_siblings_and_parent_mode_remains_supported(self):
        import contextlib
        import csv
        import io
        import shutil
        from unittest.mock import patch
        import parse_reports

        fixture = Path(__file__).resolve().parents[1] / "reports/syn/rng_validation"
        with tempfile.TemporaryDirectory() as directory:
            parent = Path(directory) / "syn"
            first, second = parent / "first_run", parent / "second_run"
            first.mkdir(parents=True)
            second.mkdir()
            for target in (first, second):
                for name in ("summary.txt", "qor.rpt", "power.rpt", "timing.rpt"):
                    shutil.copyfile(fixture / name, target / name)
            output = Path(directory) / "parsed.csv"
            for source, count in ((first, 1), (parent, 2)):
                with patch("sys.argv", ["parser", "--syn", str(source), "--out", str(output)]), \
                     contextlib.redirect_stdout(io.StringIO()):
                    parse_reports.main()
                with output.open() as stream:
                    rows = list(csv.DictReader(stream))
                self.assertEqual(len(rows), count)
                self.assertTrue(all(row["result"] == "mapped_with_violations" for row in rows))
                self.assertTrue(all(row["max_cap_violations"] == "516" for row in rows))


if __name__ == "__main__":
    unittest.main()
