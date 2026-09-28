# =====================================================================
# 00_theme_thesis.R
# One reusable theme for the Chapter 5 figures.
# Conventions come from my earlier figure code (see R/style_reference.md).
# =====================================================================

library(ggplot2)
library(data.table)

# ---------------------------------------------------------------------
# Font
# "sans" as in my R budget figure; switch to "Arial Narrow" to match the
# Chapter 2 Stata figures. On machines without Arial, a metric-compatible
# substitute is used for rendering.
# ---------------------------------------------------------------------
THESIS_FONT <- "sans"

resolve_font <- function(f) {
  have <- tryCatch(system("fc-list : family", intern = TRUE), error = function(e) character(0))
  have <- unique(trimws(unlist(strsplit(have, ","))))
  subs <- list("sans" = c("Arial", "Liberation Sans", "Helvetica"),
               "Arial Narrow" = c("Arial Narrow", "Liberation Sans Narrow", "Nimbus Sans Narrow"))
  cand <- if (f %in% names(subs)) subs[[f]] else f
  hit <- cand[cand %in% have]
  if (length(hit)) hit[1] else f
}
FONT <- resolve_font(THESIS_FONT)

# ---------------------------------------------------------------------
# Sizes (pt)
# ---------------------------------------------------------------------
SIZE <- list(base = 14, title = 15, axis_title = 15, axis_text = 11, legend = 11, caption = 11, strip = 11)

# ---------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------
COL <- c(main   = "#66C2A5",   # my R line/point colour (ColorBrewer Set2 no. 1)
         pre    = "grey40",    # placebo / secondary marks (my panel-border grey)
         bar    = "#99C7A4",   # my Stata bar fill "153 199 164"
         ref    = "grey20",    # zero / reference lines
         set2_2 = "#FC8D62", set2_3 = "#8DA0CB", set2_4 = "#E78AC3", set2_8 = "#B3B3B3")

# ---------------------------------------------------------------------
# Line widths and points
# ---------------------------------------------------------------------
LWD <- list(series = 0.9, ci = 0.6, ref = 0.4)
PT  <- list(size = 2.5, shape = 16)

# confidence-interval style: thin vertical/horizontal range in the series colour, no caps
geom_ci <- function(..., horizontal = FALSE) {
  if (horizontal) geom_linerange(..., linewidth = LWD$ci, orientation = "y")
  else geom_linerange(..., linewidth = LWD$ci)
}

# ---------------------------------------------------------------------
# Figure dimensions: 8 in x 300 dpi = 2400 px wide (my Stata export width)
# ---------------------------------------------------------------------
FIG <- list(width = 8, height_single = 5.8, dpi = 300)
show_title <- TRUE
FIG_NO <- c(fig1 = "[Figure 1]", fig2 = "[Figure 2]", fig3 = "[Figure 3]", fig4 = "[Figure 4]", fig5 = "[Figure 5]",
            fig6 = "[Figure 6]", fig7 = "[Figure 7]", fig8 = "[Figure 8]", fig9 = "[Figure 9]", fig10 = "[Figure 10]",
            figA1 = "[Appendix Figure A1]")

# ---------------------------------------------------------------------
# Theme
# ---------------------------------------------------------------------
theme_thesis <- function(base_size = SIZE$base, base_family = FONT) {
  theme_bw(base_family = base_family, base_size = base_size) +
    theme(
      plot.title        = element_text(size = SIZE$title, colour = "black", face = "plain", hjust = 0,
                                       margin = margin(b = 8)),
      plot.title.position   = "plot",
      plot.caption      = element_text(size = SIZE$caption, colour = "black", hjust = 0, lineheight = 1.1,
                                       margin = margin(t = 10)),
      plot.caption.position = "plot",
      panel.border      = element_rect(colour = "grey40", fill = NA, linewidth = 0.8),
      panel.grid.major  = element_line(colour = "grey90", linewidth = 0.6),
      panel.grid.minor  = element_line(colour = "grey95", linewidth = 0.4),
      axis.title        = element_text(size = SIZE$axis_title, colour = "black"),
      axis.text         = element_text(size = SIZE$axis_text, colour = "grey30"),
      axis.text.x       = element_text(angle = 0, hjust = 0.5, vjust = 0.5),
      legend.position   = "top",
      legend.direction  = "horizontal",
      legend.title      = element_blank(),
      legend.text       = element_text(size = SIZE$legend),
      legend.background = element_blank(),
      legend.key        = element_blank(),
      strip.text        = element_text(size = SIZE$strip),
      plot.background   = element_rect(fill = "white", colour = NA),
      panel.background  = element_rect(fill = "white", colour = NA),
      plot.margin       = margin(10, 12, 8, 10)
    )
}

# ---------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------
comma <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)

wrap <- function(x, width = 100) paste(strwrap(x, width = width), collapse = "\n")

fig_title <- function(id, text, width = 80) if (show_title) wrap(paste(FIG_NO[[id]], text), width) else NULL

# Save PNG + PDF and the exact plotted data (for QC). No numbers are typed by hand:
# every plotted value comes from verified_results/.
save_thesis_fig <- function(p, id, file, height, data, width = FIG$width) {
  dir.create("figures", showWarnings = FALSE)
  dir.create("figures/plotdata", showWarnings = FALSE)
  ggsave(file.path("figures", paste0(file, ".png")), p, width = width, height = height, dpi = FIG$dpi,
         units = "in", bg = "white")
  ggsave(file.path("figures", paste0(file, ".pdf")), p, width = width, height = height, units = "in",
         device = grDevices::cairo_pdf, bg = "white")
  fwrite(as.data.table(data), file.path("figures/plotdata", paste0(file, ".csv")))
  lab <- p$labels
  writeLines(c(paste0("id: ", id), paste0("title: ", gsub("\n", " ", lab$title %||% "")),
               paste0("x: ", lab$x %||% ""), paste0("y: ", lab$y %||% ""),
               paste0("caption: ", gsub("\n", " ", lab$caption %||% ""))),
             file.path("figures/plotdata", paste0(file, "_labels.txt")))
  invisible(p)
}

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

VERIFIED <- "verified_results"
