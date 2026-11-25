# Lab artifacts of the setup-target trial `tyler_closure3_20261124`

**Result: unsuccessful.** Two-lane setup (-0.010 ns) and four-lane hold (-0.023 ns)
fail Innovus despite passing PrimeTime. `tyler_closure2_20261123` remains the
reference, and `SETUP_TARGET_SLACK_NS` stays opt-in and unset. See the
[setup-target trial](../../../docs/Timing_Electrical_Closure.md#setup-target-trial-unsuccessful).

This record lists every file of the trial so its large outputs can stay on lab
scratch. [files.tsv](files.tsv) gives the SHA-256, size, category and status of
each file. "Committed" means the same bytes are tracked at the same path in this
repository. [make_manifest.py](make_manifest.py) regenerates the list with only
the Python standard library (checked with Python 3.6 and 3.12).

## Location

Host `mario.ece.utexas.edu`, root `/home/work/teh969/mc_closure_20261123`. All
paths in `files.tsv` are relative to that root. The directories are readable only
by their owner, so teammates need a copy from Tyler.

| Status | Files | Bytes |
|---|---:|---:|
| Committed (compact evidence) | 108 | 5,504,087 |
| Lab-only | 637 | 447,141,170 |
| Total | 745 | 452,645,257 |

Lab-only files by category:

| Category | Files | Bytes | Contents |
|---|---:|---:|---|
| layout | 6 | 158,392,409 | Routed DEF and GDS per lane |
| parasitics | 3 | 117,876,267 | Routed SPEF per lane |
| vcs_build | 270 | 71,806,374 | Routed replay `simv`, `simv.daidir` and `csrc` |
| waveform | 3 | 38,284,446 | Routed replay `activity.vcd` used for power |
| innovus_database | 225 | 36,309,822 | `mc_top.enc.dat` and `placed.enc.dat` per lane |
| symlink | 15 | 11,061,798 | Database links to the LEF and Liberty, and `csrc` links to `simv.daidir` archives (target bytes) |
| timing_report | 83 | 7,542,021 | Uncompressed and intermediate Innovus and PT reports |
| netlist | 3 | 5,463,546 | `mc_top.routed.v` per lane |
| constraints | 6 | 278,160 | Routed SDC and PT consumed SDC per lane |
| log | 10 | 87,895 | Replay compile logs, PT parasitic logs, runner and diagnostic logs |
| script | 8 | 19,145 | Innovus-written `clock_tree.tcl`/`views.tcl` and the evidence helpers |
| metadata | 5 | 19,287 | Run manifest, evidence lists and the collector's trial tables |

Key routed outputs (first 16 hex digits of SHA-256; full values are in `files.tsv`):

| Lanes | `mc_top.routed.v` | `mc_top.routed.def` | `mc_top.routed.spef` | `activity.vcd` |
|---:|---|---|---|---|
| 1 | `10ca82cb07f3325e` | `cd61b714d12b5897` | `62d558924d24e615` | `e586fab4271b0db1` |
| 2 | `100872064955e832` | `f66a142f1eb7c38b` | `304a8a932209a54d` | `28f79abf6a302223` |
| 4 | `0190cf402f1bc21d` | `5f38bba316ba13ae` | `1c302fa15bfb3992` | `0f0126fe0317facd` |

## Provenance

- Source commit `f0af8f4cbaf64d0f22160a85c2445c1d9c41f314`, recorded at the top of
  each runner log. Integration rebased it onto the cleaned #22 history as
  `850f73d` with the same patch. That pre-integration commit descends from the
  replaced #22 head `80562b1`, so do not push it or a branch that contains it.
- At `main` `5cda1dd`, `implement.tcl`, `implement.sh`, `run_multilane.sh`,
  `gate_array_sim.sh`, `prelayout.tcl`, `prelayout.sh`, `tb_mc_array.sv` and the
  RTL are byte-identical to the trial's sources. `scripts/syn/config.tcl` differs
  only in how it validates explicit `LIB_DB`/`LIB_LIB` overrides. With both unset,
  as in the trial, it selects the same `setup_fixed_v1` pair.
- Tools on mario (RHEL 8.10) through `module load synopsys/2022 cadence/2022`:
  Innovus v21.18-s099_1, PrimeTime T-2022.03-SP5 and VCS T-2022.06_Full64. The
  trial reused the committed `setupfix_v1_20261123` DC netlists and ran no synthesis.
- Settings from each run's `inputs.txt`: typical corner, native RC estimate with no
  QRC file, nominal timing with no derates, initial utilization 0.60,
  `HOLD_TARGET_SLACK_NS=0.08`, `SETUP_TARGET_SLACK_NS=0.05`,
  `PRESERVE_SYNTH_BUFFERS=1` (no instance deletion), `CTS_MAX_FANOUT=16` and
  `FIX_FANOUT_LOAD=1`.

Inputs:

| Input | SHA-256 | Status |
|---|---|---|
| `reports/syn/setupfix_v1_20261123_l1/mc_top.mapped.v` | `0e1d71833653850cdca21ba613d620bdd3b524931c5cdedc859ccbad847baa52` | committed |
| `reports/syn/setupfix_v1_20261123_l1/mc_top.mapped.sdc` | `aec0df1c94441d33e0a6afff6bcab1fed01ca86be58e381a87dc2eddb043fb59` | committed |
| `reports/syn/setupfix_v1_20261123_l2/mc_top.mapped.v` | `2388a51093ccb4ec4fafe3461fac331578b79aed5b52652e0e51930f9f80e0f8` | committed |
| `reports/syn/setupfix_v1_20261123_l2/mc_top.mapped.sdc` | `2d51a97702ec7499784f239a68a782a76e7cfa2fa8a130e7ab8b64f109650559` | committed |
| `reports/syn/setupfix_v1_20261123_l4/mc_top.mapped.v` | `1a3280aca32c8b28d34909d4443efa6fa3d52bbf21df865b768c4ab7d41367cc` | committed |
| `reports/syn/setupfix_v1_20261123_l4/mc_top.mapped.sdc` | `45541f8491f567494813bb08c822bfcb9ba6221b8c99e934c243f96fcbc04e65` | committed |
| `tech/gscl45nm/setup_fixed_v1/gscl45nm.lib` | `77b2060adaad9793b55a75bfc588408a537dbf7d2b0f7b6cb4fff64b2d6b64ff` | committed |
| `tech/gscl45nm/setup_fixed_v1/gscl45nm.db` | `dd8d0571337905400b247e75069d77fdab50f1d1520442d91cf8df8e39e1d256` | committed |
| `/usr/local/packages/FreePDK45/osu_soc/lib/files/gscl45nm.lef` | `491a1784f428792543ab26f610898d35340979b289145d4fa797c6eddd2825d2` | lab install |
| `tmp/setupfix_v1_20261123_inputs/mc_array_l1_k10.hex` | `0871c93b725d031731588c697062c27eb33780c0906f7852a1283390a162b687` | regenerable |
| `tmp/setupfix_v1_20261123_inputs/mc_array_l2_k10.hex` | `49e1ed15908ecd2ee990eb3fd536a4d9e982248fd5789a042d2035cfea82db88` | regenerable |
| `tmp/setupfix_v1_20261123_inputs/mc_array_l4_k10.hex` | `ee21bd2d3bd3aef4385cb22965f8d57d31054aee0191d7a86eb1804eb4d1b2e9` | regenerable |

The replay corpus was first generated on the laptop. On 2026-11-24,
`scripts/prepare_array_sim.py` on mario (Python 3.12.16, NumPy 2.5.4) reproduced
all six corpus files byte for byte, so mario no longer needs the laptop for it.

## Verify a retained copy

```bash
cd /home/work/teh969/mc_closure_20261123
awk -F'\t' 'NR>1 {print $1"  "$5}' <repo>/reports/lab_artifacts/tyler_closure3_20261124/files.tsv \
  | sha256sum -c --quiet
```

This passed on 2026-11-24. To detect added or missing files as well, rerun the
generator with the arguments below and compare its output with `files.tsv`.

```bash
python <repo>/reports/lab_artifacts/tyler_closure3_20261124/make_manifest.py \
  --root /home/work/teh969/mc_closure_20261123 --tag tyler_closure3_20261124 \
  --reference <checkout of main> --out /tmp/files.tsv \
  --extra tmp/tyler_runs/closure3_l1.out tmp/tyler_runs/closure3_l2.out \
    tmp/tyler_runs/closure3_l4.out tmp/tyler_runs/closure3_runs.csv \
    tmp/tyler_runs/closure3_evidence.txt tmp/tyler_runs/closure3_compact_l14.txt \
    tmp/tyler_runs/evidence_compact.sh tmp/tyler_runs/evidence_list_tag.sh \
    tmp/tyler_runs/results/multilane_closure3.csv tmp/tyler_runs/results/multilane_closure3.md
```

## Reproduce

Use a fresh tag; the runner refuses to overwrite an existing run. Run one lane
count at a time on lab scratch. The trial took 5, 7 and 12 minutes for one, two
and four lanes.

```bash
module load synopsys/2022 cadence/2022
unset LIB_DB LIB_LIB QRC_TECH
python scripts/prepare_array_sim.py --out tmp/setupfix_v1_20261123_inputs  # needs NumPy
sha256sum tmp/setupfix_v1_20261123_inputs/mc_array_l{1,2,4}_k10.hex     # compare with the inputs table
for l in 1 2 4; do
  LANES_LIST=$l SYN_BATCH=setupfix_v1_20261123 PNR_BATCH=<fresh_tag> \
    HOLD_TARGET_SLACK_NS=0.08 SETUP_TARGET_SLACK_NS=0.05 PRESERVE_SYNTH_BUFFERS=1 \
    CTS_MAX_FANOUT=16 FIX_FANOUT_LOAD=1 make implement-multilane
done
PNR_DB=reports/pnr/<fresh_tag>_l4/mc_top.enc.dat DIAG_DIR=<fresh_dir> \
  innovus -no_gui -files scripts/pnr/timing_diagnostics.tcl
```

The trial's own collector table, `tmp/tyler_runs/results/multilane_closure3.md`, was
made with the pre-integration collector. The integrated collector adds policy and
Innovus columns, so a rerun differs in format but should match these values:

| Lanes | PT setup / hold (ns) | Innovus setup / hold (ns) |
|---:|---:|---:|
| 1 | +0.244 / +0.028 | +0.006 / +0.075 |
| 2 | +0.304 / +0.012 | -0.010 / +0.024 |
| 4 | +0.329 / +0.015 | +0.028 / -0.023 |

## Retention

Keep the routed netlists, DEF, SPEF and both Innovus databases while the four-lane
timing decision is open. They are needed to re-time the trial layouts or to
regenerate their PT tables. The VCDs matter only for the power numbers, and the GDS
only for viewing layout. The VCS build products (270 files plus 3 linked archives)
can be regenerated from the routed netlists and are disposable.
