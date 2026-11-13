#!/usr/bin/env bash
# PrimeTime may log command errors without a nonzero process exit.
set -euo pipefail
cd "$(dirname "$0")/../.."
pt_command=${PT_SHELL:-pt_shell}
tag=${STA_TAG:-mc_top_$(date +%Y%m%d_%H%M%S)}
[[ "$tag" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid STA_TAG" >&2; exit 2; }
log="$PWD/reports/sta/$tag.log"
[[ ! -e "$log" && ! -e "$PWD/reports/sta/$tag" ]] || { echo "STA run exists: $tag" >&2; exit 2; }
command -v "$pt_command" >/dev/null || { echo "PrimeTime missing" >&2; exit 2; }
mkdir -p reports/sta
STA_TAG="$tag" "$pt_command" -f scripts/sta/prelayout.tcl 2>&1 | tee "$log"
if grep -Eq '^(Error|Fatal|FATAL|STA failed)(:|[[:space:]-])' "$log" || \
   ! grep -q "^STA_DONE $tag " "$log" || [[ ! -s "reports/sta/$tag/summary.txt" ]]; then
  echo "PrimeTime did not complete cleanly: $log" >&2; exit 1
fi
# Success means analysis ran; slack/coverage/electrical failures remain visible.
echo "STA analysis complete; inspect reports/sta/$tag"
