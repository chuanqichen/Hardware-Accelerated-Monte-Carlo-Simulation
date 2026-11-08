# RNG lab evidence review

Run: rng_20261108_231630, executed by Shentong on Mario, 2026-11-08.
Reviewed archive: build/rng_validation_evidence_rng_20261108_231630.tar.gz.
Its SHA-256 and every original member's digest/path mapping are recorded in
archive_manifest.json. The original transcript remains preserved separately.

## Provenance and reproducibility

- All 79 runtime source hashes agree between the exported source manifest,
  the run manifest and the current runtime files of source commit 6aa595f.
- All six source hashes in the RTL quality manifest match the run manifest.
- The synthesis input hashes match the RNG RTL/package, shared constraints,
  config.tcl and dc_synth.tcl.
- The standard-cell library digest is
  4968d1dba7ff9911cc51dfac7d8ea8b94fbab59d2f862f0531d7c774fb0a5791.
  It matches the committed mc_top_shared_5ns baseline.
- inputs.txt identifies Design Compiler T-2022.03-SP2, gscl45nm.db,
  typical conditions and a 5 ns constraint. power.rpt reports 1.1 V.
- The original run had no Git checkout. Source hashes establish the input
  correspondence; no fresh VCS/DC rerun by Codex is claimed.

## Functional and stream checks

The raw logs contain the expected PASS markers:
- 85 model tests.
- RNG: 4,440 vector cycles / 1,763 valid words.
- Integrated top: all four G/M=1/2 configurations, each 22 cases / 26,457
  trials, with exact traces/results and sustained II=1.
- Real one-lane bubble test: 100 exact trials, pause/resume, valid latency=10.
- Three uninterrupted RTL streams: 1,048,576 words each, II=1.
- Imported-stream canonical checking and declared statistical screening.

The three omitted raw hex streams were independently regenerated with
model/rng_canonical_reference.py. Every word was formatted as the original
eight-digit lowercase hexadecimal line. All three full-file SHA-256 values
match the lab input hashes:
- stream 0: ea77ecbb3d12742440308511d8c2cfaf74165c096a786ae560959bccddd532eb
- stream 1: 82a765c885aeb3eef49ad9aff361a012a33958d7653f57ae0696abd203a1a072
- stream 2: 8f1a0e1aa00fd401417727440348c271dc4d4b445d409e6eeca5562fcc528bb7

Summary moments, top-10-bit histograms and all bit counts reproduce the RTL
tables. Serial correlations agree within 1e-12 across the two environments.
The plotted statistics are now backed by canonical-checked RTL exports.
All screens passed, but this is not a statistical battery or an independence
proof.

Each short VCD was also checked independently: its first 32 output words
match the canonical oracle at 10 ns intervals from 25 ns through 335 ns.
u_valid remains high through those samples. VCD capture then stops as
designed. The full-run scoreboards, rather than these short VCDs, cover the
entire million-word streams.

The model log's test_fixture: FAIL RNG screening line is expected output from
the passing duplicate-stream rejection test. It is not a failed unit test.

## Synthesis findings

Replaying scripts/parse_reports.py on the raw reports reproduces every field
of results/rng_20261108_231630_ppa.csv after normalizing CSV scalar types.

- Cell area: 5,274.931992 um^2; 1,568 cells / 161 registers in summary.txt.
- Setup slack: +0.00604582 ns at 5 ns, with ideal clocks.
- Critical path: s0_reg[0] -> u_reg[31]. timing.rpt traverses multiple
  intadd_* carry paths; qor.rpt reports 95 logic levels and a rounded
  4.77 ns critical path length.
- Zero reported hold and max-transition violations.
- 516 maximum-capacitance violating nets. All are retained in the CSV result
  mapped_with_violations; 500 rows explicitly say increase significant digits.
  The report uses pF, but its rounded 0.00 required capacitance must not be
  interpreted as a literal zero limit.
- The violations include internal arithmetic/state nets, for example n1154,
  intadd_0/n14 and shifted1 bits. They cannot be attributed solely to the
  external output load from this report.
- constraints.rpt also marks max_leakage_power violated. synthesis.log shows
  a max_leakage_power 0 optimization target. Preserve this diagnostic; confirm
  its treatment with the shared-flow owner. The current PPA CSV has no
  leakage-constraint status column.
- Power is explicitly unannotated (PWR-414). The parsed total is 1.1657 mW;
  the raw report's total footer rounds to 1.1658 mW. Retain the original
  outputs and their display precision. No activity-based energy/trial claim.

The 200.242 MHz Fmax remains a slack-derived pre-layout estimate.
The observed RTL II=1 and the 200 MHz setup target support a constrained
200 million RNG words/second estimate, not physical timing closure.

## Tool diagnostics

stream_compile.log.txt reports a cfs_ident_exec segmentation fault after the
simulation executable was linked. That source-identification helper failure
is recorded explicitly. Subsequent runs of the fresh executable passed all
three scoreboards, and the VCD/data/checksum checks above passed.
Compilation also reports timescale/width lint diagnostics (NS and WMIA-L);
integrated compilation includes the existing ULCO comparison-width warning.
No claim of a warning-free build is made.

## Follow-up

1. With Tyler, inspect the saved mapped DDC using the same library and
   constraints. Generate report_constraint -all_violators -nosplit
   -significant_digits 6, then inspect representative violating driver
   library limits, net loads and fanout. Do not relax common comparison
   constraints just to remove violations.
2. Record whether each outstanding electrical/power objective is a library,
   constraint, mapping or physical implementation follow-up. Re-run the
   affected checks if RTL or synthesis settings change.
3. Keep the PR draft pending agreement on this follow-up; no draft-to-ready
   or merge action is performed by this review.

Raw logs are versioned as .log.txt with unchanged bytes. VCDs are retained
locally and remain gitignored; their exact bytes and paths are covered by
archive_manifest.json. Binary DDC/SVF artifacts remain in the original archive.
