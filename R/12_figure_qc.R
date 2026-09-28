# =====================================================================
# 12_figure_qc.R -- QC table for every thesis figure (brief section 19)
# Re-runs each figure script, then checks from the ggplot object and the
# saved plot data:
#   numeric match : plotted values vs the verified result files
#   label match   : no banned crop terms; required wording present
#   note match    : required caveats in the note
#   style match   : theme elements equal R/00_theme_thesis.R conventions
# Output: figures/figure_qc.csv
# =====================================================================

source("R/00_theme_thesis.R")
V <- VERIFIED
S  <- fread(file.path(V, "verified_results_summary.csv"))
D  <- fread(file.path(V, "verified_results_dynamic.csv"))
N  <- fread(file.path(V, "verified_apfs_national.csv"))
FC <- fread(file.path(V, "verified_apfs_fruit_2024_by_crop.csv"), encoding = "UTF-8")
P  <- fread(file.path(V, "verified_master_panel.csv"))

source("R/lib/thesis_names.R")
BANNED <- c(BANNED_CROP_NAMES,
            "real farm-gate", "CPI-deflated real price index", "causal effect of", "Callaway", "cancels exactly")

figs <- list(
  list(id = "fig1", script = "R/01_figure1.R", file = "fig1_annual_event_study", src = "verified_results_dynamic.csv",
       need_title = c("associated with insurance expansion"), need_note = c("omitted", "not established causal", "custom", "24 listed", "22 contribute")),
  list(id = "fig2", script = "R/02_figure2.R", file = "fig2_estimator_comparison", src = "verified_results_summary.csv",
       need_title = c("estimator"), need_note = c("benchmark", "associations", "same post-availability horizon, e = 0 to 9", "beyond e = 9 excluded")),
  list(id = "fig3", script = "R/03_figure3.R", file = "fig3_annual_robustness", src = "verified_results_summary.csv",
       need_title = c("robustness"), need_note = c("associations", "custom")),
  list(id = "fig4", script = "R/04_figure4.R", file = "fig4_fruit_event_study", src = "verified_results_dynamic.csv",
       need_title = c("suggestive"), need_note = c("suggestive at most", "consists primarily of annual crops", "later-treated fruit crops may also serve as not-yet-treated", "Astringent persimmon", "Plum", "orchard area")),
  list(id = "fig5", script = "R/05_figure5.R", file = "fig5_price_event_study", src = "verified_results_dynamic.csv",
       need_title = c("relative farm-gate"), need_note = c("not a CPI-deflated real price", "reduced-form", "associations"),
       need_y = "Log relative farm-gate price index"),
  list(id = "fig6", script = "R/06_figure6.R", file = "fig6_rice_descriptive", src = "verified_master_panel.csv; verified_treatment_coding.csv",
       need_title = c("descriptive"), need_note = c("no difference-in-differences inference", "Descriptive only")),
  list(id = "fig7", script = "R/07_figure7.R", file = "fig7_insured_to_normal_yield", src = "verified_apfs_fruit_2024_by_crop.csv; verified_apfs_fruit_2024_audit.csv",
       need_title = c("insured-to-normal"), need_note = c("descriptive", "not part of the verified bundle", "non-positive insured or normal yield")),
  list(id = "fig8", script = "R/08_figure8.R", file = "fig8_record_composition", src = "verified_apfs_fruit_2024_by_crop.csv; verified_apfs_fruit_2024_audit.csv",
       need_title = c("administrative contract-detail records"), need_note = c("not necessarily unique contracts")),
  list(id = "fig9", script = "R/09_figure9.R", file = "fig9_apfs_national_trends", src = "verified_apfs_national.csv",
       need_title = c("enrollment", "loss"), need_note = c("risk premium", "not comparable across years")),
  list(id = "fig10", script = "R/10_figure10.R", file = "fig10_apfs_financing_shares", src = "verified_apfs_national.csv",
       need_title = c("financing"), need_note = c("does not explain the residual", "not attributed to any payer")),
  list(id = "figA1", script = "R/11_figureA1.R", file = "figA1_insured_price_appendix", src = "verified_apfs_fruit_2024_by_crop.csv",
       need_title = c("insured-price"), need_note = c("not defined", "should not be compared")))

numeric_check <- function(id, pd) {
  m <- switch(id,
    fig1 = merge(pd, D[sample == "annual" & spec == "CS-A (preferred)", .(outcome, event_time, e2 = est, l2 = ci_lo_wild, h2 = ci_hi_wild)],
                 by = c("outcome", "event_time"))[, max(abs(c(est - e2, ci_lo_wild - l2, ci_hi_wild - h2)))],
    fig4 = merge(pd, D[sample == "fruit" & spec == "CS-A (preferred)", .(outcome, event_time, e2 = est, l2 = ci_lo_wild, h2 = ci_hi_wild)],
                 by = c("outcome", "event_time"))[, max(abs(c(est - e2, ci_lo_wild - l2, ci_hi_wild - h2)))],
    fig5 = merge(pd, D[sample == "price" & spec == "CS-A main (exact match, annual linking rule)", .(outcome, event_time, e2 = est, l2 = ci_lo_wild, h2 = ci_hi_wild)],
                 by = c("outcome", "event_time"))[, max(abs(c(est - e2, ci_lo_wild - l2, ci_hi_wild - h2)))],
    fig2 = , fig3 = {
      x <- merge(pd, S[sample == "annual", .(spec_internal, outcome_internal, e2 = est, l2 = ci_lo_wild_py, h2 = ci_hi_wild_py, se = se_cluster)],
                 by = c("spec_internal", "outcome_internal"))
      x[grepl("TWFE", spec_internal), `:=`(l2 = e2 - qnorm(0.975) * se, h2 = e2 + qnorm(0.975) * se)]
      x[, max(abs(c(est - e2, lo - l2, hi - h2)))]
    },
    fig6 = {
      r <- P[crop_id == "rice" & year %between% c(1991, 2024)]
      x <- merge(pd, melt(r[, .(year, ln_area, ln_yield, ln_production)], id.vars = "year", variable.name = "outcome", value.name = "v2"),
                 by = c("outcome", "year"))
      x[, max(abs(value - v2))]
    },
    fig7 = {
      x <- melt(FC[, .(crop, `Below 1` = share_ratio_below_1, `Equal to 1` = share_ratio_equal_1, `Above 1` = share_ratio_above_1)],
                id.vars = "crop", variable.name = "cat", value.name = "s2")
      merge(pd, x, by = c("crop", "cat"))[, max(abs(share - s2))]
    },
    fig8 = merge(pd, FC[, .(crop, r2 = records)], by = "crop")[, max(abs(records - r2))],
    fig9 = {
      a <- merge(pd[grepl("^A", panel)], N[, .(year, v2 = area_enrollment_rate_pct)], by = "year")[, max(abs(value - v2))]
      b <- merge(pd[grepl("^B", panel)], N[, .(year, v2 = loss_ratio_pct)], by = "year")[, max(abs(value - v2))]
      max(a, b)
    },
    fig10 = {
      x <- merge(pd[payer == "Central government"], N[, .(year, s2 = central_gov_mkrw / net_premium_mkrw)], by = "year")
      y <- merge(pd[payer == "Farmers"], N[, .(year, s2 = farmer_mkrw / net_premium_mkrw)], by = "year")
      pv <- merge(pd[payer == "Provinces"], N[, .(year, s2 = provincial_mkrw / net_premium_mkrw)], by = "year")
      mu <- merge(pd[payer == "Municipalities"], N[, .(year, s2 = municipal_mkrw / net_premium_mkrw)], by = "year")
      rs <- merge(pd[grepl("Not explained", payer)], N[, .(year, s2 = 1 - components_share_of_net_premium)], by = "year")
      max(abs(c(x$share - x$s2, y$share - y$s2, pv$share - pv$s2, mu$share - mu$s2, rs$share - rs$s2)))
    },
    figA1 = merge(pd, FC[, .(crop, m2 = insured_price_median, a2 = insured_price_p25, b2 = insured_price_p75)], by = "crop")[
      , max(abs(c(median - m2, p25 - a2, p75 - b2)))])
  m
}

style_check <- function(p) {
  t <- p$theme
  ok <- c(border = identical(t$panel.border$colour, "grey40") && t$panel.border$linewidth == 0.8,
          grid = identical(t$panel.grid.major$colour, "grey90") && t$panel.grid.major$linewidth == 0.6,
          minor = identical(t$panel.grid.minor$colour, "grey95"),
          axis_title = t$axis.title$size == 15, axis_text = t$axis.text$size == 11 && identical(t$axis.text$colour, "grey30"),
          legend = identical(t$legend.position, "top") || identical(t$legend.position, "none"),
          font = identical(t$text$family, FONT) && FONT %in% c("Arial Narrow", "Nimbus Sans Narrow"), base = t$text$size == 14)
  if (all(ok)) "MATCH" else paste("MISMATCH:", paste(names(ok)[!ok], collapse = ","))
}

rows <- list()
for (f in figs) {
  env <- new.env()
  sys.source(f$script, envir = env)
  p  <- env$p
  pd <- fread(file.path("figures/plotdata", paste0(f$file, ".csv")))
  if ("panel" %in% names(pd)) pd[, panel := as.character(panel)]
  lab <- p$labels
  alltext <- paste(lab$title, lab$caption, lab$x, lab$y, paste(levels(factor(unlist(pd[, lapply(.SD, as.character), .SDcols = is.character]))), collapse = " "))
  banned <- BANNED[vapply(BANNED, function(b) grepl(b, alltext, ignore.case = TRUE), TRUE)]
  # final style decision (2026-09-28): no figure number and no thesis title inside the graphic
  no_title <- is.null(lab$title) && !grepl("Figure\\s*[0-9A]", alltext)
  tl <- no_title && (is.null(f$need_y) || identical(lab$y, f$need_y)) && !length(banned)
  nt <- all(vapply(f$need_note, function(s) grepl(s, gsub("[\n\u00a0]", " ", lab$caption), ignore.case = TRUE), TRUE))
  dev <- numeric_check(f$id, pd)
  st <- style_check(p)
  files_ok <- all(file.exists(file.path("figures", paste0(f$file, c(".png", ".pdf")))))
  rows[[length(rows) + 1]] <- data.table(
    figure = FIG_NO[[f$id]], output_files = paste0("figures/", f$file, ".{png,pdf}"),
    underlying_data_file = paste0("verified_results/", gsub("; ", "; verified_results/", f$src)),
    number_of_plotted_observations = nrow(pd),
    numeric_match_to_verified_results = sprintf("%s (max |diff| = %.1e)", if (dev < 1e-9) "MATCH" else "MISMATCH", dev),
    label_match = if (tl) "MATCH" else paste("CHECK", paste(banned, collapse = ",")),
    note_match = if (nt) "MATCH" else "CHECK",
    style_match_to_my_R_code = st,
    status = if (dev < 1e-9 && tl && nt && st == "MATCH" && files_ok) {
      if (f$id == "figA1") "PASS (quartiles only: 5th/95th whiskers need raw APFS file)" else "PASS"
    } else "FAIL")
}
Q <- rbindlist(rows)
fwrite(Q, "figures/figure_qc.csv")
print(Q[, .(figure, number_of_plotted_observations, numeric_match_to_verified_results, label_match, note_match, style_match_to_my_R_code, status)])
