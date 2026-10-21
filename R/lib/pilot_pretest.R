# Pilot-aligned event-time contrasts and the joint pre-pilot test (thesis Section 4.3, Appendix A).
# Event time is indexed relative to the pilot year; the reference is the last pre-pilot year (e = -1).
# Each event-time contrast keeps its score-based SE and Webb multiplier interval. The joint test
# compares the sum of squared standardized pre-pilot contrasts with its distribution across the
# same multiplier draws.
pilot_event_study <- function(panel, outcome, treated, controls, pre_events = -10:-2,
                              B = 9999, seed = 1, years = c(1991, 2024), donors = NULL) {
  d   <- prep_cells(panel, outcome, treated, controls, years, pilot_clock = TRUE)
  ev  <- sort(unique(d[is_tr == TRUE, year - g]))
  cr  <- att_direct(d, treated, "A", FALSE, e_post = ev[ev >= 0], e_pre_min = min(ev), donors = donors)
  ag  <- aggregate_att(cr, ev)
  W   <- att_weights(d, cr)
  crops <- sort(unique(d$crop_id))
  set.seed(seed)
  V   <- matrix(sample(WEBB, B * length(crops), replace = TRUE), nrow = B)
  rsd <- fe_residuals(d, setNames(ag$dynamic$est, as.character(ag$dynamic$event_time)))
  rows <- list(); stat <- 0; stat_star <- numeric(B)
  for (e in ag$dynamic$event_time) {
    th  <- ag$dynamic[event_time == e, est]
    inf <- score_inference(th, crop_scores(W[event_time == e], rsd, crops), V)
    rows[[length(rows) + 1]] <- data.table(event_time = e, est = th,
      n_treated = ag$dynamic[event_time == e, n_treated], se = inf$se_cluster,
      ci_lo = inf$ci_lo, ci_hi = inf$ci_hi, p_wild = inf$p_wild)
    if (e %in% pre_events) {
      stat      <- stat + (th / inf$se_cluster)^2
      stat_star <- stat_star + (inf$star / inf$se_cluster)^2
    }
  }
  list(dynamic = rbindlist(rows), crop_att = cr,
       joint = data.table(events = paste(range(pre_events), collapse = ".."), n_events = length(pre_events),
                          stat = stat, p = (sum(stat_star >= stat) + 1) / (B + 1)))
}
