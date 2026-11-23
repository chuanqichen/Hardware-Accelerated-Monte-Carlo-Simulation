"""The approximation must affect exactly four numbers and be selected by default."""
import hashlib
from pathlib import Path
import re
import tempfile
import tkinter
import unittest

from fix_setup_library import ROOT, TECH, FIXED, NOTICE, NUMBER, repair, check_source


class TestSetupLibrary(unittest.TestCase):
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
                self.assertEqual(str(tcl.call("mc_library", str(ROOT), kind)),
                                 str(FIXED / ("gscl45nm." + kind)))
                tcl.setvar("env(LIB_" + kind.upper() + ")", "/explicit/original." + kind)
                self.assertEqual(str(tcl.call("mc_library", str(ROOT), kind)),
                                 "/explicit/original." + kind)
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
            # Keep this check independent of any host's explicit LIB_DB setting.
            original = tcl.getvar("env(LIB_DB)") if tcl.call("info", "exists", "env(LIB_DB)") else None
            tcl.call("unset", "-nocomplain", "env(LIB_DB)")
            try:
                tcl.call("mc_library", directory, "db")
                (folder / "gscl45nm.lib").write_text("edited source")
                with self.assertRaisesRegex(tkinter.TclError, "checksum mismatch"):
                    tcl.call("mc_library", directory, "db")
            finally:
                if original is not None:
                    tcl.setvar("env(LIB_DB)", original)


if __name__ == "__main__":
    unittest.main()
