#!/bin/sh
set -eu

program_path=${PROGRAM_PATH:-}

if [ -z "$program_path" ]; then
  echo "PROGRAM_PATH is not set. Exiting."
  exit 1
fi

phase10_11_convergence=${BET_PHASE10_11_CONVERGENCE:--3}
case "$phase10_11_convergence" in
  -[0-9]|-[0-9][0-9]|[0-9]|[0-9][0-9]) ;;
  *)
    echo "BET_PHASE10_11_CONVERGENCE must be numeric, e.g. -3 for quick runs or -5 for strict runs." >&2
    exit 1
    ;;
esac
echo "PHASE 10/11 convergence criterion: $phase10_11_convergence"


# -----------------------------------
#  PHASE 0 - create initial par file
# -----------------------------------

$program_path bet.frq bet.ini 00.par -makepar

# -----------------------
#  PHASE 1 - initial par
# -----------------------

$program_path bet.frq 00.par 01.par -file - <<PHASE1
# Use default quasi-Newton minimizer
  1 351 0
  1 192 0
# Allow all growth parameters to be fixed during control phase
  1 32 7
# Richards growth settings
  1 226 0
  1 227 0
# Catch conditioned flags
# General activation
  1 373 1  # activate CC with Baranov equation
  1 393 0  # estimate kludged_equilib_coffs and implicit_fm_level_regression_pars
  2 92 2   # specify catch-conditioned option with Baranov equation
# Catch equation bounds
  2 116 70   # value for Zmax_fish in catch equations
  2 189 80   # fraction of Zmax_fish above which penalty is calculated
  1 382 300  # weight for Zmax_fish penalty - set to 300 to avoid triggering Zmax_flag=1
# Deactivate any catch errors flags
  -999 1 0
  -999 4 0
  -999 10 0
  -999 15 0
  -999 13 0
# Survey fisheries defined
# fish flag 92 = round(sigma * 100); fish flag 94 allows unequal sigma.
# fish flag 66=1 reads FRQ effort_weight as temporal variance multiplier lambda_t.
# With parest flag 371=0, MFCL uses lambda_t * sigma^2 after normalizing
# lambda_t to mean one within each fishery.
# HAC4 target = base sigma * sqrt(Bartlett Newey-West DE at lag 4).
  -29 94 1 -29 92 40 -29 66 1  # Index R1 HAC4 sigma: base 0.35, DE4 1.294765, target 0.398, applied 0.40
  -30 94 1 -30 92 30 -30 66 1  # Index R2 HAC4 sigma: base 0.24, DE4 1.587703, target 0.302, applied 0.30
  -31 94 1 -31 92 35 -31 66 1  # Index R3 HAC4 sigma: base 0.21, DE4 2.820362, target 0.353, applied 0.35
  -32 94 1 -32 92 32 -32 66 1  # Index R4 HAC4 sigma: base 0.24, DE4 1.797746, target 0.322, applied 0.32
  -33 94 1 -33 92 30 -33 66 1  # Index R5 HAC4 sigma: base 0.23, DE4 1.686407, target 0.299, applied 0.30
# Grouping flags for survey CPUE
   -1 99 1
   -2 99 2
   -3 99 3
   -4 99 4
   -5 99 5
   -6 99 6
   -7 99 7
   -8 99 8
   -9 99 9
  -10 99 10
  -11 99 11
  -12 99 12
  -13 99 13
  -14 99 14
  -15 99 15
  -16 99 16
  -17 99 17
  -18 99 18
  -19 99 19
  -20 99 20
  -21 99 21
  -22 99 22
  -23 99 23
  -24 99 24
  -25 99 25
  -26 99 26
  -27 99 27
  -28 99 28
  -29 99 29
  -30 99 29
  -31 99 29
  -32 99 29
  -33 99 29
# Recruitment and initial population settings
  1 149 100        # recruitment deviation penalty
  1 400 6          # final six recruitment deviates set to zero
# Fixed terminal recruitments are arithmetic mean of remaining period (not default geometric mean)
  1 398 1
  2 177 1          # use old totpop scaling method
  2 32 1           # and estimate totpop parameter
  2 93 4           # set no. of recruitments per year to 4
  2 57 4           # set no. of recruitments per year to 4
  2 94 1 2 128 100  # initial Z = 1.0*M, i.e. initial F = 0
# Likelihood component settings
  1 111 4     # set likelihood function for tags to negative binomial
  1 141 11    # LF Dirichlet-multinomial likelihood without random effects
  1 320 5     # DM LF tail compression; retain at least five class intervals
  1 342 20  # DM-noRE maximum LF effective sample size
  1 139 3     # set likelihood function for WF data to normal
  -999 49 20  # divide LF sample sizes by 20
  -1 68 1  # DM LF group: Longline extraction
  -2 68 1  # DM LF group: Longline extraction
  -3 68 1  # DM LF group: Longline extraction
  -4 68 1  # DM LF group: Longline extraction
  -5 68 1  # DM LF group: Longline extraction
  -6 68 1  # DM LF group: Longline extraction
  -7 68 1  # DM LF group: Longline extraction
  -8 68 1  # DM LF group: Longline extraction
  -9 68 1  # DM LF group: Longline extraction
  -10 68 1  # DM LF group: Longline extraction
  -11 68 1  # DM LF group: Longline extraction
  -12 68 2  # DM LF group: Large-scale purse seine
  -13 68 4  # DM LF group: Other extraction
  -14 68 4  # DM LF group: Other extraction
  -15 68 4  # DM LF group: Other extraction
  -16 68 4  # DM LF group: Other extraction
  -17 68 3  # DM LF group: Domestic purse seine
  -18 68 3  # DM LF group: Domestic purse seine
  -19 68 2  # DM LF group: Large-scale purse seine
  -20 68 2  # DM LF group: Large-scale purse seine
  -21 68 4  # DM LF group: Other extraction
  -22 68 4  # DM LF group: Other extraction
  -23 68 4  # DM LF group: Other extraction
  -24 68 4  # DM LF group: Other extraction
  -25 68 2  # DM LF group: Large-scale purse seine
  -26 68 2  # DM LF group: Large-scale purse seine
  -27 68 2  # DM LF group: Large-scale purse seine
  -28 68 2  # DM LF group: Large-scale purse seine
  -29 68 5  # DM LF group: Index
  -30 68 5  # DM LF group: Index
  -31 68 5  # DM LF group: Index
  -32 68 5  # DM LF group: Index
  -33 68 5  # DM LF group: Index
  -999 69 1  # estimate group-specific DM LF scalar exponent
  -999 89 0  # stage relative sample-size exponent as fixed at zero
  -999 50 20  # divide WF sample sizes by 20
# Additional LF/WF sample-size reductions retained from the inherited setup.
# Index fisheries 29-33 are included; extraction labels need the 03 fishery map.
   -1 49 40   -1 50 40
   -2 49 40   -2 50 40
   -4 49 40   -4 50 40
   -6 49 40   -6 50 40
   -7 49 40   -7 50 40
   -8 49 40   -8 50 40
  -10 49 40  -10 50 40
  -29 49 40  -29 50 40
  -30 49 40  -30 50 40
  -31 49 40  -31 50 40
  -32 49 40  -32 50 40
  -33 49 40  -33 50 40
# Tag dynamics settings
  1 33 99    # maximum tag reporting rate for all fisheries is 0.99
  2 96 30    # pool tags after 30 quarters at liberty
# Mixing periods are read from bet.ini tag flags for this step.
  2 198 1    # activate release group reporting rates
  -999 43 0  # estimate tag variance if = 1
  -999 44 0  # group all tags for variance estimation if = 1
# Grouping of fisheries for tag return data, mapped from BET_PHrev_FNL.xlsx.
# New labels with region 4 in the workbook are treated as region 5 here.
   -1 32 1   # LL.WEST.1, old1
   -2 32 2   # LL.EAST.1, old2
   -3 32 3   # LL.US.1, old3
   -4 32 4   # LL.ALL.2, old7
   -5 32 5   # LL.OS.2, old6
   -6 32 6   # LL.ARCH.3, old8
   -7 32 7   # LL.WEST.3, old4
   -8 32 8   # LL.EAST.3, old9
   -9 32 9   # LL.OS.3, old5
  -10 32 10  # LL.ALL.5, old11 + old12 + old29
  -11 32 11  # LL.AU.5, old10 + old27
  -12 32 12  # PS.JP.1, old19
  -13 32 13  # PL.JP.1, old20
  -14 32 14  # HL.ID.2, part of old18
  -15 32 14  # HL.PH.2, part of old18
  -16 32 15  # PL.ALL.2, old28
  -17 32 14  # PS.ID.2, split old24
  -18 32 14  # PS.PH.2, split old24
  -19 32 16  # PS.ASS.2, old30
  -20 32 16  # PS.UNA.2, old31
  -21 32 14  # DOM.ID.2, old23
  -22 32 14  # DOM.PH.2, old17
  -23 32 17  # DOM.VN.2, old32
  -24 32 18  # PL.ALL.WEST.3, old21 + old22
  -25 32 19  # PS.ASS.WEST.3, old13 + old25
  -26 32 20  # PS.ASS.EAST.3, old15
  -27 32 19  # PS.UNA.WEST.3, old14 + old26
  -28 32 20  # PS.UNA.EAST.3, old16
  -29 32 21  # Index R1
  -30 32 21  # Index R2
  -31 32 21  # Index R3
  -32 32 21  # Index R4
  -33 32 21  # Index R5
# Selectivity settings
  -999 3 37  # all selectivities equal for age class 37 and older
  -999 26 2  # build selectivity-at-age by evaluating the spline on scaled mean length-at-age (not length-bin selectivity)
  -999 57 3  # cubic spline basis for selectivity
  -999 61 5  # five spline nodes on the scaled mean-length-at-age coordinate
# SA28: independent extraction selectivity with contiguous MFCL group labels.
  -1 24 1  # LL.WEST.ALL.1
  -2 24 2  # LL.EAST.ALL.1
  -3 24 3  # LL.US.1
  -4 24 4  # LL.ALL.2
  -5 24 5  # LL.OS.2
  -6 24 6  # LL.ARCH.3
  -7 24 7  # LL.WEST.3
  -8 24 8  # LL.EAST.4
  -9 24 9  # LL.OS.3
  -10 24 10  # LL.ALL.5
  -11 24 11  # LL.AU.5
  -12 24 12  # PS.JP.1
  -13 24 13  # PL.JP.1
  -14 24 14  # HL.ID.2
  -15 24 15  # HL.PH.2
  -16 24 16  # PL.ALL.2
  -17 24 17  # PS.ID.2
  -18 24 18  # PS.PH.2
  -19 24 19  # PS.ASS.2
  -20 24 20  # PS.UNA.2
  -21 24 21  # MISC.ID.2
  -22 24 22  # MISC.PH.2
  -23 24 23  # MISC.VN.2
  -24 24 24  # PL.ALL.WEST.3
  -25 24 25  # PS.ASSOC.WEST.3
  -26 24 26  # PS.ASSOC.EAST.4
  -27 24 27  # PS.UNASSOC.WEST.3
  -28 24 28  # PS.UNASSOC.EAST.4
  -29 24 29  # Index R1; shared initialization group through phase 4
  -30 24 29  # Index R2; shared initialization group through phase 4
  -31 24 29  # Index R3; shared initialization group through phase 4
  -32 24 29  # Index R4; shared initialization group through phase 4
  -33 24 29  # Index R5; shared initialization group through phase 4
# Single-area extraction monotonicity constraint.
   -9 16 1
# Single-area extraction young-age constraints.
  -1 75 2
  -2 75 2
  -3 75 2
  -4 75 2
  -5 75 2
  -6 75 2
  -7 75 2
  -8 75 2
  -9 75 2
  -10 75 2
  -11 75 2
  -12 75 2
  -13 75 1
  -15 75 5
# Corrected regional-index early-age constraints.
  -29 75 2  # Index R1
  -30 75 2  # Index R2
  -31 75 2  # Index R3
  -32 75 2  # Index R4
  -33 75 2  # Index R5
# Single-area extraction age-spline and upper-age constraints.
  -12 16 2  -12 3 25
  -13 16 2  -13 3 30
  -14 16 0  -14 3 37
  -15 16 0  -15 3 37
  -17 16 2  -17 3 25
  -18 16 2  -18 3 25
  -19 16 2  -19 3 25
  -20 16 0  -20 3 37
  -25 16 2  -25 3 25
  -26 16 2  -26 3 25
  -27 16 2  -27 3 30
  -28 16 0  -28 3 37
  -16 16 2  -16 3 25
  -24 16 2  -24 3 25
  -21 16 2  -21 3 10
  -22 16 2  -22 3 7
  -23 16 2  -23 3 6
# Turn on weighted spline for calculating maturity at age
  2 188 2
# Set Lorenzen M
  2 109 3  # select Lorenzen curve
  1 121 0  # do not estimate Lorenzen scaling parameter yet
# Filter out comps with input samples less than 50
  1 311 1 # retain LF preprocessing gate so the inherited N < 50 filter remains active
  1 301 1   # set tail compression for WF data
  1 313 0   # proportions in compressed tails for LF data
  1 303 0   # proportions in compressed tails for WF data
  1 312 50  # set minimum obs sample size for LF data
  1 302 50  # set minimum obs sample size for WF data
# MFCL 2.2.2.0 growth variance fix
  1 34 0    # set to 1 34 1 for backwards compatibility
PHASE1

# ---------
#  PHASE 2
# ---------

$program_path bet.frq 01.par 02.par -file - <<PHASE2
  -999 89 1  # estimate group-specific DM LF relative sample-size exponent
  1 1 100  # set max. number of function evaluations per phase to 100
  1 50 0   # set convergence criterion to 1
  2 113 0  # scaling init pop - turned off
  1 190 0 # defer DM plot reporting until the final phase; MFCL 2.4 crashes on the early report
PHASE2

# ---------
#  PHASE 3
# ---------

$program_path bet.frq 02.par 03.par -file - <<PHASE3
# OPR settings from the reviewed PDH model: 72-01-50-50.
  1 149 0   # turn off recruitment-deviation penalty for OPR
  1 398 0   # turn off arithmetic-mean terminal fixed-recruitment option for OPR
  1 400 0   # clear fixed terminal recruitment-deviate block for OPR
  2 177 0   # turn off old total-pop scaling for OPR
  2 32 0    # turn off overall population scaling parameter for OPR
  2 113 0   # keep scaling init pop off during OPR transfer
  1 155 72  # orthogonal polynomial recruitment - year effect
  1 221 72  # compatibility state retained from the reviewed PDH par
  1 217 1   # orthogonal polynomial recruitment - season effect
  1 216 50  # orthogonal polynomial recruitment - region effect
  1 218 50  # orthogonal polynomial recruitment - region-season interaction effect
  1 202 2   # OPR end window: last 2 real years use lower-degree/constant-end basis
  1 203 0   # no separate year-effect end-window override
  1 210 0   # OPR region end window: 0 inherits parest_flag(202)
  1 211 0   # no separate region-effect end-window override
  1 212 0   # OPR season end window: 0 inherits parest_flag(202)
  1 213 0   # no separate season-effect end-window override
  1 214 0   # OPR region-season end window: 0 inherits parest_flag(202)
  1 215 0   # no separate interaction end-window override
  1 397 0   # terminal-recruitment penalty starts only after the base OPR fit
  2 30 1    # keep age_flag(30) on so current MFCL activates OPR coefficients
  2 70 0    # turn off mean+deviate regional recruitment time series
  2 71 0    # turn off regional recruitment distribution deviations
  2 178 0   # turn off regional recruitment sum-product constraint
  -100000 1 0  # turn off time-invariant recruitment distribution, region 1
  -100000 2 0  # turn off time-invariant recruitment distribution, region 2
  -100000 3 0  # turn off time-invariant recruitment distribution, region 3
  -100000 4 0  # turn off time-invariant recruitment distribution, region 4
  -100000 5 0  # turn off time-invariant recruitment distribution, region 5
  1 1 500  # function evaluations from the OPR screening doitall example
PHASE3

# ---------
#  PHASE 4
# ---------

$program_path bet.frq 03.par 04.par -file - <<PHASE4
  2 68 1   # estimate movement coefficients
  2 69 1
  2 27 -1  # penalty wt 0.1 computed against prior
PHASE4

# ---------
#  PHASE 5
# ---------

$program_path bet.frq 04.par 05.par -file - <<PHASE5
  -100000 1 0 # estimate
  -100000 2 0 # time-invariant
  -100000 3 0 # distribution
  -100000 4 0 # of
  -100000 5 0 # recruitment
# Regional-scaling MVN prior.
# PHASE 1-4 retain CPUE_scaling; PHASE 5 switches to Prior_reg_biomass.
# Ungroup index CPUE likelihood and remove grouped-sigma override.
  -29 99 29  -29 94 0  # Index R1
  -30 99 30  -30 94 0  # Index R2
  -31 99 31  -31 94 0  # Index R3
  -32 99 32  -32 94 0  # Index R4
  -33 99 33  -33 94 0  # Index R5
# Ungroup index selectivity for the regional-scaling prior.
  -29 24 29  # Index R1; separate final selectivity from phase 5 onward
  -30 24 30  # Index R2; separate final selectivity from phase 5 onward
  -31 24 31  # Index R3; separate final selectivity from phase 5 onward
  -32 24 32  # Index R4; separate final selectivity from phase 5 onward
  -33 24 33  # Index R5; separate final selectivity from phase 5 onward
# MFCL reads bet.reg_scaling when parest flag 77 is > 0.
  1 77 50   # MVN regional-scaling penalty weight; CV about 0.1
  1 78 1    # use mean regional-scaling target
  1 79 240  # start regional-scaling prior at period 53; 1965-1969 CPUE covariance window
  1 80 220  # end regional-scaling prior at period 72; 1965-1969 CPUE covariance window
  1 81 1    # use multivariate-normal regional-scaling penalty
PHASE5

# ---------
#  PHASE 6
# ---------

$program_path bet.frq 05.par 06.par -file - <<PHASE6
  1 240 1  # fit to age-length data
  1 14 1   # estimate von Bertalanffy K
  1 12 1   # estimate mean length of age 1
  1 13 1   # estimate length of age n
  1 1 300  # function evaluations
PHASE6

# ---------
#  PHASE 7
# ---------

# DM numerical continuation: estimate overall length-at-age SD first.
$program_path bet.frq 06.par 06a.par -file - <<PHASE7A
  1 15 1   # estimate overall SD of length-at-age
  1 16 0   # retain length-dependent SD fixed for this transition
  1 1 250  # function evaluations
  1 50 -1  # convergence criterion
PHASE7A

$program_path bet.frq 06a.par 07.par -file - <<PHASE7
  1 15 1   # estimate overall SD of length-at-age
  1 16 1   # estimate length dependent SD
  1 173 0  # activate independent mean lengths for first 0 age classes
  1 182 0  # penalty weight
  1 184 0  # estimate parameters
  1 1 500  # function evaluations
PHASE7

# ---------
#  PHASE 8
# ---------

$program_path bet.frq 07.par 08.par -file - <<PHASE8
  2 145 1    # use SRR parameters - low penalty for deviation
  2 146 1    # estimate SRR parameters
  2 182 1    # make SRR annual rather than quarterly
  2 161 1    # lognormal bias correction
  2 163 0    # use steepness parameterization of B&H SRR
  1 149 0    # penalty for recruitment devs
  2 147 1    # time period between spawning and recruitment
  2 148 20   # period for MSY calc - last 20 quarters
  2 155 4    # but not including last year
  2 199 212  # start period for SRR estimation/yield is start 1965?
  2 200 6    # end period for SRR estimation is mid 2017
  -999 55 1  # do impact analysis
  2 171 1    # include SRR-based equilibrium recruitment to compute unfished biomass
  1 186 1    # write fishmort and plotq0.rep
  1 187 1    # write temporary_tag_report
  1 188 1    # write ests.rep
  1 189 1    # write .fit files
  1 1 500    # function evaluations
  1 50 -2    # convergence criteria
  2 116 100  # increase F bound for NR to 1.0
PHASE8

# ---------
#  PHASE 9
# ---------

# DM numerical continuation: relax the SRR penalty before widening the tag F bound.
$program_path bet.frq 08.par 08a.par -file - <<PHASE9A
  2 145 -1   # SRR penalty weight 10^-1
  1 1 500    # function evaluations
  1 50 -2    # convergence criterion
  2 116 100  # retain tag Newton-Raphson F bound at 1.0
PHASE9A

$program_path bet.frq 08a.par 09.par -file - <<PHASE9
  2 145 -1   # use SRR parameters - low penalty for deviation
  1 1 500    # function evaluations
  1 50 -2    # convergence criteria
  2 116 300  # increase F bound for NR to 3.0
PHASE9

# ----------
#  PHASE 10
# ----------

$program_path bet.frq 09.par 10.par -file - <<PHASE10
  1 1 10000  # function evaluations
  1 50 $phase10_11_convergence  # convergence criteria; default quick -3, set BET_PHASE10_11_CONVERGENCE=-5 for strict
  1 121 0    # estimate scaling parameter for Lorenzen (age_pars(5,1)); off
PHASE10

# ----------
#  PHASE 11
# ----------

$program_path bet.frq 10.par 11.par -file - <<PHASE11
  1 1 5000
  1 50 $phase10_11_convergence  # convergence criteria; default quick -3, set BET_PHASE10_11_CONVERGENCE=-5 for strict
  1 246 1   # indepvar.rpt
  1 190 1  # write the DM plot report only after all fitting phases are active
PHASE11
