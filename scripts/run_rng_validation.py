"""Lab RNG regression, long RTL streams and shared-flow synthesis.

Run with VCS/DC loaded using the desired Python environment. Keeps fresh logs,
source hashes, stream files, CSVs and short VCDs. Does not change Git or remove
existing runs. A zero simulator exit code alone never establishes success.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "model"))
from price_study import lane_seeds
from rng_lane import pack_state, unpack_state
from rng_quality import DEFAULT_ROOT

ERROR = re.compile(r"^(?:FAIL|ERROR|Error|FATAL|Fatal)(?:[:\s-])", re.MULTILINE)


def run_logged(command, log, env=None, markers=(), cwd=ROOT):
    print("Running:", " ".join(map(str, command)), flush=True)
    result = subprocess.run([str(part) for part in command], cwd=cwd, env=env,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    Path(log).write_text(json.dumps(list(map(str, command))) + "\n" + result.stdout,
                         encoding="utf-8")
    if result.returncode or ERROR.search(result.stdout):
        raise RuntimeError(f"command failed; see {log}")
    for marker in markers:
        if not re.search(marker, result.stdout, re.MULTILINE):
            raise RuntimeError(f"missing PASS evidence {marker!r}; see {log}")
    return result.stdout


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--tag", default="rng_" + datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S"))
    p.add_argument("--words", type=int, default=1 << 20)
    p.add_argument("--streams", type=int, default=3)
    p.add_argument("--root", type=lambda s: int(s, 0), default=DEFAULT_ROOT)
    p.add_argument("--skip-synth", action="store_true", help="explicitly leave synthesis pending")
    a = p.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", a.tag):
        p.error("invalid tag")
    if a.words < 20480 or a.words > 100000000 or a.streams < 1:
        p.error("need 20480..100000000 words and positive streams")
    if not 0 < a.root < 2**128:
        p.error("root must be a nonzero 128-bit integer")
    vcs, dc = os.environ.get("VCS", "vcs"), os.environ.get("DC_SHELL", "dc_shell")
    for executable in ["make", "bash", vcs] + ([] if a.skip_synth else [dc]):
        if not shutil.which(executable):
            p.error(f"{executable} is missing; load the lab tools/environment")
    export_manifest = ROOT / "SOURCE_MANIFEST.json"
    if export_manifest.is_file():
        exported = json.loads(export_manifest.read_text(encoding="utf-8"))
        for name, expected in exported["source_sha256"].items():
            path = ROOT / name
            if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
                p.error(f"source export differs from its manifest: {name}; use a fresh export")
    run_dir = ROOT / "reports/rng_validation" / a.tag
    run_dir.mkdir(parents=True, exist_ok=False)
    # Source exports work without a .git directory; record exact input bytes.
    source_files = [p.relative_to(ROOT).as_posix()
                    for folder in ("rtl", "tb", "model", "scripts", "constraints")
                    for p in sorted((ROOT / folder).rglob("*"))
                    if p.is_file() and p.suffix in
                    (".sv", ".f", ".hex", ".py", ".tcl", ".sh", ".sdc")]
    source_files.append("Makefile")
    try:
        revision = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True,
            stderr=subprocess.DEVNULL).strip()
        status = subprocess.check_output(
            ["git", "status", "--short"], cwd=ROOT, text=True,
            stderr=subprocess.DEVNULL)
    except (OSError, subprocess.CalledProcessError):
        revision, status = "source_export", "See SOURCE_MANIFEST.json and input hashes"
    manifest = dict(tag=a.tag, utc=datetime.now(timezone.utc).isoformat(),
                    git_revision=revision, working_status=status,
                    source_sha256={name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
                                   for name in source_files if (ROOT / name).is_file()},
                    words=a.words, streams=a.streams, synthesis="pending", status="running")
    manifest_path = run_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    env = dict(os.environ, PYTHON=sys.executable, VCS=vcs)
    try:
        run_logged([sys.executable, "-B", "-m", "unittest", "-v"], run_dir / "model.log",
                   env, markers=(r"^OK$",), cwd=ROOT / "model")
        run_logged(["make", "rng-sim"], run_dir / "rng_sim.log", env,
                   markers=(r"^PASS rng_lane: [1-9][0-9]* cycles, [1-9][0-9]* valid words$",))
        for target, markers in [
            ("sim-top", tuple(rf"^PASS: tb_mc_top G={g} M={m} cases=22 trials=26457,"
                              for g in (1, 2) for m in (1, 2))),
            ("sim-lane-bubbles", (r"^PASS: tb_mc_lane_bubbles 100 exact trials",))]:
            run_env = dict(env, MC_SIM_RUN_ID=a.tag + "_" + target)
            run_logged(["make", target], run_dir / (target + ".log"), run_env, markers)
        run_logged([vcs, "-full64", "-sverilog", "-timescale=1ns/1ps", "+lint=all,noVCDE",
                    "rtl/mc_pkg.sv", "rtl/rng_lane.sv", "tb/tb_rng_stream.sv",
                    "-top", "tb_rng_stream", f"-pvalue+tb_rng_stream.N_WORDS={a.words}",
                    "-debug_access+all", "-Mdir=" + str(run_dir / "csrc"),
                    "-o", run_dir / "simv_stream"], run_dir / "stream_compile.log", env)
        seeds = lane_seeds(unpack_state(a.root), a.streams)
        inputs = []
        for index, seed in enumerate(seeds):
            stream = run_dir / f"stream_{index}.hex"
            inputs.extend(["--stream", str(stream)])
            run_logged([run_dir / "simv_stream", f"+SEED={pack_state(seed):032x}",
                        "+STREAM_FILE=" + str(stream),
                        "+VCD_FILE=" + str(run_dir / f"stream_{index}.vcd")],
                       run_dir / f"stream_{index}.log", env,
                       markers=(rf"^PASS rng_stream: {a.words} consecutive words, II=1,",))
        prefix = ROOT / "results" / a.tag
        run_logged([sys.executable, "-B", "model/rng_quality.py", "--words", a.words,
                    "--streams", a.streams, "--root", hex(a.root),
                    "--out-prefix", prefix, "--plot", *inputs], run_dir / "quality.log", env,
                   markers=(r"^imported_hex_canonical_checked: PASS RNG screening;",))
        if not a.skip_synth:
            syn_env = dict(env, DESIGN="rng_lane", RTL_FILES="rtl/mc_pkg.sv rtl/rng_lane.sv",
                           CLK_PERIOD_NS="5.0", TAG=a.tag, PARAMS="",
                           SDC=str(ROOT / "constraints/lane_5ns.sdc"),
                           REPORT_DIR=str(run_dir / "synthesis" / a.tag))
            run_logged([dc, "-f", "scripts/syn/dc_synth.tcl"],
                       run_dir / "synthesis.log", syn_env,
                       markers=(rf"^SYNTH_DONE {re.escape(a.tag)} ",))
            if not (run_dir / "synthesis" / a.tag / "summary.txt").is_file():
                raise RuntimeError("synthesis did not produce summary.txt")
            run_logged([sys.executable, "-B", "scripts/parse_reports.py",
                        "--syn", run_dir / "synthesis", "--out", str(prefix) + "_ppa.csv"],
                       run_dir / "parse_ppa.log", env, markers=(r"^wrote 1 rows",))
            manifest["synthesis"] = "reports_produced_check_ppa_for_violations"
        else:
            manifest["synthesis"] = "explicitly_skipped"
        manifest["status"] = "validation_completed"
        manifest["results_prefix"] = str(prefix.relative_to(ROOT))
        print(f"PASS RNG lab validation: {run_dir}")
        print("Read the PPA CSV for violations; this is not physical signoff.")
        return 0
    except (OSError, RuntimeError) as error:
        manifest["status"], manifest["error"] = "failed", str(error)
        print(error, file=sys.stderr)
        return 1
    finally:
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
