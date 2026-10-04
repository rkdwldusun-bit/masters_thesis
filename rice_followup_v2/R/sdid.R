# Synthetic DiD (primary) and S4, S5, S7 with the official synthdid package (protocol_v2.md sections 3-4).
# Run from rice_followup_v2/:  Rscript R/sdid.R
# synthdid is installed from GitHub (synth-inference/synthdid); its only import is mvtnorm.
.libPaths(c("~/R/lib", .libPaths()))
suppressPackageStartupMessages(library(synthdid))
invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))  # keep Korean ids readable in the CSV outputs

d <- read.csv("data/panel_v2.csv", encoding = "UTF-8")
pool <- d[d$cohort != 2011 & d$complete == "True", ]
stopifnot(length(unique(pool$id[pool$treated == 1])) == 18)
dir.create("results", showWarnings = FALSE)

# Y matrix: controls first, then treated; columns 2000..2011.
mat <- function(q, y) {
  q$post_treated <- as.integer(q$treated == 1 & q$year >= 2009)
  panel.matrices(q[, c("id", "year", y, "post_treated")], unit = 1, time = 2, outcome = 3, treatment = 4)
}

SEED <- 20261004
summ <- function(label, outcome, est_name, est, se, method, N1) {
  z <- qnorm(.975); z90 <- qnorm(.95); t <- qt(.975, N1 - 1)
  data.frame(spec = label, outcome = outcome, estimator = est_name, beta = as.numeric(est), se = se,
             se_method = method, p_normal = 2 * pnorm(-abs(as.numeric(est) / se)),
             p_t = 2 * pt(-abs(as.numeric(est) / se), N1 - 1),
             ci95_low = as.numeric(est) - z * se, ci95_high = as.numeric(est) + z * se,
             ci90_low = as.numeric(est) - z90 * se, ci90_high = as.numeric(est) + z90 * se,
             ci95_t_low = as.numeric(est) - t * se, ci95_t_high = as.numeric(est) + t * se)
}
fit_all <- function(label, outcome, est_fun = synthdid_estimate, est_name = "SDID", resampling = TRUE) {
  s <- mat(pool, outcome)
  N1 <- nrow(s$Y) - s$N0
  est <- est_fun(s$Y, s$N0, s$T0)
  out <- summ(label, outcome, est_name, est, sqrt(vcov(est, method = "jackknife"))[1], "jackknife", N1)
  if (resampling) {
    set.seed(SEED); se_p <- sqrt(vcov(est, method = "placebo", replications = 500))[1]
    set.seed(SEED); se_b <- sqrt(vcov(est, method = "bootstrap", replications = 500))[1]
    out <- rbind(out, summ(label, outcome, est_name, est, se_p, "placebo (500)", N1),
                 summ(label, outcome, est_name, est, se_b, "bootstrap (500)", N1))
  }
  out$treated <- N1; out$controls <- s$N0
  list(est = est, setup = s, table = out)
}

primary <- fit_all("PRIMARY full pool", "y_share")
s4 <- fit_all("S4 full pool", "y_rice")
s5 <- fit_all("S5 full pool", "y_paddyuse")
s7sc <- fit_all("S7 full pool", "y_share", sc_estimate, "SC")
s7did <- fit_all("S7 full pool", "y_share", did_estimate, "DiD")
res <- rbind(primary$table, s4$table, s5$table, s7sc$table, s7did$table)
write.csv(res, "results/sdid.csv", row.names = FALSE)

# Weights and per-year effects for the primary fit, holding its weights fixed.
w <- attr(primary$est, "weights"); s <- primary$setup; N0 <- s$N0; T0 <- s$T0
Y <- s$Y; tr <- (N0 + 1):nrow(Y)
gap <- colMeans(Y[tr, , drop = FALSE]) - colSums(w$omega * Y[1:N0, , drop = FALSE])
base <- sum(w$lambda * gap[1:T0])
yearly <- data.frame(year = as.integer(colnames(Y)), gap = gap, effect_vs_weighted_pre = gap - base,
                     time_weight = c(w$lambda, rep(NA, ncol(Y) - T0)))
# Jackknife SE per post year with fixed weights (same scheme as the package's jackknife).
jk_year <- sapply((T0 + 1):ncol(Y), function(tt) {
  n <- nrow(Y)
  u <- sapply(1:n, function(i) {
    keep <- setdiff(1:n, i); c0 <- keep[keep <= N0]; c1 <- keep[keep > N0]
    om <- w$omega[c0] / sum(w$omega[c0])
    g <- colMeans(Y[c1, , drop = FALSE]) - colSums(om * Y[c0, , drop = FALSE])
    g[tt] - sum(w$lambda * g[1:T0])
  })
  sqrt(((n - 1) / n) * (n - 1) * var(u))
})
yearly$jackknife_se <- c(rep(NA, T0), jk_year)
write.csv(yearly, "results/sdid_primary_yearly.csv", row.names = FALSE)
omega <- data.frame(id = rownames(Y)[1:N0], omega = w$omega)
omega <- omega[order(-omega$omega), ]
write.csv(omega, "results/sdid_primary_unit_weights.csv", row.names = FALSE)

# Placebo in time: 2000-2005 pre, 2006-2008 fake post, treated = 2009 cohort.
pre <- pool[pool$year <= 2008, ]
pre$post_treated <- as.integer(pre$treated == 1 & pre$year >= 2006)
sp <- panel.matrices(pre[, c("id", "year", "y_share", "post_treated")], 1, 2, 3, 4)
ep <- synthdid_estimate(sp$Y, sp$N0, sp$T0)
plac <- summ("placebo-in-time 2006-08", "y_share", "SDID", ep, sqrt(vcov(ep, method = "jackknife"))[1], "jackknife", 18)
write.csv(plac, "results/sdid_placebo_in_time.csv", row.names = FALSE)

# Leave one treated unit out (weights re-estimated), influence diagnostic only.
loo <- do.call(rbind, lapply(rownames(Y)[tr], function(u) {
  e <- synthdid_estimate(Y[rownames(Y) != u, ], N0, T0)
  data.frame(dropped = u, beta = as.numeric(e), se_jackknife = sqrt(vcov(e, method = "jackknife"))[1])
}))
write.csv(loo, "results/sdid_primary_leave_one_out.csv", row.names = FALSE)

# Inputs for the independent Python cross-check.
write.csv(data.frame(id = rownames(Y), Y, check.names = FALSE), "results/sdid_primary_Y.csv", row.names = FALSE)
info <- c(N0 = N0, T0 = T0, beta = as.numeric(primary$est), eff_N0 = 1 / sum(w$omega^2),
          eff_T0 = 1 / sum(w$lambda^2), noise = sd(apply(Y[1:N0, 1:T0], 1, diff)),
          zeta_omega = attr(primary$est, "opts")$zeta.omega)
write.csv(data.frame(key = names(info), value = info), "results/sdid_primary_info.csv", row.names = FALSE)
print(res[, c("spec", "outcome", "estimator", "beta", "se", "se_method", "p_normal")])
print(yearly); print(plac); print(head(omega, 10)); print(info)
cat("LOO range:", range(loo$beta), "\n")
