# Protocol v3 implementation check: null-imposed Webb WCR bootstrap-t with the official
# fwildclusterboot::boottest on the same TWFE (estimator A). Different RNG, so agreement is
# judged within Monte Carlo error. Run from rice_followup_v2/:  Rscript R/v3_wcr_check.R
.libPaths(c("~/R/lib", .libPaths()))
suppressPackageStartupMessages({ library(fwildclusterboot); library(jsonlite) })
invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))
d <- read.csv("data/panel_v2.csv", encoding = "UTF-8")
q <- d[d$cohort %in% c(2009, 2011) & d$complete == "True" & d$merged == "False" & d$year <= 2010, ]
stopifnot(length(unique(q$id)) == 26, nrow(q) == 286)
q$D <- as.numeric(q$cohort == 2009 & q$year >= 2009)
q$id <- factor(q$id); q$year <- factor(q$year)
fit <- lm(y_rice ~ D + id + year, data = q)
dqrng::dqset.seed(20261004); set.seed(20261004)
bt <- boottest(fit, param = "D", clustid = "id", B = 9999, type = "webb", impose_null = TRUE,
               p_val_type = "two-tailed", conf_int = TRUE, sign_level = 0.05)
py <- fromJSON("results/v3/primary.json")
mc_se <- sqrt(py$p_wcr_bootstrap * (1 - py$p_wcr_bootstrap) / 9999)
out <- data.frame(quantity = c("beta", "t_stat", "p_wcr", "ci95_low", "ci95_high"),
                  python = c(py$beta, py$beta / py$se_cr1, py$p_wcr_bootstrap, py$ci95_wcr_low, py$ci95_wcr_high),
                  fwildclusterboot = c(coef(fit)["D"], bt$t_stat, bt$p_val, bt$conf_int[1], bt$conf_int[2]))
out$diff <- out$python - out$fwildclusterboot
out$p_mc_se <- c(NA, NA, mc_se, NA, NA)
write.csv(out, "results/v3/wcr_check_fwildclusterboot.csv", row.names = FALSE)
print(out); print(summary(bt))
cat("fwildclusterboot", as.character(packageVersion("fwildclusterboot")), "\n")
