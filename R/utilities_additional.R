get.adaptive <- function(adaptive) {
  if (!is.logical(adaptive) ||
      length(adaptive) != 1L ||
      is.na(adaptive)) {
    stop("adaptive must be TRUE or FALSE.", call. = FALSE)
  }
  adaptive
}
get.block.size.bits <- function (block.size, ntree) {
    ## Check for user silliness.
    if (!is.null(block.size)) {
        if ((block.size < 1) || (block.size > ntree)) {
            block.size <- ntree
        }
        else {
            block.size <- round(block.size)
        }
    }
    else {
        block.size <- ntree
    }
    return (block.size)
}
get.bootstrap.bits <- function (bootstrap) {
  if (bootstrap == "none") {
    bootstrap <- 0
  }
  else if (bootstrap == "by.root") {
    bootstrap <- 2^19
  }
  else if (bootstrap == "by.user") {
    bootstrap <- 2^20
  }
  else {
    stop("Invalid choice for 'bootstrap' option:  ", bootstrap)
  }
  return (bootstrap)
}
get.coe.trim <- function(coe.trim) {
  ## Retain the complete experimental trim vector in hazard.config.
  if (!is.numeric(coe.trim) || length(coe.trim) < 1L) {
    stop(
      "coe.trim must be a non-empty numeric vector with values in [0, 0.5]."
    )
  }
  coe.trim <- as.double(coe.trim)
  if (anyNA(coe.trim) ||
      any(!is.finite(coe.trim)) ||
      any(coe.trim < 0.0 | coe.trim > 0.5)) {
    stop(
      "coe.trim must be a non-empty numeric vector with values in [0, 0.5]."
    )
  }
  coe.trim
}
get.data.pass.bits <- function (data.pass) {
  if (!is.null(data.pass)) {
    if (data.pass == TRUE) {
      data.pass <- 2^15
    }
    else if (data.pass == FALSE) {
      data.pass <- 0
    }
    else {
      stop("Invalid choice for 'data.pass' option:  ", data.pass)
    }
  }
  else {
    stop("Invalid choice for 'data.pass' option:  ", data.pass)
  }
  return (data.pass)
}
get.empirical.risk.bits <-  function (empirical.risk) {
  if (empirical.risk) {
    return (2^18)
  }
  else {
    return (0)
  }
}
## convert ensemble option into native code parameter.
get.ensemble.bits <- function (ensemble) {
  if (ensemble == "oob") {
    ensemble <- 2^1
  }
  else if (ensemble == "inbag") {
    ensemble <- 2^0
  }
  else if (ensemble == "all") {
    ensemble <- 2^0 + 2^1
  }    
  else {
      ## For testing purposes, we allow the ensemble to be omitted altogether.
      ensemble <- 0
  }
  return (ensemble)
}
get.experimental.bits  <- function(experimental.bits, trace,
                                    hazard.estimator = c("NA", "COE"),
                                    coe.aggregate = c("trimmed.mean", "median", "mean")) {
  ## New protocol is to use the uniform hazard estimator. This is
  ## UBK's version of the hazard. It avoids the issue of having OOB
  ## unscaled risk inf values, that we experienced due to log(0) where
  ## the column (corresponding to a time interest point) is zero for
  ## the OOB subject.
  hazard.estimator <- match.arg(hazard.estimator)
  coe.aggregate <- match.arg(coe.aggregate)
  if (!is.null(experimental.bits)) {
    if (length(experimental.bits) != 1L || is.na(experimental.bits)) {
      stop("bits must be between 0 and 255.")
    }
    else if (experimental.bits < 0L) {
      stop("bits must be between 0 and 255.")
    }
    else if (experimental.bits > 255L) {
      stop("bits must be between 0 and 255.")
    }
    else if (experimental.bits == 0) {
        ## This is for RSF, no frills.
        experimental.bits <- 0
    }
    else if (is.bit(experimental.bits, 0) && is.bit(experimental.bits, 1)) {
        stop(paste(paste0("Endpoint Estimation:  ", is.bit(experimental.bits, 0), "\n"),
                   paste0("Uniform Estimation:   ", is.bit(experimental.bits, 1), "\n"),
                   paste0("only one protocol bit allowed."),
                   sep = "\n"))
    }
  }
  else {
    ## Default is UBK's rule when null.
    experimental.bits <- 2^1
  }
  ## Bits 4, 5, and 6 belong to the hidden COE aggregation controls.  Clear
  ## any manual settings and then set exactly one aggregation bit when COE is
  ## requested.
  experimental.bits <- bitwAnd(as.integer(experimental.bits), 255L - (2^4 + 2^5 + 2^6))
  coe.bits <- 0L
  if (hazard.estimator == "COE") {
    coe.bits <- switch(coe.aggregate,                       
                       median = 2^4,                       
                       trimmed.mean = 2^5,
                       mean = 2^6)
  }
  experimental.bits <- bitwOr(as.integer(experimental.bits), as.integer(coe.bits))
  if (isTRUE(trace)) {
      message(
          paste(
              paste0("Endpoint Estimation:  ", is.bit(experimental.bits, 0)),
              paste0("Uniform Estimation:   ", is.bit(experimental.bits, 1)),
              paste0("Uniform Head:         ", is.bit(experimental.bits, 2)),
              paste0("Uniform Tail:         ", is.bit(experimental.bits, 3)),
              sep = "\n"
          )
      )
      message(
          paste(
              paste0("COE Median Aggregate:  ", is.bit(experimental.bits, 4)),
              paste0("COE Winsor Aggregate:  ", is.bit(experimental.bits, 5)),
              paste0("COE Mean Aggregate:    ", is.bit(experimental.bits, 6)),
              sep = "\n"
          )
      )
  }
  return (experimental.bits)
}
get.forest.bits <- function (forest) {
  ## Convert forest option into native code parameter.
  if (!is.null(forest)) {
    if (forest == TRUE) {
      forest <- 2^5
    }
    else if (forest == FALSE) {
      forest <- 0
    }
    else {
      stop("Invalid choice for 'forest' option:  ", forest)
    }
  }
  else {
    stop("Invalid choice for 'forest' option:  ", forest)
  }
  return (forest)
}
.update.coe.trim.selection <- function(hazard.config, native.output) {
  if (!is.list(hazard.config)) {
    stop("hazard.config must be a list.", call. = FALSE)
  }
  trim <- get.coe.trim(hazard.config$coe.trim)
  ## coe.trim has no effect for median or arithmetic-mean aggregation.  Keep a
  ## deterministic first-candidate marker and do not retain an OOB search curve.
  if (!identical(hazard.config$hazard.estimator, "COE") ||
      !identical(hazard.config$coe.aggregate, "trimmed.mean")) {
    hazard.config$coe.trim.index <- 1L
    hazard.config$coe.trim.selected <- trim[[1L]]
    hazard.config$coe.aggregate.selected <- hazard.config$coe.aggregate
    hazard.config$coe.trim.risk.oob <- NULL
    return(hazard.config)
  }
  native.index <- native.output$coeTrimIndex
  if (!is.null(native.index)) {
    native.index <- as.integer(native.index)[1L]
    ## Index zero is the native median-fallback sentinel.  Positive indices are
    ## one-based positions in the retained coe.trim candidate vector.
    if (is.na(native.index) || native.index < 0L ||
        native.index > length(trim)) {
      stop("Invalid native coe.trim selection index.", call. = FALSE)
    }
    hazard.config$coe.trim.index <- native.index
  }
  selected.index <- as.integer(hazard.config$coe.trim.index)[1L]
  if (is.na(selected.index) ||
      selected.index < 0L || selected.index > length(trim)) {
    selected.index <- 1L
  }
  hazard.config$coe.trim.index <- selected.index
  if (selected.index == 0L) {
    hazard.config$coe.trim.selected <- NA_real_
    hazard.config$coe.aggregate.selected <- "median"
  }
  else {
    hazard.config$coe.trim.selected <- trim[[selected.index]]
    hazard.config$coe.aggregate.selected <- hazard.config$coe.aggregate
  }
  native.risk <- native.output$coeTrimRiskOOB
  if (!is.null(native.risk)) {
    native.risk <- as.double(native.risk)
    if (length(native.risk) != length(trim)) {
      stop("Invalid native coe.trim OOB-risk vector length.", call. = FALSE)
    }
    hazard.config$coe.trim.risk.oob <- native.risk
  }
  else if (!is.null(hazard.config$coe.trim.risk.oob)) {
    inherited.risk <- as.double(hazard.config$coe.trim.risk.oob)
    hazard.config$coe.trim.risk.oob <- if (length(inherited.risk) == length(trim)) {
      inherited.risk
    }
    else {
      NULL
    }
  }
  hazard.config
}
get.hazard.options <- function(dots, hazard.config = NULL, adaptive = TRUE) {
  if (!is.list(dots)) {
    stop("`dots` must be a list.", call. = FALSE)
  }
  if (!is.null(hazard.config) && !is.list(hazard.config)) {
    stop("`hazard.config` must be a list or NULL.", call. = FALSE)
  }
  adaptive <- get.adaptive(adaptive)
  hazard.option.names <- c(
    "hazard.estimator",
    "coe.aggregate",
    "coe.trim"
  )
  inherited.config <- hazard.config
  hazard.estimator.choices <- c("COE", "NA")
  coe.aggregate.choices <- c("trimmed.mean", "median", "mean")
  ## Duplicate hidden options are ambiguous and would otherwise be forwarded
  ## more than once to the workhorse function.
  dot.names <- names(dots)
  if (!is.null(dot.names)) {
    supplied.hazard.options <- dot.names[dot.names %in% hazard.option.names]
    duplicated.hazard.options <- unique(
      supplied.hazard.options[duplicated(supplied.hazard.options)]
    )
    if (length(duplicated.hazard.options) > 0L) {
      stop(
        "Hazard option(s) specified more than once in `...`: ",
        paste(duplicated.hazard.options, collapse = ", "),
        call. = FALSE
      )
    }
  }
  ## Package defaults are used during training and for older fitted objects
  ## that do not contain a hazard configuration.  The public adaptive option
  ## determines the default trim candidate set, and adaptive = FALSE can also
  ## replace an inherited trim grid unless an explicit hidden coe.trim value is
  ## supplied through `...`.
  coe.trim.default <- if (adaptive) {
    seq(0, .50, by = .005) ## when n is small, winsorization approaches median behavior
  } else {
    0.050
  }
  hazard.options <- list(
    hazard.estimator = hazard.estimator.choices[[1L]],
    coe.aggregate = coe.aggregate.choices[[1L]],
    coe.trim = coe.trim.default
  )
  ## At prediction, inherit each available non-NULL setting from the fitted
  ## object. Missing or NULL entries retain the corresponding package default.
  if (!is.null(hazard.config)) {
    for (option.name in hazard.option.names) {
      if (!is.null(hazard.config[[option.name]])) {
        hazard.options[[option.name]] <- hazard.config[[option.name]]
      }
    }
  }
  ## The public adaptive flag is allowed to override an inherited/default trim
  ## grid, but only when the expert hidden coe.trim option was not supplied.
  ## Thus adaptive = FALSE fixes prediction/restore at the historical 0.05
  ## trim value, while coe.trim in `...` remains the strongest control.
  if (!adaptive && is.null(dots[["coe.trim"]])) {
    hazard.options$coe.trim <- coe.trim.default
  }
  ## Each non-NULL value supplied through `...` overrides the corresponding
  ## fitted value. A missing or NULL value is treated as unspecified.
  for (option.name in hazard.option.names) {
    if (!is.null(dots[[option.name]])) {
      hazard.options[[option.name]] <- dots[[option.name]]
    }
  }
  ## Validate and normalize the final effective settings.
  hazard.options$hazard.estimator <- match.arg(
    hazard.options$hazard.estimator,
    choices = hazard.estimator.choices
  )
  hazard.options$coe.aggregate <- match.arg(
    hazard.options$coe.aggregate,
    choices = coe.aggregate.choices
  )
  hazard.options$coe.trim <- get.coe.trim(hazard.options$coe.trim)
  ## Preserve a grow-time selected index only when the candidate vector is
  ## unchanged and winsorized aggregation remains active.  Index zero denotes
  ## the native median fallback.  Restore mode will recompute the selection;
  ## true prediction reuses the fitted index, including that fallback sentinel.
  selected.index <- 1L
  selected.risk <- NULL
  if (identical(hazard.options$hazard.estimator, "COE") &&
      identical(hazard.options$coe.aggregate, "trimmed.mean") &&
      is.list(inherited.config) &&
      !is.null(inherited.config$coe.trim)) {
    inherited.trim <- tryCatch(
      get.coe.trim(inherited.config$coe.trim),
      error = function(e) NULL
    )
    if (!is.null(inherited.trim) &&
        identical(inherited.trim, hazard.options$coe.trim)) {
      inherited.index <- as.integer(inherited.config$coe.trim.index)[1L]
      if (!is.na(inherited.index) &&
          inherited.index >= 0L &&
          inherited.index <= length(hazard.options$coe.trim)) {
        selected.index <- inherited.index
      }
      if (!is.null(inherited.config$coe.trim.risk.oob)) {
        inherited.risk <- as.double(inherited.config$coe.trim.risk.oob)
        if (length(inherited.risk) == length(hazard.options$coe.trim)) {
          selected.risk <- inherited.risk
        }
      }
    }
  }  
  hazard.options$coe.trim.index <- selected.index
  if (selected.index == 0L) {
    hazard.options$coe.trim.selected <- NA_real_
    hazard.options$coe.aggregate.selected <- "median"
  }
  else {
    hazard.options$coe.trim.selected <- hazard.options$coe.trim[[selected.index]]
    hazard.options$coe.aggregate.selected <- hazard.options$coe.aggregate
  }
  hazard.options$coe.trim.risk.oob <- selected.risk
  hazard.options
}
get.membership.bits <- function (membership) {
  ## Convert option into native code parameter.
  bits <- 0
  if (!is.null(membership)) {
    if (membership == TRUE) {
      bits <- 2^6
    }
    else if (membership != FALSE) {
      stop("Invalid choice for 'membership' option:  ", membership)
    }
  }
  else {
    stop("Invalid choice for 'membership' option:  ", membership)
  }
  return (bits)
}
get.perf <-  function (perf, family) {
  ## Deal with non-classification
  if (family != "class") {
    if (is.null(perf)) {
      return("default")
    }
    perf <- match.arg(perf, c("none", "default", "standard"))
    if (perf == "standard") {
      perf <- "default"
    }
    return(perf)
  }
  else {
      ## Deal with classification
      if (is.null(perf)) {
          return("default")
      }
      perf <- match.arg(perf, c("none", "default", "standard", "misclass", "brier", "gmean"))
      if (perf == "standard" || perf == "misclass") {
          perf <- "default"
      }
      return(perf)
  }
}
get.perf.bits <- function (perf) {
  if (perf == "default") {
    return (2^2)
  }
  else if (perf == "gmean") {
    return (2^2 + 2^14)
  }
  else if (perf == "brier") {
    return (2^2 + 2^3)
  }
  else {#everything else becomes "none"
    return (0)
  }
}
get.rf.cores <- function () {
    ## PART I:  Two ways for the user to specify cores:
    ## (1) R-option "rf.cores"
    ## (2) Shell-environment-option "RF_CORES"
    if (is.null(getOption("rf.cores", NULL))) {
        if (!is.na(as.numeric(Sys.getenv("RF_CORES")))) {
            options(rf.cores = as.integer(Sys.getenv("RF_CORES")))
        }
    }
    ## If the user has set the cores using either of the two methods, we respect it.
    if (!is.null(getOption("rf.cores", NULL))) {
        return (getOption("rf.cores"))
    }
    ## PART II:  Respect R CMD check limit
    chk <- tolower(Sys.getenv("_R_CHECK_LIMIT_CORES_", ""))
    if (nzchar(chk) && chk != "false") {
        ## under R CMD check --as-cran (CRAN sets this)
        return(2L)
    }
    ## PART III:  Use everything.
    return (-1L)
}
get.rt.bits  <- function(real.time) {
  if (real.time == TRUE) {
    bits  <- 2^7
  }
  else {
    bits  <- 0
  }
  return (bits)
}
## convert samptype option into native code parameter.
get.samptype.bits <- function (samptype) {
  if (samptype == "swr") {
    bits <- 0
  }
  else if (samptype == "swor") {
    bits <- 2^12
  }
  else {
    stop("Invalid choice for 'samptype' option:  ", samptype)
  }
  return (bits)
}
get.seed <- function (seed) {
  if ((is.null(seed)) || (abs(seed) < 1)) {
    seed <- runif(1,1,1e6)
  }
  seed <- -round(abs(seed))
  return (seed)
}
get.trace <- function (do.trace) {
  ## Convert trace into native code parameter.
  if (!is.logical(do.trace)) {
    if (do.trace >= 1) {
      do.trace <- round(do.trace)
    }
    else {
      do.trace <- 0
    }
  }
  else {
    do.trace <- 1 * do.trace
  }
  return (do.trace)
}
get.tree.index <- function(get.tree, ntree) {
  ## NULL --> default setting
  if (is.null(get.tree)) {
    rep(1, ntree)
  }
  ## the user has specified a subset of trees
  else {
    pt <- get.tree >=1 & get.tree <= ntree
    if (sum(pt) > 0) {
      get.tree <- get.tree[pt]
      get.tree.temp <- rep(0, ntree)
      get.tree.temp[get.tree] <- 1
      get.tree.temp
    }
    else {
      rep(1, ntree)
    }
  }
}
get.weight <- function(weight, n) {
  ## set the default weight
  if (!is.null(weight)) {
    if (any(weight < 0)      ||
      length(weight) != n  ||
      any(is.na(weight))) {
        stop("Invalid weight vector specified.")
    }
  }
  else {
    weight <- rep(1, n)
  }
  return (weight)
}
get.wmode.bits <- function(wmode) {
    ## Only (1, 2, 3) are valid modes. We shift them to the local option bits. No error checking.
    wmode <- bitwShiftL(wmode, 16)
    return (wmode)
}
# Returns TRUE if the given 0-7 bit is set in an 8-bit integer, FALSE otherwise.
# - value: integer (vectorized); values outside 0..255 are masked to 8 bits
# - bit: single integer in 0..7 (0 = least significant bit)
is.bit <- function(value, bit) {
  if (length(bit) != 1L || is.na(bit) || bit != as.integer(bit) || bit < 0L || bit > 7L) {
    stop("`bit` must be a single integer in 0..7.")
  }
  v <- bitwAnd(as.integer(value), 255L)         # clamp to 8 bits
  m <- bitwShiftL(1L, as.integer(bit))          # mask for the requested bit
  bitwAnd(v, m) != 0L                           # TRUE if bit set, FALSE otherwise (NA propagates)
}
## Real time predicton option:
is.hidden.rt <-  function(dots) {
  if (is.null(dots$real.time)) {
    FALSE
  }
  else {
    as.logical(as.character(dots$real.time))
  }
}
is.hidden.rt.opt  <- function(dots) {
  if (is.null(dots$real.time.options)) {
    list(port = 6666, time.out = 15)      
  }
  else {
    dots$real.time.options
  }
}
is.hidden.wmode <- function(dots) {
    if (is.null(dots$wmode)) {
        wmode <- 2
    }
    else {
        wmode <- dots$wmode
    }
    return (wmode)
}
