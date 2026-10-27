plot.rhf <- function(x, idx = NULL, type = c("prob", "chf", "surv", "hazard"),
                     window = NULL, curve = c("step", "line", "lowess"), f = 2/3,
                     curve.lwd = 2, truth = NULL,
                     scale.hazard = FALSE, ngrid = 30, bass = 0, q = 0.99, grid = FALSE,
                     col = NULL, lty = NULL, legend.loc = "topright",
                     jitter.factor = 1, lwd = 4,
                     hazard.only = TRUE, legend.show = TRUE, ...) {
  ## a smoothed hazard object is about the hazard: that is its default display
  if (missing(type) && inherits(x, "smoothed.hazard.rhf")) type <- "hazard"
  type <- match.arg(type)
  curve <- match.arg(curve)
  sel <- .rhf_plot_cases(x, idx, col, lty)
  if (type == "hazard") {
    return(invisible(.rhf_plot_hazard(x, sel, truth, scale.hazard, ngrid, bass, q, grid,
                                      legend.loc, jitter.factor, lwd, curve.lwd, hazard.only, legend.show, ...)))
  }
  invisible(.rhf_plot_chf(x, sel, type, window, curve, f, curve.lwd, truth, legend.loc, legend.show, ...))
}
####################################################################
##
## case-specific displays from the cumulative hazard
##
####################################################################
## the displays prob (event probability per grid interval, or over a window
## of fixed width), chf and surv: each selected case from its OOB (or test)
## cumulative hazard on the time grid; the true curves of a simulated model
## dashed, faint beyond the case's observed follow-up
.rhf_plot_chf <- function(x, sel, type, window, curve, f, curve.lwd, truth,
                          legend.loc, legend.show, ...) {
  time <- x$time.interest
  K <- length(time)
  width <- diff(c(0, time))
  chf <- if (!is.null(x$chf.oob)) x$chf.oob else x$chf.test
  if (is.null(chf)) stop("no cumulative hazard (chf.oob or chf.test) in x")
  if (!is.null(window)) {
    window <- as.numeric(window)[1L]
    if (!is.finite(window) || window <= 0) stop("'window' must be a positive width in the time units of the data")
  }
  ## the values of a display from the CHF increments dH and the CHF H
  value <- function(dH, H) {
    switch(type,
           prob = if (is.null(window)) 1 - exp(-dH) else 1 - exp(-sweep(dH, 2, width, "/") * window),
           chf = H,
           surv = exp(-H))
  }
  H <- unname(chf[sel$pos, , drop = FALSE])
  dH <- H - cbind(0, H[, -K, drop = FALSE])
  dH[is.finite(dH) & dH < 0] <- 0
  y <- value(dH, H)
  tr <- .rhf_truth_curves(x, sel, truth, time, width)
  ty <- if (!is.null(tr)) value(tr$dH, tr$chf)
  ## the automatic time range: the cases' follow-up with some room beyond
  ## it, within the grid before a run of very wide tail intervals; x max
  ## extends it.  The y range covers the estimates and the true curves over
  ## the follow-up
  dots <- list(...)
  k.end <- .rhf_grid_tail(width)
  xlim <- if (!is.null(dots$xlim)) dots$xlim else .rhf_time_range(time, is.finite(y), sel$last.stop)
  shown <- time >= xlim[1] - 1e-12 & time <= xlim[2] + 1e-12
  if (!any(shown)) shown <- seq_len(k.end)
  ylim <- if (!is.null(dots$ylim)) dots$ylim else {
    ## (a case with no estimate within the range leaves nothing to range over)
    suppressWarnings(range(y[, shown, drop = FALSE],
                           if (!is.null(ty)) ty[, shown, drop = FALSE][tr$within[, shown, drop = FALSE]],
                           finite = TRUE))
  }
  if (!all(is.finite(ylim))) ylim <- c(0, 1)
  xlab <- if (!is.null(dots$xlab)) dots$xlab else "time"
  ylab <- if (!is.null(dots$ylab)) dots$ylab else switch(type,
    prob = if (is.null(window)) "P(event in grid interval | at risk)"
           else paste0("P(event within ", format(signif(window, 3)), " time units | at risk)"),
    chf = "cumulative hazard H(t)",
    surv = "survival probability exp(-H(t))")
  dots[c("xlim", "ylim", "xlab", "ylab")] <- NULL
  do.call("plot", c(list(x = NA, y = NA, xlim = xlim, ylim = ylim, xlab = xlab, ylab = ylab), dots))
  draw <- function(yk, col, lty, split.at = NULL) {
    .rhf_draw_curve(time, yk, shown, curve, f, col, curve.lwd, lty, split.at)
  }
  for (i in seq_len(sel$n)) draw(y[i, ], sel$col[i], sel$lty[i])
  if (!is.null(ty)) {
    for (i in seq_len(sel$n)) {
      draw(ty[i, ], sel$col[i], .rhf_truth_lty(i), split.at = max(c(-Inf, time[tr$within[i, ]])))
    }
  }
  my_rug(x)
  if (legend.show && sel$n > 1) {
    legend(if (type == "surv" && identical(legend.loc, "topright")) "bottomleft" else legend.loc,
           legend = sel$labels, col = sel$col, lty = sel$lty, lwd = curve.lwd, bty = "n")
  }
  list(type = type, time = time, value = y, truth = ty, idx = sel$idx)
}
####################################################################
##
## the smoothed hazard display (type = "hazard")
##
####################################################################
.rhf_plot_hazard <- function(x, sel, truth, scale.hazard, ngrid, bass, q, grid,
                             legend.loc, jitter.factor, lwd, curve.lwd, hazard.only, legend.show, ...) {
  ## Preliminary
  time.interest <- x$time.interest
  idx <- sel$pos
  n.idx <- sel$n
  col <- sel$col
  lty <- sel$lty
  dots <- list(...)
  ## pull the ensemble estimators; a case's hazard is NA outside its
  ## observed path (counting-process fits) and is drawn over the path only
  get_mat <- function(name_oob, name_test) {
      if (!is.null(x[[name_oob]])) return(x[[name_oob]])
      if (!is.null(x[[name_test]])) return(x[[name_test]])
      NULL
  }
  chf <- get_mat("chf.oob", "chf.test")
  haz <- get_mat("hazard.oob", "hazard.test")
  if (is.null(haz)) stop("no hazard (hazard.oob or hazard.test) in x")
  if (is.logical(scale.hazard)) {
    if (scale.hazard) {
      haz <- sweep(haz, 2, diff(c(0, time.interest)), "*")
    }
  } else if (is.numeric(scale.hazard) && length(scale.hazard) == 1 && is.finite(scale.hazard)) {
    haz <- scale.hazard * haz
  } else {
    stop("scale.hazard must be either logical or a finite numeric scalar.")
  }
  ## the points of a case: observed and not among the trimmed extremes
  points.of <- function(h) {
    ok <- is.finite(h)
    if (!any(ok)) return(ok)
    ok & h <= quantile(h[ok], q)
  }
  smooth.of <- function(tt, h) {
    if (length(tt) < 4L) return(h)
    supsmu(tt, h, bass = bass)$y
  }
  ## Compute plot ranges
  ranges <- lapply(idx, function(i) {
    h <- haz[i, ]
    pt <- points.of(h)
    h.smooth <- smooth.of(time.interest[pt], h[pt])
    ## auxiliary equally spaced grid (used for overlays)
    time.grid <- unique(c(0, seq(0, max(time.interest), length = ngrid)))
    if (!hazard.only) {
      H <- chf[i, ]
      H.grid <- c(0, H)[1 + sIndex(time.interest, time.grid)]
      ## (the CHF stays at its last value beyond the follow-up)
      H.grid[is.na(H.grid)] <- if (any(is.finite(H))) max(H, na.rm = TRUE) else 0
      H.grid.smooth <- supsmu(time.grid, H.grid)$y
      delta <- max(diff(time.grid))
      h.grid.smooth <- supsmu(time.grid, c(0, diff(H.grid.smooth) / delta), bass = bass)$y
    } else {
      H <- H.grid.smooth <- NULL
      h.on.grid <- if (sum(pt) >= 2L) {
        stats::approx(x = time.interest[pt], y = h[pt],
                      xout = time.grid, method = "linear", rule = 2, ties = mean)$y
      } else rep(if (any(pt)) h[pt][1] else 0, length(time.grid))
      h.grid.smooth <- supsmu(time.grid, h.on.grid, bass = bass)$y
    }
    list(H = H,
         h.smooth = h.smooth,
         h.grid.smooth = h.grid.smooth,
         H.grid.smooth = H.grid.smooth,
         time.grid = time.grid)
  })
  ## the true hazard of a simulated model, on a fine grid over the grid's
  ## span (faint beyond the case's follow-up; clipped to the time range)
  tr <- NULL
  if (!is.null(truth)) {
    xr <- .rhf_truth_rows(x, sel, truth)
    if (!is.null(xr)) {
      tt <- seq(0, max(time.interest), length.out = 200L)
      ht <- tryCatch(truth$haz(tt, xr), error = function(e) { warning("truth ignored: ", conditionMessage(e)); NULL })
      if (!is.null(ht) && (!is.matrix(ht) || nrow(ht) != n.idx)) {
        warning("truth ignored: its haz closure did not return one curve per case")
        ht <- NULL
      }
      if (!is.null(ht)) {
        if (is.logical(scale.hazard)) {
          ## scaled by the width of the grid interval holding each point, as the estimates are
          if (scale.hazard) {
            width <- diff(c(0, time.interest))
            at <- pmin(findInterval(tt, time.interest, left.open = TRUE) + 1L, length(time.interest))
            ht <- sweep(ht, 2, width[at], "*")
          }
        } else {
          ht <- scale.hazard * ht
        }
        tr <- list(time = tt, hazard = unname(ht),
                   within = outer(seq_len(n.idx), seq_along(tt), function(i, j) tt[j] <= sel$last.stop[i]))
      }
    }
  }
  ## Extract or compute plot labels and ranges.  Values supplied
  ## through ... must be removed before do.call(plot, ...), otherwise
  ## plot.default receives duplicate formal arguments.
  has.xlab <- "xlab" %in% names(dots)
  has.ylab <- "ylab" %in% names(dots)
  xlab <- if (has.xlab) dots$xlab else "time"
  ylab.default <- if (hazard.only) "Hazard" else "CHF + hazard"
  ylab <- if (has.ylab) dots$ylab else ylab.default
  ## the automatic time range, as for the other displays: the cases'
  ## follow-up (the longest, when there are several) with some room beyond
  ## it.  The estimates are NA beyond the follow-up, so the whole grid
  ## would leave most of the display empty.  The y range covers what is
  ## shown
  xlim <- if (!is.null(dots$xlim)) dots$xlim else .rhf_time_range(time.interest, is.finite(haz[idx, , drop = FALSE]), sel$last.stop)
  ylim <- if (!is.null(dots$ylim)) dots$ylim else {
    range(unlist(
      lapply(ranges, function(xi) {
        on.grid <- xi$time.grid <= xlim[2]
        if (hazard.only) {
          c(xi$h.smooth, xi$h.grid.smooth[on.grid])
        } else {
          c(xi$H[time.interest <= xlim[2]], xi$H.grid.smooth[on.grid], xi$h.smooth, xi$h.grid.smooth[on.grid])
        }
      })
    ), if (!is.null(tr)) tr$hazard[tr$within & matrix(tr$time <= xlim[2], n.idx, length(tr$time), byrow = TRUE)],
    na.rm = TRUE, finite = TRUE)
  }
  dots$xlab <- NULL
  dots$ylab <- NULL
  dots$xlim <- NULL
  dots$ylim <- NULL
  ## Main plot
  do.call("plot", c(list(x = NA, y = NA,
                         xlim = xlim, ylim = c(max(0, ylim[1]), ylim[2]),
                         xlab = xlab, ylab = ylab), dots))
  ## Loop through cases
  invisible(lapply(seq_along(idx), function(k) {
    i <- idx[k]
    h <- haz[i, ]
    pt <- points.of(h)
    h.smooth <- smooth.of(time.interest[pt], h[pt])
    ## plot hazard
    t.jittered <- jitter(time.interest[pt], factor = jitter.factor)
    lines(t.jittered, h[pt], type = "h", col = adjustcolor(col[k], alpha.f = 0.5), lwd = lwd)
    lines(time.interest[pt], h.smooth, type = "s", col = col[k], lty = if (hazard.only) lty[k] else 3, lwd = curve.lwd)
    if (!hazard.only) {
      H <- chf[i, ]
      rr <- ranges[[k]]
      lines(time.interest, H, type = "s", col = col[k], lwd = curve.lwd)
      if (grid) {
        lines(rr$time.grid, rr$H.grid.smooth, type = "s", col = col[k], lty = 3)
        lines(rr$time.grid, rr$h.grid.smooth, type = "s", col = col[k], lty = 2)
      }
    } else {
      if (grid) {
        rr <- ranges[[k]]
        lines(rr$time.grid, rr$h.grid.smooth, type = "s", col = col[k], lty = 2)
      }
    }
  }))
  ## the true hazard: one dash pattern per case, full color over the
  ## follow-up and faint beyond it
  if (!is.null(tr)) {
    for (k in seq_len(n.idx)) {
      w <- tr$within[k, ]
      lty.k <- .rhf_truth_lty(k)
      lines(tr$time, tr$hazard[k, ], lty = lty.k, col = adjustcolor(col[k], alpha.f = 0.3), lwd = curve.lwd)
      hw <- tr$hazard[k, ]
      hw[!w] <- NA
      lines(tr$time, hw, lty = lty.k, col = col[k], lwd = curve.lwd)
    }
  }
  my_rug(x)
  ## Optional legend
  if (legend.show && n.idx > 1) {
    legend(legend.loc, legend = sel$labels, col = col, lty = lty, lwd = curve.lwd, bty = "n")
  }
  list(type = "hazard", time = time.interest, value = unname(haz[idx, , drop = FALSE]),
       truth = if (!is.null(tr)) list(time = tr$time, hazard = tr$hazard), idx = sel$idx)
}
####################################################################
##
## helpers
##
####################################################################
## the selected cases: positions in the ensemble, ids, labels, colors,
## line types and the end of each case's observed follow-up
.rhf_plot_cases <- function(x, idx, col, lty) {
  if (is.null(idx)) idx <- x$ensemble.id[1]
  labels <- if (!is.null(names(idx))) names(idx) else paste("Case", idx)
  keep <- idx %in% x$ensemble.id
  if (!any(keep)) stop("idx does not match id values in x$ensemble.id")
  if (!all(keep)) warning("idx values not in x$ensemble.id are dropped: ", paste(idx[!keep], collapse = ", "))
  keep <- keep & !duplicated(idx)
  idx <- idx[keep]
  labels <- labels[keep]
  pos <- match(idx, x$ensemble.id)
  n <- length(pos)
  yv <- .rhf_yvar(x)
  last.stop <- if (!is.null(yv$stop) && !is.null(x$id)) {
    as.numeric(tapply(yv$stop, x$id, max)[as.character(idx)])
  } else rep(Inf, n)
  last.stop[is.na(last.stop)] <- Inf
  list(idx = idx, pos = pos, n = n, labels = labels,
       col = rep_len(if (is.null(col)) seq_len(n) else col, n),
       lty = rep_len(if (is.null(lty)) 1 else lty, n),
       last.stop = last.stop)
}
## the start, stop and event columns of x$yvar: named by x$yvar.names when
## present (a grow object), else the counting-process names or the internal
## names of a right-censored fit (prediction and smoothed hazard objects)
.rhf_yvar <- function(x) {
  none <- list(start = NULL, stop = NULL, event = NULL)
  yv <- x$yvar
  if (is.null(yv)) return(none)
  has <- function(nm) length(nm) >= 3L && all(nm[1:3] %in% names(yv))
  nm <- if (has(x$yvar.names)) x$yvar.names[1:3]
        else if (has(c("start", "stop", "event"))) c("start", "stop", "event")
        else if (has(c(".rhf.start", ".rhf.stop", ".rhf.event"))) c(".rhf.start", ".rhf.stop", ".rhf.event")
        else if (NCOL(yv) >= 3L) names(yv)[1:3]
        else return(none)
  list(start = yv[[nm[1]]], stop = yv[[nm[2]]], event = yv[[nm[3]]])
}
## one record per selected case (its id and the x variables), for the
## closures of hazard.simulation(); NULL, with a warning, when truth is not
## such a simulation or x does not carry the records of the cases
.rhf_truth_rows <- function(x, sel, truth) {
  if (!is.list(truth) || !is.function(truth$haz)) {
    warning("truth ignored: it is not the list returned by hazard.simulation() (no haz closure)")
    return(NULL)
  }
  if (is.null(x$id) || is.null(x$xvar)) {
    warning("truth ignored: x does not carry the records (id, xvar) of the cases")
    return(NULL)
  }
  rows <- match(sel$idx, x$id)
  if (anyNA(rows)) {
    warning("truth ignored: cases not found among the records of x")
    return(NULL)
  }
  data.frame(id = sel$idx, x$xvar[rows, , drop = FALSE])
}
## the true cumulative hazard increments of the selected cases per grid
## interval: the simulation's chf when it has one, else its hazard
## integrated by the midpoint rule (10 points per interval); with the
## follow-up mask
.rhf_truth_curves <- function(x, sel, truth, time, width, m = 10L) {
  if (is.null(truth)) return(NULL)
  xr <- .rhf_truth_rows(x, sel, truth)
  if (is.null(xr)) return(NULL)
  K <- length(time)
  dH <- tryCatch({
    if (is.function(truth$chf)) {
      H <- truth$chf(c(0, time), xr)
      H[, -1, drop = FALSE] - H[, -(K + 1), drop = FALSE]
    } else {
      left <- c(0, time[-K])
      mids <- as.vector(t(outer(left, rep(1, m)) + outer(width, (seq_len(m) - 0.5) / m)))
      h <- truth$haz(mids, xr)
      matrix(vapply(seq_len(K), function(j) rowMeans(h[, (j - 1) * m + seq_len(m), drop = FALSE]) * width[j],
                    numeric(nrow(h))), nrow = nrow(h))
    }
  }, error = function(e) { warning("truth ignored: ", conditionMessage(e)); NULL })
  if (is.null(dH)) return(NULL)
  if (!is.matrix(dH) || nrow(dH) != sel$n || ncol(dH) != K) {
    warning("truth ignored: its closures did not return one curve per case")
    return(NULL)
  }
  dH <- unname(dH)
  dH[is.finite(dH) & dH < 0] <- 0
  chf <- matrix(t(apply(dH, 1, cumsum)), nrow = sel$n)
  list(dH = dH, chf = chf,
       within = outer(seq_len(sel$n), seq_len(K), function(i, j) time[j] <= sel$last.stop[i]))
}
## the dash pattern of the k-th case's true curve (dashed, dotted, ...)
.rhf_truth_lty <- function(k) 1 + (k - 1) %% 5 + 1
## the automatic time range of a display: from 0 to a little beyond the
## selected cases' follow-up (the longest of them), within the grid before
## a run of very wide tail intervals, but never short of the follow-up
## itself.  The follow-up is where the cases' estimates are observed
## (finite: counting-process fits are NA after a case's last stop); when
## the estimates cover the whole grid (right-censored fits) it is the
## cases' observed times, when known
.rhf_time_range <- function(time, finite, last.stop) {
  K <- length(time)
  k.end <- .rhf_grid_tail(diff(c(0, time)))
  followup <- if (all(finite) && any(is.finite(last.stop))) {
    min(max(last.stop[is.finite(last.stop)]), time[K])
  } else max(c(0, time[apply(finite, 2, any)]))
  c(0, max(followup, min(time[k.end], max(1.25 * followup, time[min(3L, K)]))))
}
## the index of the last grid point before a run of very wide intervals at
## the end of an adaptive grid (over 10 times the median width)
.rhf_grid_tail <- function(width) {
  wide <- width > 10 * stats::median(width)
  k.end <- length(width)
  while (k.end > 1 && wide[k.end]) k.end <- k.end - 1
  k.end
}
## one curve over the time grid: a step (constant over each interval), a
## line through the grid points, or a lowess smooth of the shown points;
## with split.at, full color up to that time and faint beyond it (a single
## curve, so a lowess fit is the same on both sides)
.rhf_draw_curve <- function(time, yk, shown, curve, f, col, lwd, lty, split.at = NULL) {
  ok <- is.finite(yk)
  pts <- switch(curve,
                line = list(x = time[ok], y = yk[ok], type = "l"),
                lowess = if (sum(ok & shown) > 2) c(stats::lowess(time[ok & shown], yk[ok & shown], f = f), list(type = "l"))
                         else list(x = numeric(0), y = numeric(0), type = "l"),
                list(x = c(0, time)[c(TRUE, ok)], y = c(yk[which(ok)[1]], yk[ok]), type = "S"))
  if (!length(pts$x)) return(invisible(NULL))
  if (is.null(split.at)) {
    lines(pts$x, pts$y, type = pts$type, col = col, lwd = lwd, lty = lty)
    return(invisible(NULL))
  }
  w <- pts$x <= split.at + 1e-12
  if (any(w)) lines(pts$x[w], pts$y[w], type = pts$type, col = col, lwd = lwd, lty = lty)
  if (any(!w)) {
    j <- c(if (any(w)) max(which(w)), which(!w))
    lines(pts$x[j], pts$y[j], type = pts$type, col = adjustcolor(col, alpha.f = 0.3), lwd = lwd, lty = lty)
  }
  invisible(NULL)
}
## Time alignment helper
sIndex <- function(x, y) {
  sapply(seq_along(y), function(j) sum(x <= y[j]))
}
## Rug of the observed event times, with clipping protection
my_rug <- function(x, ticksize = 0.02, nmax = 350) {
  yv <- .rhf_yvar(x)
  if (is.null(yv$stop) || is.null(yv$event)) return(invisible(NULL))
  rug.time <- unique(yv$stop[yv$event == 1])
  rug.time <- sample(rug.time, size = min(length(rug.time), nmax), replace = FALSE)
  xlims <- par("usr")[1:2]
  rug.time <- rug.time[rug.time >= xlims[1] & rug.time <= xlims[2]]
  suppressWarnings(rug(rug.time, ticksize = ticksize))
}
