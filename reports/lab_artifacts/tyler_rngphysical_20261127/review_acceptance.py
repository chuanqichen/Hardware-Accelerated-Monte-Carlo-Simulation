"""Check raw physical evidence, retaining zero-limit rows and coverage limits."""
import argparse
import csv
import gzip
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "scripts"))
from summarize_multilane import collect_run, read_fields, digests, validate_comparison
from classify_violations import parse, summarize

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--manifest", type=Path, default=ROOT / "reports/multilane_rng_lookahead_runs.csv")
parser.add_argument("--out", type=Path, required=True)
args = parser.parse_args()
with args.manifest.open() as stream:
    runs = list(csv.DictReader(stream))
if [int(run["lanes"]) for run in runs] != [1, 2, 4]:
    raise SystemExit("Expected the complete ordered 1/2/4-lane matrix")
rows = [collect_run(run) for run in runs]
validate_comparison(rows)
positive_limits = [float(value) for value in re.findall(
    r"max_capacitance\s*:\s*([0-9.eE+-]+)",
    (ROOT / "tech/gscl45nm/setup_fixed_v1/gscl45nm.lib").read_text()) if float(value) > 0]
assert min(positive_limits) >= 1e-6, "Report precision cannot distinguish positive limits from zero"
for run, row in zip(runs, rows):
    physical = ROOT / "reports/pnr" / run["pnr_tag"]
    pt = ROOT / "reports/sta" / run["pt_routed_tag"]
    errors = []
    if not row["routed_setup_hold_pass_both_tools"]:
        errors.append("setup_or_hold")
    for field in ("geometry_clean", "connectivity_clean"):
        if not row[field]:
            errors.append(field)
    violations = summarize(parse((pt / "violators.rpt").read_text()))
    for name, entry in violations.items():
        if name == "max_capacitance":
            if entry["positive_limit"]:
                errors.append("positive_limit_capacitance")
        elif entry["count"]:
            errors.append("PT_" + name)
    row["pt_violations"] = violations
    # The hold-only summary omits DRVs. The setup summary reports DRVs for the
    # same final database; setup/hold slacks and path counts are checked above.
    for stage, filename in (("postroute", "mc_top.summary.gz"),):
        with gzip.open(physical / stage / filename, "rt") as stream:
            text = stream.read()
        for kind in ("max_tran", "max_fanout"):
            match = re.search(r"\|\s*" + kind + r"\s*\|\s*(\d+)", text)
            if not match:
                raise ValueError("Missing Innovus DRV count: " + kind)
            if int(match[1]):
                errors.append("Innovus_" + kind)
    coverage = re.search(r"^All Checks\s+(\d+)\s+(\d+)\s+\(\s*\d+%\)\s+(\d+)\s+\(\s*\d+%\)\s+(\d+)",
                         (pt / "coverage.rpt").read_text(), re.M)
    if not coverage:
        raise ValueError("Missing PT coverage summary")
    row["coverage"] = dict(zip(("total", "met", "violated", "untested"), map(int, coverage.groups())))
    if row["coverage"]["violated"]:
        errors.append("coverage_violations")
    inputs = read_fields(physical / "inputs.txt")
    if "eco_parent_tag" in inputs:
        parent = physical.parent / inputs["eco_parent_tag"]
        assert (physical / "parent_output_sha256.txt").read_bytes() == (parent / "output_sha256.txt").read_bytes()
        parent_inputs = read_fields(parent / "inputs.txt")
        assert all(inputs[key] == value for key, value in parent_inputs.items()), "ECO changed parent input policy"
        def constraints(path):
            return [line.strip() for line in path.read_text().splitlines()
                    if line.strip() and not line.lstrip().startswith("#")]
        assert constraints(physical / "mc_top.routed.sdc") == constraints(parent / "mc_top.routed.sdc"), "ECO changed SDC constraints"
        sources = digests(physical / "source_sha256.txt")
        for source, digest in digests(parent / "source_sha256.txt").items():
            assert sources[source] == digest, "ECO changed parent source digest"
        scripts = [(name, digest) for name, digest in sources.items() if name.endswith(
            ("targeted_hold_eco.tcl", "targeted_hold_eco_refill.tcl"))]
        assert len(scripts) == 1, "Expected exactly one ECO script"
        name, digest = scripts[0]
        assert hashlib.sha256((Path(__file__).parent / Path(name).name).read_bytes()).hexdigest() == digest
        row["eco_parent_tag"] = inputs["eco_parent_tag"]
        row["eco_policy"] = inputs["eco_policy"]
    row["acceptance_errors"] = sorted(set(errors))
result = dict(status="FAIL" if any(row["acceptance_errors"] for row in rows) else "PASS",
              note="Zero-limit capacitance and untested coverage remain unresolved; this is not signoff.", rows=rows)
args.out.parent.mkdir(parents=True, exist_ok=True)
with args.out.open("w", encoding="utf-8", newline="\n") as stream:
    stream.write(json.dumps(result, indent=2) + "\n")
print(result["status"], [(row["lanes"], row["acceptance_errors"]) for row in rows])
raise SystemExit(result["status"] != "PASS")
