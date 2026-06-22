# Initial Run Debugging Notes

Short version: most early failures were not because Kflow itself was broken.
The MFCL input files were present, but several files did not describe the same
model structure.

## What Broke

- `.frq` header said 33 fisheries, but the fishery-region line originally had
  only 28 extraction fisheries.
- Some `.ini` files were labelled MFCL 1007 but had no `# tag flags` block.
- Some mix-period `.ini` files had zero tag mixing periods, which current MFCL
  rejects.
- Some `.frq` records had absent-LF markers followed by stray LF bins.
- 04/05 used 2021-chopped `.frq` files but 2026 91-release `.ini/.tag` files,
  so MFCL stopped at tag release group 18 hitting the terminal model period.

## What Fixed It

- Added index fishery regions 1-5 so the `.frq` fishery-region line has all 33
  fisheries.
- Inserted explicit `# tag flags` for 03-07.
- Changed zero tag mixing periods to 1 for 08-12 mix-period `.ini` files.
- Normalized 84 old absent-LF `.frq` records.
- Made 04/05 use the 03-RegFish 90-release `.ini/.tag` setup and reset their
  chopped `.frq` tag-group header from 91 to 90.

## Mental Model

MFCL needs `.frq`, `.ini`, `.tag`, `.age_length`, and `doitall.sh` to agree on
the same structure: fishery count, tag group count, terminal year, and tag
mixing setup.

The main fix was aligning those contracts step by step.

## Remaining Known Noise

- `caught before it was released` tag warnings still appear in local
  `-makepar` smoke checks. These are known upstream tag-prep warnings and are
  documented in the model READMEs.
- Full results/report should only be submitted after the active 12 input jobs
  finish successfully.
