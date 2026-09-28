# =====================================================================
# 02_replicate_main.R
# Independent R replication of the preferred annual-crop estimator
# (brief section 6) and the event-study coefficients (section 7).
# Point estimates: direct formula (did_engine.R::att_direct).
# Comparison target: RESULTS_BUNDLE RAW_SUMMARY / RAW_DYNAMIC (Python).
# Run from the repository root.
# =====================================================================

suppressPackageStartupMessages(library(data.table))
source("R/lib/did_engine.R")

TOL_POINT <- 1e-6      # deterministic point estimates: must agree to 1e-6
P    <- fread("audit/extracted/data/MASTER_PANEL.csv", encoding = "UTF-8")
PS   <- fread("audit/extracted/results/RAW_SUMMARY.csv")
PDYN <- fread("audit/extracted/results/RAW_DYNAMIC.csv")

ANN  <- c("soybean", "onion", "sweet_potato", "corn", "garlic", "spring_potato", "red_pepper")
CTRL <- sort(unique(P[role == "control_pool", crop_id]))
OUTC <- c("ln_area", "ln_yield", "ln_production")

sink("audit/output/02_replicate_main.txt", split = TRUE)
cat("Treated (", length(ANN), "):", ANN, "\nControls (", length(CTRL), "):", CTRL, "\n")
cat("Point-estimate tolerance:", TOL_POINT, "\n\n")

main <- list(); dyn_all <- list(); crop_all <- list()
for (o in OUTC) {
  r <- run_gt(P, o, ANN, CTRL, norm = "A", B = 99999, seed = 20260927)
  py <- PS[sample == "annual" & spec == "CS-A (preferred)" & outcome == o]
  main[[o]] <- data.table(
    outcome = o, R_est = r$overall$est, Py_est = py$est, diff = r$overall$est - py$est,
    R_se_cluster = r$overall$se_cluster, Py_se_cluster = py$se_cluster,
    R_ci_lo = r$overall$ci_lo, Py_ci_lo = py$ci_lo_wild, R_ci_hi = r$overall$ci_hi, Py_ci_hi = py$ci_hi_wild,
    R_p_wild = r$overall$p_wild, Py_p_wild = py$p_wild, R_p_normal = r$overall$p_normal, Py_p_normal = py$p_normal_cluster,
    R_G = r$overall$G, Py_G = py$G, R_pre_k = r$overall$pre_k, Py_pre_k = py$pre_k,
    R_pre_p = r$overall$pre_p_boot, Py_pre_p = py$pre_p_boot, R_pre_mean = r$overall$pre_mean, Py_pre_mean = py$pre_mean,
    weight_vs_direct_gap = r$max_weight_vs_direct_gap)
  pd <- PDYN[sample == "annual" & spec == "CS-A (preferred)" & outcome == o,
             .(event_time = as.integer(event_time), Py_est = est, Py_se = se_cluster, Py_lo = ci_lo_wild,
               Py_hi = ci_hi_wild, Py_p = p_wild, Py_n_tr = n_treated, Py_cmin = n_ctrl_min, Py_cmax = n_ctrl_max,
               Py_G = G_contrib)]
  dd <- merge(r$dynamic, pd, by = "event_time", all = TRUE)
  dd[, outcome := o]
  dyn_all[[o]] <- dd
  cr <- copy(r$crop_att); cr[, outcome := o]; crop_all[[o]] <- cr
}
M <- rbindlist(main)
cat("==== HEADLINE (e = 0..9 average) ====\n")
print(M[, .(outcome, R_est, Py_est, diff, R_se_cluster, Py_se_cluster, R_G, Py_G)], digits = 10)
cat("\nBootstrap quantities (R: 99,999 Webb draws, own RNG; Python: 9,999 draws) -- Monte Carlo agreement only:\n")
print(M[, .(outcome, R_ci_lo, Py_ci_lo, R_ci_hi, Py_ci_hi, R_p_wild, Py_p_wild, R_p_normal, Py_p_normal)], digits = 4)
print(M[, .(outcome, R_pre_k, Py_pre_k, R_pre_p, Py_pre_p, R_pre_mean, Py_pre_mean)], digits = 4)
cat("\nmax |weights x Y - direct formula| :", max(M$weight_vs_direct_gap), "\n")

D <- rbindlist(dyn_all, fill = TRUE)
D[, d_est := est - Py_est]; D[, d_se := se_cluster - Py_se]
cat("\n==== EVENT STUDY (all event times, 3 outcomes) ====\n")
cat("max |R - Py| point estimate:", max(abs(D$d_est), na.rm = TRUE), "\n")
cat("max |R - Py| clustered SE  :", max(abs(D$d_se), na.rm = TRUE), "\n")
cat("event times only in R:", D[is.na(Py_est), .N], " only in Py:", D[is.na(est), .N], "\n")
cat("n_treated mismatches:", D[n_treated != Py_n_tr, .N], "; ctrl min/max mismatches:",
    D[n_ctrl_min != Py_cmin | n_ctrl_max != Py_cmax, .N], "; G mismatches:", D[G_contrib != Py_G, .N], "\n")
print(D[, .(outcome, e = event_time, est = round(est, 4), Py = round(Py_est, 4), se = round(se_cluster, 4),
            lo = round(ci_lo, 3), hi = round(ci_hi, 3), Py_lo = round(Py_lo, 3), Py_hi = round(Py_hi, 3),
            p = round(p_wild, 3), Py_p = round(Py_p, 3), n_tr = n_treated, cmin = n_ctrl_min, cmax = n_ctrl_max, G = G_contrib)])

C <- rbindlist(crop_all)
fwrite(M, "audit/output/02_headline_R_vs_Py.csv")
fwrite(D, "audit/output/02_dynamic_R_vs_Py.csv")
fwrite(C, "audit/output/02_crop_level_att.csv")

# ---- effective control set and contributing clusters
cat("\n==== CONTROL USE ====\n")
used <- unique(unlist(strsplit(C[outcome == "ln_production" & event_time >= 0, ctrl], ";")))
cat("controls ever used post (production):", length(used), "\n  never used:", setdiff(CTRL, used), "\n")
used_any <- unique(unlist(strsplit(C[outcome == "ln_production", ctrl], ";")))
cat("controls or not-yet-treated used at any e:", length(used_any), "; treated crops among them:",
    intersect(used_any, ANN), "\n")
sink()
