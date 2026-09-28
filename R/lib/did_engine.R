# =====================================================================
# did_engine.R
# Independent R implementation of the Chapter 5 estimators.
#
# Written from the documented definition (METHODOLOGICAL_MEMO section 0),
# NOT translated from est_engine.py. Point estimates are computed directly
# from the defining formula (att_direct). A separate linear-weight
# representation (att_weights) is built only for inference, and the two are
# cross-checked against each other.
#
# Definition (memo section 0):
#   For treated crop i with nationwide year g_i and pilot year p_i:
#     base year b_i   = last year t < p_i with the outcome observed (window)
#     ATT_i(e)        = [Y_i,g+e - Y_i,b] - mean_j [Y_j,g+e - Y_j,b]
#     controls j      = every other crop in the sample that is clean
#                       (never piloted, or year < own pilot year) in BOTH
#                       g+e and b (not-yet-treated and never-treated)
#     ATT(e)          = equal-weighted mean over treated crops observed at e
#     headline        = equal-weighted mean of ATT(e), e = 0..9
#   Transition cells (p_i <= t < g_i) of treated crops are never used.
#   Normalisation B uses the mean of all clean pre years as base; B5 the
#   mean of the last five.
# =====================================================================

suppressPackageStartupMessages(library(data.table))

# ---------------------------------------------------------------------
# 1. Cell set used by every estimator
# ---------------------------------------------------------------------
prep_cells <- function(panel, outcome, treated, controls,
                       years = c(1991, 2024), pilot_clock = FALSE,
                       gcol = "national_year", pcol = "pilot_year") {
  d <- as.data.table(panel)
  d <- d[crop_id %in% c(treated, controls) & year >= years[1] & year <= years[2]]
  d <- d[, .(crop_id, year,
             y  = as.numeric(get(outcome)),
             p  = as.numeric(get(pcol)),
             gn = as.numeric(get(gcol)))]
  d <- d[!is.na(y) & is.finite(y)]
  d[, g := if (pilot_clock) p else gn]
  d[, clean := is.na(p) | year < p]
  d[, is_tr := crop_id %in% treated]
  d[, post := is_tr & !is.na(g) & year >= g]
  # keep clean cells of every crop and post cells of treated crops;
  # this drops transition cells and every control's post-pilot cells
  d <- d[clean | post]
  d[, cell := paste(crop_id, year, sep = "|")]
  d[]
}

base_years <- function(d, i, norm = "A", b5 = FALSE) {
  pre <- sort(d[crop_id == i & clean == TRUE, year])
  if (!length(pre)) return(integer(0))
  if (norm == "A") return(max(pre))
  if (b5) return(tail(pre, 5))
  pre
}

# ---------------------------------------------------------------------
# 2. Direct point estimate from the formula (no weights)
# ---------------------------------------------------------------------
att_direct <- function(d, treated, norm = "A", b5 = FALSE,
                       e_post = 0:9, e_pre_min = -12) {
  Y      <- setNames(d$y, d$cell)
  clean  <- setNames(d$clean, d$cell)
  crops  <- unique(d$crop_id)
  is_clean <- function(j, t) { k <- paste(j, t, sep = "|"); !is.na(clean[k]) & clean[k] }
  rows <- list()
  for (i in treated) {
    if (!(i %in% crops)) next
    g   <- d[crop_id == i, g][1]
    pre <- sort(d[crop_id == i & clean == TRUE, year])
    if (!length(pre)) next
    B   <- base_years(d, i, norm, b5)
    tgt_post <- (g + e_post)[paste(i, g + e_post, sep = "|") %in% d$cell]
    tgt_pre  <- pre[(pre - g) >= e_pre_min]
    if (norm == "A") tgt_pre <- tgt_pre[tgt_pre != max(pre)]
    for (t in c(tgt_post, tgt_pre)) {
      J <- setdiff(crops, i)
      J <- J[vapply(J, function(j) is_clean(j, t) && all(is_clean(j, B)), logical(1))]
      if (!length(J)) next
      dy_i <- Y[paste(i, t, sep = "|")] - mean(Y[paste(i, B, sep = "|")])
      dy_j <- vapply(J, function(j) Y[paste(j, t, sep = "|")] - mean(Y[paste(j, B, sep = "|")]), 0)
      rows[[length(rows) + 1]] <- data.table(
        crop = i, event_time = as.integer(t - g), year = t,
        base = paste(B, collapse = ";"), base_last = max(B),
        att_i = unname(dy_i - mean(dy_j)), n_ctrl = length(J),
        ctrl = paste(sort(J), collapse = ";"))
    }
  }
  rbindlist(rows)
}

aggregate_att <- function(cr, e_post = 0:9) {
  dyn <- cr[, .(est = mean(att_i), n_treated = .N,
                n_ctrl_min = min(n_ctrl), n_ctrl_max = max(n_ctrl),
                treated_crops = paste(crop, collapse = ";")),
            by = event_time][order(event_time)]
  pe  <- intersect(e_post, dyn$event_time)
  list(dynamic = dyn, overall = mean(dyn[event_time %in% pe, est]), post_e = pe)
}

# ---------------------------------------------------------------------
# 3. Linear-weight representation (for inference only)
#    theta = sum_cells a_ct * Y_ct
# ---------------------------------------------------------------------
att_weights <- function(d, cr) {
  # returns a data.table (event_time, key, a) with ATT(e) = sum a * Y
  out <- list()
  for (r in seq_len(nrow(cr))) {
    x <- cr[r]
    B <- as.integer(strsplit(x$base, ";")[[1]])
    J <- strsplit(x$ctrl, ";")[[1]]
    w <- c(1, rep(-1 / length(B), length(B)))
    k <- c(paste(x$crop, x$year, sep = "|"), paste(x$crop, B, sep = "|"))
    for (j in J) {
      w <- c(w, -1 / length(J), rep(1 / (length(J) * length(B)), length(B)))
      k <- c(k, paste(j, x$year, sep = "|"), paste(j, B, sep = "|"))
    }
    out[[r]] <- data.table(event_time = x$event_time, crop_t = x$crop, cell = k, w = w)
  }
  W <- rbindlist(out)
  n_by_e <- cr[, .N, by = event_time]
  W <- merge(W, n_by_e, by = "event_time")
  W[, a := w / N]
  W[, .(a = sum(a)), by = .(event_time, cell)]
}

overall_weights <- function(W, post_e) {
  W[event_time %in% post_e, .(a = sum(a) / length(post_e)), by = cell]
}

# ---------------------------------------------------------------------
# 4. Residuals: two-way FE fitted on clean cells only
#    treated post cells additionally net of ATT(e)   (memo section 0)
# ---------------------------------------------------------------------
fe_residuals <- function(d, att_by_e) {
  cl <- d[clean == TRUE]
  fit <- lm(y ~ factor(crop_id) + factor(year), data = cl)
  ok  <- d$crop_id %in% cl$crop_id & d$year %in% cl$year
  dd  <- d[ok]
  dd[, yhat := predict(fit, newdata = dd)]
  dd[, res := y - yhat]
  dd[post == TRUE, res := res - att_by_e[as.character(as.integer(year - g))]]
  dd[post == TRUE & is.na(res), res := NA_real_]
  setNames(dd$res, dd$cell)
}

# ---------------------------------------------------------------------
# 5. Crop-level scores, CR1-type SE, Webb wild multiplier bootstrap
# ---------------------------------------------------------------------
WEBB <- c(-sqrt(1.5), -1, -sqrt(0.5), sqrt(0.5), 1, sqrt(1.5))

crop_scores <- function(wk, res, crops) {
  # wk: data.table(cell, a); res: named residual vector
  r <- res[wk$cell]; r[is.na(r)] <- 0         # cells without residual do not contribute
  s <- tapply(wk$a * r, sub("\\|.*$", "", wk$cell), sum)
  out <- setNames(numeric(length(crops)), crops)
  out[names(s)] <- s
  out
}

score_inference <- function(theta, psi, V) {
  G   <- sum(abs(psi) > 0)
  se  <- if (G > 1) sqrt(G / (G - 1) * sum(psi^2)) else NA_real_
  star <- as.vector(V %*% psi)
  q   <- unname(quantile(abs(star), 0.95, type = 7))
  p   <- (sum(abs(star) >= abs(theta)) + 1) / (length(star) + 1)
  list(est = theta, se_cluster = se, ci_lo = theta - q, ci_hi = theta + q,
       p_wild = p, se_wild = sd(star), G = G, star = star,
       p_normal = if (!is.na(se) && se > 0) 2 * pnorm(-abs(theta / se)) else NA_real_)
}

# ---------------------------------------------------------------------
# 6. One complete run: point estimates + inference + pre-trend Wald
# ---------------------------------------------------------------------
run_gt <- function(panel, outcome, treated, controls, norm = "A", b5 = FALSE,
                   years = c(1991, 2024), pilot_clock = FALSE, e_post = 0:9,
                   B = 9999, seed = 1, inference = TRUE) {
  d  <- prep_cells(panel, outcome, treated, controls, years, pilot_clock)
  cr <- att_direct(d, treated, norm, b5, e_post)
  ag <- aggregate_att(cr, e_post)
  res <- list(cells = d, crop_att = cr, dynamic = copy(ag$dynamic),
              overall = list(est = ag$overall, post_e = ag$post_e,
                             n_treated = uniqueN(cr[event_time %in% ag$post_e, crop]),
                             n_controls_listed = length(setdiff(unique(d$crop_id), treated))))
  # cross-check: weights reproduce the direct estimate
  W  <- att_weights(d, cr)
  Yk <- setNames(d$y, d$cell)
  chk <- W[, .(est_w = sum(a * Yk[cell])), by = event_time]
  res$dynamic <- merge(res$dynamic, chk, by = "event_time")
  res$max_weight_vs_direct_gap <- max(abs(res$dynamic$est - res$dynamic$est_w))
  if (!inference) return(res)

  crops <- sort(unique(d$crop_id))
  set.seed(seed)
  V <- matrix(sample(WEBB, B * length(crops), replace = TRUE), nrow = B)
  att_by_e <- setNames(ag$dynamic$est, as.character(ag$dynamic$event_time))
  rsd <- fe_residuals(d, att_by_e)
  stars <- list(); inf_rows <- list()
  for (e in ag$dynamic$event_time) {
    wk  <- W[event_time == e]
    psi <- crop_scores(wk, rsd, crops)
    inf <- score_inference(ag$dynamic[event_time == e, est], psi, V)
    stars[[as.character(e)]] <- inf$star
    inf_rows[[length(inf_rows) + 1]] <- data.table(
      event_time = e, se_cluster = inf$se_cluster, ci_lo = inf$ci_lo, ci_hi = inf$ci_hi,
      p_wild = inf$p_wild, se_wild = inf$se_wild, G_contrib = inf$G, p_normal = inf$p_normal)
  }
  res$dynamic <- merge(res$dynamic, rbindlist(inf_rows), by = "event_time")
  wo  <- overall_weights(W, ag$post_e)
  psi <- crop_scores(wo, rsd, crops)
  inf <- score_inference(ag$overall, psi, V)
  res$overall <- c(res$overall, inf[c("se_cluster", "ci_lo", "ci_hi", "p_wild", "se_wild", "G", "p_normal")])
  res$overall$psi <- psi
  # joint pre-trend Wald with bootstrap covariance
  pre_e <- sort(ag$dynamic$event_time[ag$dynamic$event_time < 0])
  if (length(pre_e) >= 2) {
    th <- ag$dynamic[match(pre_e, event_time), est]
    S  <- do.call(cbind, stars[as.character(pre_e)])
    Si <- MASS::ginv(cov(S))
    Wd <- as.numeric(t(th) %*% Si %*% th)
    Ws <- rowSums((S %*% Si) * S)
    res$overall$pre_wald   <- Wd
    res$overall$pre_k      <- length(pre_e)
    res$overall$pre_p_boot <- (sum(Ws >= Wd) + 1) / (length(Ws) + 1)
    res$overall$pre_mean   <- mean(th)
  }
  res
}

# ---------------------------------------------------------------------
# 7. Imputation estimator (FE fitted on clean cells; treated post imputed)
# ---------------------------------------------------------------------
run_imputation <- function(panel, outcome, treated, controls, years = c(1991, 2024), e_post = 0:9) {
  d  <- prep_cells(panel, outcome, treated, controls, years)
  cl <- d[clean == TRUE]
  fit <- lm(y ~ factor(crop_id) + factor(year), data = cl)
  tr <- d[post == TRUE & (year - g) %in% e_post & crop_id %in% cl$crop_id & year %in% cl$year]
  tr[, e := as.integer(year - g)]
  tr[, tau := y - predict(fit, newdata = tr)]
  dyn <- tr[, .(est = mean(tau), n_treated = .N), by = e][order(e)]
  list(dynamic = dyn, overall = mean(dyn$est))
}

# ---------------------------------------------------------------------
# 8. Static TWFE benchmark with CR1 clustered SE
# ---------------------------------------------------------------------
run_twfe <- function(panel, outcome, treated, controls, variant = "clean", years = c(1991, 2024)) {
  d <- as.data.table(panel)[crop_id %in% c(treated, controls) & year >= years[1] & year <= years[2]]
  d <- d[, .(crop_id, year, y = as.numeric(get(outcome)), p = as.numeric(pilot_year),
             gn = as.numeric(national_year))]
  d <- d[!is.na(y) & is.finite(y)]
  d[, post := as.numeric(crop_id %in% treated & !is.na(gn) & year >= gn)]
  if (variant == "clean") d <- d[(is.na(p) | year < p) | post == 1]
  X <- model.matrix(~ post + factor(crop_id) + factor(year), data = d)
  fit <- lm.fit(X, d$y)
  keep <- !is.na(fit$coefficients)
  X <- X[, keep, drop = FALSE]
  fit <- lm.fit(X, d$y)
  n <- nrow(X); k <- ncol(X)
  XtXi <- solve(crossprod(X))
  u <- fit$residuals
  G <- uniqueN(d$crop_id)
  meat <- Reduce(`+`, lapply(split(seq_len(n), d$crop_id), function(ix) {
    s <- crossprod(X[ix, , drop = FALSE], u[ix]); s %*% t(s) }))
  Vc <- XtXi %*% meat %*% XtXi * (G / (G - 1)) * ((n - 1) / (n - k))
  j <- which(colnames(X) == "post")
  list(est = unname(fit$coefficients[j]), se_cluster = sqrt(Vc[j, j]), G = G, n_obs = n,
       n_treated = length(intersect(treated, d$crop_id)), post_e_max = d[post == 1, max(year - gn)])
}
