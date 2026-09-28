# Event-study panel used by Figures 1, 4 and 5.
# Pre-pilot placebo estimates (grey) and post-availability estimates (main colour)
# are drawn as separate series; nothing is drawn across the omitted transition years.

plot_event_study <- function(d, facet = NULL, ncol = 1, ylab = "Estimated change (log points)") {
  d <- copy(as.data.table(d))
  d[, period := factor(period, levels = c("clean pre-pilot (placebo)", "after nationwide availability"),
                       labels = c("Clean pre-pilot years (placebo)", "Years after nationwide availability"))]
  p <- ggplot(d, aes(x = event_time, y = est, colour = period, group = period)) +
    geom_hline(yintercept = 0, colour = COL[["ref"]], linewidth = LWD$ref) +
    geom_vline(xintercept = -0.5, colour = "grey60", linewidth = LWD$ref, linetype = "dashed") +
    geom_ci(aes(ymin = ci_lo_wild, ymax = ci_hi_wild)) +
    geom_line(linewidth = LWD$series * 0.6) +
    geom_point(size = PT$size, shape = PT$shape) +
    scale_colour_manual(values = c("Clean pre-pilot years (placebo)" = COL[["pre"]],
                                   "Years after nationwide availability" = COL[["main"]])) +
    scale_x_continuous(breaks = seq(-12, 12, by = 2), minor_breaks = seq(-12, 12, by = 1)) +
    labs(x = "Years relative to nationwide availability (e)", y = ylab) +
    theme_thesis()
  if (!is.null(facet)) p <- p + facet_wrap(as.formula(paste("~", facet)), ncol = ncol, scales = "free_y")
  p
}
