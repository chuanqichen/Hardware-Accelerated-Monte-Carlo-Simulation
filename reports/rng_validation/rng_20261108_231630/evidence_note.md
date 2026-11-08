# Supplied lab evidence

Run: rng_20261108_231630 on Mario, reported by Shentong on 2026-11-08.
The run manifest and PPA CSV were copied from the supplied terminal transcript.
The earlier supplied runner output ended in PASS RNG lab validation.

All 79 input SHA-256 entries match the local runtime sources used for PR #10
(commit 6aa595f). The run used a source export, so its manifest deliberately
records git_revision=source_export. This match covers the RTL, testbenches,
vectors, model code, runner, synthesis scripts, constraints and Makefile.

The runner's reported completion implies acceptance of model tests, standalone
and integrated VCS checks, three uninterrupted RTL streams of 1,048,576 words
each, canonical comparison, stream screening and synthesis report parsing.
Raw VCS/DC logs, RTL statistics tables, waveform files and synthesis reports
have not yet been transferred into this checkout. No independent rerun by
Codex or inspection of those missing files is claimed.

Reported setup slack is +0.00604582 ns at a 5 ns constraint; the CSV reports
516 max-capacitance violations, zero hold violations and zero max-transition
violations. Retain mapped_with_violations. The 200.242 MHz Fmax is the shared
parser's slack-derived pre-layout estimate, not post-route signoff.
Power (1.1657 mW) is an unannotated-input estimate, not measured energy/trial.
The raw timing/constraint reports and synthesis inputs/library hash are needed
before reviewing the violation causes and exact library/corner assumptions.
