# [Appendix Figure A1] Insured-price field by fruit crop, 2024
# Reads verified_results/verified_apfs_fruit_2024_by_crop.csv; no estimation here.
# The raw record file is not in the verified bundle, so the 5th/95th-percentile whiskers of the
# earlier Python figure cannot be reproduced; the figure shows the embedded quartiles only.

source("R/00_theme_thesis.R")

F <- fread(file.path(VERIFIED, "verified_apfs_fruit_2024_by_crop.csv"), encoding = "UTF-8")
d <- F[order(-records)][1:8, .(crop, p25 = insured_price_p25, median = insured_price_median, p75 = insured_price_p75)]
d[, crop := factor(crop, levels = rev(crop))]

p <- ggplot(d, aes(y = crop)) +
  geom_linerange(aes(xmin = p25, xmax = p75), linewidth = 3, colour = COL[["bar"]]) +
  geom_point(aes(x = median), size = PT$size, colour = COL[["pre"]]) +
  scale_x_log10(labels = comma) +
  labs(x = "Insured price as recorded in the APFS file (log scale)", y = NULL,
       title = fig_title("figA1", "Insured-Price Field by Fruit Crop, 2024"),
       caption = wrap(paste(
         "Note: Bar = interquartile range; point = median. Eight crops with the most records. The measurement unit of this field",
         "is not defined in the available official sources; values are shown as recorded and should not be compared with market",
         "prices. Quartiles are taken from the supplied crop-level summary (raw records not in the verified bundle). Descriptive only.",
         "Source: Korea Agricultural Policy Insurance & Finance Service (APFS), public data; author's calculations."), 108)) +
  theme_thesis()

save_thesis_fig(p, "figA1", "figA1_insured_price_appendix", height = 5.8, data = d)
