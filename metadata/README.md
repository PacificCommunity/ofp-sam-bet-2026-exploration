# Metadata

Optional metadata for plotting and reporting.

Files in this folder should describe labels and assessment context without
changing MFCL model inputs. If a downstream workflow does not find these files,
it should use MFCL numeric identifiers and fail only when a required modelling
input is missing.

Suggested files:

- `fisheries.csv`: fishery labels, regions, groups, and tag recapture groups.
- `tag_reporting.csv`: tag reporting group labels.
- `regions.csv`: optional region labels.
- `assessment.yml`: optional species, assessment year, and report metadata.

