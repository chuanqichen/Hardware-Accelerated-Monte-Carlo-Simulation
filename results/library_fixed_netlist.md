# Fixed-netlist library comparison

Generated from `reports/library/setupfix_v1_20261123_ab2.csv` by `scripts/summarize_library_comparison.py`.
Each lane count uses the exact PR #21 mapped netlist and SDC for all three libraries. The period remains 5 ns and the clock transition 0.10 ns. No resynthesis or extracted parasitics are involved.

| Lanes | Installed setup (ns) | Recompiled-original setup (ns) | Fixed setup (ns) | Fixed hold (ns) |
|---:|---:|---:|---:|---:|
| 1 | -0.016767 | -0.016767 | +0.020597 | -0.041178 |
| 2 | -0.046107 | -0.046107 | +0.033530 | -0.041178 |
| 4 | -0.018574 | -0.018574 | +0.100237 | -0.041178 |

The recompiled-original control uses the same LC version as the fixed library. The CSV retains the actual library, netlist and SDC digests, worst endpoints and DFFPOSX1 path information. The worst DFFPOSX1 endpoint may differ between variants; its setup requirement is not a matched-endpoint delta.

The corrected values are the documented `setup_fixed_v1` approximation. See [the resulting architectural baseline](../docs/Library_Fix_Baseline.md).
