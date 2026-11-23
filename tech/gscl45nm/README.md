# Versioned OSU45 setup-table correction

The shared DC, PrimeTime and Innovus flows default to `setup_fixed_v1/gscl45nm.db`
and `setup_fixed_v1/gscl45nm.lib`. Both files are committed, so teammates receive
the correction by checking out this branch. No library compilation is needed
for normal use. The selector verifies both file hashes before loading either.
Explicit `LIB_DB` / `LIB_LIB` overrides remain available for controlled studies.

`original/` preserves the exact installed Liberty and compiled DB used by PR #21.
The upstream FreePDK45 1.4 distribution licenses these OSU standard-cell files
under Apache-2.0. `LICENSE.txt`, `UPSTREAM_README.txt` and `OSU_README.txt` retain
the upstream license, attribution and source description. No SVRF rules or EDA
executables are included.

## Reconstruction rule

Only four `DFFPOSX1/D` entries in `setup_rising` are changed. At each fixed CLK
transition, use two clean entries along the D-transition axis:
`y = y0 + (x-x0)*(y1-y0)/(x1-x0)`.
Interior points use bracketing neighbours; boundary points extrapolate from the
nearest two clean samples. Round to 12 decimal places in ns with ties to even.
The rule is fixed before inspecting timing results.

| Constraint | CLK ns | D ns | Original ns | Reconstructed ns | D-coordinate donors |
|---|---:|---:|---:|---:|---|
| rise | 0.3 | 0.06 | 6.2 | 0.153125 | 0.24, 0.48 |
| rise | 0.3 | 0.90 | 5.125 | 0.1640625 | 0.48, 1.20 |
| rise | 0.6 | 0.06 | 3.075 | 0.1453125 | 0.24, 0.48 |
| fall | 0.3 | 0.48 | 5.85 | 0.310227272727 | 0.24, 0.90 |

These are reproducible project approximations, not physical recharacterization.
They replace the rough example values in the email with a fully specified rule.
The derived Liberty includes a modification notice; its remaining content is
byte-preserved. Hold, propagation, power, area and electrical limits are unchanged.
`manifest.json` records the coordinates, donor values, method and source hashes.
`compiled.json` records the actual LC source/output hashes and tool version.

## Verification and rebuilding

```bash
make library-check
make library-source  # regenerate Liberty and manifest; does not recompile the DB
```

After changing the source, the existing checksums reject stale source/DB pairs.
On a lab host, compile to a fresh output path:

```bash
module load syn/2022
LIB_SOURCE="$PWD/tech/gscl45nm/setup_fixed_v1/gscl45nm.lib" \
LIB_OUTPUT="$PWD/build/library/fresh/gscl45nm.db" \
  lc_shell -f scripts/syn/compile_library.tcl
```

Inspect the LC log for errors and `LIBRARY_DONE`. To publish a rebuilt pair,
copy that DB into `setup_fixed_v1/`, then record its build metadata and run the
verification:

```bash
python scripts/fix_setup_library.py \
  --record-build build/library/fresh/gscl45nm.db.build.txt
make library-check
```

Commit the source, manifest, DB, compiled metadata and `SHA256SUMS` together.
The binary is not expected to reproduce byte-for-byte across compiler versions;
the compiled metadata binds each published binary to its actual input source.

## Original-library controls

For an original-library architecture run, set both:

```bash
export LIB_DB="$PWD/tech/gscl45nm/original/gscl45nm.db"
export LIB_LIB="$PWD/tech/gscl45nm/original/gscl45nm.lib"
```

The fixed-netlist experiment also recompiles the unchanged Liberty with the same
LC version as the corrected copy. This distinguishes compiler conversion effects
from the four-entry edit. Compile that control to
`reports/library/control/gscl45nm.db`, then run
`scripts/sta/compare_setup_library.sh`; it compares installed, recompiled control
and corrected libraries on identical mapped netlists/SDCs at the original slew.

Use separate run tags and result filenames for the new architectural baseline.
The [investigation note](../../docs/PDK_Setup_Investigation.md) records the original
diagnosis and faculty guidance. A setup-table correction does not directly close
hold/electrical violations or supply a characterized RC model.
