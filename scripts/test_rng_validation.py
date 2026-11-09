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


class TestRngReportLayout(unittest.TestCase):
    def test_synthesis_is_created_by_dc_and_parsed_as_one_run(self):
        import json
        from unittest.mock import patch
        import run_rng_validation as runner

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tag = "rng_validation"
            results_tag = "rng_20261108"
            sim = root / "reports/sim" / tag
            syn = root / "reports/syn" / tag
            (root / "Makefile").write_text("# test source\n")
            # A sibling synthesis report must never be parsed into this run.
            sibling = root / "reports/syn/other_run"
            sibling.mkdir(parents=True)
            (sibling / "summary.txt").write_text("unrelated report")
            calls = []

            def command(command, log, env=None, markers=(), **kwargs):
                command = list(map(str, command))
                calls.append((command, Path(log), env))
                if command[0] == "dc_shell":
                    self.assertFalse(syn.exists())  # DC rejects existing report directories.
                    self.assertEqual(env["REPORT_DIR"], str(syn))
                    syn.mkdir(parents=True)
                    (syn / "summary.txt").write_text("design rng_lane\n")
                if "scripts/parse_reports.py" in command:
                    self.assertEqual(command[command.index("--syn") + 1], str(syn))
                return ""

            with patch.object(runner, "ROOT", root), \
                 patch.object(runner.shutil, "which", return_value="/fake/tool"), \
                 patch.object(runner.subprocess, "check_output", return_value="fixture"), \
                 patch.object(runner, "run_logged", side_effect=command), \
                 patch.dict(runner.os.environ, {"VCS": "vcs", "DC_SHELL": "dc_shell"}), \
                 patch.object(runner.sys, "argv", ["runner", "--results-tag", results_tag, "--words", "20480", "--streams", "1"]):
                self.assertEqual(runner.main(), 0)
            manifest = json.loads((sim / "manifest.json").read_text())
            self.assertEqual(manifest["report_paths"]["simulation"], f"reports/sim/{tag}")
            self.assertEqual(manifest["report_paths"]["synthesis"], f"reports/syn/{tag}")
            self.assertEqual(manifest["status"], "validation_completed")
            self.assertEqual(manifest["results_prefix"], f"results/{results_tag}")
            quality = next(cmd for cmd, log, env in calls if "model/rng_quality.py" in cmd)
            self.assertEqual(quality[quality.index("--out-prefix") + 1], str(root / "results" / results_tag))
            parser = next(cmd for cmd, log, env in calls if "scripts/parse_reports.py" in cmd)
            self.assertEqual(parser[parser.index("--out") + 1], str(root / "results" / (results_tag + "_ppa.csv")))
            self.assertEqual(next(log for cmd, log, env in calls if cmd[0] == "dc_shell"),
                             syn / "synthesis.log")
            self.assertTrue(all(sim in log.parents or syn in log.parents for cmd, log, env in calls))
            self.assertEqual((sibling / "summary.txt").read_text(), "unrelated report")

    def test_existing_evidence_is_rejected_before_creating_simulation(self):
        from unittest.mock import patch
        import run_rng_validation as runner
        for obstacle in ("synthesis", "results"):
            with self.subTest(obstacle=obstacle), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                sentinel = (root / "reports/syn/existing/keep" if obstacle == "synthesis"
                            else root / "results/rng_20261108_summary.csv")
                sentinel.parent.mkdir(parents=True)
                sentinel.write_text("old evidence")
                with patch.object(runner, "ROOT", root), \
                     patch.object(runner.shutil, "which", return_value="/fake/tool"), \
                     patch.object(runner.sys, "argv", ["runner", "--tag", "existing",
                                                      "--results-tag", "rng_20261108"]), \
                     self.assertRaises(SystemExit):
                    runner.main()
                self.assertFalse((root / "reports/sim/existing").exists())
                self.assertEqual(sentinel.read_text(), "old evidence")
