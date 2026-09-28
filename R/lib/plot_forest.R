# Forest (coefficient) plot used by Figures 2 and 3: one row per specification,
# one panel per outcome; the preferred specification in the main colour.

plot_forest <- function(d, row_levels) {
  d <- copy(as.data.table(d))
  d[, row := factor(row, levels = rev(row_levels))]
  d[, preferred := factor(preferred, levels = c(TRUE, FALSE), labels = c("Preferred specification", "Alternative"))]
  ggplot(d, aes(x = est, y = row, colour = preferred)) +
    geom_vline(xintercept = 0, colour = COL[["ref"]], linewidth = LWD$ref) +
    geom_linerange(aes(xmin = lo, xmax = hi), linewidth = LWD$ci) +
    geom_point(size = PT$size, shape = PT$shape) +
    scale_colour_manual(values = c("Preferred specification" = COL[["main"]], "Alternative" = COL[["pre"]])) +
    facet_wrap(~ panel, nrow = 1) +
    labs(y = NULL) +
    theme_thesis() +
    theme(legend.position = "none")
}
