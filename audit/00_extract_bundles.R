# =====================================================================
# 00_extract_bundles.R
# Extract every sheet of DATA_BUNDLE.xlsx and RESULTS_BUNDLE.xlsx to CSV.
# Provenance note rows above the header are removed; nothing else changes.
# =====================================================================

# Run from the repository root:  Rscript audit/00_extract_bundles.R

library(readxl)

STALE <- c("EVENT_SUPPORT", "COHORT_SUPPORT", "CONTROL_COMP", "EVENT_SUPPORT_RAW", "COHORT_SUPPORT_RAW", "CONTROL_COMP_RAW")

find_header <- function(raw) {
  # header = first row, among the first 6, with the maximum number of non-empty cells
  n <- min(6, nrow(raw))
  nn <- vapply(seq_len(n), function(r) sum(!is.na(unlist(raw[r, ]))), 0)
  which(nn == max(nn))[1]
}

extract <- function(xlsx, outdir) {
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
  log <- data.frame()
  for (sh in excel_sheets(xlsx)) {
    raw <- read_excel(xlsx, sheet = sh, col_names = FALSE, col_types = "text", .name_repair = "minimal")
    h <- find_header(raw)
    hdr <- as.character(unlist(raw[h, ]))
    hdr[is.na(hdr)] <- paste0("V", which(is.na(hdr)))
    # strip byte-order mark carried over from source CSVs (also its latin-1 mis-decoding)
    hdr <- sub("^(﻿|ï»¿)", "", hdr)
    body <- raw[-seq_len(h), , drop = FALSE]
    names(body) <- hdr
    body <- body[rowSums(!is.na(body)) > 0, , drop = FALSE]
    note <- if (h > 1) paste(na.omit(unlist(raw[seq_len(h - 1), 1])), collapse = " ") else ""
    # stale diagnostics from an earlier pipeline (obsolete crop IDs, 20-crop pool): quarantined, never used
    dest <- if (sh %in% STALE) file.path(outdir, "stale_do_not_use") else outdir
    dir.create(dest, showWarnings = FALSE)
    write.csv(body, file.path(dest, paste0(sh, ".csv")), row.names = FALSE, na = "", fileEncoding = "UTF-8")
    log <- rbind(log, data.frame(sheet = sh, header_row = h, rows = nrow(body), cols = ncol(body), note = note))
  }
  write.csv(log, file.path(outdir, "_sheet_log.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  log
}

print(extract("input/DATA_BUNDLE.xlsx", "audit/extracted/data"))
print(extract("input/RESULTS_BUNDLE.xlsx", "audit/extracted/results"))
