#!/usr/bin/env bash
# Fixed-netlist/fixed-SDC comparison; prepare the rebuilt-original LC control first.
set -euo pipefail
cd "$(dirname "$0")/../.."
reference=${REFERENCE_ROOT:-"$PWD"}
reference_batch=${REFERENCE_BATCH:-implementation_20261123}
control=${CONTROL_LIB_DB:-"$PWD/reports/library/control/gscl45nm.db"}
batch=${AB_BATCH:-setupfix_ab_$(date +%Y%m%d_%H%M%S)}
[[ "$batch" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid AB_BATCH" >&2; exit 2; }
manifest="reports/library/${batch}.csv"
[[ ! -e "$manifest" ]] || { echo "Comparison exists: $manifest" >&2; exit 2; }
[[ -s "$control" ]] || { echo "Compile an unchanged-Liberty control first" >&2; exit 2; }
unset SPEF VCD POWER_WINDOW
mkdir -p reports/library
printf 'lanes,variant,sta_tag\n' > "$manifest"
for lanes in 1 2 4; do
  syn="$reference/reports/syn/${reference_batch}_l${lanes}"
  for variant in installed control fixed; do
    case "$variant" in
      installed) library="$PWD/tech/gscl45nm/original/gscl45nm.db";;
      control) library="$control";;
      fixed) library="$PWD/tech/gscl45nm/setup_fixed_v1/gscl45nm.db";;
    esac
    tag="${batch}_l${lanes}_${variant}"
    NETLIST="$syn/mc_top.mapped.v" MAPPED_SDC="$syn/mc_top.mapped.sdc" \
      LIB_DB="$library" STA_TAG="$tag" bash scripts/sta/prelayout.sh \
      > "reports/library/${tag}.runner.log" 2>&1
    printf '%s,%s,%s\n' "$lanes" "$variant" "$tag" >> "$manifest"
    cat "reports/sta/$tag/summary.txt"
  done
done
echo "LIBRARY_COMPARISON_DONE $batch"
