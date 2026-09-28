# Final thesis-facing English names (author decision, 2026-09-28).
# Only display labels change; internal crop_id values and all data are unchanged.
# Leaf lettuce = 상추 (open-field leaf lettuce); Lettuce = 양상추 (not in the panel).

THESIS_NAME_OVERRIDES <- c(
  other_pulses    = "Other pulses",
  malting_barley  = "Malting barley",
  ginger          = "Ginger",
  spring_napa     = "Spring Napa cabbage",
  highland_napa   = "Highland Napa cabbage",
  autumn_napa     = "Autumn Napa cabbage",
  winter_napa     = "Winter Napa cabbage",
  spring_radish   = "Spring Radish",
  highland_radish = "Highland Radish",
  autumn_radish   = "Autumn Radish",
  winter_radish   = "Winter Radish")

# APFS fruit label (not a production-panel series)
THESIS_NAME_APFS <- c("Walnut" = "Walnut")

BANNED_CROP_NAMES <- c("Asian pear", "Japanese apricot", "Chinese cabbage", "Daikon", "Satsuma", "Yuzu",
                       "Citron", "maize")

thesis_name <- function(crop_id, current) ifelse(crop_id %in% names(THESIS_NAME_OVERRIDES),
                                                 THESIS_NAME_OVERRIDES[crop_id], current)
