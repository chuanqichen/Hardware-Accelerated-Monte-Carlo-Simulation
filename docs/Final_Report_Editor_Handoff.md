# Final report editor handoff: integration, verification and physical flow

Tyler Haverlah, 2026-11-25. This note tells the final report's editor where Tyler's
material is and what still needs a decision. It links to evidence in `main` instead
of repeating it. The report text,
[Final_Integration_Contribution.md](Final_Integration_Contribution.md), holds every
number. It was merged in PR #25 with Chuanqi's clarifications, and its last section
lists the raw evidence behind each value.

## Sections

| Final report section | What to take from the report text |
|---|---|
| Design and integration | "What I contributed": the controller, configuration bus, lane array and reduction tree |
| Verification | The "Verification" bullets: RTL, mapped and routed replays and the final test runs |
| Physical implementation and results | "Results": conditions, area definitions and the tables below |
| Limitations and future work | "Limits", plus the [RNG path note](RNG_Setup_Path_Diagnostic.md) |
| Team responsibilities | "What I contributed", by PR |

The slides are in [Integration_Presentation_Draft.md](Integration_Presentation_Draft.md):
five slides, about four minutes.

## Tables

All four tables are in the report text's "Results" section. Keep the baseline and
policy tables separate.

1. PR #22 corrected-library baseline, with setup and hold from both tools.
2. `tyler_closure2` reference, with setup and hold from both tools.
3. Area and power cost, using routed signal-cell area.
4. Setup-target trial, labelled unsuccessful.

## Figures

- `results/multilane_setup_fixed_v1.png` and `results/multilane_closure_v1.png`, with
  the caption given in the report text. Panel a shows DC area, which is identical in
  both runs, so quote the closure cost from table 3.
- `docs/figures/lane_block_diagram.png` for the integrated lane.
- The critical path: the same-path table in the RNG path note.
- Layout: committed images exist only for one lane, `docs/figures/implementation_l1.png`
  (PR #21, original library) and `docs/figures/setup_fixed_v1_l1.png` (PR #22
  baseline). No `tyler_closure2` or multi-lane layout image is committed.

## Decisions for the editor

1. **Four-lane status.** Four-lane operation at 5 ns is not established, because
   Innovus misses setup by 6 ps on the lane-3 RNG path. Keep the four-lane throughput
   labelled conditional unless an RNG change passes all three acceptance checks in
   the RNG path note before the report is final. No rated maximum frequency is
   claimed.
2. **Zero-limit capacitance rows.** Report them as unresolved violations with the
   library unchanged. Do not describe them as waived or fixed.
3. **Separate baselines.** Present the PR #22 baseline and `tyler_closure2` as
   separate results. PR #21's original-library implementation also stays separate, in
   `results/multilane_implementation.{csv,md}`.
4. **Area definition.** Use routed signal-cell area for the policy's cost. DC area
   uses Liberty cell areas and routed area uses LEF geometry, so the two are not
   interchangeable.
5. **Setup-target trial.** Keep it as a short unsuccessful experiment or move it to
   an appendix. If it stays, keep its "unsuccessful" label and SI-sensitivity note.
6. **Layout figure.** Use the committed PR #22 one-lane image, or ask Tyler to render
   `tyler_closure2` layouts from his lab databases. The render command is in
   [Multilane_Implementation.md](Multilane_Implementation.md).
7. **Interim text to replace.** The interim report's preliminary-synthesis paragraph
   quotes the PR #11 PrimeTime result and plans one representative layout. PR #12
   showed that the PR #11 setup result was the `DFFPOSX1` table artifact, and the
   final results are matched 1/2/4-lane routed runs. Take throughput from the final
   1,000-trial workload, not from the interim projection.
8. **Credit for the RNG path.** Chuanqi identified the RNG output path and proposed
   the sum register in PR #12. Tyler's note adds the same-path timing comparison and
   the acceptance checks. Shentong owns any RNG change.

This note covers Tyler's material only. Eric's section is
[Final_Pricing_Contribution.md](Final_Pricing_Contribution.md).
