"""Classify a PrimeTime report_constraint -all_violators report.

python scripts/classify_violations.py reports/sta/<tag>/violators.rpt [...]

Every violation remains counted. Max-capacitance checks are split by whether the
library supplied a positive limit or a zero limit. Several gscl45nm output pins
(for example NAND2X1/Y and DFFSR/Q) declare max_capacitance 0, so any connected
load reports a violation that buffering cannot remove. That class is reported
separately from violations of positive limits; it is not waived.
"""
import argparse
import json
from pathlib import Path
import re

NUMBER = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?"
SECTION = re.compile(r"^\s{3}(min_delay/hold|max_delay/setup|max_capacitance|max_fanout|"
                     r"max_transition|min_capacitance|min_period|min_pulse_width|"
                     r"recovery|removal|[a-z_/]+)(?:\s+\('?([^)]*?)'?\s*group\))?\s*$")
DELAY_ROW = re.compile(r"^\s*(\S+)\s+(" + NUMBER + r")\s+\((VIOLATED)[^)]*\)\s*$")
LIMIT_ROW = re.compile(r"^\s*(\S+)\s+(" + NUMBER + r")\s+(" + NUMBER + r")\s+(" + NUMBER +
                       r")\s+\((VIOLATED)[^)]*\)\s*$")


def parse(text):
    """Return {section: [row, ...]} for every VIOLATED line in the report."""
    sections = {}
    current = None
    for line in text.splitlines():
        heading = SECTION.match(line)
        if heading and "VIOLATED" not in line:
            current = heading.group(1)
            sections.setdefault(current, [])
            continue
        if "VIOLATED" not in line:
            continue
        if current is None:
            raise ValueError("Violation row before any constraint section: " + line.strip())
        limit = LIMIT_ROW.match(line)
        if limit:
            sections[current].append(dict(pin=limit.group(1), required=float(limit.group(2)),
                                          actual=float(limit.group(3)), slack=float(limit.group(4))))
            continue
        delay = DELAY_ROW.match(line)
        if delay:
            sections[current].append(dict(pin=delay.group(1), slack=float(delay.group(2))))
            continue
        raise ValueError("Unrecognized violation row: " + line.strip())
    return sections


def summarize(sections):
    summary = {}
    for name, rows in sections.items():
        entry = dict(count=len(rows))
        if rows:
            entry["worst_slack"] = min(row["slack"] for row in rows)
        if name == "max_capacitance":
            zero = [row for row in rows if row["required"] == 0]
            positive = [row for row in rows if row["required"] > 0]
            entry["zero_library_limit"] = len(zero)
            entry["positive_limit"] = len(positive)
            if positive:
                entry["positive_limit_worst_slack"] = min(row["slack"] for row in positive)
        if name in ("max_fanout", "max_transition", "max_capacitance") and rows:
            entry["worst_actual"] = max(row["actual"] for row in rows)
        if name in ("min_delay/hold", "max_delay/setup"):
            entry["endpoints"] = [row["pin"] for row in rows]
        summary[name] = entry
    return summary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reports", nargs="+", type=Path)
    parser.add_argument("--json", action="store_true", help="print the complete summary as JSON")
    args = parser.parse_args()
    results = {}
    try:
        for path in args.reports:
            results[str(path)] = summarize(parse(path.read_text()))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    if args.json:
        print(json.dumps(results, indent=2, sort_keys=True))
        return
    for path, summary in results.items():
        print(path)
        if not summary:
            print("  no violations reported")
        for name, entry in sorted(summary.items()):
            details = ", ".join(f"{key}={value}" for key, value in sorted(entry.items())
                                if key != "endpoints")
            print(f"  {name}: {details}")


if __name__ == "__main__":
    main()
