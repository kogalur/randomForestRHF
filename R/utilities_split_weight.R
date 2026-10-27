########################################################################
## split weights for guided rule generation
##
## RHF analog of the split weight step in varpro().  Two screening
## components are combined as varPro combines them, with three
## deviations noted below:
##
##   lasso: penalized hazard regression on the counting process records
##          (piecewise exponential by default, Cox optional) with subject
##          level cross-validation folds.  The absolute standardized
##          coefficients at lambda.min define the component (varPro uses
##          lambda.1se, which discards weak signals that a screen should
##          keep).  Variables outside the lasso support receive zero.
##
##   tree:  split frequency from a shallow RHF grown with mtry = p and a
##          small best-first treesize.  This catches nonlinear and time
##          localized effects that the linear screen misses.
##
##   pilot: the previous xvar.wt.rhf() route.  A pilot RHF is grown, the
##          time-localized importance is summarized over time, and the
##          summary defines the component.  Kept as an option.
##
## Each component is scaled to a maximum of one and raised to the varPro
## dimension index of its support, evaluated on the support that survives
## the nvar cap (varPro uses the full support, which drives the power to
## 20 and collapses the weights onto one variable once 100 variables are
## split on).  With sparse = FALSE the power is one (varPro squares).
## The components are summed, the top nvar variables are retained, and
## every other variable receives weight zero.  Zero weight removes a
## variable from rule generation, which is what produces sparse
## importance output.
########################################################################
.rhf_dimension_index <- function(k) {
  k <- as.integer(k)[1L]
  if (!is.finite(k)) {
    return(2)
  }
  if (k >= 100L) {
    20
  }
  else if (k >= 50L) {
    10
  }
  else if (k >= 20L) {
    5
  }
  else {
    2
  }
}
.rhf_weight_tolerance <- function(w, tol = 1e-50) {
  ## varPro tolerance: keep weights from underflowing while preserving
  ## their order
  small <- w <= tol
  if (any(small)) {
    r <- rank(w[small], ties.method = "random")
    w[small] <- tol * r / max(r)
  }
  w
}
.rhf_subject_folds <- function(id, nfolds = 10L) {
  uid <- unique(id)
  n.subj <- length(uid)
  nfolds <- max(2L, min(as.integer(nfolds)[1L], n.subj))
  fold.subj <- sample(rep(seq_len(nfolds), length.out = n.subj))
  fold.subj[match(id, uid)]
}
.rhf_subject_subsample <- function(id, max.subjects = NULL) {
  uid <- unique(id)
  if (is.null(max.subjects) || length(uid) <= max.subjects) {
    return(rep(TRUE, length(id)))
  }
  keep <- sample(uid, as.integer(max.subjects)[1L])
  id %in% keep
}
.rhf_align_weights <- function(xvar.wt, xvar.names) {
  p <- length(xvar.names)
  if (!is.null(names(xvar.wt))) {
    matched <- intersect(names(xvar.wt), xvar.names)
    if (!length(matched)) {
      stop("Names of 'xvar.wt' do not match the predictors of the RHF object.")
    }
    w <- stats::setNames(numeric(p), xvar.names)
    w[matched] <- as.numeric(xvar.wt[matched])
  }
  else {
    if (length(xvar.wt) != p) {
      stop("Unnamed 'xvar.wt' must have one entry per predictor of the RHF object.")
    }
    w <- stats::setNames(as.numeric(xvar.wt), xvar.names)
  }
  if (any(!is.finite(w)) || any(w < 0)) {
    stop("'xvar.wt' must contain finite nonnegative values.")
  }
  w
}
########################################################################
## lasso component
##
## Two likelihoods are available.
##
##   poisson (default): piecewise exponential model.  Records are split
##     at lasso.ncut baseline cut points placed at quantiles of the
##     event times.  Each piece contributes a Poisson likelihood for its
##     event count with log exposure as offset, and the baseline pieces
##     enter as unpenalized indicators.  This is the standard Poisson
##     approximation to the Cox model, and it is also the penalized form
##     of the node-constant hazard working model used by RHF splitting.
##     glmnet fits it in compiled code.
##
##   cox: Cox partial likelihood on Surv(start, stop, event).  glmnet
##     fits start-stop data through an R-level iteration that runs an
##     order of magnitude slower than the poisson path, and cv.glmnet
##     fits it nfolds + 1 times.
########################################################################
.rhf_piecewise_records <- function(start, stopv, event, ncut = 10L) {
  n <- length(start)
  row <- seq_len(n)
  st <- as.numeric(start)
  sp <- as.numeric(stopv)
  ev <- as.numeric(event > 0)
  ncut <- as.integer(ncut)[1L]
  if (!is.finite(ncut) || ncut < 1L || !any(ev > 0)) {
    return(list(row = row, start = st, stop = sp, event = ev, piece = rep(1L, n)))
  }
  probs <- seq(0, 1, length.out = ncut + 1L)[-c(1L, ncut + 1L)]
  cuts <- sort(unique(stats::quantile(sp[ev > 0], probs = probs, names = FALSE)))
  cuts <- cuts[cuts > min(st) & cuts < max(sp)]
  for (cc in cuts) {
    i <- which(st < cc & sp > cc)
    if (length(i)) {
      ## right part (cc, sp] keeps the event, left part (st, cc] has none
      row <- c(row, row[i])
      st <- c(st, rep(cc, length(i)))
      sp <- c(sp, sp[i])
      ev <- c(ev, ev[i])
      sp[i] <- cc
      ev[i] <- 0
    }
  }
  piece <- findInterval(st, cuts) + 1L
  ord <- order(row, st)
  list(row = row[ord],
       start = st[ord],
       stop = sp[ord],
       event = ev[ord],
       piece = piece[ord])
}
.rhf_split_weight_lasso <- function(x,
                                    start,
                                    stopv,
                                    event,
                                    id,
                                    lasso.family = c("poisson", "cox"),
                                    lasso.ncut = 10L,
                                    lasso.s = c("lambda.min", "lambda.1se"),
                                    nfolds = 10L,
                                    maxit = 7500L,
                                    max.subjects = NULL,
                                    verbose = FALSE) {
  lasso.family <- match.arg(lasso.family)
  lasso.s <- match.arg(lasso.s)
  if (!requireNamespace("glmnet", quietly = TRUE)) {
    warning("Package 'glmnet' is required for the lasso split weight component; component skipped.")
    return(NULL)
  }
  t.start <- proc.time()[3L]
  rows <- .rhf_subject_subsample(id, max.subjects)
  ## both likelihoods require positive length intervals
  valid <- is.finite(start) & is.finite(stopv) & (stopv > start) & is.finite(event)
  rows <- rows & valid
  if (sum(rows) < 2L || !any(event[rows] > 0)) {
    if (isTRUE(verbose)) {
      message("[split.weight] lasso skipped: too few usable records or no events")
    }
    return(NULL)
  }
  p <- ncol(x)
  xm <- scale(data.matrix(x[rows, , drop = FALSE]))
  xm[!is.finite(xm)] <- 0
  attr(xm, "scaled:center") <- NULL
  attr(xm, "scaled:scale") <- NULL
  st <- as.numeric(start[rows])
  sp <- as.numeric(stopv[rows])
  ev <- as.numeric(event[rows] > 0)
  idv <- id[rows]
  if (lasso.family == "cox") {
    foldid <- .rhf_subject_folds(idv, nfolds)
    fit <- tryCatch(
      suppressWarnings(glmnet::cv.glmnet(xm, survival::Surv(st, sp, ev),
                                         family = "cox",
                                         foldid = foldid,
                                         maxit = maxit)),
      error = function(e) {
        if (isTRUE(verbose)) {
          message("[split.weight] Cox lasso failed: ", conditionMessage(e))
        }
        NULL
      })
    if (is.null(fit)) {
      return(NULL)
    }
    beta <- stats::coef(fit, s = lasso.s)[, 1L]
    beta <- beta[seq_len(p)]
  }
  else {
    pe <- .rhf_piecewise_records(st, sp, ev, ncut = lasso.ncut)
    xm <- xm[pe$row, , drop = FALSE]
    offset <- log(pe$stop - pe$start)
    penalty <- rep(1, p)
    n.piece <- length(unique(pe$piece))
    if (n.piece > 1L) {
      Z <- stats::model.matrix(~ factor(pe$piece))[, -1L, drop = FALSE]
      colnames(Z) <- paste0(".piece", seq_len(ncol(Z)))
      xm <- cbind(xm, Z)
      penalty <- c(penalty, rep(0, ncol(Z)))
    }
    foldid <- .rhf_subject_folds(idv[pe$row], nfolds)
    fit <- tryCatch(
      suppressWarnings(glmnet::cv.glmnet(xm, pe$event,
                                         family = "poisson",
                                         offset = offset,
                                         foldid = foldid,
                                         penalty.factor = penalty,
                                         maxit = maxit)),
      error = function(e) {
        if (isTRUE(verbose)) {
          message("[split.weight] Poisson lasso failed: ", conditionMessage(e))
        }
        NULL
      })
    if (is.null(fit)) {
      return(NULL)
    }
    ## drop the intercept and the baseline piece indicators
    beta <- stats::coef(fit, s = lasso.s)[-1L, 1L]
    beta <- beta[seq_len(p)]
  }
  w <- abs(as.numeric(beta))
  w[!is.finite(w)] <- 0
  names(w) <- colnames(x)
  if (isTRUE(verbose)) {
    message("[split.weight] ", lasso.family, " lasso (", lasso.s, ") retained ",
            sum(w > 0), " of ", p, " variables, elapsed ",
            .rhf_format_elapsed(proc.time()[3L] - t.start))
  }
  w
}
########################################################################
## shallow forest component
########################################################################
.rhf_split_weight_tree <- function(formula,
                                   data,
                                   xvar.names,
                                   ntree = 100L,
                                   treesize = NULL,
                                   nsplit = 10L,
                                   mtry = NULL,
                                   seed = NULL,
                                   verbose = FALSE) {
  p <- length(xvar.names)
  n.subj <- length(unique(data$id))
  if (is.null(treesize)) {
    treesize <- if (n.subj <= 200L) 4L else 8L
  }
  if (is.null(mtry)) {
    mtry <- p
  }
  t.start <- proc.time()[3L]
  ## Only the split structure of the trees is used.  Everything rhf()
  ## computes after tree growth is switched to its cheapest setting: a
  ## coarse time grid for the terminal node hazards, mean aggregation
  ## with a single trimming value in place of the adaptive search over
  ## trimming fractions, and no membership output.
  o.shallow <- tryCatch(
    rhf(formula, data,
        ntree = ntree,
        treesize = treesize,
        nsplit = nsplit,
        mtry = mtry,
        membership = FALSE,
        ntime = 5,
        adaptive = FALSE,
        coe.aggregate = "mean",
        seed = seed),
    error = function(e) {
      if (isTRUE(verbose)) {
        message("[split.weight] shallow RHF failed: ", conditionMessage(e))
      }
      NULL
    })
  if (is.null(o.shallow) || is.null(o.shallow$forest$nativeArray)) {
    return(NULL)
  }
  parm <- as.integer(o.shallow$forest$nativeArray$parmID)
  parm <- parm[!is.na(parm) & parm > 0L & parm <= p]
  used <- tabulate(parm, nbins = p)
  names(used) <- xvar.names
  if (isTRUE(verbose)) {
    message("[split.weight] shallow RHF split on ", sum(used > 0), " of ", p,
            " variables, elapsed ", .rhf_format_elapsed(proc.time()[3L] - t.start))
  }
  used
}
########################################################################
## pilot importance component (previous xvar.wt.rhf behavior)
########################################################################
.rhf_split_weight_pilot <- function(formula,
                                    data,
                                    xvar.names,
                                    ntree = 50L,
                                    rank.by = "q90",
                                    seed = NULL,
                                    verbose = FALSE) {
  t.start <- proc.time()[3L]
  o <- tryCatch(
    rhf(formula, data, ntree = ntree, seed = seed),
    error = function(e) {
      if (isTRUE(verbose)) {
        message("[split.weight] pilot RHF failed: ", conditionMessage(e))
      }
      NULL
    })
  if (is.null(o)) {
    return(NULL)
  }
  imp <- importance.rhf(o, verbose = verbose)$importance.matrix
  v <- .rhf_row_summary(imp, rank.by = rank.by)
  v[!is.finite(v)] <- 0
  v <- pmax(v, 0)
  out <- stats::setNames(numeric(length(xvar.names)), xvar.names)
  matched <- intersect(names(v), xvar.names)
  out[matched] <- v[matched]
  if (isTRUE(verbose)) {
    message("[split.weight] pilot importance screen done, elapsed ",
            .rhf_format_elapsed(proc.time()[3L] - t.start))
  }
  out
}
########################################################################
## engine
########################################################################
.rhf_split_weight <- function(x,
                              start,
                              stopv,
                              event,
                              id,
                              method = c("lasso", "tree"),
                              nvar = 30L,
                              sparse = TRUE,
                              ntree.reduce = 100L,
                              treesize.reduce = NULL,
                              nsplit.reduce = 10L,
                              mtry.reduce = NULL,
                              ntree.pilot = 50L,
                              rank.by = c("q90", "median", "mean", "max", "sum"),
                              lasso.family = c("poisson", "cox"),
                              lasso.ncut = 10L,
                              lasso.s = c("lambda.min", "lambda.1se"),
                              nfolds = 10L,
                              maxit = 7500L,
                              max.subjects = NULL,
                              tolerance = 1e-50,
                              seed = NULL,
                              verbose = FALSE) {
  method <- match.arg(method, c("lasso", "tree", "pilot"), several.ok = TRUE)
  rank.by <- match.arg(rank.by)
  lasso.family <- match.arg(lasso.family)
  lasso.s <- match.arg(lasso.s)
  t.start <- proc.time()[3L]
  if (!is.data.frame(x)) {
    x <- as.data.frame(x)
  }
  xvar.names <- colnames(x)
  p <- length(xvar.names)
  if (!p) {
    stop("No predictors supplied to the split weight calculation.")
  }
  if (length(start) != nrow(x) || length(stopv) != nrow(x) ||
      length(event) != nrow(x) || length(id) != nrow(x)) {
    stop("start, stop, event, and id must have one entry per record of x.")
  }
  if (!is.null(seed)) {
    set.seed(as.integer(seed)[1L])
  }
  n.subj <- length(unique(id))
  nvar <- as.integer(nvar)[1L]
  if (!is.finite(nvar) || nvar < 1L) {
    nvar <- p
  }
  ## The power sharpens a screen's weights.  With sparse = TRUE it is the
  ## varPro dimension index of the screen's support, evaluated on the
  ## support that survives the nvar cap: variables beyond nvar receive
  ## weight zero, so a larger support has no role in the final weights.
  ## With sparse = FALSE the scaled weights are used as they are.
  power <- function(k) {
    if (isTRUE(sparse)) .rhf_dimension_index(min(k, nvar)) else 1
  }
  w <- stats::setNames(numeric(p), xvar.names)
  raw <- list()
  add.component <- function(w, v, keep) {
    keep <- keep & is.finite(v) & (v > 0)
    if (!any(keep)) {
      return(w)
    }
    w[keep] <- w[keep] + (v[keep] / max(v[keep])) ^ power(sum(keep))
    w
  }
  ## counting process data frame used by the forest based components
  need.data <- any(c("tree", "pilot") %in% method)
  if (need.data) {
    reserved <- intersect(c("id", "start", "stop", "event"), xvar.names)
    if (length(reserved)) {
      stop("Predictor names clash with the reserved columns: ",
           paste(reserved, collapse = ", "))
    }
    data <- data.frame(id = id,
                       start = as.numeric(start),
                       stop = as.numeric(stopv),
                       event = as.numeric(event),
                       x,
                       check.names = FALSE,
                       stringsAsFactors = FALSE)
    formula <- stats::as.formula("Surv(id, start, stop, event) ~ .")
  }
  ## lasso component
  if ("lasso" %in% method) {
    v <- .rhf_split_weight_lasso(x = x,
                                 start = start,
                                 stopv = stopv,
                                 event = event,
                                 id = id,
                                 lasso.family = lasso.family,
                                 lasso.ncut = lasso.ncut,
                                 lasso.s = lasso.s,
                                 nfolds = nfolds,
                                 maxit = maxit,
                                 max.subjects = max.subjects,
                                 verbose = verbose)
    if (!is.null(v)) {
      raw$lasso <- v
      w <- add.component(w, v, v > 0)
    }
  }
  ## shallow forest component
  if ("tree" %in% method) {
    v <- .rhf_split_weight_tree(formula = formula,
                                data = data,
                                xvar.names = xvar.names,
                                ntree = ntree.reduce,
                                treesize = treesize.reduce,
                                nsplit = nsplit.reduce,
                                mtry = mtry.reduce,
                                seed = seed,
                                verbose = verbose)
    if (!is.null(v)) {
      raw$tree <- v
      cut <- if (n.subj >= 15000L) {
        stats::quantile(v, probs = 0.90, na.rm = TRUE)
      }
      else {
        1
      }
      keep <- v >= cut
      if (!any(keep & v > 0)) {
        keep <- seq_len(p) == which.max(v)
      }
      w <- add.component(w, v, keep)
    }
  }
  ## pilot importance component
  if ("pilot" %in% method) {
    v <- .rhf_split_weight_pilot(formula = formula,
                                 data = data,
                                 xvar.names = xvar.names,
                                 ntree = ntree.pilot,
                                 rank.by = rank.by,
                                 seed = seed,
                                 verbose = verbose)
    if (!is.null(v)) {
      raw$pilot <- v
      w <- add.component(w, v, v > 0)
    }
  }
  ## total failure: fall back to uniform weights and skip the cap, so the
  ## forest is unguided rather than restricted to an arbitrary subset.
  ## The status attribute reports this to the caller.
  failed <- all(w == 0)
  if (failed) {
    warning("No screen retained any variable (",
            paste(method, collapse = ", "),
            "); split weights are uniform and the forest is unguided.")
    w[] <- 1
  }
  ## retain the top nvar variables
  if (!failed && sum(w > 0) > nvar) {
    ord <- order(w, decreasing = TRUE)
    w[ord[-seq_len(nvar)]] <- 0
  }
  ## tolerance applies to the retained variables only
  pos <- w > 0
  w[pos] <- .rhf_weight_tolerance(w[pos], tolerance)
  if (isTRUE(verbose)) {
    message("[split.weight] retained ", sum(pos), " of ", p, " variables, total elapsed ",
            .rhf_format_elapsed(proc.time()[3L] - t.start))
  }
  attr(w, "raw") <- raw
  attr(w, "selected") <- xvar.names[pos]
  attr(w, "method") <- method
  attr(w, "nvar") <- nvar
  attr(w, "sparse") <- sparse
  attr(w, "status") <- if (failed) "failed" else "ok"
  w
}
########################################################################
## public helper: split weights from a formula and data
## (replaces the previous xvar.wt.rhf in utilities_importance.R)
########################################################################
xvar.wt.rhf <- function(f,
                        d,
                        method = c("lasso", "tree"),
                        nvar = 30L,
                        sparse = TRUE,
                        guided.args = list()) {
  if (!is.list(guided.args)) {
    stop("'guided.args' must be a named list.")
  }
  if (length(guided.args)) {
    nm <- names(guided.args)
    if (is.null(nm) || anyNA(nm) || any(!nzchar(nm))) {
      stop("All elements of 'guided.args' must be named.")
    }
    bad <- intersect(nm, c("x", "start", "stopv", "event", "id",
                           "method", "nvar", "sparse"))
    if (length(bad)) {
      stop("'guided.args' cannot contain: ", paste(bad, collapse = ", "))
    }
  }
  ## same input normalization as rhf(): Surv(time, event) input is
  ## converted to one interval per subject
  input <- .rhf.prepare.input(f, d)
  data <- input$data
  formula.detail <- finalize.formula(
    parse.formula(stats::as.formula(input$formula), data, NULL),
    data
  )
  xvar.names <- formula.detail$xvar.names
  yvar.names <- formula.detail$yvar.names
  subj.names <- formula.detail$subj.names
  if (!identical(formula.detail$family, "surv-tdc")) {
    stop("xvar.wt.rhf() only works for counting process survival formulas.")
  }
  if (length(yvar.names) < 3L || length(subj.names) < 1L) {
    stop("The formula must identify id, start, stop, and event variables.")
  }
  args <- c(
    list(x = data[, xvar.names, drop = FALSE],
         start = as.numeric(data[[yvar.names[1L]]]),
         stopv = as.numeric(data[[yvar.names[2L]]]),
         event = as.numeric(data[[yvar.names[3L]]]),
         id = data[[subj.names[1L]]],
         method = method,
         nvar = nvar,
         sparse = sparse),
    guided.args
  )
  do.call(.rhf_split_weight, args)
}
