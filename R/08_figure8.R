# [Figure 8] Administrative contract-detail records by fruit crop, 2024
# Reads verified_results/verified_apfs_fruit_2024_by_crop.csv (+ audit summary); no estimation here.

source("R/00_theme_thesis.R")

F <- fread(file.path(VERIFIED, "verified_apfs_fruit_2024_by_crop.csv"), encoding = "UTF-8")
A <- fread(file.path(VERIFIED, "verified_apfs_fruit_2024_audit.csv"), encoding = "UTF-8")
n_dup <- as.numeric(A[item == "exact duplicate rows", value])
n_rev <- as.numeric(A[grepl("revenue-insurance", item), value])
d <- F[, .(crop, records)][order(records)]
d[, crop := factor(crop, levels = crop)]

p <- ggplot(d, aes(x = records, y = crop)) +
  geom_col(width = 0.55, fill = COL[["bar"]], colour = NA) +
  scale_x_continuous(labels = comma, expand = expansion(mult = c(0, 0.03))) +
  labs(x = "Number of administrative contract-detail records", y = NULL,
       title = fig_title("fig8", "Administrative Contract-Detail Records by Fruit Crop, 2024"),
       caption = wrap(paste(
         sprintf("Note: APFS 2024 fruit contract-detail file, crop disaster insurance only (%s records; %s revenue-insurance grape",
                 comma(sum(d$records)), comma(n_rev)),
         sprintf("records excluded). Records are administrative contract-detail rows, not necessarily unique contracts: the file has no"),
         sprintf("contract identifier and contains %s exact duplicate rows. Counts are taken from the supplied crop-level summary. Descriptive only.",
                 comma(n_dup)),
         "Source: Korea Agricultural Policy Insurance & Finance Service (APFS), public data; author's calculations."), 108)) +
  theme_thesis()

save_thesis_fig(p, "fig8", "fig8_record_composition", height = 7.4, data = d)
