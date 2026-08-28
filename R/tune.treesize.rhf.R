## tune.treesize: choose treesize to optimize either OOB risk or OOB iAUC.uno
## Incident-AUC diagnostic revision: 2026-08-25.2
tune.treesize.rhf <- function(formula, data,
                              ntree = 500,
                              nsplit = 10,
                              nodesize = NULL,
                              ## working time-grid controls
                              ntime = 50,
                              min.events.per.gap = 10,
                              ## hazard aggregation control
                              adaptive = TRUE,
                              ## performance measure
                              perf = c("risk", "iAUC"),
                              ## extra arguments passed to auct.rhf when perf = "iAUC"
                              auct.args = NULL,
                              ## search bounds
                              lower = 5L,
                              upper = NULL,
                              C = 3,
                              ## search control
                              method = c("golden", "bisect"),
                              max.evals = 20L,
                              bracket.tol = 2L,   ## stop when width <= bracket.tol
                              ## reproducibility and output
                              seed = NULL,
                              verbose = TRUE,
                              forest = TRUE,
                              ...) {
  method <- match.arg(method)
  perf   <- match.arg(perf)
  adaptive <- get.adaptive(adaptive)
  tune.dots <- list(...)
  declared.event.process <- tune.dots$event.process
  if (is.null(declared.event.process)) {
    declared.event.process <- attr(data, "event.process", exact = TRUE)
  }
  if (is.null(declared.event.process)) {
    declared.event.process <- "auto"
  }
  declared.event.process <- .rhf.match.event.process(declared.event.process)
  ## This tuning wrapper currently assumes one terminal event per subject.
  ## Detect recurrent input before the first candidate forest is grown.
  get_counting_names_from_formula <- function(formula, data) {
    f <- as.formula(formula)
    lhs <- f[[2]]
    if (!is.call(lhs) || !identical(as.character(lhs[[1]]), "Surv")) {
      return(NULL)
    }
    L <- as.list(lhs)[-1]
    if (length(L) != 4L) {
      return(NULL)
    }
    getnm <- function(z) paste(deparse(z), collapse = "")
    nm <- vapply(L, getnm, character(1L))
    names(nm) <- c("id", "start", "stop", "event")
    if (!all(nm %in% names(data))) {
      return(NULL)
    }
    nm
  }
  counting.names <- get_counting_names_from_formula(formula, data)
  if (!is.null(counting.names)) {
    outcome.data <- data[, unname(counting.names), drop = FALSE]
    keep.outcome <- complete.cases(outcome.data)
    outcome.data <- outcome.data[keep.outcome, , drop = FALSE]
    if (nrow(outcome.data) > 0L) {
      coerce.time <- function(x) {
        if (is.factor(x)) as.numeric(as.character(x)) else as.numeric(x)
      }
      process.info <- tryCatch(
        .rhf.event.process.info(
          id = outcome.data[[counting.names[["id"]]]],
          event = outcome.data[[counting.names[["event"]]]],
          start = coerce.time(outcome.data[[counting.names[["start"]]]]),
          stop = coerce.time(outcome.data[[counting.names[["stop"]]]]),
          event.process = "auto",
          binary = TRUE,
          what = counting.names[["event"]]
        ),
        error = function(e) {
          stop("tune.treesize.rhf() requires a complete 0/1 terminal-event outcome: ",
               conditionMessage(e), call. = FALSE)
        }
      )
      recurrent.data <- identical(declared.event.process, "recurrent") ||
                        identical(process.info$inferred, "recurrent") ||
                        !isTRUE(process.info$terminal.valid)
      if (recurrent.data) {
        stop(
          "tune.treesize.rhf() is currently available only for terminal ",
          "single-event RHF data. Recurrent-event data were detected. ",
          "Specify treesize directly in rhf(); recurrent-event tree-size ",
          "tuning is not currently implemented.",
          call. = FALSE
        )
      }
    }
  }
  ## ---- robust subject count (prefer explicit id, else 'id' column, else rows)
  get_id_from_formula <- function(formula, data) {
    f   <- as.formula(formula)
    lhs <- f[[2]]
    if (is.call(lhs) && identical(as.character(lhs[[1]]), "Surv")) {
      L <- as.list(lhs)[-1]
      if (length(L) == 4L) {                # Surv(id, start, stop, event)
        nm <- paste(deparse(L[[1]]), collapse = "")
        if (nm %in% names(data)) return(nm)
      }
    }
    if ("id" %in% names(data)) return("id")
    NULL
  }
  id.var <- get_id_from_formula(formula, data)
  n.subj <- if (!is.null(id.var)) length(unique(data[[id.var]])) else nrow(data)
  ## ---- bounds
  lower <- as.integer(max(2L, lower))
  if (is.null(upper)) {
    ## Use the same event-processing path as rhf.workhorse() so the automatic
    ## tuning range is based on the number of events that remain after RHF data
    ## cleaning and event-process validation.  The explicit ntime and
    ## min.events.per.gap controls are also passed unchanged to every candidate
    ## forest and to the final refit.
    if (!is.numeric(min.events.per.gap) ||
        length(min.events.per.gap) != 1L ||
        is.na(min.events.per.gap) ||
        !is.finite(min.events.per.gap) ||
        min.events.per.gap < 1) {
      stop("min.events.per.gap must be a positive finite scalar.",
           call. = FALSE)
    }
    ntime.bound <- ntime
    formula.prelim <- parse.formula(as.formula(formula), data, NULL)
    formula.detail <- finalize.formula(formula.prelim, data)
    family <- formula.detail$family
    xvar.names <- formula.detail$xvar.names
    yvar.names <- formula.detail$yvar.names
    subj.names <- formula.detail$subj.names
    if (family != "surv-tdc") {
      stop("tune.treesize.rhf() currently works only for TDC survival.",
           call. = FALSE)
    }
    if (length(xvar.names) == 0L) {
      stop("The formula did not define any x variables.", call. = FALSE)
    }
    if (length(yvar.names) == 0L) {
      stop("The formula did not define any y variables.", call. = FALSE)
    }
    if (length(subj.names) == 0L) {
      stop("The formula did not identify a subject variable.", call. = FALSE)
    }
    bound.data <- cleanup.counting(
      data,
      xvar.names,
      yvar.names,
      subj.names,
      event.process = declared.event.process
    )
    time.map <- attr(bound.data, "time.map")
    event.process <- attr(bound.data, "event.process")
    event.process.info <- attr(bound.data, "event.process.info")
    subj.bound <- bound.data[, subj.names]
    yvar.bound <- bound.data[, yvar.names]
    n.subj <- length(unique(subj.bound))
    if (length(ntime.bound) > 1L) {
      ntime.bound <- .forward.time(ntime.bound, time.map)
    }
    event.info <- get.grow.event.info(
      yvar.bound,
      family,
      ntime = ntime.bound,
      min.events.per.gap = min.events.per.gap,
      subj = subj.bound,
      event.process = event.process,
      process.info = event.process.info
    )
    ndead <- event.info$n.event
    default.size <- default.treesize(
      ndead = ndead,
      min.events.per.leaf = min.events.per.gap
    )
    support.limit <- floor(
      ndead / min.events.per.gap
    )
    upper <- min(
      ceiling(C * default.size),
      support.limit
    )
    rm(bound.data)
    if (!is.finite(upper) || upper <= lower) {
      stop(
        paste0(
          "The event-supported automatic upper tree-size bound (", upper,
          ") must be greater than lower (", lower, "). ",
          "Reduce lower or min.events.per.gap, or specify upper explicitly."
        ),
        call. = FALSE
      )
    }
  }
  upper <- as.integer(max(lower + 1L, upper))
  if (!is.null(seed)) set.seed(seed)
  ## ---- caches (keyed by treesize)
  ## Only scalar tuning results and the native grow seed are retained.  The
  ## selected forest is refitted after the search rather than returned from an
  ## earlier candidate evaluation.  This leaves a fresh, standalone RHF object
  ## suitable for both prediction and restore mode.
  risk.cache <- new.env(parent = emptyenv())
  seed.cache <- if (isTRUE(forest)) new.env(parent = emptyenv()) else NULL
  ## Only used when perf = "iAUC"
  iauc.cache       <- if (perf == "iAUC") new.env(parent = emptyenv()) else NULL
  iauc.se.cache    <- if (perf == "iAUC") new.env(parent = emptyenv()) else NULL
  iauc.error.cache <- if (perf == "iAUC") new.env(parent = emptyenv()) else NULL
  ## ---- helper to evaluate a single treesize
  eval.one <- function(ts) {
    ts  <- as.integer(ts)
    key <- as.character(ts)
    ## cached result?
    if (exists(key, envir = risk.cache, inherits = FALSE)) {
      r <- get(key, envir = risk.cache, inherits = FALSE)
      if (isTRUE(verbose)) {
        if (perf == "risk") {
          message(sprintf("treesize = %d   OOB risk (criterion) = %.6f (cached)", ts, r))
        } else {
          message(sprintf("treesize = %d   1 - iAUC.uno (criterion) = %.6f (cached)", ts, r))
        }
      }
      return(r)
    }
    ## Fit RHF at this treesize.  Generate the native grow seed explicitly so
    ## it can be reused for the final refit at the selected tree size.  This
    ## preserves the previous seed behavior: with a user seed, every candidate
    ## uses the same forest randomization; without one, candidates use successive
    ## random seeds.
    if (!is.null(seed)) set.seed(seed)
    fit.seed <- get.seed(NULL)
    fit <- rhf(formula = formula,
               data = data,
               ntree = ntree,
               nsplit = nsplit,
               treesize = ts,
               nodesize = nodesize,
               ntime = ntime,
               min.events.per.gap = min.events.per.gap,
               adaptive = adaptive,
               seed = fit.seed,
               ...)
    ## ---- performance measure
    if (perf == "risk") {
      rsk <- fit$risk.oob
      if (is.null(rsk))
        stop("OOB risk values (fit$risk.oob) are missing; cannot tune by 'risk'.")
      r <- mean(rsk[is.finite(rsk)], na.rm = TRUE)
      if (!is.finite(r)) r <- Inf
      if (isTRUE(verbose))
        message(sprintf("treesize = %d   OOB risk (criterion) = %.6f", ts, r))
    } else { ## perf == "iAUC"
      args.auct <- auct.args
      if (is.null(args.auct)) args.auct <- list()
      args.auct$object <- fit  ## enforce
      auct.result <- tryCatch(
        do.call(auct.rhf, args.auct),
        error = identity
      )
      if (inherits(auct.result, "error")) {
        auct.error <- conditionMessage(auct.result)
        if (isTRUE(verbose)) {
          message(
            sprintf(
              "treesize = %d   auct.rhf() failed; treating criterion as +Inf\n  %s",
              ts, auct.error
            )
          )
        }
        r <- Inf
        if (!is.null(iauc.cache)) {
          assign(key, NA_real_, envir = iauc.cache)
        }
        if (!is.null(iauc.se.cache)) {
          assign(key, NA_real_, envir = iauc.se.cache)
        }
        if (!is.null(iauc.error.cache)) {
          assign(key, auct.error, envir = iauc.error.cache)
        }
      } else {
        auct.obj <- auct.result
        iauc <- auct.obj$iAUC.uno
        if (!is.numeric(iauc) || length(iauc) != 1L || !is.finite(iauc)) {
          auct.error <- "auct.rhf() returned a missing or non-finite scalar iAUC.uno."
          if (isTRUE(verbose)) {
            message(
              sprintf(
                "treesize = %d   iAUC.uno is non-finite; treating criterion as +Inf",
                ts
              )
            )
          }
          r <- Inf
          se <- NA_real_
        } else {
          r <- 1 - iauc
          auct.error <- NA_character_
          if (isTRUE(verbose)) {
            message(sprintf("treesize = %d   iAUC.uno = %.6f   criterion (1 - iAUC.uno) = %.6f",
                            ts, iauc, r))
          }
          ## try to grab bootstrap SE if available
          se <- NA_real_
          if (!is.null(auct.obj$boot) &&
              !is.null(auct.obj$boot$iAUC.uno.se) &&
              is.finite(auct.obj$boot$iAUC.uno.se)) {
            se <- auct.obj$boot$iAUC.uno.se
          }
        }
        if (!is.null(iauc.cache)) {
          assign(key, iauc, envir = iauc.cache)
        }
        if (!is.null(iauc.se.cache)) {
          assign(key, se, envir = iauc.se.cache)
        }
        if (!is.null(iauc.error.cache)) {
          assign(key, auct.error, envir = iauc.error.cache)
        }
      }
    }
    ## Cache the criterion and, when a forest is requested, the exact native
    ## seed needed to reproduce this candidate in the final refit.
    assign(key, r, envir = risk.cache)
    if (isTRUE(forest)) assign(key, fit.seed, envir = seed.cache)
    r
  }
  ## collect the path
  collect.path <- function() {
    sizes <- as.integer(sort(as.integer(ls(risk.cache))))
    crit  <- vapply(
      sizes,
      function(k) get(as.character(k), envir = risk.cache, inherits = FALSE),
      numeric(1)
    )
    path <- data.frame(treesize = sizes, risk = crit)
    if (perf == "iAUC" && !is.null(iauc.cache)) {
      iauc <- vapply(
        sizes,
        function(k) {
          key <- as.character(k)
          if (exists(key, envir = iauc.cache, inherits = FALSE)) {
            get(key, envir = iauc.cache, inherits = FALSE)
          } else {
            NA_real_
          }
        },
        numeric(1)
      )
      se <- vapply(
        sizes,
        function(k) {
          key <- as.character(k)
          if (!is.null(iauc.se.cache) &&
              exists(key, envir = iauc.se.cache, inherits = FALSE)) {
            get(key, envir = iauc.se.cache, inherits = FALSE)
          } else {
            NA_real_
          }
        },
        numeric(1)
      )
      err <- vapply(
        sizes,
        function(k) {
          key <- as.character(k)
          if (!is.null(iauc.error.cache) &&
              exists(key, envir = iauc.error.cache, inherits = FALSE)) {
            value <- get(key, envir = iauc.error.cache, inherits = FALSE)
            if (is.null(value) || !length(value)) {
              NA_character_
            } else {
              as.character(value)[1L]
            }
          } else {
            NA_character_
          }
        },
        character(1L)
      )
      path$iAUC       <- iauc
      path$iAUC.se    <- se
      path$auct.error <- err
    }
    path
  }
  ## ---- initialize
  a <- lower; b <- upper
  evals <- 0L
  ## Always evaluate the smallest treesize at least once
  eval.one(lower); evals <- evals + 1L
  if (method == "golden") {
    ## classic discrete golden-section on integers
    phi <- (1 + sqrt(5)) / 2
    x1 <- as.integer(round(b - (b - a) / phi))
    x2 <- as.integer(round(a + (b - a) / phi))
    if (x1 == x2) x2 <- min(b, x1 + 1L)
    f1 <- eval.one(x1); evals <- evals + 1L
    f2 <- eval.one(x2); evals <- evals + 1L
    while ((b - a > bracket.tol) && evals < max.evals) {
      if (f1 > f2) {
        a <- x1
        x1 <- x2
        f1 <- f2
        x2 <- as.integer(round(a + (b - a) / phi))
        if (x2 <= x1) x2 <- min(b, x1 + 1L)
        f2 <- eval.one(x2); evals <- evals + 1L
      } else {
        b <- x2
        x2 <- x1
        f2 <- f1
        x1 <- as.integer(round(b - (b - a) / phi))
        if (x1 >= x2) x1 <- max(a, x2 - 1L)
        f1 <- eval.one(x1); evals <- evals + 1L
      }
    }
  } else { ## method == "bisect"
    while ((b - a > bracket.tol) && evals < max.evals) {
      m  <- as.integer(floor((a + b) / 2))
      fm <- eval.one(m);       evals <- evals + 1L
      fl <- eval.one(m - 1L);  evals <- evals + 1L
      fr <- eval.one(m + 1L);  evals <- evals + 1L
      if (fl >= fm && fr >= fm) { a <- max(a, m - 1L); b <- min(b, m + 1L); break }
      if (fl <  fm) { b <- m - 1L } else
      if (fr <  fm) { a <- m + 1L } else {
        a <- max(a, m - 1L); b <- min(b, m + 1L)
      }
    }
  }
  ## Evaluate remaining integers in [a, b], but only those not already cached
  left  <- max(lower, a)
  right <- min(upper, b)
  if (right >= left) {
    cand <- seq.int(left, right)
    not.eval <- cand[!(as.character(cand) %in% ls(risk.cache))]
    if (length(not.eval)) {
      vapply(not.eval, eval.one, numeric(1))
      evals <- evals + length(not.eval)
    }
  }
  ## ---- GLOBAL best over *all* evaluated sizes
  path <- collect.path()
  if (!any(is.finite(path$risk))) {
    detail <- NULL
    if ("auct.error" %in% names(path)) {
      detail <- unique(path$auct.error[
        !is.na(path$auct.error) & nzchar(path$auct.error)
      ])
    }
    suffix <- if (length(detail)) {
      paste0(" First auct.rhf() error: ", detail[[1L]])
    } else {
      ""
    }
    stop(
      "No evaluated tree size produced a finite ",
      if (perf == "iAUC") "iAUC tuning criterion." else "OOB-risk criterion.",
      suffix,
      call. = FALSE
    )
  }
  idx  <- which.min(path$risk)
  best.size <- path$treesize[idx]
  best.err  <- path$risk[idx]
  ## Optionally return a final RHF fit at best.size.  Do not return a forest
  ## object cached from an earlier candidate evaluation: the tuning search may
  ## perform several native grow calls after that candidate was fitted.  Refit
  ## the selected size last, using the exact candidate seed, so the returned
  ## object is coherent for ordinary prediction and restore mode.
  best.fit <- NULL
  if (isTRUE(forest)) {
    key <- as.character(best.size)
    if (!exists(key, envir = seed.cache, inherits = FALSE)) {
      stop("Internal error: selected tree size has no cached grow seed.",
           call. = FALSE)
    }
    best.seed <- get(key, envir = seed.cache, inherits = FALSE)
    best.fit <- rhf(formula = formula,
                    data = data,
                    ntree = ntree,
                    nsplit = nsplit,
                    treesize = best.size,
                    nodesize = nodesize,
                    ntime = ntime,
                    min.events.per.gap = min.events.per.gap,
                    adaptive = adaptive,
                    seed = best.seed,
                    ...)
  }
  out <- list(
    best.size   = best.size,
    best.err    = best.err,
    bounds      = c(lower = lower, upper = upper),
    n.subjects  = n.subj,
    C           = C,
    method      = method,
    perf        = perf,
    adaptive    = adaptive,
    path        = path
  )
  if (!is.null(best.fit)) out$forest <- best.fit
  class(out) <- "tune.treesize.rhf"
  out
}
tune.rhf <- tune.treesize.rhf
## Convenience wrapper: tune treesize by iAUC.uno from auct.rhf
tune.iAUC.rhf <- function(formula, data, auct.args = NULL,
                          adaptive = TRUE, ...) {
  tune.treesize.rhf(
    formula  = formula,
    data     = data,
    perf     = "iAUC",
    auct.args = auct.args,
    adaptive = adaptive,
    ...
  )
}
tune.iAUC <- tune.iAUC.rhf
## plot results (metric vs treesize, also has bootstrap now)
plot.tune.treesize.rhf <- function(x,
                                   ylab   = NULL,
                                   main   = NULL,
                                   se.band = TRUE,
                                   se.mult = 1,
                                   ylim   = NULL,
                                   ...) {
  stopifnot(inherits(x, "tune.treesize.rhf"))
  path <- x$path
  perf <- if (!is.null(x$perf)) x$perf else "risk"
  if (perf == "iAUC" && "iAUC" %in% names(path)) {
    ## ---------- iAUC tuning plot ----------
    xx <- path$treesize
    yy <- path$iAUC
    if (is.null(ylab)) ylab <- "OOB iAUC.uno"
    if (is.null(main)) main <- "Tuning treesize by OOB iAUC"
    if (!any(is.finite(yy))) {
      detail <- if ("auct.error" %in% names(path)) {
        unique(path$auct.error[
          !is.na(path$auct.error) & nzchar(path$auct.error)
        ])
      } else {
        character(0L)
      }
      suffix <- if (length(detail)) {
        paste0(" First auct.rhf() error: ", detail[[1L]])
      } else {
        ""
      }
      stop(
        "No finite OOB iAUC values are available for plotting.",
        suffix,
        call. = FALSE
      )
    }
    ## compute ylim to include band if needed
    if (is.null(ylim)) {
      y.all <- yy
      if (isTRUE(se.band) && "iAUC.se" %in% names(path)) {
        se   <- path$iAUC.se
        mult <- if (is.finite(se.mult) && se.mult > 0) se.mult else 1
        yl   <- yy - mult * se
        yu   <- yy + mult * se
        y.all <- c(y.all, yl, yu)
      }
      y.all <- y.all[is.finite(y.all)]
      ymin <- min(y.all)
      ymax <- max(y.all)
      span <- ymax - ymin
      pad <- if (is.finite(span) && span > 0) {
        0.05 * span
      } else {
        0.05 * max(1, abs(ymin))
      }
      ylim <- c(ymin - pad, ymax + pad)
    }
    plot(xx, yy, type = "p", pch = 16,
         xlab = "treesize", ylab = ylab, main = main,
         ylim = ylim, ...)
    ok <- is.finite(xx) & is.finite(yy)
    if (sum(ok) >= 3L) {
      sm <- stats::lowess(xx[ok], yy[ok])
      lines(sm, lwd = 2)
    }
    ## gray SE ribbon, if available
    if (isTRUE(se.band) &&
        "iAUC.se" %in% names(path) &&
        any(is.finite(path$iAUC.se))) {
      se   <- path$iAUC.se
      mult <- if (is.finite(se.mult) && se.mult > 0) se.mult else 1
      yl   <- yy - mult * se
      yu   <- yy + mult * se
      okb <- is.finite(xx) & is.finite(yl) & is.finite(yu)
      if (sum(okb) >= 2L) {
        ord  <- order(xx[okb])
        xt   <- xx[okb][ord]
        yl.t <- yl[okb][ord]
        yu.t <- yu[okb][ord]
        polygon(c(xt, rev(xt)),
                c(yl.t, rev(yu.t)),
                border = NA,
                col = grDevices::adjustcolor("gray", alpha.f = 0.25))
        ## redraw points on top
        points(xx, yy, pch = 16)
      }
    }
    ## vertical line + annotation at best treesize
    abline(v = x$best.size, lty = 2)
    idx <- which(path$treesize == x$best.size)
    best.iAUC <- if (length(idx) >= 1L && is.finite(path$iAUC[idx[1L]])) {
      path$iAUC[idx[1L]]
    } else {
      1 - x$best.err
    }
    mtext(sprintf("best treesize = %d, iAUC = %.4f",
                  x$best.size, best.iAUC),
          line = 0.5)
  } else {
    ## ---------- OOB risk plot (no band) ----------
    xx <- path$treesize
    yy <- path$risk
    if (is.null(ylab)) ylab <- "OOB empirical risk"
    if (is.null(main)) main <- "Tuning treesize by OOB risk"
    if (!any(is.finite(yy))) {
      stop("No finite OOB-risk values are available for plotting.",
           call. = FALSE)
    }
    if (is.null(ylim)) {
      y.all <- yy[is.finite(yy)]
      ymin <- min(y.all)
      ymax <- max(y.all)
      span <- ymax - ymin
      pad <- if (is.finite(span) && span > 0) {
        0.05 * span
      } else {
        0.05 * max(1, abs(ymin))
      }
      ylim <- c(ymin - pad, ymax + pad)
    }
    plot(xx, yy, type = "p", pch = 16,
         xlab = "treesize", ylab = ylab, main = main,
         ylim = ylim, ...)
    ok <- is.finite(xx) & is.finite(yy)
    if (sum(ok) >= 3L) {
      sm <- stats::lowess(xx[ok], yy[ok])
      lines(sm, lwd = 2)
    }
    abline(v = x$best.size, lty = 2)
    mtext(sprintf("best treesize = %d, risk = %.4f",
                  x$best.size, x$best.err),
          line = 0.5)
  }
}
