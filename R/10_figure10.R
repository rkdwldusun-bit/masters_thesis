# [Figure 10] Financing of net premiums by payer
# Reads verified_results/verified_apfs_national.csv; no estimation here.
# 2010-2011: the reported components do not sum to the net premium. The gap is
# drawn as an unfilled segment and labelled as unexplained; it is NOT assigned to any payer.

source("R/00_theme_thesis.R")

N <- fread(file.path(VERIFIED, "verified_apfs_national.csv"))
d <- melt(N[, .(year, `Central government` = central_gov_mkrw, Provinces = provincial_mkrw,
                Municipalities = municipal_mkrw, Farmers = farmer_mkrw, net_premium_mkrw)],
          id.vars = c("year", "net_premium_mkrw"), variable.name = "payer", value.name = "mkrw")
d[, share := mkrw / net_premium_mkrw]
res <- N[, .(year, payer = "Not explained by the public dataset", share = 1 - components_share_of_net_premium)][share > 1e-3]
d <- rbind(d[, .(year, payer = as.character(payer), share)], res)
lv <- c("Central government", "Provinces", "Municipalities", "Farmers", "Not explained by the public dataset")
d[, payer := factor(payer, levels = lv)]
gap_years <- res$year

p <- ggplot(d, aes(x = year, y = share, fill = payer, colour = payer)) +
  geom_col(width = 0.55, position = position_stack(reverse = TRUE), linewidth = 0.4) +
  scale_fill_manual(values = c(COL[["main"]], COL[["set2_3"]], COL[["set2_4"]], COL[["set2_2"]], "white")) +
  scale_colour_manual(values = c(rep("transparent", 4), "grey40")) +
  scale_x_continuous(breaks = seq(2001, 2024, by = 2)) +
  scale_y_continuous(labels = function(x) paste0(round(100 * x), "%"), expand = expansion(mult = c(0, 0.03))) +
  guides(fill = guide_legend(nrow = 2), colour = guide_legend(nrow = 2)) +
  labs(x = "Year", y = "Share of net premium",
       title = fig_title("fig10", "Financing of Net Premiums by Payer, 2001–2024"),
       caption = wrap(paste(
         sprintf("Note: APFS public national series. In %s the reported components sum to %s of the net premium, and the",
                 paste(gap_years, collapse = " and "),
                 paste(sprintf("%.1f%%", 100 * N[year %in% gap_years, components_share_of_net_premium]), collapse = " and ")),
         "provincial and municipal subsidy fields are recorded as zero. The public dataset does not explain the residual (unfilled",
         "segment); it is not attributed to any payer. Descriptive only.",
         "Source: Korea Agricultural Policy Insurance & Finance Service (APFS), public data; author's calculations."), 108)) +
  theme_thesis()

save_thesis_fig(p, "fig10", "fig10_apfs_financing_shares", height = 6.2, data = d)
