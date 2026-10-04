# Addendum 1 diagnostics D1, D2, D3(d), D4 (protocol_v2_addendum1.md). Descriptive only.
# Run from rice_followup_v2/:  Rscript R/placebo_trace.R
.libPaths(c("~/R/lib", .libPaths()))
suppressPackageStartupMessages(library(synthdid))
invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))

d <- read.csv("data/panel_v2.csv", encoding = "UTF-8")
d$y_farmland <- log(d$farmland)
pool <- d[d$cohort != 2011 & d$complete == "True", ]
dir.create("results/placebo_trace", showWarnings = FALSE)
P <- function(f) file.path("results/placebo_trace", f)

mat <- function(q, y, post_from) {
  q$w <- as.integer(q$treated == 1 & q$year >= post_from)
  panel.matrices(q[, c("id", "year", y, "w")], 1, 2, 3, 4)
}
jk <- function(u) { n <- length(u); sqrt(((n - 1) / n) * (n - 1) * var(u)) }

# ---- Placebo fit: 2000-05 pre, 2006-08 fake post --------------------------------------
pre <- pool[pool$year <= 2008, ]
s <- mat(pre, "y_share", 2006)
ep <- synthdid_estimate(s$Y, s$N0, s$T0)
w <- attr(ep, "weights"); N0 <- s$N0; T0 <- s$T0; Y <- s$Y
tr <- (N0 + 1):nrow(Y); N1 <- length(tr); post <- (T0 + 1):ncol(Y)
write.csv(data.frame(year = colnames(Y)[1:T0], lambda = w$lambda), P("D1_placebo_time_weights.csv"), row.names = FALSE)

# D1: tau = mean_i d_i - c, with d_i = mean post - lambda' pre.
dev <- function(M) rowMeans(M[, post, drop = FALSE]) - as.vector(M[, 1:T0, drop = FALSE] %*% w$lambda)
dev_t <- function(M) M[, post, drop = FALSE] - as.vector(M[, 1:T0, drop = FALSE] %*% w$lambda)
e_co <- dev(Y[1:N0, ]); cc <- sum(w$omega * e_co)
d_tr <- dev(Y[tr, ])
stopifnot(abs(mean(d_tr) - cc - as.numeric(ep)) < 1e-12)
cc_t <- colSums(w$omega * dev_t(Y[1:N0, ]))
unit_tab <- data.frame(id = rownames(Y)[tr], own_placebo = d_tr - cc,
                       contribution = (d_tr - cc) / N1, sweep(dev_t(Y[tr, ]), 2, cc_t))
names(unit_tab)[4:6] <- paste0("own_", colnames(Y)[post])
unit_tab <- unit_tab[order(-unit_tab$own_placebo), ]
write.csv(unit_tab, P("D1_treated_unit_contributions.csv"), row.names = FALSE)
ctrl_tab <- data.frame(id = rownames(Y)[1:N0], omega = w$omega, e = e_co, weighted = w$omega * e_co)
ctrl_tab <- ctrl_tab[order(ctrl_tab$weighted), ]
write.csv(ctrl_tab, P("D1_control_contributions.csv"), row.names = FALSE)

# D2: same fixed weights applied to ln rice and ln farmland (share = rice - farmland).
comp <- sapply(c("y_share", "y_rice", "y_farmland"), function(v) {
  m <- mat(pre, v, 2006); stopifnot(identical(rownames(m$Y), rownames(Y)))
  tau <- c(-w$omega, rep(1 / N1, N1)) %*% m$Y %*% c(-w$lambda, rep(1 / length(post), length(post)))
  u <- sapply(seq_len(nrow(Y)), function(i) {
    k <- setdiff(seq_len(nrow(Y)), i); c0 <- k[k <= N0]; c1 <- k[k > N0]
    om <- w$omega[c0] / sum(w$omega[c0])
    c(-om, rep(1 / length(c1), length(c1))) %*% m$Y[k, ] %*% c(-w$lambda, rep(1 / length(post), length(post)))
  })
  c(tau = as.numeric(tau), jackknife_se = jk(u))
})
comp <- data.frame(outcome = colnames(comp), t(comp))
stopifnot(abs(comp$tau[1] - comp$tau[2] + comp$tau[3]) < 1e-12)
write.csv(comp, P("D2_component_decomposition.csv"), row.names = FALSE)
# Per-unit component split for the treated units.
cs <- lapply(c("y_rice", "y_farmland"), function(v) { m <- mat(pre, v, 2006)$Y; dev(m[tr, ]) - sum(w$omega * dev(m[1:N0, ])) })
unit_comp <- data.frame(id = rownames(Y)[tr], own_share = d_tr - cc, own_rice = cs[[1]], own_farmland = cs[[2]])
write.csv(unit_comp[order(-unit_comp$own_share), ], P("D2_treated_unit_components.csv"), row.names = FALSE)

# ---- D3(d): year-on-year change of the primary gap, primary weights fixed -------------
sp <- mat(pool, "y_share", 2009)
e1 <- synthdid_estimate(sp$Y, sp$N0, sp$T0); w1 <- attr(e1, "weights"); Y1 <- sp$Y; n0 <- sp$N0
gapf <- function(k) {
  c0 <- k[k <= n0]; c1 <- k[k > n0]; om <- w1$omega[c0] / sum(w1$omega[c0])
  colMeans(Y1[c1, , drop = FALSE]) - colSums(om * Y1[c0, , drop = FALSE])
}
g <- gapf(seq_len(nrow(Y1))); dg <- diff(g)
u <- sapply(seq_len(nrow(Y1)), function(i) diff(gapf(setdiff(seq_len(nrow(Y1)), i))))
yoy <- data.frame(year = names(dg), gap_change = dg, jackknife_se = apply(u, 1, jk))
yoy$z <- yoy$gap_change / yoy$jackknife_se
# Same decomposition by component.
for (v in c("y_rice", "y_farmland")) {
  Yv <- mat(pool, v, 2009)$Y; stopifnot(identical(rownames(Yv), rownames(Y1)))
  yoy[[paste0(v, "_change")]] <- diff(colMeans(Yv[(n0 + 1):nrow(Yv), ]) - colSums(w1$omega * Yv[1:n0, ]))
}
write.csv(yoy, P("D3d_gap_year_on_year.csv"), row.names = FALSE)

# ---- D4: Nonsan+Gyeryong sensitivity -------------------------------------------------
fit2 <- function(q, label) {
  a <- mat(q, "y_share", 2009); ea <- synthdid_estimate(a$Y, a$N0, a$T0)
  b <- mat(q[q$year <= 2008, ], "y_share", 2006); eb <- synthdid_estimate(b$Y, b$N0, b$T0)
  rbind(data.frame(sample = label, analysis = "main 2009-11", treated = nrow(a$Y) - a$N0, controls = a$N0,
                   beta = as.numeric(ea), se_jackknife = sqrt(vcov(ea, method = "jackknife"))[1]),
        data.frame(sample = label, analysis = "placebo 2006-08", treated = nrow(b$Y) - b$N0, controls = b$N0,
                   beta = as.numeric(eb), se_jackknife = sqrt(vcov(eb, method = "jackknife"))[1]))
}
d4 <- rbind(fit2(pool, "v2 pool (18/121)"),
            fit2(pool[pool$id != "CN_논산시+계룡시", ], "D4a drop Nonsan+Gyeryong (17/121)"),
            fit2(pool[pool$merged == "False", ], "D4b drop all merged units (17/119)"))
d4$p_normal <- 2 * pnorm(-abs(d4$beta / d4$se_jackknife))
write.csv(d4, P("D4_nonsan_sensitivity.csv"), row.names = FALSE)

print(as.numeric(ep)); print(w$lambda); print(unit_tab, digits = 3); print(head(ctrl_tab, 8), digits = 3)
print(tail(ctrl_tab, 5), digits = 3); print(comp); print(unit_comp, digits = 3); print(yoy, digits = 3); print(d4, digits = 4)
