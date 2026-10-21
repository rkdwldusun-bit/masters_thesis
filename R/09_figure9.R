# [Figure 9] National enrollment and loss experience
# Reads verified_results/verified_apfs_national.csv; no estimation here.
# Extends the APFS series with the MAFRA press release of 2 Feb 2026
# (input/supplementary/, see README there): 2025 enrollment rate, 2024-2025 loss ratio.

source("R/00_theme_thesis.R")

N <- fread(file.path(VERIFIED, "verified_apfs_national.csv"))
M <- fread("input/supplementary/mafra_2026-02-02_crop_insurance_2024_2025.csv", encoding = "UTF-8")

# bridge year: the release must reproduce the APFS 2024 values and loss-ratio definition
b <- merge(N[year == 2024], M[year == 2024], by = "year", suffixes = c("", "_m"))
stopifnot(nrow(b) == 1,
          b$farms_enrolled == b$farms_enrolled_m, b$insured_area_ha == b$insured_area_ha_m,
          b$area_enrollment_rate_pct == b$area_enrollment_rate_pct_m,
          abs(round(100 * b$indemnity_100mkrw / (b$risk_premium_mkrw / 100), 1) - b$loss_ratio_pct_m) < 1e-9)

A  <- rbind(N[, .(year, value = area_enrollment_rate_pct, src = "APFS")],
            M[!year %in% N$year, .(year, value = area_enrollment_rate_pct, src = "MAFRA")])
L  <- rbind(N[!is.na(loss_ratio_pct), .(year, value = loss_ratio_pct, src = "APFS")],
            M[!year %in% N[!is.na(loss_ratio_pct), year], .(year, value = loss_ratio_pct, src = "MAFRA")])
d <- rbind(A[, panel := "A. Area enrollment rate (%)"], L[, panel := "B. Loss ratio (%)"])
d[, panel := factor(panel, levels = c("A. Area enrollment rate (%)", "B. Loss ratio (%)"))]
ref <- data.table(panel = factor("B. Loss ratio (%)", levels = levels(d$panel)), y = 100)
yrs <- range(d$year)

p <- ggplot(d, aes(year, value)) +
  geom_col(data = d[panel == "B. Loss ratio (%)" & src == "APFS"], width = 0.55, fill = COL[["bar"]], colour = NA) +
  geom_col(data = d[panel == "B. Loss ratio (%)" & src == "MAFRA"], width = 0.55, fill = "white",
           colour = COL[["bar"]], linewidth = LWD$ci) +
  geom_hline(data = ref, aes(yintercept = y), colour = COL[["ref"]], linewidth = LWD$ref, linetype = "dashed") +
  geom_line(data = d[panel == "A. Area enrollment rate (%)"], colour = COL[["main"]], linewidth = LWD$series) +
  geom_point(data = d[panel == "A. Area enrollment rate (%)" & src == "APFS"], colour = COL[["main"]], size = PT$size) +
  geom_point(data = d[panel == "A. Area enrollment rate (%)" & src == "MAFRA"], colour = COL[["main"]], fill = "white",
             shape = 21, stroke = 1, size = PT$size) +
  facet_wrap(~ panel, ncol = 1, scales = "free_y") +
  scale_x_continuous(breaks = seq(yrs[1], yrs[2], by = 2)) +
  scale_y_continuous(labels = comma, limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  labs(x = "Year", y = "%",
       title = fig_title("fig9", sprintf("Crop Disaster Insurance: National Enrollment and Loss Experience, %d–%d", yrs[1], yrs[2])),
       caption = wrap(paste(
         sprintf("Note: APFS public national series: area enrollment rate %d–%d; loss ratio %d–%d (indemnities paid / risk premium × 100,",
                 min(N$year), max(N$year), min(N[!is.na(loss_ratio_pct), year]), max(N[!is.na(loss_ratio_pct), year])),
         sprintf("recomputed from the same file). Open markers and bars: MAFRA (2026), enrollment rate %s and loss ratio %s, same definitions",
                 paste(A[src == "MAFRA", year], collapse = ", "), paste(L[src == "MAFRA", year], collapse = "–")),
         "(the release reproduces the APFS 2024 values). The eligible-area denominator of the enrollment rate expands as crops are added, so the",
         "rate is not comparable across years without adjustment. Dashed line: loss ratio of 100%. Descriptive only.",
         "Source: Korea Agricultural Policy Insurance & Finance Service (APFS), public data; Ministry of Agriculture, Food and Rural Affairs",
         "(MAFRA), press release of 2 February 2026; author's calculations."), NOTE_WIDTH)) +
  theme_thesis()

save_thesis_fig(p, "fig9", "fig9_apfs_national_trends", height = 7.8, data = d)

# thesis-document version: the note is set as text under the figure, so the graphic carries none
save_thesis_fig(p + labs(caption = NULL), "fig9", "fig9_apfs_national_trends_nonote", height = 6.6, data = d)
