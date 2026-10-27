########################################################################
## small internal helpers
########################################################################
.rhf_get_int_haz <- function(o) {
  if (!inherits(o, "rhf")) {
    stop("This function only works for objects inheriting from class 'rhf'.")
  }
  ## Native RHF now supplies the integrated hazard exposure directly.
  ## In grow mode this is int.haz.oob; in prediction / test mode it is
  ## int.haz.test.  The importance code always prioritizes int.haz.oob.
  if (!is.null(o$int.haz.oob)) {
    return(list(values = as.numeric(o$int.haz.oob), source = "int.haz.oob"))
  }
  if (!is.null(o$int.haz.test)) {
    return(list(values = as.numeric(o$int.haz.test), source = "int.haz.test"))
  }
  stop("RHF object is missing integrated hazard exposure values. ",
       "Expected 'int.haz.oob' in grow mode or 'int.haz.test' in test mode.")
}
.rhf_get_working_response <- function(o,
                                      y.external = NULL,
                                      eps = 1e-6) {
  eps <- as.numeric(eps)[1L]
  if (!is.finite(eps) || eps < 0) {
    stop("Argument 'eps' must be a finite nonnegative number.")
  }
  if (!is.null(y.external)) {
    return(list(
      y = as.numeric(y.external),
      y.source = "y.external"
    ))
  }
  int.haz.info <- .rhf_get_int_haz(o)
  if (any(int.haz.info$values < 0, na.rm = TRUE)) {
    stop("Integrated hazard exposure values must be nonnegative before log transformation.")
  }
  list(
    y = log(as.numeric(int.haz.info$values) + eps),
    y.source = int.haz.info$source
  )
}
.rhf_get_start_stop <- function(o) {
  if (!inherits(o, "rhf")) {
    stop("This function only works for objects inheriting from class 'rhf'.")
  }
  if (is.null(o$yvar) || !is.data.frame(o$yvar)) {
    stop("RHF object does not contain a valid 'yvar' data.frame.")
  }
  if (ncol(o$yvar) < 2L) {
    stop("RHF object does not appear to contain counting-process start/stop times.")
  }
  start <- as.numeric(o$yvar[[1L]])
  stopv <- as.numeric(o$yvar[[2L]])
  if (length(start) != length(stopv)) {
    stop("Internal error: start/stop vectors have different lengths.")
  }
  if (any(!is.finite(start)) || any(!is.finite(stopv))) {
    stop("Non-finite start/stop values found in the RHF object.")
  }
  if (any(stopv <= start)) {
    stop("Found non-positive length start/stop intervals in the RHF object.")
  }
  list(start = start, stop = stopv)
}
.rhf_get_grid <- function(o) {
  grid <- as.numeric(o$time.interest)
  if (!length(grid)) {
    stop("RHF object has an empty 'time.interest' grid.")
  }
  if (any(!is.finite(grid))) {
    stop("Non-finite values found in 'time.interest'.")
  }
  if (is.unsorted(grid, strictly = TRUE)) {
    stop("'time.interest' must be strictly increasing.")
  }
  grid
}
.rhf_format_time_names <- function(x) {
  out <- format(as.numeric(x), trim = TRUE, scientific = FALSE)
  bad <- !nzchar(out) | is.na(out)
  if (any(bad)) {
    out[bad] <- as.character(x[bad])
  }
  out
}
.rhf_format_time_labels <- function(x, digits = 2) {
  x <- suppressWarnings(as.numeric(x))
  out <- as.character(x)
  ok <- is.finite(x)
  if (any(ok)) {
    tmp <- formatC(x[ok], format = "f", digits = digits)
    tmp <- sub("\\.?0+$", "", tmp)
    out[ok] <- paste0("t=", tmp)
  }
  out
}
.rhf_format_elapsed <- function(seconds) {
  seconds <- as.numeric(seconds)[1L]
  if (!is.finite(seconds) || seconds < 0) {
    return("NA")
  }
  if (seconds < 60) {
    return(sprintf("%.1fs", seconds))
  }
  minutes <- floor(seconds / 60)
  secs <- round(seconds - 60 * minutes)
  if (minutes < 60) {
    return(sprintf("%dm %02ds", minutes, secs))
  }
  hours <- floor(minutes / 60)
  minutes <- minutes - 60 * hours
  sprintf("%dh %02dm %02ds", hours, minutes, secs)
}
.rhf_validate_cache <- function(o, cache) {
  if (!inherits(cache, "varpro.cache.rhf")) {
    stop("Argument 'cache' must be NULL or an object returned by varpro.cache.rhf().")
  }
  ss <- .rhf_get_start_stop(o)
  grid <- .rhf_get_grid(o)
  if (length(ss$start) != cache$n.pseudo) {
    stop("The supplied cache does not match the RHF object: pseudo-individual count differs.")
  }
  ## A guided cache holds rules from the internal guided rule forest,
  ## whose predictors are the retained subset of o$xvar.names.
  if (isTRUE(cache$guided)) {
    if (!all(as.character(cache$xvar.names) %in% as.character(o$xvar.names))) {
      stop("The supplied guided cache does not match the RHF object: xvar.names differ.")
    }
  }
  else {
    if (length(o$xvar.names) != length(cache$xvar.names) ||
        any(as.character(o$xvar.names) != as.character(cache$xvar.names))) {
      stop("The supplied cache does not match the RHF object: xvar.names differ.")
    }
  }
  ## the guided rule forest receives o$time.interest as user-supplied time
  ## points and returns them through the internal time map, so compare the
  ## grids with a tolerance rather than exactly
  if (length(grid) != length(cache$grid) ||
      !isTRUE(all.equal(as.numeric(grid), as.numeric(cache$grid), tolerance = 1e-8))) {
    stop("The supplied cache does not match the RHF object: time.interest differs.")
  }
  invisible(TRUE)
}
.rhf_nonmissing_mean <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) {
    NA_real_
  } else {
    mean(x)
  }
}
.rhf_nonmissing_max <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) {
    NA_real_
  } else {
    max(x)
  }
}
