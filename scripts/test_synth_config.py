"""Check shared flow input contracts without consuming a DC license."""
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
        self.library.write_bytes(b"configuration test only")
        self.tcl = tkinter.Tcl()
        for key in ("DESIGN", "RTL_FILES", "LIB_DB", "TAG", "SDC", "REPORT_DIR", "CLK_PERIOD_NS", "PARAMS", "OPCOND"):
            self.tcl.eval(f"unset -nocomplain ::env({key})")
        self.tcl.call("source", str(ROOT / "scripts/syn/config.tcl"))
        self.tcl.setvar("env(LIB_DB)", str(self.library))
        self.tcl.setvar("env(TAG)", "configuration_test")

    def config(self):
        return self.tcl.call("mc_synth_config", str(ROOT))

    def sources(self, cfg):
        items = self.tcl.splitlist(self.tcl.call("dict", "get", cfg, "sources"))
        return [Path(str(path)).as_posix() for path in items]

    def test_library_path_with_spaces_and_shared_five_ns_default(self):
        cfg = self.config()
        self.assertEqual(self.tcl.call("dict", "get", cfg, "design"), "gauss_lut")
        self.assertEqual(float(self.tcl.call("dict", "get", cfg, "period")), 5.0)
        self.assertEqual([Path(p).name for p in self.sources(cfg)], ["mc_pkg.sv", "gauss_lut_rom.sv", "gauss_lut.sv"])

    def test_missing_library_rejected(self):
        self.tcl.setvar("env(LIB_DB)", str(self.directory / "missing.db"))
        with self.assertRaisesRegex(tkinter.TclError, "Missing standard-cell"):
            self.config()

    def test_missing_source_rejected(self):
        self.tcl.setvar("env(RTL_FILES)", "rtl/missing.sv")
        with self.assertRaisesRegex(tkinter.TclError, "Missing RTL"):
            self.config()

    def test_mock_source_rejected(self):
        self.tcl.setvar("env(RTL_FILES)", "tb/mocks/mc_lane_array.sv")
        with self.assertRaisesRegex(tkinter.TclError, "forbidden"):
            self.config()

    def test_controller_has_no_pricing_mock_sources(self):
        self.tcl.setvar("env(DESIGN)", "mc_controller")
        self.assertEqual([Path(p).name for p in self.sources(self.config())], ["mc_controller.sv"])

    def test_integrated_top_has_reset_package_and_real_backend(self):
        self.tcl.setvar("env(DESIGN)", "mc_top")
        sources = self.sources(self.config())
        self.assertTrue(sources[0].endswith("rtl/mc_pkg.sv"))
        for name in ("rst_sync.sv", "mc_lane_array.sv", "accumulator.sv"):
            self.assertIn(name, [Path(p).name for p in sources])
        self.assertTrue(all("/tb/" not in p for p in sources))

    def test_custom_design_requires_sources(self):
        self.tcl.setvar("env(DESIGN)", "missing_top")
        with self.assertRaisesRegex(tkinter.TclError, "RTL_FILES is required"):
            self.config()

    def test_invalid_period_and_run_path_rejected(self):
        for period in ("0", "-1", "Inf", "NaN", "five"):
            self.tcl.setvar("env(CLK_PERIOD_NS)", period)
            with self.subTest(period=period), self.assertRaises(tkinter.TclError):
                self.config()
        self.tcl.setvar("env(CLK_PERIOD_NS)", "5.0")
        for tag in ("../escape", "folder/name", ".", "a b"):
            self.tcl.setvar("env(TAG)", tag)
            with self.subTest(tag=tag), self.assertRaisesRegex(tkinter.TclError, "TAG"):
                self.config()

    def test_existing_evidence_cannot_be_overwritten(self):
        self.tcl.setvar("env(REPORT_DIR)", str(self.directory))
        with self.assertRaisesRegex(tkinter.TclError, "already exists"):
            self.config()

    def test_missing_sdc_rejected(self):
        self.tcl.setvar("env(SDC)", "constraints/missing.sdc")
        with self.assertRaisesRegex(tkinter.TclError, "Missing SDC"):
            self.config()

    def test_parameters_checked_and_production_lanes_bounded(self):
        for params in ("A=one", "A=1;exit", "bad"):
            self.tcl.setvar("env(PARAMS)", params)
            with self.subTest(params=params), self.assertRaisesRegex(tkinter.TclError, "PARAMS"):
                self.config()
        self.tcl.setvar("env(DESIGN)", "mc_top")
        self.tcl.setvar("env(PARAMS)", "LANES=4")
        with self.assertRaisesRegex(tkinter.TclError, "LANES=1"):
            self.config()
        self.tcl.setvar("env(PARAMS)", "LANES=1,GAUSS_LATENCY=2,MUL_STAGES=2")
        self.config()

if __name__ == "__main__":
    unittest.main()
