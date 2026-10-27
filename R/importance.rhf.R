########################################################################
## guided rule forest
########################################################################
.rhf_is_guided <- function(o) {
  w <- o$forest$parms$xvar.wt
  if (is.null(w) || length(w) < 2L) {
    return(FALSE)
  }
  any(w == 0) || length(unique(as.numeric(w))) > 1L
}
## Grow the internal rule forest used by the guided analysis.  The forest
## is grown on the retained variables only, with the split weights as
## xvar.wt, on the same records, the same time grid, and the same tree
## settings as the user's forest.  Only ntree differs: the rule forest
## needs max.tree trees because rule extraction uses at most max.tree
## trees.
.rhf_guided_rule_forest <- function(o,
                                    xvar.wt = NULL,
                                    ntree,
                                    guided.args = list(),
                                    verbose = FALSE) {
  if (is.null(o$id) || is.null(o$yvar) || is.null(o$xvar)) {
    stop("The guided analysis requires an RHF object that stores id, yvar, and xvar.")
  }
  t.start <- proc.time()[3L]
  data <- .rhf.build_data_from_object(o)
  xvar.names <- o$xvar.names
  p <- length(xvar.names)
  ## split weights
  raw <- NULL
  if (!is.list(guided.args)) {
    stop("'guided.args' must be a named list.")
  }
  guided.args$verbose <- NULL
  if (is.null(xvar.wt)) {
    if (isTRUE(verbose)) {
      message("[varpro.cache.rhf] computing split weights for guided rule generation")
    }
    ## mtry.guided belongs to the rule forest, not to the screening engine
    engine.args <- guided.args
    engine.args$mtry.guided <- NULL
    args <- c(
      list(x = data[, xvar.names, drop = FALSE],
           start = data$start,
           stopv = data$stop,
           event = data$event,
           id = data$id,
           verbose = verbose),
      engine.args
    )
    xvar.wt <- do.call(.rhf_split_weight, args)
    raw <- attr(xvar.wt, "raw")
    ## No screen retained a variable.  Uniform weights would reproduce an
    ## unguided forest, so the rules of o are used as they are and the
    ## result is reported as unguided.
    if (identical(attr(xvar.wt, "status"), "failed")) {
      if (isTRUE(verbose)) {
        message("[varpro.cache.rhf] screening retained no variable; using the rules of the supplied forest")
      }
      return(list(
        forest = o,
        split.weight = NULL,
        split.weight.raw = raw,
        xvar.selected = character(0),
        xvar.names.all = xvar.names,
        status = "screening failed"
      ))
    }
  }
  w <- .rhf_align_weights(xvar.wt, xvar.names)
  keep <- w > 0
  if (!any(keep)) {
    stop("All split weights are zero; no variables available for rule generation.")
  }
  p.keep <- sum(keep)
  ## mtry for the guided rule forest.  varPro grows its rule forest with
  ## the regression default of one third of the retained variables, so
  ## the leading variables are candidates at every node and the split
  ## rule, not the weights alone, decides the split.  RHF's square root
  ## default would offer too few candidates on a retained set of 30.
  mtry.guided <- guided.args$mtry.guided
  if (is.null(mtry.guided)) {
    mtry.guided <- max(1L, ceiling(p.keep / 3))
  }
  mtry.guided <- max(1L, min(as.integer(mtry.guided)[1L], p.keep))
  ## refit on the retained variables with the original tree settings
  parms <- o$forest$parms
  if (is.null(parms)) {
    stop("The RHF object does not store forest parameters; cannot grow the guided rule forest.")
  }
  refit.data <- data.frame(
    id = data$id,
    start = data$start,
    stop = data$stop,
    event = data$event,
    data[, xvar.names[keep], drop = FALSE],
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  args <- list(
    formula = stats::as.formula("Surv(id, start, stop, event) ~ ."),
    data = refit.data,
    ntree = ntree,
    xvar.wt = unname(w[keep]),
    mtry = mtry.guided,
    membership = TRUE,
    ntime = o$time.interest
  )
  copy <- c("nodesize", "nsplit", "bootstrap", "samptype", "sampsize",
            "case.wt", "samp", "splitrule", "experimental.bits",
            "adaptive", "event.process", "min.events.per.gap", "block.size")
  for (nm in intersect(names(parms), copy)) {
    if (!is.null(parms[[nm]])) {
      args[[nm]] <- parms[[nm]]
    }
  }
  if (!is.null(o$forest$lot$treesize)) {
    args$treesize <- o$forest$lot$treesize
  }
  if (!is.null(guided.args$seed)) {
    args$seed <- guided.args$seed
  }
  hazard.config <- if (!is.null(o$hazard.config)) o$hazard.config else parms$hazard.config
  hazard.options <- get.hazard.options(dots = list(), hazard.config = hazard.config)
  args[names(hazard.options)] <- hazard.options
  if (isTRUE(verbose)) {
    message("[varpro.cache.rhf] growing guided rule forest: ",
            p.keep, " of ", p, " variables, ", ntree, " trees, mtry ", mtry.guided)
  }
  forest <- do.call(rhf, args)
  if (isTRUE(verbose)) {
    message("[varpro.cache.rhf] guided rule forest ready, elapsed ",
            .rhf_format_elapsed(proc.time()[3L] - t.start))
  }
  list(
    forest = forest,
    split.weight = w,
    split.weight.raw = raw,
    xvar.selected = xvar.names[keep],
    xvar.names.all = xvar.names,
    status = "guided"
  )
}
########################################################################
## cache builder
########################################################################
varpro.cache.rhf <- function(o,
                             max.rules.tree = 150L,
                             max.tree = 150L,
                             y.external = NULL,
                             eps = 1e-6,
                             guided = FALSE,
                             xvar.wt = NULL,
                             guided.args = list(),
                             verbose = FALSE) {
  if (!inherits(o, "rhf")) {
    stop("This function only works for objects inheriting from class 'rhf'.")
  }
  t.start <- proc.time()[3L]
  ## guided rule generation: use the object when it is already guided,
  ## otherwise grow an internal guided rule forest
  guided.info <- NULL
  if (isTRUE(guided) || !is.null(xvar.wt)) {
    if (is.null(xvar.wt) && .rhf_is_guided(o)) {
      if (isTRUE(verbose)) {
        message("[varpro.cache.rhf] RHF object is already guided; using its rules")
      }
      w <- stats::setNames(as.numeric(o$forest$parms$xvar.wt), o$xvar.names)
      guided.info <- list(
        split.weight = w,
        split.weight.raw = NULL,
        xvar.selected = o$xvar.names[w > 0],
        xvar.names.all = o$xvar.names,
        refit = FALSE,
        status = "already guided"
      )
    }
    else {
      g <- .rhf_guided_rule_forest(o,
                                   xvar.wt = xvar.wt,
                                   ntree = max.tree,
                                   guided.args = guided.args,
                                   verbose = verbose)
      o <- g$forest
      guided.info <- g[c("split.weight", "split.weight.raw",
                         "xvar.selected", "xvar.names.all", "status")]
      guided.info$refit <- identical(g$status, "guided")
    }
  }
  ## guided is TRUE only when the rules come from a guided forest
  guided.used <- !is.null(guided.info) && guided.info$status != "screening failed"
  if (isTRUE(verbose)) {
    message("[varpro.cache.rhf] building rule-membership cache")
  }
  varpro.strength.fun <- varpro.strength
  get.strengthArray.fun <- get.varpro.strengthArray
  oo <- varpro.strength.fun(object = o,
                            max.rules.tree = max.rules.tree,
                            max.tree = max.tree,
                            membership = TRUE)
  if (is.null(oo$strengthArray)) {
    stop("varpro.strength() did not return a valid 'strengthArray'.")
  }
  if (is.null(oo$oobMembership) || is.null(oo$compMembership)) {
    stop("varpro.strength() did not return membership lists.")
  }
  y.info <- .rhf_get_working_response(o,
                                      y.external = y.external,
                                      eps = eps)
  y <- y.info$y
  y.source <- y.info$y.source
  ss <- .rhf_get_start_stop(o)
  grid <- .rhf_get_grid(o)
  n.pseudo <- length(ss$start)
  if (length(y) != n.pseudo) {
    stop("Length of working response does not match the number of pseudo-individuals.")
  }
  attr(y, "family") <- "regr"
  attr(y, "y.org") <- if (!is.null(y.external)) y.external else if (!is.null(o$y.org)) o$y.org else y
  ## Mirror the RHF branch in importance.varpro(): add an importance slot and
  ## build the regression-style strength array used downstream.
  oo$strengthArray$importance <- NA_real_
  results.template <- get.strengthArray.fun(oo$strengthArray, "regr", y)
  imp.col <- colnames(results.template) == "imp"
  if (sum(imp.col) != 1L) {
    imp.col <- grepl("^imp($|[.])", colnames(results.template))
  }
  if (sum(imp.col) != 1L) {
    stop("RHF time-localized importance expects a single regression-style 'imp' column.")
  }
  if (!("n.oob" %in% colnames(results.template))) {
    stop("Expected column 'n.oob' in the regression-style strength array.")
  }
  if (!all(c("tree", "variable") %in% colnames(results.template))) {
    stop("Expected columns 'tree' and 'variable' in the regression-style strength array.")
  }
  base.rules <- which(oo$strengthArray$oobCT > 0 & oo$strengthArray$compCT > 0)
  results.base <- results.template[base.rules, , drop = FALSE]
  results.base[, imp.col] <- NA_real_
  plan <- .rhf_build_window_plan(start = ss$start,
                                 stopv = ss$stop,
                                 grid = grid)
  precomp <- .rhf_precompute_rule_windows(
    strength = oo$strengthArray,
    base.rules = base.rules,
    oobMembership = oo$oobMembership,
    compMembership = oo$compMembership,
    y = y,
    left.idx = plan$left.idx,
    right.idx = plan$right.idx,
    K = plan$K,
    verbose = verbose
  )
  out <- list(
    call = match.call(),
    results.base = results.base,
    imp.col = imp.col,
    local.imp.window = precomp$local.imp,
    keep.window = precomp$keep,
    n.oob.window = precomp$n.oob,
    n.rules.window = precomp$n.rules,
    xvar.names = o$xvar.names,
    y = y,
    y.source = y.source,
    start = ss$start,
    stop = ss$stop,
    grid = grid,
    K = plan$K,
    window.left = plan$window.left,
    window.right = plan$window.right,
    window.mid = plan$window.mid,
    window.label = plan$window.label,
    n.risk.window = plan$n.risk,
    max.rules.tree = max.rules.tree,
    max.tree = max.tree,
    n.pseudo = n.pseudo,
    guided = guided.used,
    guided.status = if (is.null(guided.info)) "unguided" else guided.info$status,
    guided.info = guided.info
  )
  class(out) <- "varpro.cache.rhf"
  if (isTRUE(verbose)) {
    message("[varpro.cache.rhf] done: ",
            nrow(results.base), " usable rules, ",
            n.pseudo, " pseudo-individuals",
            if (!is.null(y.source) && nzchar(y.source)) paste0(", y.source=", y.source) else "",
            if (guided.used) {
              paste0(", guided (", length(guided.info$xvar.selected), " of ",
                     length(guided.info$xvar.names.all), " variables)")
            } else if (!is.null(guided.info)) {
              paste0(", ", guided.info$status, ", rules unguided")
            } else "",
            ", elapsed ",
            .rhf_format_elapsed(proc.time()[3L] - t.start))
  }
  out
}
varpro.cache <- varpro.cache.rhf
########################################################################
## localized rule calculations
########################################################################
.rhf_local_results_from_cache <- function(cache,
                                          window.index,
                                          trim,
                                          sort,
                                          ...) {
  workhorse.fun <- function(...) {
    args <- list(...)
    ## hard-coded for compatibility
    args$cutoff <- 0.76
    args$plot.it <- FALSE
    args$conf <- FALSE
    args$ylab <- "Importance"
    do.call(importance.varpro.workhorse, args)
  }
  take <- which(cache$keep.window[, window.index])
  if (!length(take)) {
    return(list(table = data.frame(), n.rules = 0L))
  }
  results <- cache$results.base[take, , drop = FALSE]
  results[, cache$imp.col] <- cache$local.imp.window[take, window.index]
  results$n.oob <- cache$n.oob.window[take, window.index]
  o.tmp <- list(
    results = results,
    xvar.names = cache$xvar.names,
    family = "regr"
  )
  tab <- workhorse.fun(o = o.tmp,
                       trim = trim,
                       sort = sort,
                       local.std = TRUE,
                       ...)
  list(table = tab, n.rules = length(take))
}
.rhf_importance_long <- function(importance.matrix, window.info) {
  if (!is.matrix(importance.matrix) || !length(importance.matrix)) {
    return(data.frame())
  }
  if (ncol(importance.matrix) != nrow(window.info)) {
    stop("Internal error: window metadata do not align with the importance matrix.")
  }
  imp.vec <- as.vector(importance.matrix)
  out <- data.frame(
    variable = rep(rownames(importance.matrix), times = ncol(importance.matrix)),
    time = rep(window.info$time, each = nrow(importance.matrix)),
    time.index = rep(window.info$index, each = nrow(importance.matrix)),
    window = rep(window.info$label, each = nrow(importance.matrix)),
    start = rep(window.info$start, each = nrow(importance.matrix)),
    stop = rep(window.info$stop, each = nrow(importance.matrix)),
    midpoint = rep(window.info$midpoint, each = nrow(importance.matrix)),
    n.risk = rep(window.info$n.risk, each = nrow(importance.matrix)),
    n.rules = rep(window.info$n.rules, each = nrow(importance.matrix)),
    importance = imp.vec,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  ord.imp <- out$importance
  ord.imp[is.na(ord.imp)] <- -Inf
  ord <- order(out$time.index, -ord.imp, out$variable)
  out[ord, , drop = FALSE]
}
########################################################################
## main user routine
########################################################################
importance.rhf <- function(o,
                           cache = NULL,
                           time.index = NULL,
                           trim = 0.1,
                           sort = TRUE,
                           max.rules.tree,
                           max.tree,
                           eps = 1e-6,
                           y.external = NULL,
                           guided = FALSE,
                           xvar.wt = NULL,
                           guided.args = list(),
                           verbose = FALSE,
                           ...) {
  if (!inherits(o, "rhf")) {
    stop("This function only works for objects inheriting from class 'rhf'.")
  }
  if (is.null(cache)) {
    cache.args <- list(o = o,
                       eps = eps,
                       y.external = y.external,
                       guided = guided,
                       xvar.wt = xvar.wt,
                       guided.args = guided.args,
                       verbose = verbose)
    if (!missing(max.rules.tree)) {
      cache.args$max.rules.tree <- max.rules.tree
    }
    if (!missing(max.tree)) {
      cache.args$max.tree <- max.tree
    }
    cache <- do.call(varpro.cache.rhf, cache.args)
  }
  else {
    .rhf_validate_cache(o, cache)
    if (isTRUE(verbose)) {
      message("[importance.rhf] using supplied cache",
              if (!is.null(cache$y.source) && nzchar(cache$y.source)) {
                paste0(" (y.source=", cache$y.source, ")")
              } else "",
              if (isTRUE(cache$guided)) " (guided)" else "")
    }
  }
  if (is.null(time.index)) {
    time.index <- seq_len(cache$K)
  }
  if (is.logical(time.index)) {
    if (length(time.index) != cache$K) {
      stop("Logical 'time.index' must have length equal to length(o$time.interest).")
    }
    time.index <- which(time.index)
  }
  time.index <- sort(unique(as.integer(time.index)))
  if (!length(time.index)) {
    stop("No valid time indices supplied.")
  }
  if (any(!is.finite(time.index)) || any(time.index < 1L) || any(time.index > cache$K)) {
    stop("Argument 'time.index' contains invalid window indices.")
  }
  p <- length(cache$xvar.names)
  m <- length(time.index)
  importance.matrix <- matrix(
    NA_real_,
    nrow = p,
    ncol = m,
    dimnames = list(
      cache$xvar.names,
      .rhf_format_time_names(cache$window.right[time.index])
    )
  )
  n.risk <- as.integer(cache$n.risk.window[time.index])
  n.rules <- as.integer(cache$n.rules.window[time.index])
  t.start <- proc.time()[3L]
  for (jj in seq_len(m)) {
    target.window <- time.index[jj]
    local.out <- .rhf_local_results_from_cache(
      cache = cache,
      window.index = target.window,
      trim = trim,
      sort = sort,
      ...
    )
    if (is.data.frame(local.out$table) && nrow(local.out$table)) {
      importance.matrix[rownames(local.out$table), jj] <- local.out$table$z
    }
    if (isTRUE(verbose)) {
      elapsed <- proc.time()[3L] - t.start
      eta <- if (jj < m) elapsed / jj * (m - jj) else 0
      message(
        "[importance.rhf] window ", jj, "/", m,
        " (grid index ", target.window,
        ", t=", .rhf_format_time_names(cache$window.right[target.window]), ")",
        " | remaining ", m - jj,
        " | n.risk ", n.risk[jj],
        " | n.rules ", n.rules[jj],
        " | elapsed ", .rhf_format_elapsed(elapsed),
        " | ETA ", .rhf_format_elapsed(eta)
      )
    }
  }
  window.info <- data.frame(
    index = time.index,
    time = cache$window.right[time.index],
    start = cache$window.left[time.index],
    stop = cache$window.right[time.index],
    midpoint = cache$window.mid[time.index],
    n.risk = n.risk,
    n.rules = n.rules,
    label = cache$window.label[time.index],
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  out <- list(
    call = match.call(),
    xvar.names = cache$xvar.names,
    importance.matrix = importance.matrix,
    importance.long = .rhf_importance_long(
      importance.matrix = importance.matrix,
      window.info = window.info
    ),
    window.info = window.info,
    y.source = cache$y.source,
    trim = trim,
    guided = isTRUE(cache$guided),
    guided.status = if (is.null(cache$guided.status)) "unguided" else cache$guided.status,
    split.weight = if (isTRUE(cache$guided)) cache$guided.info$split.weight else NULL,
    split.weight.raw = if (!is.null(cache$guided.info)) cache$guided.info$split.weight.raw else NULL,
    xvar.selected = if (isTRUE(cache$guided)) cache$guided.info$xvar.selected else NULL,
    xvar.names.all = if (!is.null(cache$guided.info)) cache$guided.info$xvar.names.all else cache$xvar.names
  )
  class(out) <- "importance.rhf"
  out
}
