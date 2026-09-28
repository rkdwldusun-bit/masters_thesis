# [Figure 6] Rice: descriptive series with alternative insurance dates
# Reads verified_results/verified_master_panel.csv and verified_treatment_coding.csv; no estimation here.

source("R/00_theme_thesis.R")

P  <- fread(file.path(VERIFIED, "verified_master_panel.csv"))
TR <- fread(file.path(VERIFIED, "verified_treatment_coding.csv"))
r  <- P[crop_id == "rice" & year >= 1991 & year <= 2024, .(year, ln_area, ln_yield, ln_production)]
ref <- TR[crop_id == "rice", last_clean_pre_obs_production]            # 2008 = last year before the 2009 pilot
d  <- melt(r, id.vars = "year", variable.name = "outcome", value.name = "value")
d[, value_rel := value - value[year == ref], by = outcome]
d[, panel := factor(outcome, levels = c("ln_area", "ln_yield", "ln_production"),
                    labels = c("A. Area (log cultivated area)", "B. Yield (log yield per 10a)", "C. Production (log production)"))]

rt <- TR[crop_id == "rice"]
alt <- as.integer(regmatches(rt$alternative_dates, gregexpr("[0-9]{4}", rt$alternative_dates))[[1]])
dates <- data.table(year = c(rt$pilot_year, alt[1], rt$national_year, alt[2]),
                    lab = c("First pilot", "Product-table date", "Nationwide (baseline)", "Full-scale"))
dates[, lab := factor(paste0(lab, " (", year, ")"), levels = paste0(lab, " (", year, ")"))]

p <- ggplot(d, aes(year, value_rel)) +
  geom_hline(yintercept = 0, colour = COL[["ref"]], linewidth = LWD$ref) +
  geom_vline(data = dates, aes(xintercept = year, linetype = lab), colour = "grey45", linewidth = 0.6) +
  geom_line(colour = COL[["main"]], linewidth = LWD$series) +
  geom_point(colour = COL[["main"]], size = PT$size * 0.7) +
  scale_linetype_manual(values = c("dotted", "dashed", "solid", "dotdash")) +
  scale_x_continuous(breaks = seq(1991, 2024, by = 3)) +
  facet_wrap(~ panel, ncol = 1, scales = "free_y") +
  guides(linetype = guide_legend(nrow = 2)) +
  labs(x = "Year", y = sprintf("Log difference from %d", ref),
       title = fig_title("fig6", "Rice: Area, Yield and Production with Alternative Insurance Dates (Descriptive Case Only)"),
       caption = wrap(paste(
         sprintf("Note: Paddy rice, national series, 1991–2024, expressed as the log difference from %d, the last year before the", ref),
         "first pilot. Rice is a single treated crop, so no difference-in-differences inference is reported; its insurance timing",
         "also overlaps with rice-specific policies. Vertical lines mark alternative dates from the treatment-coding input.",
         "Descriptive only.",
         "Source: KOSIS Crop Production Survey (national series); author's calculations."), 108)) +
  theme_thesis()

save_thesis_fig(p, "fig6", "fig6_rice_descriptive", height = 9.4,
                data = d[, .(outcome, year, value, value_rel)])
