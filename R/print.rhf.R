print.rhf <- function(x, digits = 3, label.width = 34, ...) {
  ## ---- Class / mode -------------------------------------------------------
  is_rhf     <- inherits(x, "rhf")
  is_grow    <- "grow" %in% class(x)
  is_predict <- any(c("predict", "predict.rhf") %in% class(x))
  if (!(is_rhf && (is_grow || is_predict))) {
    print.default(x)
    return()
  }
  has_test  <- is_predict && !is.null(x$risk.test)
  is_restore <- is_predict && !has_test
  ## ---- Helpers ------------------------------------------------------------
  .lab <- function(label) sprintf("%*s: ", label.width, label)
  .fmt <- function(label, value) paste0(.lab(label), value)
  .is_num1 <- function(v) is.numeric(v) && length(v) == 1 && is.finite(v)
  fnum <- function(v) if (.is_num1(v)) format(round(v, digits), scientific = FALSE, trim = TRUE) else "NA"
  fint <- function(v) if (.is_num1(v)) format(as.integer(round(v)), big.mark = ",", trim = TRUE) else "NA"
  ## ---- Identify yvar indices (id/status if available) ---------------------
  status_idx <- NA_integer_
  id_idx     <- NA_integer_
  if (!is.null(x$yvar.names)) {
    id_idx     <- match("id",     x$yvar.names, nomatch = NA_integer_)
    status_idx <- match("status", x$yvar.names, nomatch = NA_integer_)
  } else if (!is.null(colnames(x$yvar))) {
    id_idx     <- match("id",     colnames(x$yvar), nomatch = NA_integer_)
    status_idx <- match("status", colnames(x$yvar), nomatch = NA_integer_)
  }
  if (is.na(status_idx) && !is.null(x$yvar) && NCOL(x$yvar) >= 3) status_idx <- 3
  ## ---- Counts: grow/restore vs predict-with-test --------------------------
  n_records <- NA_real_
  n_ids     <- NA_real_
  rec_per   <- NA_real_
  if (is_grow || is_restore) {
    ## Training domain
    n_records <- if (!is.null(x$n)) as.integer(x$n) else if (!is.null(x$yvar)) NROW(x$yvar) else NA_integer_
    n_ids <- if (!is.null(x$id)) length(unique(x$id))
             else if (!is.null(x$yvar) && !is.na(id_idx) && id_idx <= NCOL(x$yvar))
               length(unique(x$yvar[, id_idx])) else NA_integer_
    rec_per <- if (.is_num1(n_records) && .is_num1(n_ids) && n_ids > 0) n_records / n_ids else NA_real_
  } else {
    ## Predict with test data
    ## Cases (prefer xvar rows; yvar rows may be CP or condensed; n may be training n)
    n_cases <- if (!is.null(x$xvar)) NROW(x$xvar)
               else if (!is.null(x$id)) length(unique(x$id))
               else if (!is.null(x$yvar)) NROW(x$yvar)
               else if (!is.null(x$n)) as.integer(x$n) else NA_integer_
    ## Unique IDs for test
    n_ids <- if (!is.null(x$id) && length(x$id) == n_cases) length(unique(x$id))
             else if (!is.null(x$yvar) && !is.na(id_idx) && id_idx <= NCOL(x$yvar))
               length(unique(x$yvar[, id_idx]))
             else n_cases
    ## Records: if yvar carries CP rows and is >= ids, use it; otherwise fall back to cases
    if (!is.null(x$yvar)) {
      nr <- NROW(x$yvar)
      n_records <- if (.is_num1(nr) && .is_num1(n_ids) && nr >= n_ids) nr else n_cases
    } else {
      n_records <- n_cases
    }
    ## Note: rec_per from test rows can be misleading (many predict objects don't carry CP rows),
    ## so we intentionally do NOT print average records/case for predict-with-test.
  }
  ## ---- Deaths/events (available if yvar has status) -----------------------
  n_deaths <- if (!is.null(x$yvar) && !is.na(status_idx)) sum(x$yvar[, status_idx], na.rm = TRUE) else NA_integer_
  ## ---- Forest stats (always present) --------------------------------------
  avg_tree_size <- if (!is.null(x$forest$leafCount)) mean(as.numeric(x$forest$leafCount), na.rm = TRUE) else NA_real_
  nodeSZ <- NA_real_
  na_arr <- x$forest$nativeArray
  if (!is.null(na_arr) && all(c("brnodeID", "nodeSZ", "treeID") %in% names(na_arr))) {
    arr0 <- na_arr[!is.na(na_arr$brnodeID) & na_arr$brnodeID == 0, , drop = FALSE]
    if (NROW(arr0)) nodeSZ <- mean(tapply(arr0$nodeSZ, arr0$treeID, mean, na.rm = TRUE), na.rm = TRUE)
  }
  ## ---- Time-varying features & TDC line ----------------------------------
  n_tdc <- if (!is.null(x$xvar.time)) sum(x$xvar.time > 0, na.rm = TRUE)
           else if (!is.null(x$forest$xvar.time)) sum(x$forest$xvar.time > 0, na.rm = TRUE)
           else NA_integer_
  fam <- if (!is.null(x$family)) tolower(as.character(x$family)) else ""
  is_tdc_family <- grepl("tdc", fam)
  if (is_grow || is_restore) {
    tdc_note <- if (!isTRUE(rec_per > 1)) {
      "NO (records per ID = 1)"
    } else if (!isTRUE(n_tdc > 0)) {
      "NO (0 time-varying features)"
    } else "YES"
  } else {
    ## predict-with-test: CP rows may not be present; base on model + features
    if (!isTRUE(is_tdc_family)) {
      tdc_note <- "NO (family is not TDC)"
    } else if (!isTRUE(n_tdc > 0)) {
      tdc_note <- "NO (0 time-varying features)"
    } else {
      tdc_note <- "YES"
    }
  }
  ## ---- Risk vectors / ordering -------------------------------------------
  risks <- list(
    "In-bag" = if (!is.null(x$risk.inbag)) x$risk.inbag[is.finite(x$risk.inbag)] else NULL,
    "OOB"    = if (!is.null(x$risk.oob))   x$risk.oob[is.finite(x$risk.oob)]     else NULL,
    "Test"   = if (!is.null(x$risk.test))  x$risk.test[is.finite(x$risk.test)]   else NULL
  )
  rmean <- function(v) if (!is.null(v) && length(v)) mean(v, na.rm = TRUE) else NA_real_
  ## ---- Print --------------------------------------------------------------
  out <- c(
    .fmt("Number of records", fint(n_records)),
    .fmt("Sample size (unique IDs)", fint(n_ids))
  )
  if (is_grow || is_restore) {
    out <- c(out, .fmt("Average records per ID",
                       fnum(if (.is_num1(n_records) && .is_num1(n_ids) && n_ids > 0) n_records / n_ids else NA_real_)))
  }
  if (!is.na(n_deaths)) out <- c(out, .fmt("Number of deaths/events", fint(n_deaths)))
  if (!is.null(x$sampsize))  out <- c(out, .fmt("Tree sample size", paste(x$sampsize, collapse = ", ")))
  if (!is.null(x$ntree))     out <- c(out, .fmt("Number of trees",  fint(x$ntree)))
  out <- c(out,
           .fmt("Average tree size (leaves)", fnum(avg_tree_size)),
           .fmt("Average node size",          fnum(nodeSZ)))
  if (!is.null(x$forest$parms) && !is.null(x$forest$parms$mtry)) {
    out <- c(out, .fmt("No. features tried at each split", fint(x$forest$parms$mtry)))
  }
  out <- c(out, .fmt("Total no. time-varying features", if (!is.na(n_tdc)) fint(n_tdc) else "NA"))
  if (!is.null(x$forest$parms) && !is.null(x$forest$parms$xvar.wt)) {
    out <- c(out, .fmt("Total no. features", fint(length(x$forest$parms$xvar.wt))))
  }
  if (!is.null(x$family))    out <- c(out, .fmt("Family",    as.character(x$family)))
  if (!is.null(x$splitrule)) {
    splitrule <- as.character(x$splitrule)
    if (!is.null(x$forest$parms) &&
        .is_num1(x$forest$parms$nsplit) &&
        x$forest$parms$nsplit > 0) {
      splitrule <- paste(splitrule, "*random*")
    }
    out <- c(out, .fmt("Splitrule", splitrule))
  }
  if (!is.null(x$forest$parms) && !is.null(x$forest$parms$nsplit)) {
    out <- c(out, .fmt("No. of random splits", fint(x$forest$parms$nsplit)))
  }
  ## Risk lines
  if (is_grow || is_restore) {
    oob_lbl <- if (is_restore) "OOB (restore)" else "OOB"
    if (!is.null(risks[["OOB"]])) {
      out <- c(out, .fmt(paste0(oob_lbl, " risk"), fnum(rmean(risks[["OOB"]]))))
    }
    if (is_restore) out <- c(out, .fmt("Predict restore mode", "YES (using original forest)"))
  } else {
    if (!is.null(risks[["Test"]])) {
      out <- c(out, .fmt("Test risk", fnum(rmean(risks[["Test"]]))))
    }
    if (!is.null(risks[["OOB"]])) {
      out <- c(out, .fmt("OOB risk",  fnum(rmean(risks[["OOB"]]))))
    }
  }
  out <- c(out, .fmt("TDC analysis", tdc_note))
  message(paste(out, collapse = "\n"))
  invisible(x)
}
