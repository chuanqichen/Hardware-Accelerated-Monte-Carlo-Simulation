"""Optional slang static check. This does not simulate or synthesize the RTL.

Install pyslang in an isolated directory, then pass --parser-dir. No runtime or
model dependency is added. ARRAY_INPUTS must come from prepare_array_sim.py.
"""
import argparse
from pathlib import Path
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--parser-dir", type=Path)
    parser.add_argument("--inputs", type=Path, required=True)
    args = parser.parse_args()
    if args.parser_dir:
        sys.path.insert(0, str(args.parser_dir.resolve()))
    try:
        import pyslang
        from pyslang.driver import Driver
    except ImportError:
        parser.error("Install pyslang in an isolated tool directory and set --parser-dir")
    baseline = (ROOT / "rtl/mc_top.f").read_text().split()
    scratch = ROOT / "tmp"
    scratch.mkdir(exist_ok=True)

    def check(sources, top):
        # The driver's command-line parser accepts quoted forward-slash paths.
        command = "slang --timescale 1ns/1ps --top " + top + " " + " ".join(
            '"' + Path(source).resolve().as_posix() + '"' for source in sources)
        driver = Driver()
        driver.addStandardArgs()
        if not (driver.parseCommandLine(command) and driver.processOptions() and
                driver.parseAllSources() and driver.runFullCompilation()):
            raise SystemExit("FAIL: static elaboration")

    with tempfile.TemporaryDirectory(prefix="array_elab_", dir=scratch) as directory:
        wrapper = Path(directory) / "check.sv"
        for bits in (10, 8):
            instances = []
            for lanes in (1, 2, 4):
                for gauss in (1, 2):
                    for mul in (1, 2):
                        instances.append(f"tb_mc_array #(.LANES({lanes}),.GAUSS_LATENCY({gauss}),"
                                         f".MUL_STAGES({mul}),.EXP_ADDR_BITS({bits})) c{lanes}{gauss}{mul}();")
            wrapper.write_text("module array_check;\n" + "\n".join(instances) + "\nendmodule\n")
            sources = [args.inputs / "k8/exp2_rom.sv" if s == "rtl/generated/exp2_rom.sv" and bits == 8
                       else ROOT / s for s in baseline]
            check(sources + [ROOT / "tb/tb_mc_array.sv", wrapper], "array_check")
            print(f"ELABORATION_PASS k={bits}: 12 configurations")
        wrapper.write_text("module tree_check; tb_accumulator_tree #(.LANES(2)) c2(); "
                           "tb_accumulator_tree #(.LANES(4)) c4(); endmodule\n")
        check([ROOT / "rtl/accumulator.sv", ROOT / "tb/tb_accumulator_tree.sv", wrapper], "tree_check")
        for top in ("tb_mc_top", "tb_mc_lane_bubbles"):
            check([ROOT / s for s in baseline] + [ROOT / f"tb/{top}.sv"], top)
        wrapper.write_text("module control_check; " + " ".join(
            f"tb_mc_control #(.LANES({lanes})) c{lanes}();" for lanes in (1, 2, 4)) + " endmodule\n")
        check([ROOT / s for s in ("rtl/mc_pkg.sv", "rtl/rst_sync.sv", "rtl/mc_controller.sv",
                                 "rtl/mc_top.sv", "tb/mocks/mc_lane_array.sv", "tb/tb_mc_control.sv")] + [wrapper],
              "control_check")
    print(f"ELABORATION_DONE pyslang={pyslang.__version__}; simulation still required")


if __name__ == "__main__":
    main()
