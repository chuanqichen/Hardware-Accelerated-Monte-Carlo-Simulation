"""Summarize DC smoke reports, retaining violations and pre-layout limitations.

Usage: python scripts/parse_reports.py reports/syn/RUN [...] --out results/synthesis_smoke.csv
"""
import argparse
import csv
from pathlib import Path
import re


def read_smoke(run: Path) -> dict:
    """Require the expected DC report fields; never substitute zero for missing data."""
    inputs = dict(line.split("=", 1) for line in (run / "inputs.txt").read_text().splitlines() if "=" in line)
    qor = (run / "qor.rpt").read_text()

    def number(label):
        match = re.search(rf"^\s*{re.escape(label)}:\s+([-+]?\d+(?:\.\d+)?)\s*$", qor, re.MULTILINE)
        if not match:
            raise ValueError(f"{run}/qor.rpt: missing numeric field {label!r}")
        return float(match[1])

    row = {
        "design": inputs["top"],
        "corner": inputs["corner_label"],
        "clock_period_ns": float(inputs["clock_period_ns"]),
        "cell_area_library_units": number("Cell Area"),
        "critical_path_ns": number("Critical Path Length"),
        "setup_slack_ns": number("Critical Path Slack"),
        "worst_hold_slack_ns": number("Worst Hold Violation"),
        "hold_violating_paths": int(number("No. of Hold Violations")),
        "max_cap_violations": int(number("Max Cap Violations")),
        "max_transition_violations": int(number("Max Trans Violations")),
        "stage": "synthesis_ideal_clock_no_wire_load",
    }
    violations = (row["setup_slack_ns"] < 0 or row["hold_violating_paths"] > 0
                  or row["max_cap_violations"] > 0 or row["max_transition_violations"] > 0)
    row["result"] = "mapped_with_violations" if violations else "setup_met_pre_layout"
    row["evidence"] = run.as_posix()
    return row


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("runs", type=Path, nargs="+")
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    rows = [read_smoke(run) for run in args.runs]
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {len(rows)} smoke summaries to {args.out}; this is not PPA signoff.")


if __name__ == "__main__":
    main()
