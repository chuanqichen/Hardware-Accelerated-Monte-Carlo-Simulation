"""The approximation must affect exactly four numbers and be selected by default."""
import hashlib
import csv
import json
from pathlib import Path
import re
import tempfile
import tkinter
import unittest
from unittest.mock import patch

from fix_setup_library import ROOT, TECH, FIXED, NOTICE, NUMBER, repair, check_source
from summarize_multilane import library_label, collect_run, digests, markdown, timing_failures
from summarize_library_comparison import validate_sdc
from check_evidence_artifacts import build_products


class TestSetupLibrary(unittest.TestCase):
    def test_generated_results_expose_the_innovus_setup_failure(self):
        with (ROOT / "reports/multilane_setup_fixed_v1_runs.csv").open() as stream:
            run = list(csv.DictReader(stream))[-1]
        row = collect_run(run)
        self.assertGreater(row["pt_routed_setup_ns"], 0)
        self.assertAlmostEqual(row["innovus_setup_ns"], -0.019)
        self.assertEqual(row["innovus_setup_violating_paths"], 2)
        self.assertEqual(row["routed_setup_hold_pass_both_tools"], 0)
        table = markdown([row])
        self.assertIn("Innovus setup (ns)", table)
        self.assertIn("-0.019", table)
        self.assertIn("Open timing: setup (lanes 4)", table)

    def test_rounded_zero_wns_does_not_hide_a_violation(self):
        row = dict(pt_routed_setup_ns=0.1, pt_routed_hold_ns=0.1,
                   innovus_setup_ns=0.0, innovus_hold_ns=0.1,
                   innovus_setup_violating_paths=1, innovus_hold_violating_paths=0)
        self.assertEqual(timing_failures(row), ["setup"])

    def test_build_products_are_not_archival_evidence(self):
        generated = ["reports/sim/run/simv", "reports/sim/run/simv.daidir/data",
                     "reports/sim/run/csrc/generated.c", "reports/sim/run/helper.so",
                     "reports/sim/run/helper.o", "reports/sim/run/archive.a",
                     "reports/syn/run/work/generated", "reports/syn/run/MC_TOP.mr"]
        evidence = ["reports/sim/run/run.log", "reports/sim/run/compile.log",
                    "reports/sim/run/activity.txt", "reports/sim/run/cycles.csv",
                    "reports/sim/run/source_sha256.txt", "reports/pnr/run/mc_top.routed.v.gz",
                    "tech/gscl45nm/setup_fixed_v1/gscl45nm.db"]
        self.assertEqual(build_products(generated + evidence), generated)

    def test_result_collector_rejects_dc_pt_library_mismatch(self):
        run = dict(lanes="1", syn_tag="implementation_20261123_l1",
                   pnr_tag="implementation_20261123_l1_try3",
                   pt_routed_tag="implementation_20261123_l1_validated",
                   sim_mapped_tag="implementation_20261123_l1_mapped",
                   sim_routed_tag="implementation_20261123_l1_routed")
        def changed_library(path):
            return {"wrong.db": "0" * 64} if path.name == "library_sha256.txt" else digests(path)
        with patch("summarize_multilane.digests", side_effect=changed_library):
            with self.assertRaisesRegex(ValueError, "DC and PT libraries differ"):
                collect_run(run)

    def test_comparison_rejects_a_slew_workaround_or_clock_relaxation(self):
        sdc = (ROOT / "reports/syn/implementation_20261123_l1/mc_top.mapped.sdc").read_text()
        validate_sdc(sdc)
        with self.assertRaisesRegex(ValueError, "0.10 ns"):
            validate_sdc(sdc.replace("-max -rise 0.1", "-max -rise 0.06"))
        with self.assertRaisesRegex(ValueError, "5 ns"):
            validate_sdc(sdc.replace("-period 5 ", "-period 6 "))

    def test_result_collector_rejects_mixed_library_variants(self):
        compiled = json.loads((FIXED / "compiled.json").read_text())
        row = dict(library_db_sha256=compiled["db_sha256"],
                   library_lib_sha256=compiled["source_sha256"])
        self.assertEqual(library_label([row]), "setup_fixed_v1")
        original = hashlib.sha256((TECH / "original/gscl45nm.lib").read_bytes()).hexdigest()
        with self.assertRaisesRegex(ValueError, "Mixed original/corrected"):
            library_label([dict(row, library_lib_sha256=original)])
        with self.assertRaisesRegex(ValueError, "Mixed original/corrected"):
            library_label([dict(row, library_db_sha256="unmatched")])

    def test_exactly_four_numeric_changes_preserve_every_other_source_byte(self):
        original = (TECH / "original/gscl45nm.lib").read_bytes()
        fixed, changes = repair(original)
        self.assertEqual([entry["new_ns"] for entry in changes],
                         ["0.153125", "0.1640625", "0.1453125", "0.310227272727"])
        before = re.split("(" + NUMBER + ")", original.decode())
        after = re.split("(" + NUMBER + ")", fixed.decode()[len(NOTICE):])
        self.assertEqual(len(before), len(after))
        changed = [(a, b) for a, b in zip(before, after) if a != b]
        self.assertEqual(changed, [("6.2", "0.153125"), ("5.125", "0.1640625"),
                                   ("3.075", "0.1453125"), ("5.85", "0.310227272727")])
        self.assertEqual(fixed, (FIXED / "gscl45nm.lib").read_bytes())
        check_source()

    def test_unrecognized_source_is_rejected(self):
        original = (TECH / "original/gscl45nm.lib").read_bytes()
        with self.assertRaisesRegex(ValueError, "Unexpected original"):
            repair(original.replace(b"6.2,", b"6.3,", 1))

    def test_shared_default_and_explicit_overrides(self):
        tcl = tkinter.Tcl()
        tcl.call("source", str(ROOT / "scripts/syn/config.tcl"))
        saved = {}
        for key in ("LIB_DB", "LIB_LIB"):
            variable = "env(" + key + ")"
            if tcl.call("info", "exists", variable):
                saved[variable] = tcl.getvar(variable)
            tcl.call("unset", "-nocomplain", variable)
        try:
            for kind in ("db", "lib"):
                self.assertEqual(Path(str(tcl.call("mc_library", str(ROOT), kind))),
                                 FIXED / ("gscl45nm." + kind))
            for kind in ("db", "lib"):
                variable = "env(LIB_" + kind.upper() + ")"
                tcl.setvar(variable, str(TECH / "original" / ("gscl45nm." + kind)))
                for requested in ("db", "lib"):
                    with self.subTest(override=kind, requested=requested):
                        with self.assertRaisesRegex(tkinter.TclError, "Set both LIB_DB and LIB_LIB"):
                            tcl.call("mc_library", str(ROOT), requested)
                tcl.call("unset", variable)
            for kind in ("db", "lib"):
                tcl.setvar("env(LIB_" + kind.upper() + ")",
                           str(TECH / "original" / ("gscl45nm." + kind)))
            for kind in ("db", "lib"):
                self.assertEqual(Path(str(tcl.call("mc_library", str(ROOT), kind))),
                                 TECH / "original" / ("gscl45nm." + kind))
        finally:
            for key in ("LIB_DB", "LIB_LIB"):
                tcl.call("unset", "-nocomplain", "env(" + key + ")")
            for key, value in saved.items():
                tcl.setvar(key, value)

    def test_changed_source_cannot_silently_use_an_old_db(self):
        with tempfile.TemporaryDirectory(prefix="Library pair ") as directory:
            folder = Path(directory) / "tech/gscl45nm/setup_fixed_v1"
            folder.mkdir(parents=True)
            lines = []
            for name in ("gscl45nm.lib", "gscl45nm.db"):
                data = name.encode()
                (folder / name).write_bytes(data)
                lines.append(hashlib.sha256(data).hexdigest() + "  " + name)
            (folder / "SHA256SUMS").write_text("\n".join(lines) + "\n")
            tcl = tkinter.Tcl()
            tcl.call("source", str(ROOT / "scripts/syn/config.tcl"))
            # Keep this check independent of the host's explicit library pair.
            original = {}
            for variable in ("env(LIB_DB)", "env(LIB_LIB)"):
                if tcl.call("info", "exists", variable):
                    original[variable] = tcl.getvar(variable)
                tcl.call("unset", "-nocomplain", variable)
            try:
                tcl.call("mc_library", directory, "db")
                (folder / "gscl45nm.lib").write_text("edited source")
                with self.assertRaisesRegex(tkinter.TclError, "checksum mismatch"):
                    tcl.call("mc_library", directory, "db")
            finally:
                for variable, value in original.items():
                    tcl.setvar(variable, value)


if __name__ == "__main__":
    unittest.main()
