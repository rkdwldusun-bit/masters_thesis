# [Figure 7] Insured-to-normal yield ratio, eight largest fruit crops, 2024
# Reads verified_results/verified_apfs_fruit_2024_by_crop.csv (+ audit summary); no estimation here.

source("R/00_theme_thesis.R")

F <- fread(file.path(VERIFIED, "verified_apfs_fruit_2024_by_crop.csv"), encoding = "UTF-8")
A <- fread(file.path(VERIFIED, "verified_apfs_fruit_2024_audit.csv"), encoding = "UTF-8")
n_rows <- as.numeric(A[item == "rows in file", value]); n_dup <- as.numeric(A[item == "exact duplicate rows", value])
top <- F[order(-records)][1:8]
d <- melt(top[, .(crop, records, share_ratio_below_1, share_ratio_equal_1, share_ratio_above_1)],
          id.vars = c("crop", "records"), variable.name = "cat", value.name = "share")
d[, cat := factor(cat, levels = c("share_ratio_below_1", "share_ratio_equal_1", "share_ratio_above_1"),
                  labels = c("Below 1", "Equal to 1", "Above 1"))]
d[, crop := factor(crop, levels = rev(top$crop))]

p <- ggplot(d, aes(x = share, y = crop, fill = cat)) +
  geom_col(width = 0.55, position = position_stack(reverse = TRUE)) +
  scale_fill_manual(values = c("Below 1" = COL[["set2_2"]], "Equal to 1" = COL[["set2_8"]], "Above 1" = COL[["main"]])) +
  scale_x_continuous(labels = function(x) paste0(round(100 * x), "%"), expand = expansion(mult = c(0, 0.03))) +
  labs(x = "Share of administrative contract-detail records (insured yield / normal yield)", y = NULL,
       title = fig_title("fig7", "Insured-to-Normal Yield Ratio, Eight Largest Fruit Crops, 2024"),
       caption = wrap(paste(
         sprintf("Note: APFS 2024 fruit contract-detail file (%s rows; %s exact duplicate rows; no contract identifier).", comma(n_rows), comma(n_dup)),
         "Crop disaster insurance only; records with a missing or non-positive insured or normal yield are excluded.",
         "'Equal to 1' = ratio within \u00b10.0005.",
         "Shares are taken from the supplied crop-level summary; the raw record file is not part of the verified bundle. Descriptive only.",
         "Source: Korea Agricultural Policy Insurance & Finance Service (APFS), public data; author's calculations."), NOTE_WIDTH)) +
  theme_thesis()

save_thesis_fig(p, "fig7", "fig7_insured_to_normal_yield", height = 5.8, data = d)
