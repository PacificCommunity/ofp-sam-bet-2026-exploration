# Debugging Notes

Dated notes for run/debugging issues that are useful when restarting this work.

| Date | Note | Why it matters |
| --- | --- | --- |
| 2026-06-22 | [Initial run failures](2026-06-22-initial-run-failures.md) | Early Kflow/MFCL failures were caused by inconsistent MFCL input structure, not by Kflow itself. |
| 2026-06-22 | [Regional scaling alignment](2026-06-22-regional-scaling.md) | Steps 08-15 now include an active-window `bet.reg_scaling` and MFCL flags 77-81 so the global regional-scaling CPUE prior is explicit. |
| 2026-06-22 | [Fast success with only 04.par](2026-06-22-fast-success-four-par.md) | Explains why one Kflow run finished quickly after PHASE 4 and how regional-scaling period flags plus `set -eu` fixed it. |
| 2026-06-26 | [Input alignment and Kflow rerun](2026-06-26-input-alignment-and-kflow-rerun.md) | Records the 04/05 hybrid `.frq` pairing, 06/07 tag-control alignment fix, and clean 12-step Kflow rerun. |
| 2026-06-26 | [Tag reporting rates PPT check](2026-06-26-tag-reporting-rates-ppt-check.md) | Checks the tag reporting-rate slide deck against generated reporting-rate matrix shapes and clarifies release rows versus pooled rows. |
| 2026-07-02 | [Tag reporting `it2=0` rerun](2026-07-02-tag-reporting-it2-zero-rerun.md) | Records why 07-09 failed with stale zero reporting-rate cells, why step 10 differed, and how the updated 2026 RR matrix rerun is configured. |
