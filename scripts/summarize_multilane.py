"""Validate matched 1/2/4-lane evidence and regenerate CSV, tables and plots.

python scripts/summarize_multilane.py --plot
Requires only the archived reports; proprietary libraries and simulators are not
needed. VCD/GDS/checkpoint files remain on the lab disk; their digests are retained.
"""
import argparse
import csv
import gzip
import hashlib
import json
from pathlib import Path
import re
import shlex

ROOT = Path(__file__).resolve().parents[1]
REPORTS = ROOT / "reports"
NUMBER = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?"


def read_fields(path, separator="="):
    return dict(line.split(separator, 1) if separator else line.split(None, 1)
                for line in path.read_text().splitlines() if line.strip())


def digests(path):
    return dict((name, digest) for digest, name in
                (line.split(None, 1) for line in path.read_text().splitlines() if line.strip()))


def verified_digest(path, expected):
    """Check uncompressed content, including when the archive uses gzip."""
    compressed = not path.exists()
    source = path.with_name(path.name + ".gz") if compressed else path
    opener = gzip.open if compressed else open
    digest = hashlib.sha256()
    with opener(source, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    if digest.hexdigest() != expected:
        raise ValueError(f"Input digest mismatch: {path}")
    return expected


def normalize_sdc(text):
    """Independent audit of the two design-selector translations used by PT."""
    lines = []
    for line in text.split("\n"):
        selected = re.fullmatch(r"\s*current_design\s+(\S+)\s*", line)
        if selected:
            if selected[1] != "mc_top":
                raise ValueError("SDC selects an unexpected design")
            line = "# mc_top already selected by link_design"
        lines.append(line.replace("[get_designs {mc_top}]", "[current_design]"))
    return "".join(line + "\n" for line in lines)


def number(pattern, text):
    match = re.search(pattern, text, re.MULTILINE)
    if not match:
        raise ValueError(f"Missing numeric report field: {pattern}")
    return float(match[1])


def innovus_timing(physical, kind):
    """Read the all-paths column; counts catch violations rounded to 0.000 ns."""
    name = ("postroute/mc_top.summary" if kind == "setup"
            else "postroute_hold/mc_top_hold.summary")
    path = physical / name
    text = (path.read_text() if path.is_file() else
            gzip.decompress(path.with_name(path.name + ".gz").read_bytes()).decode("utf-8"))
    slack = number(r"^\s*\|\s*WNS \(ns\):\s*\|\s*(" + NUMBER + r")\s*\|", text)
    count = int(number(r"^\s*\|\s*Violating Paths:\s*\|\s*(\d+)\s*\|", text))
    return slack, count


def timing_failures(row):
    return [kind for kind in ("setup", "hold")
            if row[f"pt_routed_{kind}_ns"] < 0 or row[f"innovus_{kind}_ns"] < 0
            or row[f"innovus_{kind}_violating_paths"] > 0]


def timing_note(rows):
    failures = []
    for kind in ("setup", "hold"):
        lanes = [str(row["lanes"]) for row in rows if kind in timing_failures(row)]
        if lanes:
            failures.append(f"{kind} (lanes {', '.join(lanes)})")
    return ("Open timing: " + "; ".join(failures) if failures else
            "Setup/hold pass in both tools; electrical and PVT limits remain")


def completed(log, marker):
    text = log.read_text()
    if not re.search(r"^" + re.escape(marker) + r"(?:\s|$)", text, re.MULTILINE):
        raise ValueError(f"Missing completion marker: {log}")
    if re.search(r"^(?:\*\*ERROR|ERROR|Error|Fatal|FATAL|STA failed|PNR failed)\s*:", text, re.MULTILINE):
        raise ValueError(f"Tool errors in completed run: {log}")
    return text


def collect_run(run):
    lanes = int(run["lanes"])
    syn = REPORTS / "syn" / run["syn_tag"]
    pre_tag = run.get("pt_pre_tag") or run["syn_tag"]
    pre = REPORTS / "sta" / pre_tag
    physical = REPORTS / "pnr" / run["pnr_tag"]
    post = REPORTS / "sta" / run["pt_routed_tag"]
    mapped_sim = REPORTS / "sim" / run["sim_mapped_tag"]
    routed_sim = REPORTS / "sim" / run["sim_routed_tag"]
    summary = read_fields(syn / "summary.txt", separator=None)
    params = dict(pair.split("=") for pair in summary["params"].split(","))
    if params != dict(LANES=str(lanes), GAUSS_LATENCY="1", MUL_STAGES="1",
                      GAUSS_ADDR_BITS="10", EXP_ADDR_BITS="10") or summary["retime"] != "0":
        raise ValueError(f"Unexpected synthesis configuration: {syn}")
    completed(syn / "dc.log.txt", "SYNTH_DONE " + run["syn_tag"])
    completed(pre.with_suffix(".log"), "STA_DONE " + pre_tag)
    completed(physical.with_suffix(".log"), "PNR_DONE " + run["pnr_tag"])
    post_log = completed(post.with_suffix(".log"), "STA_DONE " + run["pt_routed_tag"])
    pre_inputs = read_fields(pre / "inputs.txt")
    post_inputs = read_fields(post / "inputs.txt")
    physical_inputs = read_fields(physical / "inputs.txt")
    syn_inputs = read_fields(syn / "inputs.txt")
    if {syn_inputs["corner_label"], pre_inputs["corner"], post_inputs["corner"],
            physical_inputs["corner"]} != {"typical"}:
        raise ValueError("Unexpected or unmatched analysis corners")
    pre_sha = digests(pre / "source_sha256.txt")
    syn_library_sha = digests(syn / "library_sha256.txt")
    if len(syn_library_sha) != 1 or set(syn_library_sha.values()) != {pre_sha[pre_inputs["library"]]}:
        raise ValueError("DC and PT libraries differ")
    post_sha = digests(post / "source_sha256.txt")
    physical_sha = digests(physical / "source_sha256.txt")
    output_sha = digests(physical / "output_sha256.txt")
    mapped_sha = digests(mapped_sim / "source_sha256.txt")
    routed_sha = digests(routed_sim / "source_sha256.txt")
    for filename, key in (("mc_top.mapped.v", "netlist"), ("mc_top.mapped.sdc", "sdc")):
        expected = pre_sha[pre_inputs[key]]
        verified_digest(syn / filename, expected)
        if physical_sha[physical_inputs[key]] != expected:
            raise ValueError("PnR did not consume the matched synthesis inputs")
    for filename, key in (("mc_top.routed.v", "netlist"), ("mc_top.routed.sdc", "sdc"),
                          ("mc_top.routed.spef", "spef")):
        verified_digest(physical / filename, post_sha[post_inputs[key]])
        if output_sha[post_inputs[key]] != post_sha[post_inputs[key]]:
            raise ValueError("Routed exports differ from the PT inputs")
    def_path = post_inputs["netlist"].replace(".routed.v", ".routed.def")
    verified_digest(physical / "mc_top.routed.def", output_sha[def_path])
    if mapped_sha[pre_inputs["netlist"]] != pre_sha[pre_inputs["netlist"]] or \
            routed_sha[post_inputs["netlist"]] != post_sha[post_inputs["netlist"]]:
        raise ValueError("Simulation and timing netlists differ")
    mapped_cases = {p: h for p, h in mapped_sha.items() if p.endswith(".hex")}
    routed_cases = {p: h for p, h in routed_sha.items() if p.endswith(".hex")}
    if len(mapped_cases) != 1 or mapped_cases != routed_cases:
        raise ValueError("Mapped and routed replays used different corpora")
    if pre_sha[pre_inputs["library"]] != post_sha[post_inputs["library"]]:
        raise ValueError("DC-matched and routed PT libraries differ")
    normalized = post / "constraints.pt.sdc"
    if normalized.read_text() != normalize_sdc((physical / "mc_top.routed.sdc").read_text()):
        raise ValueError("The consumed SDC changes more than design selectors")
    consumed_sdc = next(p for p in post_sha if p.endswith("/constraints.pt.sdc"))
    verified_digest(normalized, post_sha[consumed_sdc])
    vcd_digest = post_sha[post_inputs["vcd"]]
    if digests(routed_sim / "activity_sha256.txt")[post_inputs["vcd"]] != vcd_digest:
        raise ValueError("PT activity differs from the recorded simulation")
    verified_digest(routed_sim / "activity.txt", post_sha[
        next(p for p in post_sha if p.endswith("/activity.txt"))])
    cases, trials = {1: (26, 27492), 2: (27, 27495), 4: (28, 27502)}[lanes]
    marker = f"PASS: tb_mc_array L={lanes} G=1 M=1 A=10 K=10 cases={cases} trials={trials}"
    for folder in (mapped_sim, routed_sim):
        completed(folder / "run.log", marker)
    activity = read_fields(routed_sim / "activity.txt")
    with (routed_sim / "cycles.csv").open() as stream:
        cycles = list(csv.DictReader(stream))
    if len(cycles) != cases or sum(int(row["trials"]) for row in cycles) != trials:
        raise ValueError("Incomplete measured cycle corpus")
    profile = cycles[int(activity["case_id"])]
    period = float(summary["clk_period_ns"])
    count = int(activity["trials"])
    duration = float(activity["stop_ns"]) - float(activity["start_ns"])
    if count != int(profile["trials"]) or count != 1000 or duration <= 0 or \
            float(activity["clock_period_ns"]) != period:
        raise ValueError("Unexpected activity workload or clock")
    power_text = (post / "power.rpt").read_text()
    for kind in ("Dynamic", "Leakage"):
        if not re.search(kind + r" Power Units\s*=\s*1 W\s*$", power_text, re.MULTILINE):
            raise ValueError("Unexpected power units")
    power = number(r"^Total Power\s*=\s*(" + NUMBER + r")\s+\(", power_text)
    pre_slack = read_fields(pre / "summary.txt")
    post_slack = read_fields(post / "summary.txt")
    impl = (physical / "implementation.rpt").read_text()
    if not (post / "parasitics.log").is_file():
        raise ValueError("Missing parasitic annotation diagnostics")
    annotation = (post / "parasitic_annotation.rpt").read_text()
    pin_nets = re.findall(r"Pin to pin nets\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)", annotation)
    if len(pin_nets) != 2 or any(int(total) != int(rc) or int(lumped) or int(pi) or int(missing)
                                 for total, lumped, pi, rc, missing in pin_nets):
        raise ValueError("Incomplete internal/boundary pin-to-pin RC annotation")
    driverless = re.findall(r"Driverless nets\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*(\d+)", annotation)
    if len(driverless) != 2:
        raise ValueError("Missing driverless-net annotation diagnostics")
    innovus_setup, innovus_setup_count = innovus_timing(physical, "setup")
    innovus_hold, innovus_hold_count = innovus_timing(physical, "hold")
    row = dict(
        lanes=lanes, syn_tag=run["syn_tag"], pnr_tag=run["pnr_tag"],
        pt_routed_tag=run["pt_routed_tag"], period_ns=period,
        dc_area_um2=float(summary["area_um2"]), dc_cells=int(summary["cells"]),
        dc_setup_ns=float(summary["wns_ns"]),
        pt_pre_setup_ns=float(pre_slack["setup_slack_ns"]),
        pt_pre_hold_ns=float(pre_slack["hold_slack_ns"]),
        physical_signal_area_um2=number(r"Total area of Standard cells\(Subtracting Physical Cells\):\s*(" + NUMBER + ")", impl),
        core_area_um2=number(r"Total area of Core:\s*(" + NUMBER + ")", impl),
        die_area_um2=number(r"Total area of Chip:\s*(" + NUMBER + ")", impl),
        pt_routed_setup_ns=float(post_slack["setup_slack_ns"]),
        pt_routed_hold_ns=float(post_slack["hold_slack_ns"]),
        innovus_setup_ns=innovus_setup, innovus_hold_ns=innovus_hold,
        innovus_setup_violating_paths=innovus_setup_count,
        innovus_hold_violating_paths=innovus_hold_count,
        geometry_clean=int("No DRC violations were found" in (physical / "geometry.rpt").read_text()),
        connectivity_clean=int("Found no problems or warnings." in (physical / "connectivity.rpt").read_text()),
        corpus_cases=cases, corpus_trials=trials, profile_trials=count,
        profile_busy_cycles=int(profile["cycles"]), profile_duration_ns=duration,
        conditional_busy_mtrials_s=1000 * count / (int(profile["cycles"]) * period),
        estimated_power_w=power, estimated_energy_pj_per_trial=power * duration * 1000 / count,
        activity_invariant_annotation_pct=number(r"annotation_ratio = (" + NUMBER + r")%", post_log),
        activity_fully_annotated_cells_pct=number(r"Number of fully annotated leaf cells = \d+ \((" + NUMBER + r")%\)", post_log),
        rc_pin_to_pin_nets=sum(int(values[0]) for values in pin_nets),
        rc_unannotated_driverless_nets=sum(int(value) for value in driverless),
        rc_method=physical_inputs["rc_method"],
        mapped_netlist_sha256=pre_sha[pre_inputs["netlist"]],
        routed_netlist_sha256=post_sha[post_inputs["netlist"]],
        spef_sha256=post_sha[post_inputs["spef"]], vcd_sha256=vcd_digest,
        library_db_sha256=pre_sha[pre_inputs["library"]],
        library_lib_sha256=physical_sha[physical_inputs["library"]],
        lef_sha256=physical_sha[physical_inputs["lef"]],
        profile_a_hex=activity["a"], profile_b_hex=activity["b"], profile_k_hex=activity["k"])
    row["routed_setup_hold_pass_both_tools"] = int(not timing_failures(row))
    if run.get("pt_pre_tag"):
        row["pt_pre_tag"] = pre_tag
    return row


def library_label(rows):
    """Recognize the published pair and reject a mixed original/corrected flow."""
    package = ROOT / "tech/gscl45nm/setup_fixed_v1/compiled.json"
    if not package.is_file():
        return ""
    compiled = json.loads(package.read_text())
    labels = set()
    for row in rows:
        matches = (row["library_db_sha256"] == compiled["db_sha256"],
                   row["library_lib_sha256"] == compiled["source_sha256"])
        if any(matches) and not all(matches):
            raise ValueError("Mixed original/corrected library pair")
        labels.add("setup_fixed_v1" if all(matches) else "")
    if len(labels) != 1:
        raise ValueError("Mixed library variants across lane counts")
    return labels.pop()


def markdown(rows, manifest="reports/multilane_runs.csv", output="results/multilane_implementation"):
    label = library_label(rows)
    command = "python scripts/summarize_multilane.py --plot"
    if manifest != "reports/multilane_runs.csv" or output != "results/multilane_implementation":
        command += " --manifest " + shlex.quote(manifest) + " --out " + shlex.quote(output)
    library = "library" if not label else f"`{label}` project-approximation library"
    timing = timing_note(rows)
    lines = ["# Multi-lane implementation results", "",
             f"Generated by `{command}` from "
             f"`{manifest}`. Input digests, completion markers, corpora, "
             "SDC translations and power units are checked before publication.", "",
             "All points use a10/k10, G=1, M=1, no retiming, the typical OSU/FreePDK45 "
             f"{library} and a {rows[0]['period_ns']:g} ns target. These are tool estimates. "
             f"**{timing}.** Passing these checks alone does not establish signoff; "
             "the installation has no characterized QRC/capacitance table.", "",
             "## Synthesis and matched pre-layout PrimeTime", "",
             "| Lanes | DC cell area (µm²) | Cells | DC setup (ns) | PT setup (ns) | PT hold (ns) |",
             "|---:|---:|---:|---:|---:|---:|"]
    for r in rows:
        lines.append(f"| {r['lanes']} | {r['dc_area_um2']:.3f} | {r['dc_cells']} | {r['dc_setup_ns']:.6f} | {r['pt_pre_setup_ns']:.6f} | {r['pt_pre_hold_ns']:.6f} |")
    lines += ["", "## Routed implementation", "",
              "Physical signal-cell area excludes fillers and uses LEF geometry. DC area "
              "uses Liberty cell areas; their difference is not solely an optimization gain.", "",
              "Innovus reports SI-aware post-route timing. The pass/open column covers "
              "setup and hold in both tools, including Innovus violation counts when WNS "
              "rounds to zero; it does not waive electrical violations.", "",
              "| Lanes | Signal-cell area (µm²) | Core area (µm²) | Die area (µm²) | PT setup (ns) | PT hold (ns) | Innovus setup (ns) | Innovus hold (ns) | Both tools: setup/hold | Geometry / connectivity |",
              "|---:|---:|---:|---:|---:|---:|---:|---:|:---|:---|"]
    for r in rows:
        checks = "clean" if r["geometry_clean"] and r["connectivity_clean"] else "review violations"
        timing = "pass" if r["routed_setup_hold_pass_both_tools"] else "open"
        lines.append(f"| {r['lanes']} | {r['physical_signal_area_um2']:.3f} | {r['core_area_um2']:.3f} | {r['die_area_um2']:.3f} | {r['pt_routed_setup_ns']:.6f} | {r['pt_routed_hold_ns']:.6f} | {r['innovus_setup_ns']:.3f} | {r['innovus_hold_ns']:.3f} | {timing} | {checks} |")
    lines += ["", "## Activity-based power and conditional throughput", "",
              "One normal 1000-trial case per lane count, identical A/B/K and matching "
              "golden corpora. Activity comes from zero-delay routed-netlist simulation. "
              "Energy = power × captured window duration / completed trials. Busy-cycle "
              "throughput excludes configuration; the power window also includes the "
              "start/sample boundary. Neither is a measured silicon result.", "",
              "| Lanes | Busy cycles | Window (ns) | Target-rate throughput (Mtrials/s) | Power (mW) | Energy (pJ/trial) | Annotated invariant points | Fully annotated cells |",
              "|---:|---:|---:|---:|---:|---:|---:|---:|"]
    for r in rows:
        lines.append(f"| {r['lanes']} | {r['profile_busy_cycles']} | {r['profile_duration_ns']:.1f} | {r['conditional_busy_mtrials_s']:.3f} | {1000*r['estimated_power_w']:.4g} | {r['estimated_energy_pj_per_trial']:.1f} | {r['activity_invariant_annotation_pct']:.2f}% | {r['activity_fully_annotated_cells_pct']:.2f}% |")
    lines += ["", f"Both the mapped and routed replays pass {sum(r['corpus_cases'] for r in rows)} "
              f"cases / {sum(r['corpus_trials'] for r in rows):,} completed trials across the three lane counts.",
              "", "The full CSV retains file digests and run IDs. See " +
              ("[methods and remaining closure work](../docs/Library_Fix_Baseline.md)." if label else
               "[methods and remaining closure work](../docs/Multilane_Implementation.md)."), ""]
    return "\n".join(lines)


def plot(rows, output):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    plt.rcParams.update({"font.size": 10, "axes.spines.top": False, "axes.spines.right": False,
                         "svg.fonttype": "none", "pdf.fonttype": 42})
    fig, axes = plt.subplots(2, 2, figsize=(7.2, 5.5), constrained_layout=True)
    panels = [
        ("dc_area_um2", 0.001, "Mapped cell area (10³ µm²)", "#0072B2", "//", ".1f"),
        ("conditional_busy_mtrials_s", 1, "Conditional throughput (Mtrials/s)", "#E69F00", "..", ".0f"),
        ("estimated_power_w", 1000, "Estimated power (mW)", "#009E73", "xx", ".1f"),
        ("estimated_energy_pj_per_trial", 1, "Estimated energy (pJ/trial)", "#CC79A7", "--", ".1f")]
    for index, (ax, (field, scale, label, color, hatch, fmt)) in enumerate(zip(axes.flat, panels)):
        values = [r[field] * scale for r in rows]
        bars = ax.bar([str(r["lanes"]) for r in rows], values, color=color,
                      edgecolor="#333333", linewidth=0.6, hatch=hatch, width=0.60)
        ax.bar_label(bars, labels=[format(value, fmt) for value in values], padding=3, fontsize=9)
        ax.set(xlabel="Lanes", ylabel=label, ylim=(0, max(values) * 1.22))
        ax.set_axisbelow(True)
        ax.grid(axis="y", alpha=0.2)
        ax.set_title(chr(ord("a") + index), loc="left", fontweight="bold")
    label = library_label(rows)
    subtitle = "Native RC estimates\n" + timing_note(rows)
    title = f"{rows[0]['period_ns']:g} ns target · 1000-trial activity window\n"
    if label:
        title += label + " project approximation\n"
    fig.suptitle(title + subtitle, fontsize=11)
    for suffix in (".png", ".svg", ".pdf"):
        fig.savefig(output.with_suffix(suffix), dpi=600, facecolor="white")
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=REPORTS / "multilane_runs.csv")
    parser.add_argument("--out", type=Path, default=ROOT / "results/multilane_implementation")
    parser.add_argument("--plot", action="store_true")
    args = parser.parse_args()
    with args.manifest.open() as stream:
        runs = list(csv.DictReader(stream))
    if [int(r["lanes"]) for r in runs] != [1, 2, 4]:
        parser.error("expected exactly the ordered 1/2/4-lane matrix")
    try:
        rows = [collect_run(run) for run in runs]
        for field in ("period_ns", "library_db_sha256", "library_lib_sha256", "lef_sha256",
                      "profile_a_hex", "profile_b_hex", "profile_k_hex", "rc_method"):
            if len({r[field] for r in rows}) != 1:
                raise ValueError(f"Unmatched comparison field: {field}")
        library_label(rows)
    except (ValueError, KeyError, OSError) as error:
        parser.error(str(error))
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.with_suffix(".csv").open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    def display_path(path):
        try:
            return str(path.resolve().relative_to(ROOT))
        except ValueError:
            return str(path)
    args.out.with_suffix(".md").write_text(markdown(rows, display_path(args.manifest),
                                                   display_path(args.out)))
    if args.plot:
        plot(rows, args.out)
    print(f"Verified {len(rows)} matched implementations; wrote {args.out}.csv and .md")


if __name__ == "__main__":
    main()
