from pathlib import Path
import tempfile
import unittest

from parse_smoke_reports import read_smoke
from parse_reports import parse_qor
from summarize_multilane import normalize_sdc, verified_digest


class TestImplementationInputs(unittest.TestCase):
    def test_changed_input_is_rejected_including_compressed_archives(self):
        import gzip
        import hashlib
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "design.spef"
            data = b"known extracted network\n"
            expected = hashlib.sha256(data).hexdigest()
            path.write_bytes(data)
            self.assertEqual(verified_digest(path, expected), expected)
            path.unlink()
            with gzip.open(str(path) + ".gz", "wb") as stream:
                stream.write(data)
            self.assertEqual(verified_digest(path, expected), expected)
            with gzip.open(str(path) + ".gz", "wb") as stream:
                stream.write(b"different network\n")
            with self.assertRaisesRegex(ValueError, "digest mismatch"):
                verified_digest(path, expected)

    def test_sdc_translation_preserves_timing_and_electrical_constraints(self):
        text = ("current_design mc_top\ncreate_clock -period 5 clk\n"
                "set_max_fanout 16 [get_designs {mc_top}]\n"
                "set_clock_uncertainty 0.1 [get_clocks clk]\n")
        self.assertEqual(normalize_sdc(text),
                         "# mc_top already selected by link_design\ncreate_clock -period 5 clk\n"
                         "set_max_fanout 16 [current_design]\n"
                         "set_clock_uncertainty 0.1 [get_clocks clk]\n\n")
        with self.assertRaisesRegex(ValueError, "unexpected design"):
            normalize_sdc("current_design other_top\n")


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
