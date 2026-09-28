# [Figure 9] National enrollment and loss experience
# Reads verified_results/verified_apfs_national.csv; no estimation here.

source("R/00_theme_thesis.R")

N <- fread(file.path(VERIFIED, "verified_apfs_national.csv"))
d <- rbind(N[, .(year, value = area_enrollment_rate_pct, panel = "A. Area enrollment rate (%)")],
           N[!is.na(loss_ratio_pct), .(year, value = loss_ratio_pct, panel = "B. Loss ratio (%)")])
d[, panel := factor(panel, levels = c("A. Area enrollment rate (%)", "B. Loss ratio (%)"))]
ref <- data.table(panel = factor("B. Loss ratio (%)", levels = levels(d$panel)), y = 100)

p <- ggplot(d, aes(year, value)) +
  geom_col(data = d[panel == "B. Loss ratio (%)"], width = 0.55, fill = COL[["bar"]], colour = NA) +
  geom_hline(data = ref, aes(yintercept = y), colour = COL[["ref"]], linewidth = LWD$ref, linetype = "dashed") +
  geom_line(data = d[panel == "A. Area enrollment rate (%)"], colour = COL[["main"]], linewidth = LWD$series) +
  geom_point(data = d[panel == "A. Area enrollment rate (%)"], colour = COL[["main"]], size = PT$size) +
  facet_wrap(~ panel, ncol = 1, scales = "free_y") +
  scale_x_continuous(breaks = seq(2001, 2024, by = 2)) +
  scale_y_continuous(labels = comma, limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  labs(x = "Year", y = "%",
       title = fig_title("fig9", "Crop Disaster Insurance: National Enrollment and Loss Experience, 2001–2024"),
       caption = wrap(paste(
         sprintf("Note: APFS public national series. Area enrollment rate %d–%d; loss ratio %d–%d (indemnities paid / risk premium \u00d7 100,",
                 min(N$year), max(N$year), min(N[!is.na(loss_ratio_pct), year]), max(N[!is.na(loss_ratio_pct), year])),
         "recomputed from the same file). The eligible-area denominator of the enrollment rate expands as crops are added, so the",
         "rate is not comparable across years without adjustment. Dashed line: loss ratio of 100%. Descriptive only.",
         "Source: Korea Agricultural Policy Insurance & Finance Service (APFS), public data; author's calculations."), NOTE_WIDTH)) +
  theme_thesis()

save_thesis_fig(p, "fig9", "fig9_apfs_national_trends", height = 7.6, data = d)
