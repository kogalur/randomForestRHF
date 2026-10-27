########################################################################
## print and coercion helpers
########################################################################
print.importance.rhf <- function(x,
                                 top = 10L,
                                 rank.by = c("q90", "median", "mean", "max"),
                                 digits = 4L,
                                 scientific.threshold = 1e4,
                                 ...) {
  rank.by <- match.arg(rank.by)
  top <- as.integer(top)[1L]
  if (!is.finite(top) || top < 1L) {
    stop("'top' must be a positive integer.")
  }
  header <- c(
    "",
    "RHF time-localized VarPro importance",
    paste0("  windows:   ", ncol(x$importance.matrix)),
    paste0("  variables: ", nrow(x$importance.matrix)),
    paste0("  ranking:   ", rank.by)
  )
  if (isTRUE(x$guided)) {
    header <- c(header,
                paste0("  guided:    ", length(x$xvar.selected), " of ",
                       length(x$xvar.names.all),
                       " variables retained for rule generation"))
  }
  else if (identical(x$guided.status, "screening failed")) {
    header <- c(header,
                "  guided:    requested, but no screen retained a variable; rules are unguided")
  }
  else {
    ## unguided: with many variables the guided importance is much sparser
    p.all <- if (length(x$xvar.names.all)) length(x$xvar.names.all) else nrow(x$importance.matrix)
    if (isTRUE(p.all >= 50L)) {
      header <- c(header,
                  paste0("  note:      ", p.all, " variables; guided = TRUE gives a sparser importance (see ?importance.rhf)"))
    }
  }
  if (!is.null(x$y.source) && nzchar(x$y.source)) {
    header <- c(header, paste0("  y.source:  ", x$y.source))
  }
  header <- c(
    header,
    "  matrix:    imp.t$importance.matrix (variables x time)",
    "  long:      imp.t$importance.long",
    ""
  )
  message(paste(header, collapse = "\n"))
  score.q90 <- .rhf_row_summary(x$importance.matrix, rank.by = "q90")
  score.median <- .rhf_row_summary(x$importance.matrix, rank.by = "median")
  score.mean <- .rhf_row_summary(x$importance.matrix, rank.by = "mean")
  score.max <- .rhf_row_summary(x$importance.matrix, rank.by = "max")
  score.rank <- switch(rank.by,
                       q90 = score.q90,
                       median = score.median,
                       mean = score.mean,
                       max = score.max)
  ord <- order(score.rank, decreasing = TRUE, na.last = TRUE)
  top.show <- head(ord, min(top, length(ord)))
  if (length(top.show)) {
    tab <- data.frame(
      variable = rownames(x$importance.matrix)[top.show],
      q90.importance = .rhf_format_importance_numbers(score.q90[top.show],
                                                      digits = digits,
                                                      scientific.threshold = scientific.threshold),
      median.importance = .rhf_format_importance_numbers(score.median[top.show],
                                                         digits = digits,
                                                         scientific.threshold = scientific.threshold),
      mean.importance = .rhf_format_importance_numbers(score.mean[top.show],
                                                       digits = digits,
                                                       scientific.threshold = scientific.threshold),
      max.importance = .rhf_format_importance_numbers(score.max[top.show],
                                                      digits = digits,
                                                      scientific.threshold = scientific.threshold),
      stringsAsFactors = FALSE,
      row.names = NULL,
      check.names = FALSE
    )
    print(tab, row.names = FALSE, right = TRUE)
  }
  invisible(x)
}
as.data.frame.importance.rhf <- function(x,
                                         row.names = NULL,
                                         optional = FALSE,
                                         format = c("long", "variable_by_time", "time_by_variable"),
                                         ...) {
  format <- match.arg(format)
  if (format == "long") {
    return(x$importance.long)
  }
  if (format == "variable_by_time") {
    out <- as.data.frame(x$importance.matrix,
                         stringsAsFactors = FALSE,
                         check.names = FALSE)
    out$variable <- rownames(x$importance.matrix)
    out <- out[, c("variable", colnames(x$importance.matrix)), drop = FALSE]
    rownames(out) <- NULL
    return(out)
  }
  out <- as.data.frame(t(x$importance.matrix),
                       stringsAsFactors = FALSE,
                       check.names = FALSE)
  out$time <- x$window.info$time
  out$window <- x$window.info$label
  out <- out[, c("time", "window", rownames(x$importance.matrix)), drop = FALSE]
  rownames(out) <- NULL
  out
}
