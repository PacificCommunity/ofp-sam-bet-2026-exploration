# BET 2026 S001 strict refit

This public restart run continues the fitted S001 model from the final PAR stored in Kflow Job 12774.

## Provenance

- Model: `S001-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW11-RRPTTP26`
- Parent fit: Kflow Job `12774`
- Parent final PAR source: `model_payload.rds` compressed `par` artifact
- Parent final PAR SHA-256: `6b8bae94f83a98f7ed5ea7cd278bc5ef521f61e7db9f3406f74d020f1771aab1`
- Parent final maximum gradient: `9.89731527858462e-05`

## Strict restart

The existing `RUN_MODE=job_par` pathway restores the parent final PAR without rerunning earlier phases. MFCL then performs one additional phase-11-style optimization with:

- 20,000 maximum function evaluations;
- convergence exponent `-5` (target `1e-5`);
- independent-variable reporting enabled.

The run writes a standard compact `model_payload.rds`, including the new final PAR artifact, so Kflow Hessian checks can use the result directly.
