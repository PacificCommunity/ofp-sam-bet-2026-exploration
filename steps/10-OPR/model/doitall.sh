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
# fish flag 92 = round(region sigma * 100), fish flag 94 = allow unequal sigma,
# fish flag 66 = 0. The freq file supplies the temporal sigma pattern.
# Arni's suggestion, 19/06/2026.
  -29 94 1       -29 92 28   -29 66 0  # Index R1, sigma 0.28
  -30 94 1       -30 92 20   -30 66 0  # Index R2, sigma 0.20
  -31 94 1       -31 92 22   -31 66 0  # Index R3, sigma 0.22
  -32 94 1       -32 92 21   -32 66 0  # Index R4, sigma 0.21
  -33 94 1       -33 92 24   -33 66 0  # Index R5, sigma 0.24
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
  1 141 3     # set likelihood function for LF data to normal
  1 139 3     # set likelihood function for WF data to normal
  -999 49 20  # divide LF sample sizes by 20
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
  -21 32 14  # MISC.ID.2, old23
  -22 32 14  # MISC.PH.2, old17
  -23 32 17  # MISC.VN.2, old32
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
  -999 26 3  # use length-based selectivity
  -999 57 3  # uses cubic spline selectivity
  -999 61 5  # with 5 nodes for cubic spline
# Grouping of fisheries with common selectivity, mapped from BET_PHrev_FNL.xlsx.
# The old 29 groups become 25 groups here: 24 extraction groups + 1 index group.
   -1 24 1   # LL.WEST.1, old1
   -2 24 2   # LL.EAST.1, old2
   -3 24 3   # LL.US.1, old3
   -4 24 4   # LL.ALL.2, old7
   -5 24 5   # LL.OS.2, old6
   -6 24 6   # LL.ARCH.3, old8
   -7 24 7   # LL.WEST.3, old4
   -8 24 8   # LL.EAST.3, old9
   -9 24 9   # LL.OS.3, old5
  -10 24 10  # LL.ALL.5, old11 + old12 + old29
  -11 24 11  # LL.AU.5, old10 + old27
  -12 24 12  # PS.JP.1, old19
  -13 24 13  # PL.JP.1, old20
  -14 24 14  # HL.ID.2, part of old18
  -15 24 14  # HL.PH.2, part of old18
  -16 24 15  # PL.ALL.2, old28
  -17 24 16  # PS.ID.2, split old24
  -18 24 16  # PS.PH.2, split old24
  -19 24 17  # PS.ASS.2, old30; share with PS.ASS.WEST.3
  -20 24 18  # PS.UNA.2, old31; share with PS.UNA.WEST.3
  -21 24 19  # MISC.ID.2, old23
  -22 24 20  # MISC.PH.2, old17
  -23 24 21  # MISC.VN.2, old32
  -24 24 22  # PL.ALL.WEST.3, old21 + old22
  -25 24 17  # PS.ASS.WEST.3, old13 + old25
  -26 24 23  # PS.ASS.EAST.3, old15
  -27 24 18  # PS.UNA.WEST.3, old14 + old26
  -28 24 24  # PS.UNA.EAST.3, old16
  -29 24 25  # Index R1
  -30 24 25  # Index R2
  -31 24 25  # Index R3
  -32 24 25  # Index R4
  -33 24 25  # Index R5
# Non-decreasing selectivity for the old6-derived longline fishery.
   -5 16 1
# Selected old-derived longline fisheries set to zero for first two age classes.
   -2 75 2
   -4 75 2
   -5 75 2
   -7 75 2
   -8 75 2
   -9 75 2
  -10 75 2
# Old18 split into HL.ID.2 and HL.PH.2.
  -14 75 5
  -15 75 5
# Age-based spline constraints mapped from old fishery recipes.
  -19 16 2  -19 3 25  # PS.ASS.2, old30
  -25 16 2  -25 3 25  # PS.ASS.WEST.3, old13 + old25
  -26 16 2  -26 3 25  # PS.ASS.EAST.3, old15
  -20 16 2  -20 3 30  # PS.UNA.2, old31
  -27 16 2  -27 3 30  # PS.UNA.WEST.3, old14 + old26
  -28 16 2  -28 3 30  # PS.UNA.EAST.3, old16
  -17 16 2  -17 3 12  # PS.ID.2, split old24
  -18 16 2  -18 3 12  # PS.PH.2, split old24
  -12 16 2  -12 3 25  # PS.JP.1, old19
  -13 16 2  -13 3 25  # PL.JP.1, old20
# Upper-age selectivity constraints mapped from old fishery recipes.
  -22 16 2  -22 3 9   # MISC.PH.2, old17
  -24 16 2  -24 3 10  # PL.ALL.WEST.3, old21 + old22
  -21 16 2  -21 3 6   # MISC.ID.2, old23
  -16 16 2  -16 3 7   # PL.ALL.2, old28
  -23 16 2  -23 3 9   # MISC.VN.2, old32
# Turn on weighted spline for calculating maturity at age
  2 188 2
# Set Lorenzen M
  2 109 3  # select Lorenzen curve
  1 121 0  # do not estimate Lorenzen scaling parameter yet
# Filter out comps with input samples less than 50
  1 311 1   # set tail compression for LF data
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
  1 1 100  # set max. number of function evaluations per phase to 100
  1 50 0   # set convergence criterion to 1
  2 113 0  # scaling init pop - turned off
  1 190 1  # write plot-xxx.par.rep
PHASE2

# ---------
#  PHASE 3
# ---------

$program_path bet.frq 02.par 03.par -file - <<PHASE3
# OPR settings. John Hampton's BET OPR screening rank-1 model: 69-01-50-50.
  1 149 0   # turn off recruitment-deviation penalty for OPR
  1 398 0   # turn off arithmetic-mean terminal fixed-recruitment option for OPR
  1 400 0   # clear fixed terminal recruitment-deviate block for OPR
  2 177 0   # turn off old total-pop scaling for OPR
  2 32 0    # turn off overall population scaling parameter for OPR
  2 113 0   # keep scaling init pop off during OPR transfer
  1 155 69  # orthogonal polynomial recruitment - year effect
  1 217 1   # orthogonal polynomial recruitment - season effect
  1 216 50  # orthogonal polynomial recruitment - region effect
  1 218 50  # orthogonal polynomial recruitment - region-season interaction effect
  1 202 2   # OPR end window: last 2 real years use lower-degree/constant-end basis
  1 210 0   # OPR region end window: 0 inherits parest_flag(202)
  1 212 0   # OPR season end window: 0 inherits parest_flag(202)
  1 214 0   # OPR region-season end window: 0 inherits parest_flag(202)
  2 30 1    # keep age_flag(30) on; John/Nick found OPR coefficients are otherwise not activated
  2 70 0    # turn off mean+deviate regional recruitment time series
  2 71 0    # turn off regional recruitment distribution deviations
  2 178 0   # turn off regional recruitment sum-product constraint
  -100000 1 0  # turn off time-invariant recruitment distribution, region 1
  -100000 2 0  # turn off time-invariant recruitment distribution, region 2
  -100000 3 0  # turn off time-invariant recruitment distribution, region 3
  -100000 4 0  # turn off time-invariant recruitment distribution, region 4
  -100000 5 0  # turn off time-invariant recruitment distribution, region 5
  1 1 500  # function evaluations, matching John Hampton's OPR doitall example
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
# Regional-scaling MVN prior. Nick's suggestion, 09/06/2026.
# PHASE 1-4 retain CPUE_scaling; PHASE 5 switches to Prior_reg_biomass.
# Ungroup index CPUE likelihood and remove grouped-sigma override.
  -29 99 29  -29 94 0  # Index R1
  -30 99 30  -30 94 0  # Index R2
  -31 99 31  -31 94 0  # Index R3
  -32 99 32  -32 94 0  # Index R4
  -33 99 33  -33 94 0  # Index R5
# Ungroup index selectivity for the regional-scaling prior.
  -29 24 25  # Index R1
  -30 24 26  # Index R2
  -31 24 27  # Index R3
  -32 24 28  # Index R4
  -33 24 29  # Index R5
# MFCL reads bet.reg_scaling when parest flag 77 is > 0.
  1 77 50   # MVN regional-scaling penalty weight; CV about 0.1 in the 09/06/2026 note
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

$program_path bet.frq 06.par 07.par -file - <<PHASE7
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

$program_path bet.frq 08.par 09.par -file - <<PHASE9
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
PHASE11
