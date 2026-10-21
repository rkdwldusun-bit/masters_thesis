# Helpers for the national crop tables of the thesis (Tables 2, 4-6, 9, A1; Figures 6-7).
# All estimates use R/lib/did_engine.R; area weights and pre-pilot slopes follow
# thesis equation (6) and Table 9.

# One specification: estimate, score SE, Webb multiplier interval and p-value,
# and the number of contributing comparison series.
spec_row <- function(panel, outcome, treated, controls, B, seed, ...) {
  r <- run_gt(panel, outcome, treated, controls, B = B, seed = seed, ...)
  o <- r$overall
  list(row = data.table(outcome = outcome, est = o$est, se = o$se_cluster, ci_lo = o$ci_lo,
                        ci_hi = o$ci_hi, p = o$p_wild, n_treated = o$n_treated,
                        n_comparison = o$G - o$n_treated),
       fit = r)
}

# Equation (6): treated crops weighted by mean cultivated area in 2003-2007;
# comparison crops stay equally weighted within each contrast.
area_weights <- function(panel, treated, years = 2003:2007) {
  a <- panel[crop_id %in% treated & year %in% years, .(a = mean(area_ha)), by = crop_id]
  setNames(a$a / sum(a$a), a$crop_id)
}

area_weighted_row <- function(panel, outcome, treated, controls, wcrop, B, seed, e_post = 0:9) {
  d  <- prep_cells(panel, outcome, treated, controls)
  cr <- att_direct(d, treated, "A", FALSE, e_post)
  cr <- cr[event_time %in% e_post]
  cr[, w_i := wcrop[crop] / sum(wcrop[crop]), by = event_time]
  est <- cr[, .(th = sum(w_i * att_i)), by = event_time][, mean(th)]
  # linear cell weights: as att_weights(), with crop weights in place of 1/N
  out <- list()
  for (r in seq_len(nrow(cr))) {
    x <- cr[r]
    Bs <- as.integer(strsplit(x$base, ";")[[1]]); J <- strsplit(x$ctrl, ";")[[1]]
    w <- c(1, rep(-1 / length(Bs), length(Bs)))
    k <- c(paste(x$crop, x$year, sep = "|"), paste(x$crop, Bs, sep = "|"))
    for (j in J) {
      w <- c(w, -1 / length(J), rep(1 / (length(J) * length(Bs)), length(Bs)))
      k <- c(k, paste(j, x$year, sep = "|"), paste(j, Bs, sep = "|"))
    }
    out[[r]] <- data.table(cell = k, a = w * x$w_i / length(e_post))
  }
  W <- rbindlist(out)[, .(a = sum(a)), by = cell]
  Yk <- setNames(d$y, d$cell)
  stopifnot(abs(sum(W$a * Yk[W$cell]) - est) < 1e-10)
  # residuals as in run_gt (equal-weight event-time contrasts centre treated post cells)
  ag  <- aggregate_att(cr, e_post)
  rsd <- fe_residuals(d, setNames(ag$dynamic$est, as.character(ag$dynamic$event_time)))
  crops <- sort(unique(d$crop_id))
  set.seed(seed)
  V <- matrix(sample(WEBB, B * length(crops), replace = TRUE), nrow = B)
  inf <- score_inference(est, crop_scores(W, rsd, crops), V)
  data.table(outcome = outcome, est = est, se = inf$se_cluster, ci_lo = inf$ci_lo, ci_hi = inf$ci_hi,
             p = inf$p_wild, n_treated = length(unique(cr$crop)), n_comparison = inf$G - length(unique(cr$crop)))
}

# Table 2: unique crop-year observations entering the main comparison (levels).
comparison_cells <- function(fit, treated) {
  cr <- fit$crop_att[event_time %in% 0:9]
  tr_ref <- unique(cr[, .(crop_id = crop, year = base_last)])
  tr_tgt <- unique(cr[, .(crop_id = crop, year)])
  ctl <- cr[, .(crop_id = strsplit(ctrl, ";")[[1]]), by = .(crop, year, base_last)]
  co_ref <- unique(ctl[, .(crop_id, year = base_last)])
  co_tgt <- unique(ctl[, .(crop_id, year)])
  rbind(tr_ref[, group := "Treated, reference year"], tr_tgt[, group := "Treated, target years"],
        co_ref[, group := "Comparison, reference years"], co_tgt[, group := "Comparison, target years"])
}

summary_stats <- function(panel, cells) {
  x <- merge(cells, panel[, .(crop_id, year, area_ha, yield_kg10a, production_t)], by = c("crop_id", "year"))
  melt(x, id.vars = c("group", "crop_id", "year"), variable.name = "variable")[
    , .(mean = mean(value), sd = sd(value), min = min(value), max = max(value), obs = .N,
        crops = uniqueN(crop_id)), by = .(variable, group)]
}

# Table 9: least-squares slope of each log outcome on year, 1998-2007.
prepilot_slopes <- function(panel, crops, years = 1998:2007) {
  x <- panel[crop_id %in% crops & year %in% years]
  melt(x[, .(crop_id, year, ln_area, ln_yield, ln_production)], id.vars = c("crop_id", "year"))[
    is.finite(value), .(slope = unname(coef(lm(value ~ year))[2])), by = .(variable, crop_id)]
}

slope_table <- function(panel, treated, comparison) {
  s <- rbind(prepilot_slopes(panel, treated)[, grp := "treated"],
             prepilot_slopes(panel, comparison)[, grp := "comparison"])
  s[, .(m_t = mean(slope[grp == "treated"]), sd_t = sd(slope[grp == "treated"]),
        m_c = mean(slope[grp == "comparison"]), sd_c = sd(slope[grp == "comparison"]),
        n_t = sum(grp == "treated"), n_c = sum(grp == "comparison")), by = variable][
    , `:=`(diff = m_t - m_c, std_diff = (m_t - m_c) / sqrt((sd_t^2 + sd_c^2) / 2))][]
}
