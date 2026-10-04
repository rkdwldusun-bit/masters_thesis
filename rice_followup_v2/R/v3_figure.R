# Protocol v3 supplementary (c): municipal ln rice area paths relative to 2008, by cohort.
# Thin grey line = one municipality; thick line = cohort mean. Cohort identity comes from the
# facet strip, so colour is never the only cue. Thesis theme (../R/00_theme_thesis.R).
# Run from rice_followup_v2/ after python/v3_estimate.py:  Rscript R/v3_figure.R
suppressPackageStartupMessages({ library(ggplot2); library(data.table) })
invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))
source("../R/00_theme_thesis.R")
p <- fread("results/v3/unit_paths.csv", encoding = "UTF-8")
p[, cohort_lab := factor(cohort, levels = c(2009, 2011),
                         labels = c("Early pilots: insurance offered from 2009 (17)",
                                    "Late pilots: insurance offered from 2011 (9)"))]
m <- p[, .(rel_2008 = mean(rel_2008)), by = .(cohort_lab, year)]
fig <- ggplot(p, aes(year, rel_2008)) +
  geom_hline(yintercept = 0, colour = COL[["ref"]], linewidth = LWD$ref) +
  geom_vline(xintercept = 2008.5, colour = "grey60", linewidth = LWD$ref, linetype = "dashed") +
  geom_line(aes(group = id), colour = "grey70", linewidth = 0.35) +
  geom_line(data = m, colour = COL[["main"]], linewidth = LWD$series * 1.4) +
  geom_point(data = m, colour = COL[["main"]], size = PT$size, shape = PT$shape) +
  facet_wrap(~cohort_lab, ncol = 2) +
  scale_x_continuous(breaks = seq(2000, 2010, 2)) +
  labs(x = "Year", y = "ln rice area relative to 2008",
       caption = "Grey: individual municipalities. Coloured line: cohort mean. Dashed line: start of 2009 availability.\nSource: KOSIS DT_1ET0033, municipal paddy-rice planted area.") +
  theme_thesis() +
  theme(strip.text = element_text(size = SIZE$strip))
dir.create("figures", showWarnings = FALSE)
# Same export conventions as save_thesis_fig() in ../R/00_theme_thesis.R.
ggsave("figures/v3_unit_paths.png", fig, width = FIG$width, height = FIG$height_single, dpi = FIG$dpi,
       units = "in", bg = "white")
ggsave("figures/v3_unit_paths.pdf", fig, width = FIG$width, height = FIG$height_single, units = "in",
       device = grDevices::cairo_pdf, bg = "white")
cat("font:", FONT, "\n")
