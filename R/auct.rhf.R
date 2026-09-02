##########################################################################
##
## main wrapper function
##
## Marker revisions: incident 2026-08-25.3; cumulative 2026-08-27.2
##
##########################################################################
auct.rhf <- function(object,
                     marker = c("cumhaz",  "hazard", "chf", "haz"),
                     method = c("cumulative", "incident"),
                     tau = NULL,
                     riskset = c("subject", "record"),
                     min.controls = 25,
                     nfrac.controls = 0.10,
                     min.cases = 1,
                     g.floor = 0.10,
                     g.floor.q = NULL,
                     power = 2,
                     ydata = NULL,
                     winsor.q = NULL,
                     eps = 1e-12,
                     bootstrap.rep = 0L,
                     bootstrap.refit = FALSE,
                     bootstrap.conf = 0.95,
                     bootstrap.seed = NULL,
                     verbose = TRUE) {
  marker <- match.arg(marker)
  if (marker == "chf") marker <- "cumhaz"
  if (marker == "haz") marker <- "hazard"
  method  <- match.arg(method)
  riskset <- match.arg(riskset)
  ## --- 1) Time grid and marker matrix (RHF-specific) ---
  times.full <- object$time.interest
  if (is.null(times.full) || length(times.full) < 1L)
    stop("time.interest missing")
  keep.time <- if (is.null(tau)) rep(TRUE, length(times.full)) else times.full <= tau
  if (!any(keep.time))
    stop("No time.interest <= tau.")
  times <- times.full[keep.time]
  ## Pick the requested public marker matrix.  For incident hazard AUC,
  ## off-grid event cases are restored below from the pre-mask interval
  ## hazard while every other path-domain NA remains unchanged.
  get.mat <- function(name.oob, name.test) {
    if (!is.null(object[[name.oob]])) {
      return(list(value = object[[name.oob]], ensemble = "oob"))
    }
    if (!is.null(object[[name.test]])) {
      return(list(value = object[[name.test]], ensemble = "test"))
    }
    NULL
  }
  marker.object <- switch(
    marker,
    "cumhaz" = get.mat("chf.oob", "chf.test"),
    "hazard" = get.mat("hazard.oob", "hazard.test")
  )
  if (is.null(marker.object))
    stop("Requested marker matrix is missing in RHF object.")
  ## Public hazard.* and chf.* outputs obey the supplied subject path.  For
  ## cumulative/dynamic AUC, however, cases who failed before t and controls
  ## still at risk at t require a common-time marker.  Reconstruct the
  ## historical AUC-only marker by applying the fitted forest aggregation
  ## pointwise to hazard.tree.* or chf.tree.*.  The public path-domain outputs
  ## are never modified.
  cumulative.marker <- NULL
  if (identical(method, "cumulative")) {
    cumulative.marker <- .rhf.auct.cumulative.marker(
      object = object,
      marker = marker,
      ensemble = marker.object$ensemble,
      keep.time = keep.time
    )
    Z <- cumulative.marker$marker
  } else {
    Z <- as.matrix(marker.object$value)
    Z <- Z[, keep.time, drop = FALSE]
  }
  ## --- 2) Outcomes and subject alignment (RHF-specific extraction) ---
  YY <- if (is.null(object$id) || is.null(object$yvar)) {
    if (is.null(ydata))
      stop("Predict object lacks id/yvar; supply counting-process data via ydata=.")
    ydata[, c("id","start","stop","event")]
  } else {
    yv <- as.data.frame(object$yvar)
    if (!is.null(object$yvar.names) && length(object$yvar.names) >= 3L) {
      colnames(yv)[1:3] <- object$yvar.names[1:3]
    }
    if (!all(colnames(yv)[1:3] %in% c("start","stop","event"))) {
      colnames(yv)[1:3] <- c("start","stop","event")
    }
    data.frame(id = object$id, yv)
  }
  YY$id <- as.character(YY$id)
  ## auct.rhf() uses terminal-event case/control definitions and reduces each
  ## subject to the final event/censoring row.  Detect recurrent input before
  ## entering the model-agnostic core so it cannot be analyzed silently as a
  ## single-event outcome.
  process.candidates <- c(
    object$event.process,
    if (is.list(object$event.info)) object$event.info$event.process else NULL,
    if (is.list(object$forest)) object$forest$event.process else NULL,
    if (is.list(object$forest) && is.list(object$forest$event.info)) {
      object$forest$event.info$event.process
    } else NULL,
    if (is.list(object$forest) && is.list(object$forest$parms)) {
      object$forest$parms$event.process
    } else NULL,
    attr(ydata, "event.process", exact = TRUE)
  )
  process.candidates <- as.character(process.candidates)
  process.candidates <- process.candidates[
    !is.na(process.candidates) & nzchar(process.candidates)
  ]
  declared.recurrent <- any(process.candidates == "recurrent")
  process.info <- tryCatch(
    .rhf.event.process.info(
      id = YY$id,
      event = YY$event,
      start = YY$start,
      stop = YY$stop,
      event.process = "auto",
      binary = TRUE,
      what = "event"
    ),
    error = function(e) {
      stop("auct.rhf() requires a complete 0/1 terminal-event outcome: ",
           conditionMessage(e), call. = FALSE)
    }
  )
  recurrent.data <- declared.recurrent ||
                    identical(process.info$inferred, "recurrent") ||
                    !isTRUE(process.info$terminal.valid)
  if (recurrent.data) {
    stop(
      "auct.rhf() is available only for terminal single-event RHF data. ",
      "Recurrent-event data were detected (a subject has multiple event rows ",
      "or follow-up continues after an event). Recurrent-event AUC requires a ",
      "separate case/control definition and is not currently implemented.",
      call. = FALSE
    )
  }
  YY$event <- process.info$event
  ## The subject order of every RHF ensemble matrix is defined by
  ## object$ensemble.id. Matrix row names are only a secondary diagnostic:
  ## native output may omit them or retain syntactically valid row names that
  ## are not the outcome IDs. Canonicalize the marker rows once here so the
  ## incident restoration and the model-agnostic AUC core use the same order.
  marker.alignment <- .rhf.auct.subject.ids(object, Z, YY)
  rownames(Z) <- marker.alignment$ids
  ## For an incident case with event time inside (t[k-1], t[k]), the public
  ## pointwise hazard at t[k] is correctly NA because t[k] lies outside the
  ## subject's path. Incident AUC nevertheless needs the pre-mask interval
  ## hazard for that event-containing cell. Restore only those case markers;
  ## controls and all other out-of-domain entries retain the public NA mask.
  incident.marker <- NULL
  if (identical(marker, "hazard") && identical(method, "incident")) {
    incident.marker <- .rhf.restore.incident.hazard.cases(
      object = object,
      Z = Z,
      YY = YY,
      times = times,
      keep.time = keep.time,
      ensemble = marker.object$ensemble,
      subject.ids = marker.alignment$ids,
      alignment.source = marker.alignment$source
    )
    Z <- incident.marker$marker
  }
  ## --- 3) Call model-agnostic core for AUC(t)/iAUC ---
  core <- .tdc_auct_core(times        = times,
                         Z            = Z,
                         YY           = YY,
                         method       = method,
                         riskset      = riskset,
                         min.controls = min.controls,
                         nfrac.controls = nfrac.controls,
                         min.cases    = min.cases,
                         g.floor      = g.floor,
                         g.floor.q    = g.floor.q,
                         power        = power,
                         winsor.q     = winsor.q,
                         eps          = eps)
  A             <- core$AUC.by.time
  iAUC.uno      <- core$iAUC.uno
  iAUC.std      <- core$iAUC.std
  diag.riskset  <- core$diag.riskset
  times         <- core$times
  g.floor       <- core$g.floor   ## possibly adjusted by g.floor.q
  aux           <- core$aux
  ## unpack aux objects needed for bootstrap branches
  Tstop      <- aux$Tstop
  Delta      <- aux$Delta
  entry      <- aux$entry
  subj.order <- aux$subj.order
  id.to.row  <- aux$id.to.row
  start.vec  <- aux$start.vec
  stop.vec   <- aux$stop.vec
  id.vec     <- aux$id.vec
  Nsubj      <- aux$Nsubj
  k.list     <- aux$k.list
  by.k       <- aux$by.k
  ## ---- Bootstrap SEs (unchanged logic, uses objects above) ----
  boot <- NULL
  if (isTRUE(bootstrap.rep > 0L)) {
    if (!is.null(bootstrap.seed)) {
      set.seed(as.integer(bootstrap.seed)[1L])
    }
    B <- as.integer(bootstrap.rep)
    base.times <- A$time
    if (isTRUE(bootstrap.refit)) {
      ## -------- Refit bootstrap (refit RHF each replicate) --------
      parms <- object$forest$parms
      if (is.null(parms)) {
        warning("bootstrap.refit=TRUE requested but object$forest$parms is missing; falling back to plug-in bootstrap.")
        bootstrap.refit <- FALSE
      } else {
        eval.df <- .rhf.build_data_from_object(object)
        is.predict.obj <- any(c("predict", "predict.rhf") %in% class(object))
        train.df <- eval.df
        ## A subject-level pairs bootstrap must retain every sampled copy.
        ## Repeated draws are therefore expanded as complete counting-process
        ## histories and assigned new IDs; using `%in%` would discard the
        ## bootstrap multiplicities and reduce the number of subjects.
        uid <- .rhf.unique.subject.order(train.df$id)
        n.subjects <- length(uid)
        subject.index <- match(as.character(train.df$id), uid)
        if (n.subjects < 1L || anyNA(subject.index)) {
          stop("Unable to construct subject blocks for the refit bootstrap.", call. = FALSE)
        }
        rows.by.subject <- split(seq_len(nrow(train.df)), subject.index)
        ## Refit with the same hazard/CHF configuration used by the original
        ## forest. For legacy objects without hazard.config, the helper applies
        ## the current package defaults.
        hazard.options <- get.hazard.options(
          dots = list(),
          hazard.config = parms$hazard.config
        )
        build.args <- function(parms, fml, dat, draw.index) {
          ## `case.wt` and `samp` are handled separately because they are
          ## indexed by subject and must follow the bootstrap draws.
          allowed <- c("ntree", "treesize", "nodesize", "nsplit", "mtry",
                       "ntime", "splitrule", "experimental.bits", "bootstrap",
                       "samptype", "xvar.wt", "sampsize", "membership", "seed",
                       "do.trace", "block.size", "min.events.per.gap")
          args <- list(formula = fml, data = dat)
          for (nm in intersect(names(parms), allowed)) {
            if (nm == "xvar.wt") {
              p <- ncol(dat) - 4L  # predictors only
              if (length(parms$xvar.wt) == p) {
                args$xvar.wt <- parms$xvar.wt
              }
            } else {
              args[[nm]] <- parms[[nm]]
            }
          }
          if (!is.null(parms$case.wt)) {
            if (length(parms$case.wt) != n.subjects) {
              stop(
                "Stored case.wt has length ", length(parms$case.wt),
                ", but the refit data contain ", n.subjects, " subjects.",
                call. = FALSE
              )
            }
            args$case.wt <- parms$case.wt[draw.index]
          }
          if (identical(parms$bootstrap, "by.user")) {
            if (is.null(parms$samp) || !is.matrix(parms$samp) ||
                nrow(parms$samp) != n.subjects) {
              stop(
                "Stored by-user bootstrap sample is missing or has an incompatible number of rows.",
                call. = FALSE
              )
            }
            args$samp <- parms$samp[draw.index, , drop = FALSE]
          }
          ## Hidden hazard options are supplied individually through `...`.
          args[names(hazard.options)] <- hazard.options
          args
        }
        try.message <- function(x) {
          condition <- attr(x, "condition")
          if (!is.null(condition)) {
            conditionMessage(condition)
          } else {
            as.character(x)[1L]
          }
        }
        finite.sd <- function(x) {
          x <- x[is.finite(x)]
          if (length(x) >= 2L) stats::sd(x) else NA_real_
        }
        auc.mat    <- matrix(NA_real_, nrow = B, ncol = length(base.times))
        iauc.uno.v <- rep(NA_real_, B)
        iauc.std.v <- rep(NA_real_, B)
        fml <- as.formula("Surv(id, start, stop, event) ~ .")
        fit.failures <- 0L
        evaluation.failures <- 0L
        first.failure <- NULL
        if (isTRUE(verbose) && B > 0L) {
          t.start <- proc.time()[3]
          step    <- max(1L, floor(B / 10L))
          message("auct.rhf bootstrap (refit): starting ", B, " replicates...")
        }
        for (bb in seq_len(B)) {
          draw.index <- sample.int(n.subjects, n.subjects, replace = TRUE)
          selected.blocks <- rows.by.subject[draw.index]
          row.index <- unlist(selected.blocks, use.names = FALSE)
          tr.b <- train.df[row.index, , drop = FALSE]
          tr.b$id <- rep(seq_len(n.subjects), times = lengths(selected.blocks))
          rownames(tr.b) <- NULL
          args.fit <- build.args(
            parms = parms,
            fml = fml,
            dat = tr.b,
            draw.index = draw.index
          )
          ofit <- try(do.call(rhf, args.fit), silent = TRUE)
          if (inherits(ofit, "try-error")) {
            fit.failures <- fit.failures + 1L
            if (is.null(first.failure)) {
              first.failure <- paste0("RHF refit: ", try.message(ofit))
            }
          } else {
            ans.b <- try({
              if (is.predict.obj) {
                pr <- predict.rhf(ofit, eval.df)
                auct.rhf(pr, marker = marker, method = method, tau = tau,
                         riskset = riskset, min.controls = min.controls,
                         nfrac.controls = nfrac.controls, min.cases = min.cases,
                         g.floor = g.floor, g.floor.q = g.floor.q, power = power,
                         ydata = eval.df, winsor.q = winsor.q, eps = eps,
                         bootstrap.rep = 0L)
              } else {
                auct.rhf(ofit, marker = marker, method = method, tau = tau,
                         riskset = riskset, min.controls = min.controls,
                         nfrac.controls = nfrac.controls, min.cases = min.cases,
                         g.floor = g.floor, g.floor.q = g.floor.q, power = power,
                         winsor.q = winsor.q, eps = eps, bootstrap.rep = 0L)
              }
            }, silent = TRUE)
            if (inherits(ans.b, "try-error")) {
              evaluation.failures <- evaluation.failures + 1L
              if (is.null(first.failure)) {
                first.failure <- paste0("AUC evaluation: ", try.message(ans.b))
              }
            } else {
              at   <- ans.b$AUC.by.time
              aucb <- .rhf.align_auc_by_time(at$time, at$AUC, base.times)
              auc.mat[bb, ] <- aucb
              iauc.uno.v[bb] <- ans.b$iAUC.uno
              iauc.std.v[bb] <- ans.b$iAUC.std
            }
          }
          if (isTRUE(verbose) && B > 0L) {
            if (bb == 1L || bb %% step == 0L || bb == B) {
              t.now   <- proc.time()[3]
              elapsed <- t.now - t.start
              rate    <- elapsed / bb
              remain  <- max(0, rate * (B - bb))
              message(sprintf(
                "  [auct.rhf] refit bootstrap %d/%d  elapsed=%.1fs  approx.remaining=%.1fs",
                bb, B, elapsed, remain
              ))
            }
          }
        }
        completed.rep <- B - fit.failures - evaluation.failures
        finite.rep <- rowSums(is.finite(auc.mat)) > 0L |
                      is.finite(iauc.uno.v) |
                      is.finite(iauc.std.v)
        informative.rep <- sum(finite.rep)
        if (completed.rep == 0L) {
          stop(
            "All ", B, " refit bootstrap replicates failed",
            if (!is.null(first.failure)) paste0(". First failure: ", first.failure) else ".",
            call. = FALSE
          )
        }
        if (informative.rep == 0L) {
          stop(
            "Refit bootstrap completed, but no replicate produced a finite AUC estimate. ",
            "Check tau, min.controls, nfrac.controls, and min.cases.",
            call. = FALSE
          )
        }
        if (completed.rep < B) {
          warning(
            completed.rep, " of ", B, " refit bootstrap replicates completed successfully",
            if (!is.null(first.failure)) paste0(". First failure: ", first.failure) else ".",
            call. = FALSE
          )
        }
        auc.se      <- apply(auc.mat, 2L, finite.sd)
        iauc.uno.se <- finite.sd(iauc.uno.v)
        iauc.std.se <- finite.sd(iauc.std.v)
        auc.lower <- auc.upper <- NULL
        if (is.finite(bootstrap.conf) && !is.na(bootstrap.conf) &&
            bootstrap.conf > 0 && bootstrap.conf < 1) {
          zc <- stats::qnorm((1 + bootstrap.conf) / 2)
          auc.lower <- A$AUC - zc * auc.se
          auc.upper <- A$AUC + zc * auc.se
        }
        boot <- list(
          AUC.se       = auc.se,
          iAUC.uno.se  = iauc.uno.se,
          iAUC.std.se  = iauc.std.se,
          conf.level   = bootstrap.conf,
          AUC.lower    = auc.lower,
          AUC.upper    = auc.upper,
          rep          = bootstrap.rep,
          mode         = "refit"
        )
      }
    }
    if (!isTRUE(bootstrap.refit)) {
      ## -------- Plug-in bootstrap (hold marker fixed; resample subjects) --------
      case.rows.by.k <- vector("list", length(k.list))
      ctrl.rows.by.k <- vector("list", length(k.list))
      names(case.rows.by.k) <- names(ctrl.rows.by.k) <- as.character(k.list)
      for (hh in seq_along(k.list)) {
        k  <- k.list[hh]
        tk <- times[k]
        if (method == "incident") {
          case.ids <- subj.order[ by.k[[as.character(k)]] ]
          cs <- as.integer(id.to.row[case.ids]); cs <- cs[is.finite(cs)]
          if (riskset == "subject") {
            cr0 <- which(entry < tk & Tstop >= tk)
          } else {
            at  <- which(start.vec < tk & stop.vec >= tk)
            ids <- unique(as.character(id.vec[at]))
            cr0 <- as.integer(id.to.row[ids]); cr0 <- cr0[is.finite(cr0)]
          }
          cr <- setdiff(cr0, cs)
        } else {
          cs <- which(Delta == 1 & Tstop <= tk)
          cr <- which(Tstop > tk)
        }
        case.rows.by.k[[hh]] <- cs
        ctrl.rows.by.k[[hh]] <- cr
      }
      auc.mat    <- matrix(NA_real_, nrow = B, ncol = length(k.list))
      iauc.uno.v <- rep(NA_real_, B)
      iauc.std.v <- rep(NA_real_, B)
      if (isTRUE(verbose) && B > 0L) {
        t.start <- proc.time()[3]
        step    <- max(1L, floor(B / 10L))
        message("auct.rhf bootstrap (plug-in): starting ", B, " replicates...")
      }
      for (bb in seq_len(B)) {
        w <- tabulate(sample.int(Nsubj, Nsubj, replace = TRUE), nbins = Nsubj)
        km.b  <- survival::survfit(survival::Surv(Tstop, 1 - Delta) ~ 1, weights = w)
        km.tb <- c(0, km.b$time)
        km.sb <- c(1, km.b$surv)
        G.left.b <- function(t) {
          idx <- findInterval(t, km.tb, left.open = TRUE, rightmost.closed = TRUE)
          pmax(km.sb[pmax(idx, 1L)], eps)
        }
        A.vec <- rep(NA_real_, length(k.list))
        W.vec <- rep(NA_real_, length(k.list))
        for (hh in seq_along(k.list)) {
          k  <- k.list[hh]
          tk <- times[k]
          cs <- case.rows.by.k[[hh]]
          cr <- ctrl.rows.by.k[[hh]]
          n.case.eff <- sum(w[cs])
          n.ctrl.eff <- sum(w[cr])
          n.ctrl.min <- max(min.controls, ceiling(nfrac.controls * Nsubj))
          if (n.case.eff < min.cases || n.ctrl.eff < n.ctrl.min) {
            A.vec[hh] <- NA_real_; W.vec[hh] <- NA_real_
            next
          }
          sc.case <- rep(Z[cs, k], times = w[cs])
          sc.ctrl <- rep(Z[cr, k], times = w[cr])
          sc.ctrl.sorted <- sort(sc.ctrl)
          less.idx <- findInterval(sc.case, sc.ctrl.sorted,
                                   left.open = TRUE,  rightmost.closed = TRUE)
          leq.idx  <- findInterval(sc.case, sc.ctrl.sorted,
                                   left.open = FALSE, rightmost.closed = TRUE)
          n.less   <- less.idx
          n.equal  <- pmax(leq.idx - less.idx, 0L)
          A.k      <- mean((n.less + 0.5 * n.equal) / length(sc.ctrl))
          Gk.raw <- G.left.b(tk)
          Gk     <- max(Gk.raw %||% 0, g.floor)
          Wk     <- n.case.eff / (Gk^power + eps)
          A.vec[hh] <- A.k
          W.vec[hh] <- Wk
        }
        auc.mat[bb, ] <- A.vec
        ok.b <- is.finite(A.vec) & is.finite(W.vec) & W.vec > 0
        iauc.uno.v[bb] <- if (any(ok.b)) {
          sum(A.vec[ok.b] * W.vec[ok.b]) / sum(W.vec[ok.b])
        } else {
          NA_real_
        }
        tt <- times[k.list]
        ok.t <- is.finite(A.vec) & is.finite(tt)
        if (sum(ok.t) >= 2L) {
          num <- sum((head(A.vec[ok.t], -1L) + tail(A.vec[ok.t], -1L)) *
                     diff(tt[ok.t]) / 2)
          den <- max(tt[ok.t]) - min(tt[ok.t])
          iauc.std.v[bb] <- if (is.finite(den) && den > 0) num / den else NA_real_
        } else {
          iauc.std.v[bb] <- NA_real_
        }
        if (isTRUE(verbose) && B > 0L) {
          step <- max(1L, floor(B / 10L))
          if (bb == 1L || bb %% step == 0L || bb == B) {
            t.now   <- proc.time()[3]
            elapsed <- t.now - t.start
            rate    <- elapsed / bb
            remain  <- max(0, rate * (B - bb))
            message(sprintf("  [auct.rhf] plug-in bootstrap %d/%d  elapsed=%.1fs  approx.remaining=%.1fs", bb, B, elapsed, remain))
          }
        }
      }
      auc.se <- apply(auc.mat, 2L, stats::sd, na.rm = TRUE)
      se.full <- rep(NA_real_, nrow(A))
      kk <- match(times[k.list], A$time)
      se.full[kk] <- auc.se
      iauc.uno.se <- stats::sd(iauc.uno.v, na.rm = TRUE)
      iauc.std.se <- stats::sd(iauc.std.v, na.rm = TRUE)
      auc.lower <- auc.upper <- NULL
      if (is.finite(bootstrap.conf) && !is.na(bootstrap.conf) &&
          bootstrap.conf > 0 && bootstrap.conf < 1) {
        zc <- stats::qnorm((1 + bootstrap.conf) / 2)
        auc.lower <- A$AUC - zc * se.full
        auc.upper <- A$AUC + zc * se.full
      }
      boot <- list(
        AUC.se       = se.full,
        iAUC.uno.se  = iauc.uno.se,
        iAUC.std.se  = iauc.std.se,
        conf.level   = bootstrap.conf,
        AUC.lower    = auc.lower,
        AUC.upper    = auc.upper,
        rep          = bootstrap.rep,
        mode         = "plug-in"
      )
    }
  }
  structure(list(
    AUC.by.time  = A,
    iAUC.uno     = iAUC.uno,
    iAUC.std     = iAUC.std,
    boot         = boot,
    marker       = marker,
    method       = method,
    riskset      = riskset,
    power        = power,
    g.floor      = g.floor,
    g.floor.q    = g.floor.q,
    winsor.q     = winsor.q,
    times        = times,
    diag.riskset = diag.riskset,
    cumulative.marker = if (is.null(cumulative.marker)) NULL else cumulative.marker$diagnostic,
    incident.marker = if (is.null(incident.marker)) NULL else incident.marker$diagnostic
  ), class = "auct.rhf")
}
auct <- auct.rhf
##########################################################################
##
## Model-agnostic core: AUC(t) + iAUC for counting-process data
##
##########################################################################
.tdc_auct_core <- function(times,
                           Z,
                           YY,
                           method        = c("cumulative", "incident"),
                           riskset       = c("subject", "record"),
                           min.controls  = 25,
                           nfrac.controls = 0.10,
                           min.cases     = 1,
                           g.floor       = 0.10,
                           g.floor.q     = NULL,
                           power         = 2,
                           winsor.q      = NULL,
                           eps           = 1e-12) {
  method  <- match.arg(method)
  riskset <- match.arg(riskset)
  ## basic checks
  if (is.null(times) || !length(times))
    stop("AUC core: 'times' must be a non-empty numeric vector.")
  if (!is.numeric(times))
    stop("AUC core: 'times' must be numeric.")
  if (!is.matrix(Z))
    stop("AUC core: 'Z' must be a matrix.")
  if (ncol(Z) != length(times))
    stop("AUC core: ncol(Z) must equal length(times).")
  needed <- c("id", "start", "stop", "event")
  if (!all(needed %in% names(YY)))
    stop("AUC core: 'YY' must contain columns: id, start, stop, event.")
  ## canonical y-data
  YY <- YY[, needed]
  YY$id <- as.character(YY$id)
  ## --- last record per subject (event/censor time) ---
  last <- YY[!duplicated(YY$id, fromLast = TRUE), , drop = FALSE]
  ## subject order: prefer rownames(Z) if present
  rn <- rownames(Z)
  if (!is.null(rn) && length(rn) == nrow(Z)) {
    subj.order <- as.character(rn)
  } else {
    subj.order <- as.character(YY$id[!duplicated(YY$id)])
  }
  last <- last[match(subj.order, last$id), , drop = FALSE]
  if (anyNA(last$id))
    stop("Cannot align subjects between predictions and outcomes.")
  Tstop <- last$stop
  Delta <- last$event
  ## subject entry time (for riskset = 'subject')
  entry <- tapply(YY$start, YY$id, min)
  entry <- entry[match(subj.order, names(entry))]
  Nsubj     <- nrow(Z)
  nmin.ctrl <- max(min.controls, ceiling(nfrac.controls * Nsubj))
  id.to.row <- stats::setNames(seq_len(Nsubj), subj.order)
  ## --- event-to-grid mapping for incident evaluation ---
  maxT  <- max(times, na.rm = TRUE)
  ev.idx <- which(Delta == 1 & Tstop <= maxT)
  if (!length(ev.idx))
    stop("No events within the evaluation grid.")
  ## nearest-right grid index k for each event time
  k.of.ev <- vapply(Tstop[ev.idx],
                    function(s) which(times >= s)[1L],
                    integer(1L))
  by.k   <- split(ev.idx, k.of.ev)
  k.list <- sort(as.integer(names(by.k)))
  k.list <- k.list[!is.na(k.list)]
  ## --- OPTIONAL aggregation for incident AUC: time windows with >= min.cases events ---
  ## This only activates for method = "incident" and min.cases > 1.
  if (identical(method, "incident") && is.finite(min.cases) && min.cases > 1L) {
    k.vec <- k.list
    if (length(k.vec)) {
      ## number of events at each k
      ev.per.k <- vapply(k.vec,
                         function(kk) length(by.k[[as.character(kk)]]),
                         integer(1L))
      total.ev <- sum(ev.per.k)
      if (total.ev > 0L) {
        blocks    <- list()
        start.pos <- 1L
        while (start.pos <= length(k.vec)) {
          cum.ev  <- 0L
          end.pos <- start.pos
          while (end.pos <= length(k.vec) && cum.ev < min.cases) {
            cum.ev  <- cum.ev + ev.per.k[end.pos]
            end.pos <- end.pos + 1L
          }
          if (cum.ev == 0L)
            break
          ## indices in k.vec that belong to this block
          idx.seq <- start.pos:(end.pos - 1L)
          ## If this is the last chunk and still < min.cases, merge into previous block
          if (cum.ev < min.cases && length(blocks) > 0L && end.pos > length(k.vec)) {
            blocks[[length(blocks)]]$k_idx <-
              c(blocks[[length(blocks)]]$k_idx, k.vec[idx.seq])
            break
          } else {
            block.k <- k.vec[idx.seq]
            blocks[[length(blocks) + 1L]] <- list(
              eval_k = block.k[1L],  ## evaluate at the earliest time in the block
              k_idx  = block.k       ## but include events from all these k's
            )
            start.pos <- end.pos
          }
        }
        if (length(blocks)) {
          ## rebuild k.list and by.k based on blocks
          new.k.list <- vapply(blocks, function(b) b$eval_k, integer(1L))
          new.by.k   <- vector("list", length(blocks))
          names(new.by.k) <- as.character(new.k.list)
          for (bb in seq_along(blocks)) {
            kk.seq <- blocks[[bb]]$k_idx
            idxs   <- unlist(by.k[as.character(kk.seq)], use.names = FALSE)
            ## just in case, drop duplicates
            new.by.k[[bb]] <- unique(idxs)
          }
          k.list <- new.k.list
          by.k   <- new.by.k
        }
      }
    }
  }
  ## --- KM IPCW (left-continuous) and optional floor augmentation ---
  km.fit <- survival::survfit(survival::Surv(Tstop, 1 - Delta) ~ 1)
  km.t   <- c(0, km.fit$time)
  km.s   <- c(1, km.fit$surv)
  G.left <- function(t) {
    idx <- findInterval(t, km.t, left.open = TRUE, rightmost.closed = TRUE)
    pmax(km.s[pmax(idx, 1L)], eps)
  }
  if (!is.null(g.floor.q)) {
    G.grid  <- vapply(times, G.left, numeric(1L))
    g.floor <- max(g.floor,
                   stats::quantile(G.grid, probs = g.floor.q,
                                   na.rm = TRUE))
  }
  ## --- loop over evaluation times and compute AUC(t) + weights ---
  res <- vector("list", length(k.list))
  names(res) <- k.list
  ## vectors used for record riskset
  start.vec <- YY$start
  stop.vec  <- YY$stop
  id.vec    <- YY$id
  for (hh in seq_along(k.list)) {
    k  <- k.list[hh]
    tk <- times[k]
    if (method == "incident") {
      ## Cases: fail at tk (mapped event-time index k.list)
      case.ids  <- subj.order[ by.k[[as.character(k)]] ]
      case.rows <- as.integer(id.to.row[case.ids])
      case.rows <- case.rows[is.finite(case.rows)]
      ## Controls: at risk at tk
      if (riskset == "subject") {
        ctrl.rows <- which(entry < tk & Tstop >= tk)
        ctrl.rows <- setdiff(ctrl.rows, case.rows)
      } else {
        at.risk.rows <- which(start.vec < tk & stop.vec >= tk)
        ctrl.ids     <- setdiff(unique(as.character(id.vec[at.risk.rows])),
                                case.ids)
        ctrl.rows    <- as.integer(id.to.row[ctrl.ids])
        ctrl.rows    <- ctrl.rows[is.finite(ctrl.rows)]
      }
    } else {  ## cumulative/dynamic
      ## Cases: failed by tk (T.i <= tk, Delta.i = 1)
      case.rows <- which(Delta == 1 & Tstop <= tk)
      ## Controls: event-free at tk (T.i > tk)
      ctrl.rows <- which(Tstop > tk)
      ## (Riskset ignored here by design.)
    }
    n.cases    <- length(case.rows)
    n.ctrl.raw <- length(ctrl.rows)
    if (n.cases < min.cases || n.ctrl.raw < nmin.ctrl) {
      res[[hh]] <- data.frame(time    = tk,
                              AUC     = NA_real_,
                              n.cases = n.cases,
                              n.ctrl  = n.ctrl.raw,
                              G       = NA_real_,
                              W       = NA_real_)
      next
    }
    sc.case <- Z[case.rows, k]
    sc.case <- sc.case[is.finite(sc.case)]
    sc.ctrl <- Z[ctrl.rows, k]
    sc.ctrl <- sc.ctrl[is.finite(sc.ctrl)]
    n.ctrl  <- length(sc.ctrl)
    if (!length(sc.case) || n.ctrl < nmin.ctrl) {
      res[[hh]] <- data.frame(time    = tk,
                              AUC     = NA_real_,
                              n.cases = length(sc.case),
                              n.ctrl  = n.ctrl,
                              G       = NA_real_,
                              W       = NA_real_)
      next
    }
    ## Unweighted within-time AUC with 0.5 for ties
    sc.ctrl.sorted <- sort(sc.ctrl)
    less.idx <- findInterval(sc.case, sc.ctrl.sorted,
                             left.open = TRUE,  rightmost.closed = TRUE)
    leq.idx  <- findInterval(sc.case, sc.ctrl.sorted,
                             left.open = FALSE, rightmost.closed = TRUE)
    n.less   <- less.idx
    n.equal  <- pmax(leq.idx - less.idx, 0L)
    AUC.k    <- mean((n.less + 0.5 * n.equal) / n.ctrl)
    ## Uno-style time weight using KM IPCW (stabilized)
    Gk.raw <- G.left(tk)
    Gk     <- max(Gk.raw %||% 0, g.floor)
    Wk     <- length(sc.case) / (Gk^power + eps)
    res[[hh]] <- data.frame(time    = tk,
                            AUC     = AUC.k,
                            n.cases = length(sc.case),
                            n.ctrl  = n.ctrl,
                            G       = Gk.raw,
                            W       = Wk)
  }
  A <- do.call(rbind, res)
  ## optional winsorization of time weights
  if (!is.null(winsor.q) && is.numeric(winsor.q) &&
      length(winsor.q) == 1L &&
      winsor.q > 0 && winsor.q < 1 &&
      "W" %in% names(A)) {
    cap <- stats::quantile(A$W, probs = winsor.q,
                           na.rm = TRUE, names = FALSE)
    A$W <- pmin(A$W, cap)
  }
  ## iAUC (Uno-style time weighting)
  ok <- is.finite(A$AUC) & is.finite(A$W) & A$W > 0
  iAUC.uno <- if (any(ok)) {
    sum(A$AUC[ok] * A$W[ok]) / sum(A$W[ok])
  } else {
    NA_real_
  }
  ## time-standardized mean of AUC(t)
  iAUC.std <- .rhf.trapz.std(A$time, A$AUC)
  ## ---------- risk-set diagnostic: subject vs record ----------
  diag.riskset <- NULL
  {
    J <- min(5L, max(1L, floor(length(times) / 10)))
    idx.sel <- unique(pmax(1L,
                           pmin(length(times),
                                round(stats::quantile(seq_along(times),
                                                      probs = seq(0.2, 0.8,
                                                                  length.out = J),
                                                      names = FALSE)))))
    t.sel <- times[idx.sel]
    subj.ctrl.ct <- integer(length(t.sel))
    rec.ctrl.ct  <- integer(length(t.sel))
    n.diff       <- integer(length(t.sel))
    for (j in seq_along(t.sel)) {
      t0 <- t.sel[j]
      ## subject-level controls
      ctrl.subj <- which(entry < t0 & Tstop >= t0)
      ## record-level controls
      at       <- which(start.vec < t0 & stop.vec >= t0)
      ctrl.ids <- unique(as.character(id.vec[at]))
      ctrl.rec <- as.integer(id.to.row[ctrl.ids])
      ctrl.rec <- ctrl.rec[is.finite(ctrl.rec)]
      subj.ctrl.ct[j] <- length(ctrl.subj)
      rec.ctrl.ct[j]  <- length(unique(ctrl.rec))
      n.diff[j]       <- length(setdiff(ctrl.subj, ctrl.rec)) +
                         length(setdiff(ctrl.rec,  ctrl.subj))
    }
    prop.diff <- if (length(t.sel)) mean(n.diff > 0) else NA_real_
    diag.riskset <- list(
      times              = t.sel,
      n.ctrl.subject     = subj.ctrl.ct,
      n.ctrl.record      = rec.ctrl.ct,
      n.diff             = n.diff,
      prop.times.different = prop.diff
    )
  }
  structure(list(
    AUC.by.time = A,
    iAUC.uno    = iAUC.uno,
    iAUC.std    = iAUC.std,
    diag.riskset = diag.riskset,
    times       = times,
    g.floor     = g.floor,
    aux = list(
      Tstop      = Tstop,
      Delta      = Delta,
      entry      = entry,
      subj.order = subj.order,
      id.to.row  = id.to.row,
      start.vec  = start.vec,
      stop.vec   = stop.vec,
      id.vec     = id.vec,
      Nsubj      = Nsubj,
      k.list     = k.list,
      by.k       = by.k
    )
  ), class = "auct.rhf")
}
##########################################################################
##
## Plot method
##
##########################################################################
plot.auct.rhf <- function(x,
                          bass = 10,
                          xlab = "Time",
                          ylab = NULL,
                          main = NULL,
                          ylim = NULL,
                          pch = 16,
                          alpha = .05,
                          ...) {
  A <- x$AUC.by.time
  ylab <- ylab %||% "AUC(t) [KM-IPCW]"
  ttl  <- paste0("Time-varying AUC(t) - ", x$method, ", marker=", x$marker)
  main <- main %||% ttl
  if (is.null(ylim)) {
    y <- A$AUC
    ymin <- suppressWarnings(min(y[is.finite(y)], na.rm = TRUE))
    ymax <- suppressWarnings(max(y[is.finite(y)], na.rm = TRUE))
    ylim <- if (is.finite(ymax) & is.finite(ymin)) c(ymin * .95, ymax * 1.05) else c(0, 1)
  }
  keep <- !is.na(A$AUC)
  plot(A$time[keep], A$AUC[keep], pch = pch, xlab = xlab, ylab = ylab, main = main, ylim = ylim, ...)
  ok <- is.finite(A$time) & is.finite(A$AUC)
  if (sum(ok) >= 5L) {
    sm <- stats::supsmu(A$time[ok], A$AUC[ok], bass = bass)
    lines(sm, lwd = 2)
  }
  ## optional bootstrap SE ribbon (base R polygon)
  if (!is.null(x$boot) && !is.null(x$boot$AUC.se)) {
    yhat <- A$AUC
    se   <- x$boot$AUC.se
    if (!is.null(x$boot$AUC.lower) && !is.null(x$boot$AUC.upper)) {
      yl <- x$boot$AUC.lower; yu <- x$boot$AUC.upper
    } else {
      zc <- stats::qnorm(1 - min(alpha/2, .5))
      yl <- yhat - zc * se
      yu <- yhat + zc * se
    }
    okb <- is.finite(A$time) & is.finite(yl) & is.finite(yu)
    if (sum(okb) >= 2L) {
      xt <- A$time[okb]
      polygon(c(xt, rev(xt)), c(yl[okb], rev(yu[okb])),
              border = NA, col = grDevices::adjustcolor("gray", alpha.f = 0.25))
      points(A$time[keep], A$AUC[keep], pch = pch)
    }
  }
}
##########################################################################
##
## Print method (right-justified; aligned colon incl. quantiles) 
##
##########################################################################
print.auct.rhf <- function(x, digits = 4, max.rows = 8, ...) {
  stopifnot(inherits(x, "auct.rhf"))
  A    <- x$AUC.by.time
  K    <- nrow(A)
  K.ok <- sum(is.finite(A$AUC))
  tr   <- range(x$times, na.rm = TRUE)
  fnum <- function(v) {
    if (is.numeric(v) && length(v) == 1L && is.finite(v)) {
      formatC(v, digits = digits, format = "f")
    } else {
      "NA"
    }
  }
  method <- if (!is.null(x$method)) x$method else x$definition
  riskln <- if (identical(method, "cumulative")) "ignored" else x$riskset
  main.labels <- c(
    "Method",
    "Marker",
    "Riskset",
    "Grid points (evaluated)",
    "Time range",
    "iAUC.uno",
    "iAUC.std (mean over time)",
    "IPCW"
  )
  main.values <- c(
    method,
    x$marker,
    riskln,
    sprintf("%d (%d with finite AUC)", K, K.ok),
    sprintf("[%.6g, %.6g]", tr[1], tr[2]),
    fnum(x$iAUC.uno),
    fnum(x$iAUC.std),
    paste0("KM  floor=", x$g.floor,
           if (!is.null(x$g.floor.q)) paste0(" (q=", x$g.floor.q, ")") else "",
           ", power=", x$power,
           if (!is.null(x$winsor.q)) paste0(", winsor.q=", x$winsor.q) else "")
  )
  q.label <- "AUC(t) quantiles (10%, 50%, 90%)"
  all.labels <- if (K.ok > 0) c(main.labels, q.label) else main.labels
  w <- max(nchar(all.labels), 0L)
  out <- "RHF time-varying AUC"
  for (i in seq_along(main.labels)) {
    out <- c(out, sprintf("  %*s : %s", w, main.labels[i], main.values[i]))
  }
  if (K.ok > 0) {
    yy <- A$AUC[is.finite(A$AUC)]
    qs <- stats::quantile(yy, probs = c(0.1, 0.5, 0.9), na.rm = TRUE, names = FALSE)
    out <- c(out,
             sprintf("  %*s : %s",
                     w, q.label, paste(formatC(qs, digits = digits, format = "f"), collapse = ", ")))
  }
  ## optional diagnostic summary
  if (!is.null(x$diag.riskset)) {
    dr <- x$diag.riskset
    if (is.list(dr) && length(dr$times)) {
      out <- c(
        out,
        sprintf(
          "  Risk-set diagnostic: subject vs record differ at %d/%d times (%.2f), median |Delta-ctrl| = %d",
          sum(dr$n.diff > 0), length(dr$times),
          if (is.finite(dr$prop.times.different)) dr$prop.times.different else NA_real_,
          stats::median(dr$n.diff, na.rm = TRUE)
        )
      )
    }
  }
  message(paste(out, collapse = "\n"))
  ## optional small table preview: finite-AUC rows only (safe printing)
  if (K.ok > 0 && max.rows > 0) {
    cols <- intersect(c("time","AUC","n.cases","n.ctrl","G","W"), colnames(A))
    A.show <- A[is.finite(A$AUC), cols, drop = FALSE]
    A.show <- head(A.show, max.rows)
    message("\nAUC(t) by time (head):")
    if (nrow(A.show) > 0) {
      print.data.frame(
        as.data.frame(lapply(A.show, function(col)
          if (is.numeric(col)) signif(col, digits) else col)),
        row.names = FALSE
      )
      message(" ..... ")
    } else {
      message("  (no finite AUC rows to display)")
    }
  }
  ## optional bootstrap information
  if (!is.null(x$boot)) {
    mode.txt <- if (!is.null(x$boot$mode)) x$boot$mode else "pointwise"
    se.txt <- paste0("iAUC.uno.se = ", fnum(x$boot$iAUC.uno.se),
                     ", iAUC.std.se = ", fnum(x$boot$iAUC.std.se),
                     " (B = ", as.integer(x$boot$rep), ")")
    message(sprintf("  %*s : %s", w, paste0("Bootstrap (", mode.txt, ")"), se.txt))
  }
  invisible(x)
}
##########################################################################
##
## RHF cumulative/dynamic AUC marker
##
## Public hazard.* and chf.* outputs obey the supplied subject path.  A
## cumulative/dynamic comparison at time t instead requires the requested
## marker at that same t for cases who failed before t and controls who remain
## event-free at t.  RHF historically supplied the pointwise fitted aggregate
## of the corresponding raw tree array.  Reconstruct that full-grid marker
## only for AUC; never replace or modify the public path-domain outputs.
##
##########################################################################
.rhf.auct.cumulative.marker <- function(object, marker, ensemble, keep.time) {
  marker <- match.arg(marker, c("cumhaz", "hazard"))
  tree.prefix <- if (identical(marker, "cumhaz")) "chf.tree." else "hazard.tree."
  tree.name <- paste0(tree.prefix, ensemble)
  tree <- object[[tree.name]]
  tree.dim <- dim(tree)
  if (is.null(tree) || length(tree.dim) != 3L) {
    stop(
      "Cumulative/dynamic AUC with marker = '", marker,
      "' requires the retained raw tree array `", tree.name, "`. ",
      "The public path-domain marker is not a common-time cumulative-AUC marker.",
      call. = FALSE
    )
  }
  if (length(keep.time) != tree.dim[[2L]]) {
    stop("The AUC tree-marker array does not match time.interest.",
         call. = FALSE)
  }
  options <- .rhf.auct.aggregation.options(object)
  if (is.null(options)) {
    stop(
      "Unable to resolve the fitted RHF ensemble aggregation rule for cumulative AUC.",
      call. = FALSE
    )
  }
  kept <- which(keep.time)
  answer <- matrix(
    NA_real_,
    nrow = tree.dim[[1L]],
    ncol = length(kept),
    dimnames = list(
      if (!is.null(dimnames(tree))) dimnames(tree)[[1L]] else NULL,
      if (!is.null(dimnames(tree))) dimnames(tree)[[2L]][kept] else NULL
    )
  )
  for (i in seq_len(tree.dim[[1L]])) {
    for (jj in seq_along(kept)) {
      k <- kept[[jj]]
      answer[i, jj] <- .rhf.auct.aggregate(tree[i, k, ], options)
    }
  }
  list(
    marker = answer,
    diagnostic = list(
      marker = marker,
      ensemble = ensemble,
      source = tree.name,
      aggregate = options$rule,
      trim = options$trim,
      full.grid = TRUE
    )
  )
}
##########################################################################
##
## RHF incident-hazard marker restoration
##
## Public hazard matrices are NA outside each subject's path. For an off-grid
## terminal event in (t[k-1], t[k]), this correctly makes the public pointwise
## value at t[k] unavailable, but incident AUC still needs the pre-mask
## interval hazard for that event case.
##
## Restoration uses the raw tree-specific hazard array and the fitted
## ensemble aggregation rule. This directly recovers the same pre-mask
## subject-by-time aggregate that was finalized into the public hazard matrix.
## Only missing incident-case cells are restored; controls and every other
## out-of-domain value retain the public NA mask.
##
##########################################################################
.rhf.incident.valid.ids <- function(x, n = NULL) {
  if (is.null(x)) return(FALSE)
  x <- as.character(x)
  if (!is.null(n) && length(x) != n) return(FALSE)
  length(x) > 0L && !anyNA(x) && !anyDuplicated(x) && all(nzchar(x))
}
.rhf.auct.subject.ids <- function(object, Z, YY) {
  Z <- as.matrix(Z)
  outcome.ids <- as.character(YY$id)
  outcome.order <- outcome.ids[!duplicated(outcome.ids)]
  candidates <- list(
    ensemble.id = object$ensemble.id,
    marker.rownames = rownames(Z),
    outcome.order = outcome.order
  )
  for (source in names(candidates)) {
    ids <- candidates[[source]]
    if (!.rhf.incident.valid.ids(ids, nrow(Z))) next
    ids <- as.character(ids)
    if (all(ids %in% outcome.order)) {
      return(list(ids = ids, source = source))
    }
  }
  stop(
    "Unable to align the RHF marker matrix with the outcome subjects. ",
    "Expected ", nrow(Z), " unique marker-row IDs and found ",
    length(outcome.order), " unique outcome IDs.",
    call. = FALSE
  )
}
.rhf.auct.aggregation.options <- function(object) {
  config <- object$hazard.config
  if (!is.list(config) &&
      is.list(object$forest) &&
      is.list(object$forest$parms)) {
    config <- object$forest$parms$hazard.config
  }
  if (!is.list(config)) return(NULL)
  estimator <- config$hazard.estimator
  if (!is.null(estimator) && length(estimator) &&
      identical(as.character(estimator[[1L]]), "NA")) {
    return(list(rule = "mean", trim = NA_real_, estimator = "NA"))
  }
  rule <- config$coe.aggregate.selected
  if (is.null(rule) || !length(rule) || is.na(rule[[1L]])) {
    rule <- config$coe.aggregate
  }
  if (is.null(rule) || !length(rule) || is.na(rule[[1L]])) return(NULL)
  rule <- as.character(rule[[1L]])
  trim.index <- suppressWarnings(as.integer(config$coe.trim.index)[1L])
  if (!is.na(trim.index) && trim.index == 0L) rule <- "median"
  if (!(rule %in% c("trimmed.mean", "median", "mean"))) return(NULL)
  trim <- NA_real_
  if (identical(rule, "trimmed.mean")) {
    selected <- suppressWarnings(as.double(config$coe.trim.selected)[1L])
    if (is.finite(selected)) {
      trim <- selected
    } else {
      grid <- suppressWarnings(as.double(config$coe.trim))
      if (!is.na(trim.index) &&
          trim.index >= 1L &&
          trim.index <= length(grid) &&
          is.finite(grid[[trim.index]])) {
        trim <- grid[[trim.index]]
      } else if (length(grid) == 1L && is.finite(grid[[1L]])) {
        trim <- grid[[1L]]
      }
    }
    if (!is.finite(trim) || trim < 0 || trim > 0.5) return(NULL)
    ## The 0.50 endpoint is the exact median under the RHF aggregation
    ## contract, regardless of whether it arrived through a scalar or a
    ## selected candidate value.
    if (trim >= 0.5) {
      rule <- "median"
      trim <- NA_real_
    }
  }
  list(rule = rule, trim = trim, estimator = "COE")
}
.rhf.auct.aggregate <- function(value, options) {
  value <- as.double(value)
  value <- value[is.finite(value)]
  if (!length(value) || is.null(options)) return(NA_real_)
  if (identical(options$rule, "median")) {
    return(stats::median(value))
  }
  if (identical(options$rule, "mean")) {
    return(mean(value))
  }
  trim <- options$trim
  if (!is.finite(trim) || trim < 0 || trim > 0.5) return(NA_real_)
  if (trim <= 0) return(mean(value))
  cutpoint <- stats::quantile(
    value,
    probs = c(trim, 1 - trim),
    type = 8,
    names = FALSE,
    na.rm = TRUE
  )
  mean(pmin(pmax(value, cutpoint[[1L]]), cutpoint[[2L]]))
}
.rhf.incident.restore.from.trees <- function(object, Z, ensemble,
                                             event.subject, event.cell,
                                             missing, keep.time) {
  restored <- rep(FALSE, length(missing))
  if (!any(missing)) return(list(marker = Z, restored = restored))
  tree <- object[[paste0("hazard.tree.", ensemble)]]
  options <- .rhf.auct.aggregation.options(object)
  tree.dim <- dim(tree)
  kept.cell <- which(keep.time)
  if (is.null(tree) ||
      length(tree.dim) != 3L ||
      tree.dim[[1L]] != nrow(Z) ||
      tree.dim[[2L]] != length(keep.time) ||
      length(kept.cell) != ncol(Z) ||
      is.null(options)) {
    return(list(marker = Z, restored = restored))
  }
  ## Do not subset the complete subject-by-time-by-tree array. Only the
  ## event-case vectors are touched, which keeps this path practical for large
  ## forests and large longitudinal cohorts.
  for (j in which(missing)) {
    i <- event.subject[[j]]
    k <- event.cell[[j]]
    full.k <- kept.cell[[k]]
    value <- .rhf.auct.aggregate(tree[i, full.k, ], options)
    if (is.finite(value)) {
      Z[i, k] <- value
      restored[[j]] <- TRUE
    }
  }
  list(marker = Z, restored = restored)
}
.rhf.restore.incident.hazard.cases <- function(object, Z, YY, times,
                                               keep.time,
                                               ensemble,
                                               subject.ids = NULL,
                                               alignment.source = NULL) {
  Z <- as.matrix(Z)
  if (!.rhf.incident.valid.ids(subject.ids, nrow(Z))) {
    alignment <- .rhf.auct.subject.ids(object, Z, YY)
    subject.ids <- alignment$ids
    alignment.source <- alignment$source
  }
  subject.ids <- as.character(subject.ids)
  rownames(Z) <- subject.ids
  last <- YY[!duplicated(as.character(YY$id), fromLast = TRUE), , drop = FALSE]
  last$id <- as.character(last$id)
  last <- last[match(subject.ids, last$id), , drop = FALSE]
  if (anyNA(last$id)) {
    stop("Cannot align incident-event outcomes with the RHF marker rows.",
         call. = FALSE)
  }
  event.subject <- which(
    last$event == 1 & last$stop <= max(times, na.rm = TRUE)
  )
  event.cell <- if (length(event.subject)) {
    vapply(
      last$stop[event.subject],
      function(value) {
        hit <- which(times >= value)
        if (length(hit)) hit[[1L]] else NA_integer_
      },
      integer(1L)
    )
  } else {
    integer(0L)
  }
  mapped <- !is.na(event.cell)
  event.subject <- event.subject[mapped]
  event.cell <- event.cell[mapped]
  if (!length(event.subject)) {
    return(list(
      marker = Z,
      diagnostic = list(
        ensemble = ensemble,
        alignment = alignment.source,
        events.in.grid = 0L,
        missing.before = 0L,
        restored = 0L,
        restored.by.tree = 0L,
        unavailable = 0L
      )
    ))
  }
  marker.index <- cbind(event.subject, event.cell)
  missing.before.vector <- !is.finite(Z[marker.index])
  missing.before <- sum(missing.before.vector)
  tree.restored <- rep(FALSE, length(missing.before.vector))
  if (missing.before > 0L) {
    tree.answer <- .rhf.incident.restore.from.trees(
      object = object,
      Z = Z,
      ensemble = ensemble,
      event.subject = event.subject,
      event.cell = event.cell,
      missing = missing.before.vector,
      keep.time = keep.time
    )
    Z <- tree.answer$marker
    tree.restored <- tree.answer$restored
  }
  missing.after <- !is.finite(Z[marker.index])
  list(
    marker = Z,
    diagnostic = list(
      ensemble = ensemble,
      alignment = alignment.source,
      events.in.grid = length(event.subject),
      missing.before = missing.before,
      restored = sum(missing.before.vector & !missing.after),
      restored.by.tree = sum(tree.restored),
      unavailable = sum(missing.after)
    )
  )
}
##########################################################################
##
## helpers
##
##########################################################################
`%||%` <- function(a, b) if (!is.null(a)) a else b
.rhf.trapz <- function(t, y) {
  o <- order(t); t <- t[o]; y <- y[o]
  ok <- is.finite(t) & is.finite(y)
  t <- t[ok]; y <- y[ok]
  if (length(t) < 2L) return(NA_real_)
  sum((head(y, -1L) + tail(y, -1L)) * diff(t) / 2)
}
.rhf.trapz.std <- function(t, y) {
  num <- .rhf.trapz(t, y)
  if (!is.finite(num)) return(NA_real_)
  den <- max(t, na.rm = TRUE) - min(t, na.rm = TRUE)
  if (!is.finite(den) || den <= 0) return(NA_real_)
  num / den
}
.rhf.unique.subject.order <- function(id) {
  id.char <- as.character(id)
  id.char[!duplicated(id.char)]
}
.rhf.slice_by_subject <- function(Z, subj.order, keep.ids) {
  if (!is.matrix(Z)) stop("Z must be a matrix.")
  idx <- match(keep.ids, subj.order)
  Z[idx, , drop = FALSE]
}
.rhf.bootstrap_once <- function(object, Z, YY, times, subj.order,
                                marker, method, riskset,
                                min.cases, min.controls, nfrac.controls,
                                g.floor, g.floor.q, power, winsor.q, eps) {
  o.tmp <- list(
    time.interest = times,
    id  = YY$id,
    yvar = as.matrix(YY[, c("start","stop","event")])
  )
  if (marker == "cumhaz") {
    o.tmp$chf.oob  <- Z
  } else {
    o.tmp$hazard.oob <- Z
  }
  class(o.tmp) <- c("rhf", "grow")
  auct.rhf(object = o.tmp, marker = marker, method = method, tau = max(times),
           riskset = riskset, min.controls = min.controls, nfrac.controls = nfrac.controls,
           min.cases = min.cases, g.floor = g.floor, g.floor.q = g.floor.q,
           power = power, ydata = YY, winsor.q = winsor.q, eps = eps,
           bootstrap.rep = 0L)
}
.rhf.build_data_from_object <- function(object) {
  if (is.null(object$id) || is.null(object$yvar) || is.null(object$xvar)) {
    stop("object must carry id, yvar, and xvar for bootstrap.refit.")
  }
  idv <- as.character(object$id)
  yv  <- as.data.frame(object$yvar)
  xv  <- as.data.frame(object$xvar)
  ## apply provided names if available
  if (!is.null(object$yvar.names) && length(object$yvar.names) >= 3L) {
    colnames(yv)[1:3] <- object$yvar.names[1:3]
  }
  ## standardize y names to start/stop/event
  colnames(yv)[1:3] <- c("start","stop","event")
  if (!is.null(object$xvar.names) && length(object$xvar.names) == ncol(xv)) {
    colnames(xv) <- object$xvar.names
  }
  data.frame(id = idv, yv[, c("start","stop","event")], xv, check.names = FALSE)
}
.rhf.align_auc_by_time <- function(src.time, src.auc, base.time) {
  ## align src AUC(t) to base.time via left-continuous step function
  idx <- findInterval(base.time, src.time, left.open = TRUE, rightmost.closed = TRUE)
  out <- rep(NA_real_, length(base.time))
  ok  <- idx >= 1 & idx <= length(src.time)
  out[ok] <- src.auc[idx[ok]]
  out
}
