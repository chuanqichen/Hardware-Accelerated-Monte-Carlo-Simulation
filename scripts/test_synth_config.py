"""Exercise plain Tcl setup validation, not a replacement for licensed DC."""
from pathlib import Path
import tempfile
import tkinter
import unittest


ROOT = Path(__file__).resolve().parents[1]


class TestSynthesisSetup(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.library = self.directory / "test library.db"
        self.library.write_bytes(b"setup test only, not a timing library")
        self.tcl = tkinter.Tcl()
        for key in ("MC_TARGET_LIBS", "MC_CORNER", "MC_TOP", "MC_CLOCK_NS", "MC_RUN_ID"):
            self.tcl.eval(f"unset -nocomplain ::env({key})")
        self.tcl.call("source", str(ROOT / "scripts/syn/config.tcl"))
        self.tcl.setvar("env(MC_TARGET_LIBS)", self.tcl.call("list", str(self.library)))
        self.tcl.setvar("env(MC_CORNER)", "test-only")
        self.tcl.setvar("env(MC_RUN_ID)", "configuration_test")

    def config(self):
        return self.tcl.call("mc_synth_config", str(ROOT))

    def test_explicit_library_path_with_spaces_and_baseline(self):
        cfg = self.config()
        self.assertEqual(self.tcl.call("dict", "get", cfg, "top"), "gauss_lut")
        self.assertEqual(float(self.tcl.call("dict", "get", cfg, "period")), 10.0)
        sources = self.tcl.splitlist(self.tcl.call("dict", "get", cfg, "sources"))
        self.assertEqual([Path(str(path)).name for path in sources], ["gauss_lut_rom.sv", "gauss_lut.sv"])

    def test_missing_library_and_corner_fail_before_creating_output(self):
        for key in ("MC_TARGET_LIBS", "MC_CORNER"):
            with self.subTest(key=key):
                value = self.tcl.getvar(f"env({key})")
                self.tcl.eval(f"unset ::env({key})")
                with self.assertRaisesRegex(tkinter.TclError, f"{key} is required"):
                    self.config()
                self.tcl.setvar(f"env({key})", value)

    def test_nonexistent_library_rejected(self):
        self.tcl.setvar("env(MC_TARGET_LIBS)", str(self.directory / "missing.db"))
        with self.assertRaisesRegex(tkinter.TclError, "Missing standard-cell"):
            self.config()

    def test_controller_has_no_pricing_mock_sources(self):
        self.tcl.setvar("env(MC_TOP)", "mc_controller")
        cfg = self.config()
        sources = self.tcl.splitlist(self.tcl.call("dict", "get", cfg, "sources"))
        self.assertEqual([Path(str(path)).name for path in sources], ["mc_controller.sv"])

    def test_integrated_top_uses_package_and_real_backend_without_mock(self):
        self.tcl.setvar("env(MC_TOP)", "mc_top")
        cfg = self.config()
        sources = self.tcl.splitlist(self.tcl.call("dict", "get", cfg, "sources"))
        sources = [Path(str(path)).as_posix() for path in sources]
        self.assertTrue(sources[0].endswith("rtl/mc_pkg.sv"))
        self.assertTrue(any(path.endswith("rtl/mc_lane_array.sv") for path in sources))
        self.assertTrue(any(path.endswith("rtl/accumulator.sv") for path in sources))
        self.assertTrue(all("/tb/" not in path for path in sources))

    def test_unknown_top_rejected(self):
        self.tcl.setvar("env(MC_TOP)", "missing_top")
        with self.assertRaisesRegex(tkinter.TclError, "MC_TOP must be"):
            self.config()

    def test_invalid_periods_and_run_path_rejected(self):
        for period in ("0", "-1", "Inf", "NaN", "five"):
            with self.subTest(period=period):
                self.tcl.setvar("env(MC_CLOCK_NS)", period)
                with self.assertRaises(tkinter.TclError):
                    self.config()
        self.tcl.setvar("env(MC_CLOCK_NS)", "5.0")
        for run_id in ("../escape", "folder/name", ".", "", "a b"):
            with self.subTest(run_id=run_id):
                self.tcl.setvar("env(MC_RUN_ID)", run_id)
                with self.assertRaisesRegex(tkinter.TclError, "MC_RUN_ID"):
                    self.config()

    def test_existing_run_evidence_cannot_be_overwritten(self):
        root = self.directory / "repo"
        (root / "rtl").mkdir(parents=True)
        (root / "rtl/mc_controller.sv").write_text("module mc_controller; endmodule")
        (root / "reports/syn/configuration_test").mkdir(parents=True)
        self.tcl.setvar("env(MC_TOP)", "mc_controller")
        with self.assertRaisesRegex(tkinter.TclError, "already exists"):
            self.tcl.call("mc_synth_config", str(root))


if __name__ == "__main__":
    unittest.main()
