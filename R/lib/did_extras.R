# =====================================================================
# did_extras.R  -- comparison estimators with inference
#   run_imputation_inf : imputation estimator (FE fitted on clean cells),
#                        score-based CR1 SE + Webb wild multiplier bootstrap
#   run_twfe_wcr       : static TWFE, CR1 SE, restricted wild cluster
#                        bootstrap-t (WCR, Webb weights, H0: beta = 0)
# Derived from the estimators' algebra, not from est_engine.py.
# Requires did_engine.R (prep_cells, WEBB, score_inference).
# =====================================================================

fe_design <- function(dt, crop_levels, year_levels) {
  f <- data.frame(crop = factor(dt$crop_id, levels = crop_levels), yr = factor(dt$year, levels = year_levels))
  model.matrix(~ crop + yr, data = f)
}

run_imputation_inf <- function(panel, outcome, treated, controls, years = c(1991, 2024), e_post = 0:9,
                               B = 9999, seed = 1) {
  d  <- prep_cells(panel, outcome, treated, controls, years)
  U  <- d[clean == TRUE]
  cl <- sort(unique(U$crop_id)); yl <- sort(unique(U$year))
  XU <- fe_design(U, cl, yl)
  XtXi <- solve(crossprod(XU))
  beta <- XtXi %*% crossprod(XU, U$y)
  T  <- d[post == TRUE & (year - g) %in% e_post & crop_id %in% cl & year %in% yl]
  T[, e := as.integer(year - g)]
  XT <- fe_design(T, cl, yl)
  T[, tau := y - as.vector(XT %*% beta)]
  resU <- U$y - as.vector(XU %*% beta)
  es <- sort(unique(T$e))
  crops <- sort(unique(d$crop_id))
  set.seed(seed)
  V <- matrix(sample(WEBB, B * length(crops), replace = TRUE), nrow = B)
  one <- function(wT) {
    aU  <- -as.vector(XU %*% (XtXi %*% crossprod(XT, wT)))
    th  <- sum(wT * T$y) + sum(aU * U$y)
    sel <- wT != 0
    rT  <- T$tau - ave(ifelse(sel, T$tau, NA), T$e, FUN = function(z) mean(z, na.rm = TRUE))
    rT[!sel] <- 0
    s   <- tapply(c(wT * rT, aU * resU), c(T$crop_id, U$crop_id), sum)
    psi <- setNames(numeric(length(crops)), crops); psi[names(s)] <- s
    c(score_inference(th, psi, V), n_treated = length(unique(T$crop_id[sel])))
  }
  dyn <- rbindlist(lapply(es, function(ee) {
    wT <- ifelse(T$e == ee, 1 / sum(T$e == ee), 0)
    r <- one(wT)
    data.table(event_time = ee, est = r$est, se_cluster = r$se_cluster, ci_lo = r$ci_lo, ci_hi = r$ci_hi,
               p_wild = r$p_wild, n_treated = r$n_treated, G = r$G)
  }))
  wT <- vapply(seq_len(nrow(T)), function(k) 1 / (sum(T$e == T$e[k]) * length(es)), 0)
  r  <- one(wT)
  list(dynamic = dyn, est = r$est, se_cluster = r$se_cluster, ci_lo = r$ci_lo, ci_hi = r$ci_hi,
       p_wild = r$p_wild, G = r$G, n_treated = r$n_treated,
       check_direct = mean(T[, .(m = mean(tau)), by = e]$m))
}

run_twfe_wcr <- function(panel, outcome, treated, controls, variant = "clean", years = c(1991, 2024),
                         B = 9999, seed = 1, e_max = Inf) {
  d <- as.data.table(panel)[crop_id %in% c(treated, controls) & year >= years[1] & year <= years[2]]
  d <- d[, .(crop_id, year, y = as.numeric(get(outcome)), p = as.numeric(pilot_year), gn = as.numeric(national_year))]
  d <- d[!is.na(y) & is.finite(y)]
  d[, post := as.numeric(crop_id %in% treated & !is.na(gn) & year >= gn)]
  if (variant == "clean") d <- d[(is.na(p) | year < p) | post == 1]
  # horizon restriction: treated cells beyond e_max are dropped (not recoded as untreated),
  # so the static coefficient averages over e = 0..e_max like the group-time estimators
  if (is.finite(e_max)) d <- d[!(crop_id %in% treated & !is.na(gn) & year - gn > e_max)]
  X  <- model.matrix(~ post + factor(crop_id) + factor(year), data = d)
  X  <- X[, qr(X)$pivot[seq_len(qr(X)$rank)], drop = FALSE]
  n  <- nrow(X); k <- ncol(X); G <- uniqueN(d$crop_id)
  XtXi <- solve(crossprod(X))
  j  <- which(colnames(X) == "post")
  a  <- as.vector(XtXi[j, , drop = FALSE] %*% t(X))          # beta_post = a . y
  cl <- d$crop_id
  adj <- (G / (G - 1)) * ((n - 1) / (n - k))
  M  <- diag(n) - X %*% XtXi %*% t(X)                          # residual maker
  se_of <- function(u) sqrt(adj * sum(tapply(a * u, cl, sum)^2))
  b0 <- sum(a * d$y); u0 <- as.vector(M %*% d$y); se0 <- se_of(u0); t0 <- b0 / se0
  Xr <- X[, -j, drop = FALSE]
  fr <- as.vector(Xr %*% solve(crossprod(Xr), crossprod(Xr, d$y))); ur <- d$y - fr
  gi <- match(cl, sort(unique(cl)))
  set.seed(seed)
  tstar <- vapply(seq_len(B), function(b) {
    v  <- sample(WEBB, G, replace = TRUE)
    ys <- fr + v[gi] * ur
    us <- as.vector(M %*% ys)
    sum(a * ys) / se_of(us)
  }, 0)
  list(est = b0, se_cluster = se0, p_wcr = (sum(abs(tstar) >= abs(t0)) + 1) / (B + 1), G = G, n_obs = n,
       n_treated = length(intersect(treated, d$crop_id)), post_e_max = d[post == 1, max(year - gn)])
}
