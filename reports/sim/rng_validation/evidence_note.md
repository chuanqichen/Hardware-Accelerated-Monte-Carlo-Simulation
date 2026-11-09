# Lab evidence

The PPA CSV and run manifest were initially supplied as terminal text.
The full raw archive was subsequently copied from Mario, imported selectively
and reviewed. See review.md for verified PASS markers, independent canonical
stream checksums/statistics, source/library hashes, VCD checks, synthesis
findings and remaining electrical/tool diagnostics.

archive_manifest.json records original archive/member hashes and imported
paths. Raw logs use .log.txt names with unchanged bytes. VCDs are local and
ignored; binary DDC/SVF files remain in the original archive. The original
supplied terminal transcript is preserved.

## Report locations

Simulation logs and run/audit metadata are in reports/sim/rng_validation/.
Synthesis reports and synthesis/parser logs are in reports/syn/rng_validation/.
Original archive member names, source hashes and paths embedded in raw logs
are historical and unchanged. archive_manifest.json maps those members to
their current local paths. Runner/parser layout changes after commit
6aa595f do not alter the recorded RTL validation.
