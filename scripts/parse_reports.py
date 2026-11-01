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
          "power_total_mw", "power_dyn_mw", "power_leak_mw", "crit_start", "crit_end"]


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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--syn", type=Path, default=Path("reports/syn"))
    ap.add_argument("--out", type=Path, default=Path("results/gauss_lut_ppa.csv"))
    ap.add_argument("--filter", default="", help="only tags containing this substring")
    a = ap.parse_args()

    rows = []
    for summ in sorted(a.syn.glob("*/summary.txt")):
        if a.filter and a.filter not in summ.parent.name:
            continue
        row = parse_summary(summ)
        row.update(parse_power(summ.parent / "power.rpt"))
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
