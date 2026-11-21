"""Plot mapped-cycle efficiency and conditional throughput projections.

python scripts/plot_integration.py
The frequency comes from the synthesis constraint, not a timing-closure claim.
"""
import argparse
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cycles", type=Path, default=ROOT / "reports/sim/gate_interim_20261111/cycles.csv")
    parser.add_argument("--synthesis", type=Path, default=ROOT / "results/one_lane_interim_5ns.csv")
    parser.add_argument("--out", type=Path, default=ROOT / "results/one_lane_interim_throughput")
    args = parser.parse_args()
    with args.cycles.open(newline="") as file:
        cases = list(csv.DictReader(file))
    if len(cases) != 22 or sum(int(row["trials"]) for row in cases) != 26457:
        parser.error("expected the complete 22-case / 26457-trial mapped corpus")
    points = {}
    for row in cases:
        trials, cycles = int(row["trials"]), int(row["cycles"])
        if trials <= 0 or cycles != trials + 11:
            parser.error("unexpected default one-lane busy-cycle count")
        points[trials] = cycles
    with args.synthesis.open(newline="") as file:
        synth = list(csv.DictReader(file))
    if len(synth) != 1 or synth[0]["design"] != "mc_top":
        parser.error("expected one mc_top synthesis result")
    period = float(synth[0]["clk_period_ns"])
    if period <= 0:
        parser.error("clock period must be positive")
    rows = [dict(trials=n, measured_busy_cycles=points[n], trials_per_busy_cycle=n / points[n],
                 target_period_ns=period, projected_mtrials_s=1000 / period * n / points[n],
                 scope="conditional_on_target_frequency_no_configuration_overhead")
            for n in sorted(points)]
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.with_suffix(".csv").open("w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=list(rows[0]))
        writer.writeheader(); writer.writerows(rows)

    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(8.6, 4.5))
    ax.plot([r["trials"] for r in rows], [100 * r["trials_per_busy_cycle"] for r in rows],
            "o-", color="#3569a8", linewidth=2)
    for row in rows:
        if row["trials"] in (1, 100, 1000, 10000):
            offset = {1: (8, 12), 100: (8, -28), 1000: (-8, -38), 10000: (-8, -22)}[row["trials"]]
            ax.annotate(f"N={row['trials']:,}\n{row['measured_busy_cycles']:,} cycles",
                        (row["trials"], 100 * row["trials_per_busy_cycle"]),
                        xytext=offset,
                        textcoords="offset points", ha="left" if offset[0] > 0 else "right",
                        fontsize=8)
    ax.set_xscale("log")
    ax.set_ylim(0, 108)
    ax.set_xlabel("trials per run (N)")
    ax.set_ylabel("trials per busy cycle [% of one trial/cycle]")
    ax.axhline(100, color="#999", linestyle="--", linewidth=1)
    ax.grid(alpha=0.2)
    ax.set_title("One-lane batch efficiency: measured cycles = N + 11")
    fig.text(0.5, 0.025, f"At the {period:g} ns target, N=10,000 projects to "
             f"{1000 / period * 10000 / points[10000]:.2f} Mtrials/s. "
             "Target frequency has not closed in PrimeTime.\n"
             "Zero-delay mapped simulation; busy cycles exclude configuration and reset release.",
             ha="center", fontsize=8, color="#444")
    fig.tight_layout(rect=(0, 0.12, 1, 1))
    fig.savefig(args.out.with_suffix(".png"), dpi=200)
    plt.close(fig)
    print(f"Wrote {args.out}.csv and .png")


if __name__ == "__main__":
    main()
