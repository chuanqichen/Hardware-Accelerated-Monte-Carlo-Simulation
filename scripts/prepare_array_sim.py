"""Prepare bounded portable lab inputs without changing committed baseline ROMs."""
import argparse
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "model"))
from gen_mc_array_vectors import generate as generate_array
from gen_mc_top_vectors import generate as generate_top
from price_dp import PriceDpConfig, write_exp_rom_sv


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error("Output exists; choose a fresh directory")
    args.out.mkdir(parents=True)
    for exp_bits in (10, 8):
        for lanes in (1, 2, 4):
            generate_array(args.out / f"mc_array_l{lanes}_k{exp_bits}.hex", lanes, exp_bits=exp_bits)
    generate_top(args.out / "k8", exp_bits=8)
    write_exp_rom_sv(PriceDpConfig(exp_addr_bits=8), args.out / "k8/exp2_rom.sv")


if __name__ == "__main__":
    main()
