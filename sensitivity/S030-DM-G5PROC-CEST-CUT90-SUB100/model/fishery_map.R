# Fishery map for 03-RegFish
#
# Extraction fishery labels and regions follow BET/bet.RR.2026.csv from
# ofp-sam-2026-BET-YFT-build-ini@f8faf7c. Index labels retain the explicit
# region prefix used throughout the assessment and MFCLShiny.

fishery_map <- data.frame(
  fishery_name = c(
    "01.LL.WEST.ALL.1",
    "02.LL.EAST.ALL.1",
    "03.LL.US.1",
    "04.LL.ALL.2",
    "05.LL.OS.2",
    "06.LL.ARCH.3",
    "07.LL.WEST.3",
    "08.LL.EAST.4",
    "09.LL.OS.3",
    "10.LL.ALL.5",
    "11.LL.AU.5",
    "12.PS.JP.1",
    "13.PL.JP.1",
    "14.HL.ID.2",
    "15.HL.PH.2",
    "16.PL.ALL.2",
    "17.PS.ID.2",
    "18.PS.PH.2",
    "19.PS.ASS.2",
    "20.PS.UNA.2",
    "21.MISC.ID.2",
    "22.MISC.PH.2",
    "23.MISC.VN.2",
    "24.PL.ALL.WEST.3",
    "25.PS.ASSOC.WEST.3",
    "26.PS.ASSOC.EAST.4",
    "27.PS.UNASSOC.WEST.3",
    "28.PS.UNASSOC.EAST.4",
    "29.Index R1",
    "30.Index R2",
    "31.Index R3",
    "32.Index R4",
    "33.Index R5"
  ),
  fishery = 1:33,
  region = c(
    1, 1, 1, 2, 2, 3, 3, 4, 3, 5, 5, 1, 1, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 3, 3, 4, 3, 4, 1, 2, 3, 4, 5
  ),
  group = c(
    "LL", "LL", "LL", "LL", "LL", "LL", "LL", "LL", "LL",
    "LL", "LL", "PS", "PL", "HL", "HL", "PL", "PS", "PS",
    "PS ASSOC", "PS UNASSOC", "MISC", "MISC", "MISC", "PL",
    "PS ASSOC", "PS ASSOC", "PS UNASSOC", "PS UNASSOC",
    "Index", "Index", "Index", "Index", "Index"
  ),
  source_recipe = c(
    "old1",
    "old2",
    "old3",
    "old7",
    "old6",
    "old8",
    "old4 - boundary shifted",
    "old9 - boundary shifted",
    "old5 - boundary shifted",
    "old11 + old12 + old29",
    "old10 + old27",
    "old19",
    "old20",
    "part of old18",
    "part of old18",
    "old28",
    "split old24",
    "split old24",
    "old30",
    "old31",
    "old23",
    "old17",
    "old32",
    "old21 + old22 - boundary shift",
    "old13 + old25",
    "old15",
    "old14 + old26",
    "old16",
    "index R1",
    "index R2",
    "index R3",
    "index R4",
    "index R5"
  ),
  stringsAsFactors = FALSE
)

fishery_map$tag_recapture_group <- c(
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 14, 15,
  14, 14, 16, 16, 14, 14, 17, 18, 19, 20, 19, 20, 21, 21,
  21, 21, 21
)

tag_recapture_names <- c(
  "LL.WEST.ALL.1", "LL.EAST.ALL.1", "LL.US.1", "LL.ALL.2", "LL.OS.2",
  "LL.ARCH.3", "LL.WEST.3", "LL.EAST.4", "LL.OS.3",
  "LL.ALL.5", "LL.AU.5", "PS.JP.1", "PL.JP.1", "PHID.2",
  "PL.ALL.2", "PS.2", "MISC.VN.2", "PL.ALL.WEST.3",
  "PS.WEST.3", "PS.EAST.4", "Index"
)
fishery_map$tag_recapture_name <-
  tag_recapture_names[fishery_map$tag_recapture_group]

fishery_map$selectivity_group <- c(
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 14, 15,
  16, 16, 17, 18, 19, 20, 21, 22, 17, 23, 18, 24, 25, 25,
  25, 25, 25
)

selectivity_names <- c(
  "LL.WEST.ALL.1", "LL.EAST.ALL.1", "LL.US.1", "LL.ALL.2", "LL.OS.2",
  "LL.ARCH.3", "LL.WEST.3", "LL.EAST.4", "LL.OS.3",
  "LL.ALL.5", "LL.AU.5", "PS.JP.1", "PL.JP.1", "HL.IDPH.2",
  "PL.ALL.2", "PS.IDPH.2", "PS.ASS.WEST3+2", "PS.UNA.WEST3+2",
  "MISC.ID.2", "MISC.PH.2", "MISC.VN.2", "PL.ALL.WEST.3",
  "PS.ASS.EAST.4", "PS.UNA.EAST.4", "Index"
)
fishery_map$selectivity_name <- selectivity_names[fishery_map$selectivity_group]

# Regional-scaling Prior_reg_biomass variants unshare index selectivity groups.
# In doitall this switch starts in PHASE 5; PHASE 1-4 retain the
# current CPUE_scaling setup with one shared index selectivity group.
fishery_map$selectivity_group[29:33] <- 25:29
selectivity_names[25:29] <- paste0("Index R", 1:5)
fishery_map$selectivity_name <- selectivity_names[fishery_map$selectivity_group]

make_fishery_group_map <- function(group_col, name_col) {
  groups <- sort(unique(fishery_map[[group_col]]))
  data.frame(
    group = groups,
    group_name = vapply(groups, function(group) {
      unique(fishery_map[[name_col]][fishery_map[[group_col]] == group])[1]
    }, character(1)),
    fisheries = vapply(groups, function(group) {
      paste(fishery_map$fishery[fishery_map[[group_col]] == group], collapse = ",")
    }, character(1)),
    fishery_names = vapply(groups, function(group) {
      paste(fishery_map$fishery_name[fishery_map[[group_col]] == group],
            collapse = "; ")
    }, character(1)),
    source_recipes = vapply(groups, function(group) {
      paste(unique(fishery_map$source_recipe[fishery_map[[group_col]] == group]),
            collapse = "; ")
    }, character(1)),
    stringsAsFactors = FALSE
  )
}

# SA28 extraction and final index groups are independent with contiguous labels.
fishery_map$selectivity_group[1:28] <- 1:28
fishery_map$selectivity_group[29:33] <- 29:33
fishery_map$selectivity_name[1:28] <- sub("^[0-9]+\\.", "", fishery_map$fishery_name[1:28])
fishery_map$selectivity_name[29:33] <- paste0("Index R", 1:5)

selectivity_group_map <- make_fishery_group_map(
  group_col = "selectivity_group",
  name_col = "selectivity_name"
)

tag_recapture_group_map <- make_fishery_group_map(
  group_col = "tag_recapture_group",
  name_col = "tag_recapture_name"
)

#save(fishery_map, file = "fishery_map.RData")
