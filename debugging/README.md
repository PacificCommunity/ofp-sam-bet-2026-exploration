# Debugging Notes

Dated notes for run/debugging issues that are useful when restarting this work.

| Date | Note | Why it matters |
| --- | --- | --- |
| 2026-06-22 | [Initial run failures](2026-06-22-initial-run-failures.md) | Early Kflow/MFCL failures were caused by inconsistent MFCL input structure, not by Kflow itself. |
| 2026-06-22 | [Regional scaling alignment](2026-06-22-regional-scaling.md) | Steps 06-12 now include `bet.reg_scaling` and MFCL flags 77-81 so plan v2's global regional-scaling CPUE input is explicit. |
| 2026-06-22 | [Fast success with only 04.par](2026-06-22-fast-success-four-par.md) | Explains why one Kflow run finished quickly after PHASE 4 and how `parest_flags(79)=290` plus `set -eu` fixes it. |
| 2026-06-26 | [Input alignment and Kflow rerun](2026-06-26-input-alignment-and-kflow-rerun.md) | Records the 04/05 hybrid `.frq` pairing, 06/07 tag-control alignment fix, and clean 12-step Kflow rerun. |
| 2026-06-26 | [Tag reporting rates PPT check](2026-06-26-tag-reporting-rates-ppt-check.md) | Checks the tag reporting-rate slide deck against generated reporting-rate matrix shapes and clarifies release rows versus pooled rows. |
