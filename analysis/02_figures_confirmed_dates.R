# =====================================================================
# 02_figures_confirmed_dates.R -- thesis Figures 6 and 7 for the main
# national analysis (six crops, confirmed dates). Reads only
# analysis/output/ written by 01_national_confirmed_dates.R.
# Output: figures/confirmed_dates/fig6_event_time_contrasts.{png,pdf},
#         figures/confirmed_dates/fig7_crop_contrasts.{png,pdf}
# =====================================================================

source("R/00_theme_thesis.R")
dir.create("figures/confirmed_dates", showWarnings = FALSE, recursive = TRUE)
dir.create("figures/plotdata/confirmed_dates", showWarnings = FALSE, recursive = TRUE)
OUT  <- "analysis/output"
OUTC <- c(ln_area = "Area", ln_yield = "Yield", ln_production = "Production")

# ---- Figure 6: event time relative to the pilot -------------------------
F6 <- fread(file.path(OUT, "fig6_event_time.csv"))[design == "main" & event_time %between% c(-10, 12)]
F6[, outcome := factor(OUTC[outcome], levels = OUTC)]
ref <- data.table(event_time = -1, est = 0, outcome = factor(OUTC, levels = OUTC))

p6 <- ggplot(F6, aes(event_time, est)) +
  geom_hline(yintercept = 0, colour = COL[["ref"]], linewidth = LWD$ref, linetype = "dashed") +
  geom_vline(xintercept = -0.5, colour = COL[["ref"]], linewidth = LWD$ref, linetype = "dotted") +
  geom_ci(aes(ymin = ci_lo, ymax = ci_hi), colour = COL[["main"]]) +
  geom_point(colour = COL[["main"]], size = PT$size, shape = PT$shape) +
  geom_point(data = ref, shape = 21, fill = "white", colour = COL[["pre"]], size = PT$size, stroke = 0.7) +
  facet_wrap(~ outcome, ncol = 1) +
  scale_x_continuous(breaks = seq(-10, 12, 2), labels = function(x) sub("^-", "−", x)) +
  coord_cartesian(ylim = c(-0.55, 0.55)) +
  scale_y_continuous(breaks = seq(-0.5, 0.5, 0.25), labels = function(x) sub("^-", "\u2212", sprintf("%.2f", x))) +
  labs(x = "Years relative to pilot introduction", y = "Event-time contrast (log points)") +
  theme_thesis()
save_thesis_fig(p6, "fig6", "confirmed_dates/fig6_event_time_contrasts", height = 8, data = F6)

# ---- Figure 7: crop-specific mean contrasts -----------------------------
F7 <- fread(file.path(OUT, "fig7_crop_means.csv"))[pool != "Supplementary (S1)"]
crop_order <- c(soybean = "Soybean", onion = "Onion", sweet_potato = "Sweet potato", corn = "Corn",
                garlic = "Garlic", red_pepper = "Red pepper")
F7[, `:=`(outcome = factor(OUTC[outcome], levels = OUTC),
          crop = factor(crop_order[crop_id], levels = rev(crop_order)),
          pool = factor(pool, levels = c("Full comparison pool", "Excluding two spring series")))]

p7 <- ggplot(F7, aes(est, crop, colour = pool, shape = pool)) +
  geom_vline(xintercept = 0, colour = COL[["ref"]], linewidth = LWD$ref) +
  geom_point(size = PT$size + 0.5, position = position_dodge(width = 0.35)) +
  facet_wrap(~ outcome, nrow = 1) +
  scale_colour_manual(values = c(COL[["main"]], COL[["set2_2"]])) +
  scale_shape_manual(values = c(16, 17)) +
  scale_x_continuous(breaks = seq(-0.8, 0.4, 0.4), labels = function(x) sub("^-", "−", sprintf("%.1f", x))) +
  coord_cartesian(xlim = c(-0.8, 0.45)) +
  labs(x = "Mean log contrast, event years 0–9", y = NULL) +
  theme_thesis()
save_thesis_fig(p7, "fig7", "confirmed_dates/fig7_crop_contrasts", height = 4.5, data = F7)
