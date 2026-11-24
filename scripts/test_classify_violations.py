"""Check that violation classification keeps every row and separates zero library limits."""
from pathlib import Path
import unittest

from classify_violations import parse, summarize

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = """****************************************
Report : constraint
	-all_violators
****************************************

   min_delay/hold ('clk' group)

   Endpoint                                                  Slack
   -----------------------------------------------------------------
   u_lanes/u_gauss/z_reg_11_/D                            -0.022807 (VIOLATED)
   u_lanes/u_price/acc_r_reg_0__0_/D                      -0.011447 (VIOLATED)


   max_capacitance

                             Required        Actual
   Pin                      Capacitance    Capacitance       Slack
   -----------------------------------------------------------------
   u_lanes/u_price/u_exp/u_rom/U955/Y 0.000000 0.046920   -0.046920 (VIOLATED)
   u_controller/U9/Y         0.137429       0.140000      -0.002571 (VIOLATED)


   max_fanout

                             Required        Actual
   Pin                        Fanout         Fanout          Slack
   -----------------------------------------------------------------
   U1515/Y                  16.000000      67.000000      -51.000000 (VIOLATED)
"""


class TestViolationClassification(unittest.TestCase):
    def test_rows_are_counted_and_zero_limits_are_separate(self):
        summary = summarize(parse(FIXTURE))
        self.assertEqual(summary["min_delay/hold"]["count"], 2)
        self.assertAlmostEqual(summary["min_delay/hold"]["worst_slack"], -0.022807)
        self.assertEqual(summary["min_delay/hold"]["endpoints"][0], "u_lanes/u_gauss/z_reg_11_/D")
        cap = summary["max_capacitance"]
        self.assertEqual((cap["count"], cap["zero_library_limit"], cap["positive_limit"]), (2, 1, 1))
        self.assertAlmostEqual(cap["positive_limit_worst_slack"], -0.002571)
        self.assertEqual(summary["max_fanout"]["count"], 1)
        self.assertEqual(summary["max_fanout"]["worst_actual"], 67.0)

    def test_unrecognized_violation_rows_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "Unrecognized violation row"):
            parse("   max_fanout\n   odd row text (VIOLATED)\n")
        with self.assertRaisesRegex(ValueError, "before any constraint section"):
            parse("   U1/Y 16 17 -1 (VIOLATED)\n")

    def test_archived_routed_report_has_only_zero_limit_capacitance_rows(self):
        report = ROOT / "reports/sta/setupfix_v1_20261123_l1_routed_validated/violators.rpt"
        if not report.is_file():
            self.skipTest("archived PR #22 report not present")
        summary = summarize(parse(report.read_text()))
        cap = summary["max_capacitance"]
        self.assertEqual(cap["count"], cap["zero_library_limit"])
        self.assertEqual(cap["positive_limit"], 0)
        self.assertEqual(summary["min_delay/hold"]["count"], 33)
        self.assertEqual(summary["max_fanout"]["count"], 160)


if __name__ == "__main__":
    unittest.main()
