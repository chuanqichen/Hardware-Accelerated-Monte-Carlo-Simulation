#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
tag=${PNR_TAG:-mc_top_$(date +%Y%m%d_%H%M%S)}
[[ "$tag" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid PNR_TAG" >&2; exit 2; }
command=${INNOVUS:-innovus}
command -v "$command" >/dev/null || { echo "Innovus missing" >&2; exit 2; }
log="$PWD/reports/pnr/$tag.log"
[[ ! -e "$log" && ! -e "$PWD/reports/pnr/$tag" ]] || { echo "Run exists: $tag" >&2; exit 2; }
mkdir -p reports/pnr
tool_status=0
PNR_TAG="$tag" "$command" -no_gui -files scripts/pnr/implement.tcl > "$log" 2>&1 || tool_status=$?
# verifyConnectivity prints "Error Limit = ..."; that is a setting, not an error.
if [[ "$tool_status" -ne 0 ]] || grep -Eq '^(\*\*ERROR|ERROR|Error|Fatal|FATAL|PNR failed)[[:space:]]*:' "$log" || \
   ! grep -q "^PNR_DONE $tag " "$log" || [[ ! -s "reports/pnr/$tag/summary.txt" ]]; then
  tail -n 40 "$log" >&2
  echo "Innovus did not complete cleanly: $log" >&2; exit 1
fi
cat "reports/pnr/$tag/summary.txt"
