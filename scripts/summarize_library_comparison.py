"""Verify and summarize the fixed-netlist installed/control/corrected PT study."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import re

from summarize_multilane import (ROOT, REPORTS, NUMBER, completed, digests,
                                normalize_sdc, number, read_fields, verified_digest)

def validate_sdc(sdc):
    clocks = re.findall(r"^create_clock\b.*$", sdc, re.M)
    transitions = re.findall(
        r"^set_clock_transition\s+-(max|min)\s+-(rise|fall)\s+(" + NUMBER +
        r")\s+\[get_clocks\s+\{?clk\}?\]\s*$", sdc, re.M)
    expected = {(limit, edge) for limit in ("max", "min") for edge in ("rise", "fall")}
    if len(clocks) != 1 or number(r"-period\s+(" + NUMBER + ")", clocks[0]) != 5.0:
        raise ValueError("Expected one 5 ns clock")
    if len(transitions) != 4 or {(a, b) for a, b, _ in transitions} != expected or \
            any(float(value) != 0.10 for _, _, value in transitions):
        raise ValueError("Expected unchanged 0.10 ns clock transitions")


def collect(manifest, reference_batch):
    with manifest.open() as stream:
        runs = list(csv.DictReader(stream))
    expected = [(lanes, variant) for lanes in (1, 2, 4)
                for variant in ("installed", "control", "fixed")]
    if [(int(r["lanes"]), r["variant"]) for r in runs] != expected:
        raise ValueError("Expected ordered 1/2/4 x installed/control/fixed comparisons")
    package = ROOT / "tech/gscl45nm"
    fixed = json.loads((package / "setup_fixed_v1/compiled.json").read_text())
    control_dir = REPORTS / "library/control"
    control = read_fields(control_dir / "gscl45nm.db.build.txt")
    if control["source_sha256"] != hashlib.sha256(
            (package / "original/gscl45nm.lib").read_bytes()).hexdigest():
        raise ValueError("Compilation control did not use the unchanged Liberty")
    if control["tool"] != fixed["tool"]:
        raise ValueError("Control and corrected libraries used different LC versions")
    verified_digest(control_dir / "gscl45nm.db", control["db_sha256"])
    verified_digest(package / "setup_fixed_v1/gscl45nm.db", fixed["db_sha256"])
    verified_digest(package / "setup_fixed_v1/gscl45nm.lib", fixed["source_sha256"])
    libraries = dict(installed=hashlib.sha256(
        (package / "original/gscl45nm.db").read_bytes()).hexdigest(),
        control=control["db_sha256"], fixed=fixed["db_sha256"])
    rows = []
    for run in runs:
        lanes = int(run["lanes"])
        tag = run["sta_tag"]
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", tag):
            raise ValueError("Invalid analysis tag")
        folder = REPORTS / "sta" / tag
        completed(folder.with_suffix(".log"), "STA_DONE " + tag)
        inputs = read_fields(folder / "inputs.txt")
        hashes = digests(folder / "source_sha256.txt")
        summary = read_fields(folder / "summary.txt")
        if inputs["corner"] != "typical" or not inputs["analysis"].startswith("prelayout") or inputs.get("spef"):
            raise ValueError("Comparison is not a matched typical pre-layout analysis")
        if hashes[inputs["library"]] != libraries[run["variant"]]:
            raise ValueError("Unexpected library used in comparison")
        baseline = REPORTS / "syn" / f"{reference_batch}_l{lanes}"
        for key, name in (("netlist", "mc_top.mapped.v"), ("sdc", "mc_top.mapped.sdc")):
            verified_digest(baseline / name, hashes[inputs[key]])
        sdc = (baseline / "mc_top.mapped.sdc").read_text()
        validate_sdc(sdc)
        if (folder / "constraints.pt.sdc").read_text() != normalize_sdc(sdc):
            raise ValueError("Analysis altered constraints beyond design selectors")
        setup = (folder / "setup.rpt").read_text()
        dff = (folder / "dffposx1_setup.rpt").read_text()
        rows.append(dict(
            lanes=lanes, variant=run["variant"], sta_tag=tag, pt_version=inputs["tool"],
            setup_slack_ns=float(summary["setup_slack_ns"]),
            hold_slack_ns=float(summary["hold_slack_ns"]),
            startpoint=re.search(r"^\s*Startpoint:\s+(\S+)", setup, re.M)[1],
            endpoint=re.search(r"^\s*Endpoint:\s+(\S+)", setup, re.M)[1],
            setup_requirement_ns=-number(r"library setup time\s+(" + NUMBER + ")", setup),
            dffposx1_worst_endpoint=re.search(r"^\s*Endpoint:\s+(\S+)", dff, re.M)[1],
            dffposx1_worst_slack_ns=number(r"slack \((?:MET|VIOLATED)\)\s+(" + NUMBER + ")", dff),
            dffposx1_setup_requirement_ns=-number(r"library setup time\s+(" + NUMBER + ")", dff),
            netlist_sha256=hashes[inputs["netlist"]], sdc_sha256=hashes[inputs["sdc"]],
            library_db_sha256=hashes[inputs["library"]],
            pt_script_sha256=next(h for p, h in hashes.items() if
                                 p == "scripts/sta/prelayout.tcl" or p.endswith("/scripts/sta/prelayout.tcl")),
            config_sha256=next(h for p, h in hashes.items() if
                              p == "scripts/syn/config.tcl" or p.endswith("/scripts/syn/config.tcl"))))
    if len({row["pt_version"] for row in rows}) != 1:
        raise ValueError("Unmatched PT versions")
    for field in ("pt_script_sha256", "config_sha256"):
        if len({row[field] for row in rows}) != 1:
            raise ValueError("Unmatched analysis scripts")
    return rows


def markdown(rows, manifest):
    lines = ["# Fixed-netlist library comparison", "",
             f"Generated from `{manifest}` by `scripts/summarize_library_comparison.py`.",
             "Each lane count uses the exact PR #21 mapped netlist and SDC for all three "
             "libraries. The period remains 5 ns and the clock transition 0.10 ns. "
             "No resynthesis or extracted parasitics are involved.", "",
             "| Lanes | Installed setup (ns) | Recompiled-original setup (ns) | Fixed setup (ns) | Fixed hold (ns) |",
             "|---:|---:|---:|---:|---:|"]
    for lanes in (1, 2, 4):
        group = {r["variant"]: r for r in rows if r["lanes"] == lanes}
        lines.append(f"| {lanes} | {group['installed']['setup_slack_ns']:+.6f} | "
                     f"{group['control']['setup_slack_ns']:+.6f} | "
                     f"{group['fixed']['setup_slack_ns']:+.6f} | "
                     f"{group['fixed']['hold_slack_ns']:+.6f} |")
    lines += ["", "The recompiled-original control uses the same LC version as the fixed "
              "library. The CSV retains the actual library, netlist and SDC digests, "
              "worst endpoints and DFFPOSX1 path information. The worst DFFPOSX1 endpoint "
              "may differ between variants; its setup requirement is not a matched-endpoint delta.",
              "", "The corrected values are the documented `setup_fixed_v1` approximation. "
              "See [the resulting architectural baseline](../docs/Library_Fix_Baseline.md).", ""]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--reference-batch", default="implementation_20261123")
    parser.add_argument("--out", type=Path, default=ROOT / "results/library_fixed_netlist")
    args = parser.parse_args()
    try:
        rows = collect(args.manifest, args.reference_batch)
    except (ValueError, OSError, KeyError, TypeError, StopIteration) as error:
        parser.error(str(error))
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.with_suffix(".csv").open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    args.out.with_suffix(".md").write_text(markdown(rows, args.manifest))
    print("Verified nine fixed-netlist library analyses")


if __name__ == "__main__":
    main()
