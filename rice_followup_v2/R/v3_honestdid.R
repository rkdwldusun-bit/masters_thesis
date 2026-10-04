# Protocol v3 supplementary (d): HonestDiD relative-magnitude sensitivity for the 17-vs-9
# event study (2008 reference, CR1 covariance), target = mean of 2009 and 2010 effects.
# Run from rice_followup_v2/ after python/v3_estimate.py:  Rscript R/v3_honestdid.R
.libPaths(c("~/R/lib", .libPaths()))
suppressPackageStartupMessages(library(HonestDiD))
ev <- read.csv("results/v3/event_study.csv")
V <- as.matrix(read.csv("results/v3/event_study_vcov_cr1.csv", row.names = 1, check.names = FALSE))
stopifnot(identical(as.character(ev$year), rownames(V)), identical(as.character(ev$year), colnames(V)),
          identical(ev$year, c(2000:2007, 2009:2010)))
orig <- constructOriginalCS(betahat = ev$beta, sigma = V, numPrePeriods = 8, numPostPeriods = 2,
                            l_vec = c(.5, .5), alpha = .05)
rm <- createSensitivityResults_relativeMagnitudes(betahat = ev$beta, sigma = V, numPrePeriods = 8,
        numPostPeriods = 2, l_vec = c(.5, .5), Mbarvec = c(0, .5, 1, 1.5, 2), alpha = .05)
res <- rbind(data.frame(lb = orig$lb, ub = orig$ub, method = orig$method, Delta = NA, Mbar = NA),
             data.frame(lb = rm$lb, ub = rm$ub, method = rm$method, Delta = rm$Delta, Mbar = rm$Mbar))
res$target <- mean(ev$beta[ev$year %in% c(2009, 2010)])
write.csv(res, "results/v3/honestdid_relative_magnitudes.csv", row.names = FALSE)
print(res)
cat("HonestDiD", as.character(packageVersion("HonestDiD")), "\n")
