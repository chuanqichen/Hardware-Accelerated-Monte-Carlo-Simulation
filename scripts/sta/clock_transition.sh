#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
pt_command=${PT_SHELL:-pt_shell}
export OUT=${OUT:-reports/sta/clkslew_$(date +%Y%m%d_%H%M%S)}
log="${OUT}.log"
[[ ! -e "$OUT" && ! -e "$log" ]] || { echo "Run exists: $OUT" >&2; exit 2; }
command -v "$pt_command" >/dev/null || { echo "PrimeTime missing" >&2; exit 2; }
mkdir -p "$(dirname "$OUT")"
"$pt_command" -f scripts/sta/pt_clock_transition_check.tcl 2>&1 | tee "$log"
if grep -Eq '^(Error|Fatal|FATAL|CLKSLEW failed)(:|[[:space:]-])' "$log" ||
   ! grep -Fq "CLKSLEW_DONE $OUT " "$log"; then
  echo "Clock-transition study did not complete cleanly: $log" >&2; exit 1
fi
for file in source_sha256.txt inputs.txt summary.txt setup_clkslew_0.10.rpt setup_clkslew_0.06.rpt; do
  [[ -s "$OUT/$file" ]] || { echo "Missing study evidence: $OUT/$file" >&2; exit 1; }
done
for slew in 0.10 0.06; do
  grep -q "^CLKSLEW $slew worst_endpoint .* arrival .* slack " "$OUT/summary.txt" || {
    echo "Missing slew result: $slew" >&2; exit 1;
  }
done
echo "Clock-transition study complete; inspect $OUT"
