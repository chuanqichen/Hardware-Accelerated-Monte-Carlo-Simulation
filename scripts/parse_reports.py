"""Turn raw synthesis reports into one canonical CSV.

Reads every reports/syn/<tag>/summary.txt written by scripts/syn/dc_synth.tcl, adds
the total power from power.rpt and the critical-path endpoints from timing.rpt, and
writes one row per run. Report numbers come from this file, never typed by hand.

    python3 scripts/parse_reports.py --syn reports/syn --out results/gauss_lut_ppa.csv
"""
from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

FIELDS = ["tag", "design", "params", "library", "clk_period_ns", "wns_ns", "fmax_mhz",
          "area_um2", "area_comb_um2", "area_bufinv_um2", "area_seq_um2", "cells", "registers",
          "worst_hold_slack_ns", "hold_violating_paths", "max_cap_violations", "max_transition_violations", "result", "power_activity", "power_total_mw", "power_dyn_mw", "power_leak_mw", "crit_start", "crit_end"]


def parse_summary(path: Path) -> dict:
    row = {}
    for line in path.read_text().splitlines():
        parts = line.split(None, 1)
        if len(parts) == 2:
            row[parts[0]] = parts[1].strip()
    return row


def parse_power(path: Path) -> dict:
    """DC report_power: 'Total Dynamic Power = 1.23 mW', 'Cell Leakage Power = 45.6 uW'."""
    out = {}
    if not path.exists():
        return out
    txt = path.read_text()
    scale = {"W": 1e3, "mW": 1.0, "uW": 1e-3, "nW": 1e-6, "pW": 1e-9}

    def grab(label):
        m = re.search(rf"{label}\s*=\s*([\d.eE+-]+)\s*([munp]?W)", txt)
        return float(m.group(1)) * scale[m.group(2)] if m else None

    dyn, leak = grab("Total Dynamic Power"), grab("Cell Leakage Power")
    if dyn is not None:
        out["power_dyn_mw"] = f"{dyn:.4f}"
    if leak is not None:
        out["power_leak_mw"] = f"{leak:.4f}"
    if dyn is not None and leak is not None:
        out["power_total_mw"] = f"{dyn + leak:.4f}"
    return out


def parse_timing(path: Path) -> dict:
    out = {}
    if not path.exists():
        return out
    txt = path.read_text()
    m = re.search(r"Startpoint:\s*(\S+)", txt)
    if m:
        out["crit_start"] = m.group(1)
    m = re.search(r"Endpoint:\s*(\S+)", txt)
    if m:
        out["crit_end"] = m.group(1)
    return out


def parse_qor(path: Path) -> dict:
    txt = path.read_text()
    def number(label):
        match = re.search(rf"^\s*{re.escape(label)}:\s+([-+]?\d+(?:\.\d+)?)\s*$", txt, re.MULTILINE)
        if not match:
            raise ValueError(f"{path}: missing {label}")
        return float(match[1])
    setup = number("Critical Path Slack")
    hold = number("Worst Hold Violation")
    holds = int(number("No. of Hold Violations"))
    caps = int(number("Max Cap Violations"))
    transitions = int(number("Max Trans Violations"))
    violated = setup < 0 or holds > 0 or caps > 0 or transitions > 0
    return dict(worst_hold_slack_ns=hold, hold_violating_paths=holds,
                max_cap_violations=caps, max_transition_violations=transitions,
                result="mapped_with_violations" if violated else "setup_met_pre_layout")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--syn", type=Path, default=Path("reports/syn"),
                    help="one synthesis run directory or a parent containing multiple runs")
    ap.add_argument("--out", type=Path, default=Path("results/gauss_lut_ppa.csv"))
    ap.add_argument("--filter", default="", help="only tags containing this substring")
    a = ap.parse_args()

    rows = []
    summaries = ([a.syn / "summary.txt"] if (a.syn / "summary.txt").is_file()
                 else sorted(a.syn.glob("*/summary.txt")))
    for summ in summaries:
        if a.filter and a.filter not in summ.parent.name:
            continue
        row = parse_summary(summ)
        row.update(parse_qor(summ.parent / "qor.rpt"))
        row.update(parse_power(summ.parent / "power.rpt"))
        power_path = summ.parent / "power.rpt"
        row["power_activity"] = ("unannotated_estimate" if power_path.exists() and "PWR-414" in power_path.read_text()
                                 else "verify_annotation")
        row.update(parse_timing(summ.parent / "timing.rpt"))
        rows.append({k: row.get(k, "") for k in FIELDS})

    a.out.parent.mkdir(parents=True, exist_ok=True)
    with a.out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS)
        w.writeheader()
        w.writerows(rows)
    print(f"wrote {len(rows)} rows to {a.out}")
    for r in rows:
        print(f"  {r['tag']:<24} area {r['area_um2']:>10} um2  wns {r['wns_ns']:>7} ns  "
              f"fmax {r['fmax_mhz']:>7} MHz  P {r['power_total_mw']:>8} mW  regs {r['registers']}")


if __name__ == "__main__":
    main()
