########################################################################
## plot helpers
########################################################################
.rhf_validate_named_list <- function(x, arg = "argument") {
  if (!is.list(x)) {
    stop("'", arg, "' must be a list.")
  }
  if (!length(x)) {
    return(invisible(TRUE))
  }
  nms <- names(x)
  if (is.null(nms) || any(!nzchar(nms))) {
    stop("All elements of '", arg, "' must be named.")
  }
  if (anyDuplicated(nms)) {
    dup <- unique(nms[duplicated(nms)])
    stop("Duplicated argument name(s) in '", arg, "': ",
         paste(dup, collapse = ", "), ".")
  }
  invisible(TRUE)
}
.rhf_graphics_call <- function(fun,
                               fixed,
                               extra = list(),
                               protected = names(fixed),
                               arg = "...") {
  .rhf_validate_named_list(extra, arg)
  conflict <- intersect(names(extra), protected)
  if (length(conflict)) {
    stop("'", arg, "' cannot override argument(s) controlled by the RHF ",
         "plot helper: ", paste(conflict, collapse = ", "), ".")
  }
  ## Arguments not marked as protected may replace a default. This is useful
  ## for optional legend placement and formatting while keeping data-driven
  ## geometry (coordinates, colors, sizes) under the helper's control.
  replace <- intersect(names(extra), names(fixed))
  if (length(replace)) {
    fixed[replace] <- NULL
  }
  do.call(fun, c(fixed, extra))
}
.rhf_importance_plot_data <- function(x) {
  if (!inherits(x, "importance.rhf")) {
    stop("This function only works for objects of class 'importance.rhf'.")
  }
  mat <- x$importance.matrix
  if (!is.matrix(mat) || length(dim(mat)) != 2L ||
      nrow(mat) < 1L || ncol(mat) < 1L) {
    stop("No importance values available to plot.")
  }
  if (!is.numeric(mat)) {
    stop("'x$importance.matrix' must be a numeric matrix.")
  }
  var.codes <- rownames(mat)
  if (is.null(var.codes)) {
    fallback <- x$xvar.names
    if (length(fallback) == nrow(mat)) {
      var.codes <- as.character(fallback)
      rownames(mat) <- var.codes
    }
    else {
      stop("'x$importance.matrix' must have variable row names.")
    }
  }
  if (anyNA(var.codes) || any(!nzchar(var.codes))) {
    stop("Variable row names must be non-missing and non-empty.")
  }
  if (anyDuplicated(var.codes)) {
    stop("Variable row names in 'x$importance.matrix' must be unique.")
  }
  window.info <- x$window.info
  if (is.null(window.info) || is.null(window.info$time)) {
    stop("'x$window.info$time' is required for importance plotting.")
  }
  time.values <- window.info$time
  if (length(time.values) != ncol(mat)) {
    stop("The number of values in 'x$window.info$time' (",
         length(time.values), ") must equal the number of importance-matrix ",
         "columns (", ncol(mat), ").")
  }
  if (!is.numeric(time.values)) {
    stop("'x$window.info$time' must be numeric.")
  }
  time.codes <- colnames(mat)
  if (is.null(time.codes)) {
    time.codes <- as.character(time.values)
  }
  else {
    time.codes <- as.character(time.codes)
    empty <- is.na(time.codes) | !nzchar(time.codes)
    time.codes[empty] <- as.character(time.values[empty])
  }
  colnames(mat) <- time.codes
  list(mat = mat,
       var.codes = rownames(mat),
       time.codes = time.codes,
       time.values = time.values)
}
.rhf_resolve_time_labels <- function(time.codes,
                                     time.values,
                                     time.labels = NULL) {
  if (is.null(time.labels)) {
    out <- .rhf_format_time_labels(time.values)
  }
  else if (!is.data.frame(time.labels) && is.null(names(time.labels))) {
    if (length(time.labels) != length(time.codes)) {
      stop("An unnamed 'time.labels' vector must have one label per time window.")
    }
    out <- as.character(time.labels)
  }
  else {
    out <- .rhf_label_lookup(time.codes, time.labels, infer_prefix = FALSE)
  }
  if (length(out) != length(time.codes)) {
    stop("The resolved time labels must have one entry per matrix column.")
  }
  as.character(out)
}
.rhf_expand_plot_range <- function(x,
                                   fallback = c(0, 1),
                                   relative.pad = 0.04,
                                   absolute.pad = 1) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  if (!length(x)) {
    return(fallback)
  }
  rng <- range(x)
  if (rng[1L] != rng[2L]) {
    return(rng)
  }
  pad <- max(abs(rng[1L]) * relative.pad, absolute.pad)
  c(rng[1L] - pad, rng[2L] + pad)
}
.rhf_thin_breaks <- function(x, max.breaks = 5L) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  if (length(x) <= max.breaks) {
    return(x)
  }
  idx <- unique(round(seq(1, length(x), length.out = max.breaks)))
  x[idx]
}
.rhf_select_dotmatrix_variables <- function(mat,
                                            vars = NULL,
                                            top.n.union = 15L,
                                            sort.abs = TRUE) {
  if (!is.null(vars)) {
    vars <- intersect(as.character(vars), rownames(mat))
    if (!length(vars)) {
      stop("No requested variables found in the importance matrix.")
    }
    return(mat[vars, , drop = FALSE])
  }
  top.n.union <- as.integer(top.n.union)[1L]
  if (!is.finite(top.n.union) || top.n.union < 1L) {
    stop("'top.n.union' must be a positive integer.")
  }
  top.vars <- unique(unlist(lapply(seq_len(ncol(mat)), function(j) {
    v <- mat[, j]
    score <- if (isTRUE(sort.abs)) abs(v) else v
    keep <- is.finite(score)
    if (!any(keep)) {
      return(character(0))
    }
    idx <- which(keep)
    ord <- idx[order(score[idx], decreasing = TRUE)]
    rownames(mat)[head(ord, min(top.n.union, length(ord)))]
  }), use.names = FALSE))
  if (!length(top.vars)) {
    stop("No finite variables available for the matrix plot.")
  }
  mat[top.vars, , drop = FALSE]
}
.rhf_order_dotmatrix_variables <- function(mat,
                                           variable.labels = NULL,
                                           sort.by = c("q90", "sum", "max", "mean", "median", "alphabetical", "cluster", "none"),
                                           sort.abs = TRUE) {
  sort.by <- match.arg(sort.by)
  if (sort.by == "none" || nrow(mat) < 2L) {
    return(rownames(mat))
  }
  if (sort.by %in% c("q90", "sum", "max", "mean", "median")) {
    score <- .rhf_row_summary(mat,
                              rank.by = sort.by,
                              abs = sort.abs)
    return(rownames(mat)[order(score, decreasing = TRUE, na.last = TRUE)])
  }
  if (sort.by == "alphabetical") {
    lab <- .rhf_label_lookup(rownames(mat), variable.labels, infer_prefix = TRUE)
    lab <- .rhf_make_unique_labels(lab, rownames(mat))
    return(rownames(mat)[order(lab, na.last = TRUE)])
  }
  ## cluster
  mat.z <- t(scale(t(mat)))
  mat.z[!is.finite(mat.z)] <- 0
  hc <- stats::hclust(stats::dist(mat.z), method = "ward.D2")
  rownames(mat.z)[hc$order]
}
.rhf_rescale_from_range <- function(x,
                                    from,
                                    to = c(0.5, 3.0)) {
  x <- as.numeric(x)
  from <- as.numeric(from)
  to <- as.numeric(to)
  out <- rep(0, length(x))
  ok <- is.finite(x)
  if (!any(ok)) {
    return(out)
  }
  if (length(from) != 2L || any(!is.finite(from))) {
    return(out)
  }
  if (length(to) != 2L || any(!is.finite(to))) {
    stop("'to' must be a finite numeric vector of length 2.")
  }
  if (from[1L] == from[2L]) {
    out[ok] <- mean(to)
    return(out)
  }
  out[ok] <- to[1L] + (x[ok] - from[1L]) /
    (from[2L] - from[1L]) * (to[2L] - to[1L])
  out
}
.rhf_pretty_breaks <- function(x,
                               n = 5L,
                               positive.only = FALSE,
                               symmetric = FALSE) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  if (positive.only) {
    x <- x[x > 0]
  }
  if (!length(x)) {
    return(numeric(0))
  }
  n <- max(2L, as.integer(n)[1L])
  if (symmetric) {
    lim <- max(abs(x), na.rm = TRUE)
    if (!is.finite(lim) || lim <= 0) {
      return(0)
    }
    br <- pretty(c(-lim, lim), n = n)
    br <- br[br >= -lim & br <= lim]
    br <- unique(br[is.finite(br)])
    if (!0 %in% br) {
      br <- sort(unique(c(br, 0)))
    }
    return(br)
  }
  rng <- range(x, na.rm = TRUE)
  if (!is.finite(rng[1L]) || !is.finite(rng[2L])) {
    return(numeric(0))
  }
  if (rng[1L] == rng[2L]) {
    return(rng[1L])
  }
  br <- pretty(rng, n = n)
  br <- br[br >= rng[1L] & br <= rng[2L]]
  if (positive.only) {
    br <- br[br > 0]
  }
  br <- unique(br[is.finite(br)])
  if (!length(br)) {
    probs <- seq(0, 1, length.out = n)
    br <- as.numeric(stats::quantile(x, probs = probs,
                                     na.rm = TRUE, names = FALSE))
    if (positive.only) {
      br <- br[br > 0]
    }
    br <- unique(br[is.finite(br)])
  }
  br
}
.rhf_format_legend_values <- function(x,
                                      digits = 3L) {
  format(signif(as.numeric(x), digits = digits),
         trim = TRUE, scientific = FALSE)
}
.rhf_draw_matrix_guides <- function(x.at = numeric(0),
                                    y.at = numeric(0),
                                    xlim,
                                    ylim,
                                    col = "grey92",
                                    lty = 3,
                                    lwd = graphics::par("lwd")) {
  x.at <- as.numeric(x.at)
  y.at <- as.numeric(y.at)
  xlim <- as.numeric(xlim)
  ylim <- as.numeric(ylim)
  if (length(xlim) != 2L || any(!is.finite(xlim)) ||
      length(ylim) != 2L || any(!is.finite(ylim))) {
    stop("'xlim' and 'ylim' must be finite numeric vectors of length 2.")
  }
  x.at <- x.at[is.finite(x.at) &
                 x.at >= min(xlim) & x.at <= max(xlim)]
  y.at <- y.at[is.finite(y.at) &
                 y.at >= min(ylim) & y.at <= max(ylim)]
  if (!length(x.at) && !length(y.at)) {
    return(invisible(TRUE))
  }
  ## The matrix plot keeps xpd = NA so large symbols and rotated labels are
  ## not clipped. Grid and reference lines should nevertheless remain inside
  ## the data panel rather than extending into the variable-label margin.
  old.xpd <- graphics::par("xpd")
  on.exit(graphics::par(xpd = old.xpd), add = TRUE)
  graphics::par(xpd = FALSE)
  if (length(y.at)) {
    graphics::segments(x0 = xlim[1L],
                       y0 = y.at,
                       x1 = xlim[2L],
                       y1 = y.at,
                       col = col,
                       lty = lty,
                       lwd = lwd)
  }
  if (length(x.at)) {
    graphics::segments(x0 = x.at,
                       y0 = ylim[1L],
                       x1 = x.at,
                       y1 = ylim[2L],
                       col = col,
                       lty = lty,
                       lwd = lwd)
  }
  invisible(TRUE)
}
.rhf_draw_dotmatrix_xlabels <- function(at,
                                        labels,
                                        cex = 0.9,
                                        gap.lines = 0.10,
                                        srt = 45) {
  if (!length(at) || !length(labels)) {
    return(invisible(TRUE))
  }
  usr <- graphics::par("usr")
  csi <- graphics::par("csi")
  din <- graphics::par("din")
  if (!is.finite(csi) || csi <= 0) {
    csi <- 0.2
  }
  if (!is.finite(din[2L]) || din[2L] <= 0) {
    din[2L] <- 7
  }
  ## Position labels using a fixed physical gap beneath the x-axis rather than
  ## a gap that scales with the number of variables in the plot.
  y.axis.ndc <- graphics::grconvertY(usr[3L], from = "user", to = "ndc")
  gap.in <- max(0, gap.lines) * csi * cex
  y.text.ndc <- y.axis.ndc - gap.in / din[2L]
  y.user <- graphics::grconvertY(y.text.ndc, from = "ndc", to = "user")
  graphics::text(at,
                 rep(y.user, length(at)),
                 labels = labels,
                 srt = srt,
                 adj = c(1, 1),
                 xpd = NA,
                 cex = cex)
  invisible(TRUE)
}
.rhf_dotmatrix_default_mar <- function(var.labels,
                                       x.labels,
                                       var.cex = 0.9,
                                       axis.cex = 0.9,
                                       time.label.srt = 45,
                                       legend = TRUE,
                                       left.min = 4.0,
                                       left.max = 30,
                                       left.pad = 1.7) {
  csi <- graphics::par("csi")
  if (!is.finite(csi) || csi <= 0) {
    csi <- 0.2
  }
  left.in <- if (length(var.labels)) {
    max(graphics::strwidth(var.labels, units = "inches", cex = var.cex),
        na.rm = TRUE)
  }
  else {
    0
  }
  if (!is.finite(left.in)) {
    left.in <- 0
  }
  lab.w.in <- if (length(x.labels)) {
    max(graphics::strwidth(x.labels, units = "inches", cex = axis.cex),
        na.rm = TRUE)
  }
  else {
    0
  }
  if (!is.finite(lab.w.in)) {
    lab.w.in <- 0
  }
  lab.h.in <- if (length(x.labels)) {
    max(graphics::strheight(x.labels, units = "inches", cex = axis.cex),
        na.rm = TRUE)
  }
  else {
    0
  }
  if (!is.finite(lab.h.in)) {
    lab.h.in <- 0
  }
  theta <- abs(as.numeric(time.label.srt)[1L]) * pi / 180
  rot.ext.in <- lab.w.in * sin(theta) + lab.h.in * cos(theta)
  ## The label width determines the left margin. A small conventional floor is
  ## retained for short names and y-axis labels, while long informatics labels
  ## still receive their measured physical width plus padding.
  left.mar <- left.in / csi + left.pad
  left.mar <- min(left.max, max(left.min, left.mar))
  ## Keep enough room for rotated time labels so they are not clipped, while
  ## controlling label proximity to the axis separately at draw time.
  bottom.mar <- 0.45 + rot.ext.in / csi + 0.65
  bottom.mar <- min(6.5, max(2.8, bottom.mar))
  top.mar <- 2.8
  right.mar <- if (isTRUE(legend)) 0.5 else 0.4
  c(bottom.mar, left.mar, top.mar, right.mar)
}
.rhf_resolve_matrix_legend_title <- function(value,
                                             default,
                                             arg) {
  if (is.null(value)) {
    return(NULL)
  }
  if (is.logical(value)) {
    if (length(value) != 1L || is.na(value)) {
      stop("'", arg,
           "' must be TRUE, FALSE, NULL, or a single character string.")
    }
    return(if (isTRUE(value)) default else NULL)
  }
  if (is.character(value)) {
    if (length(value) != 1L || is.na(value)) {
      stop("'", arg,
           "' must be TRUE, FALSE, NULL, or a single character string.")
    }
    return(if (nzchar(value)) value else NULL)
  }
  stop("'", arg,
       "' must be TRUE, FALSE, NULL, or a single character string.")
}
.rhf_resolve_matrix_legend_args <- function(legend.args = list(),
                                           title,
                                           color.title = NULL,
                                           cex = 0.85,
                                           title.cex = 0.9) {
  .rhf_validate_named_list(legend.args, "legend.args")
  supported <- c("title", "color.title", "cex", "title.cex")
  unknown <- setdiff(names(legend.args), supported)
  if (length(unknown)) {
    stop("Unsupported name(s) in 'legend.args': ",
         paste(unknown, collapse = ", "),
         ". Supported names are: ",
         paste(supported, collapse = ", "), ".")
  }
  title.out <- title
  color.title.out <- color.title
  titles.were.identical <- identical(title, color.title)
  if ("title" %in% names(legend.args)) {
    title.out <- .rhf_resolve_matrix_legend_title(
      value = legend.args[["title"]],
      default = title,
      arg = "legend.args$title"
    )
    ## A suppressed general title suppresses both matrix-legend headings.
    ## A later, explicit color.title entry can selectively restore the color
    ## heading. If the two automatic titles represented the same quantity,
    ## a custom general title is propagated to both so it is drawn only once.
    if (is.null(title.out)) {
      color.title.out <- NULL
    }
    else if (titles.were.identical &&
             !("color.title" %in% names(legend.args))) {
      color.title.out <- title.out
    }
  }
  if ("color.title" %in% names(legend.args)) {
    color.title.out <- .rhf_resolve_matrix_legend_title(
      value = legend.args[["color.title"]],
      default = color.title,
      arg = "legend.args$color.title"
    )
  }
  get.cex <- function(name, default) {
    if (!(name %in% names(legend.args))) {
      return(default)
    }
    value <- legend.args[[name]]
    if (!is.numeric(value) || length(value) != 1L ||
        is.na(value) || !is.finite(value) || value <= 0) {
      stop("'legend.args$", name,
           "' must be a single positive finite numeric value.")
    }
    as.numeric(value)
  }
  list(
    title = title.out,
    color.title = color.title.out,
    cex = get.cex("cex", cex),
    title.cex = get.cex("title.cex", title.cex)
  )
}
.rhf_has_matrix_legend_title <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
}
.rhf_draw_dotmatrix_legend <- function(size.breaks,
                                       size.range,
                                       size.title,
                                       cex.range,
                                       alpha,
                                       color.by,
                                       color.range = NULL,
                                       color.title = NULL,
                                       point.color = "steelblue4",
                                       value.colors = c("grey85", "steelblue4"),
                                       sign.colors = c("firebrick3", "grey90", "steelblue4"),
                                       cex.text = 0.85,
                                       cex.title = 0.9) {
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 0.72), ylim = c(0, 1),
                        xaxs = "i", yaxs = "i")
  has.color <- color.by %in% c("value", "sign") &&
    length(color.range) == 2L && all(is.finite(color.range))
  size.breaks <- as.numeric(size.breaks)
  size.breaks <- sort(unique(size.breaks[is.finite(size.breaks)]),
                      decreasing = TRUE)
  size.breaks <- .rhf_thin_breaks(size.breaks, max.breaks = 4L)
  x.title <- 0.06
  x.dot <- 0.22
  x.size.lab <- 0.40
  if (length(size.breaks)) {
    panel.top <- if (has.color) 0.88 else 0.82
    panel.bottom <- if (has.color) 0.60 else 0.20
    size.y <- if (length(size.breaks) == 1L) {
      mean(c(panel.top, panel.bottom))
    }
    else {
      seq(panel.top, panel.bottom, length.out = length(size.breaks))
    }
    if (.rhf_has_matrix_legend_title(size.title)) {
      graphics::text(x.title,
                     min(0.97, panel.top + 0.08),
                     labels = size.title,
                     adj = c(0, 0.5),
                     font = 2,
                     cex = cex.title)
    }
    cex.val <- .rhf_rescale_from_range(size.breaks,
                                       from = size.range,
                                       to = cex.range)
    graphics::points(rep(x.dot, length(size.breaks)),
                     size.y,
                     pch = 16,
                     cex = cex.val,
                     col = grDevices::adjustcolor(point.color,
                                                  alpha.f = alpha))
    graphics::text(rep(x.size.lab, length(size.breaks)),
                   size.y,
                   labels = .rhf_format_legend_values(size.breaks),
                   adj = c(0, 0.5),
                   cex = cex.text)
  }
  else {
    if (.rhf_has_matrix_legend_title(size.title)) {
      graphics::text(x.title,
                     0.80,
                     labels = size.title,
                     adj = c(0, 0.5),
                     font = 2,
                     cex = cex.title)
    }
    graphics::text(x.title,
                   if (.rhf_has_matrix_legend_title(size.title)) 0.70 else 0.78,
                   labels = "No positive values",
                   adj = c(0, 0.5),
                   cex = cex.text)
  }
  if (has.color) {
    x0 <- 0.18
    x1 <- 0.34
    y0 <- 0.12
    y1 <- 0.43
    if (.rhf_has_matrix_legend_title(color.title) &&
        !identical(color.title, size.title)) {
      graphics::text(x.title,
                     y1 + 0.08,
                     labels = color.title,
                     adj = c(0, 0.5),
                     font = 2,
                     cex = cex.title)
    }
    n.bar <- 64L
    y.seq <- seq(y0, y1, length.out = n.bar + 1L)
    vals <- seq(color.range[1L], color.range[2L], length.out = n.bar)
    pal <- if (color.by == "value") {
      .rhf_map_palette(vals, value.colors, symmetric = FALSE)
    }
    else {
      .rhf_map_palette(vals, sign.colors, symmetric = TRUE)
    }
    pal <- grDevices::adjustcolor(pal, alpha.f = alpha)
    graphics::rect(rep(x0, n.bar), y.seq[-length(y.seq)],
                   rep(x1, n.bar), y.seq[-1L],
                   col = pal, border = pal)
    graphics::rect(x0, y0, x1, y1, border = "grey40")
    br <- if (color.by == "sign") {
      .rhf_pretty_breaks(color.range, n = 5L, symmetric = TRUE)
    }
    else {
      .rhf_pretty_breaks(color.range, n = 5L,
                         positive.only = FALSE,
                         symmetric = FALSE)
    }
    if (!length(br)) {
      br <- color.range
    }
    ypos <- .rhf_rescale_from_range(br,
                                    from = color.range,
                                    to = c(y0, y1))
    graphics::segments(x1, ypos, x1 + 0.035, ypos, col = "grey35")
    graphics::text(x1 + 0.055,
                   ypos,
                   labels = .rhf_format_legend_values(br),
                   adj = c(0, 0.5),
                   cex = cex.text)
  }
  invisible(TRUE)
}
########################################################################
## bar-matrix plot legend
########################################################################
.rhf_draw_barmatrix_legend <- function(height.breaks,
                                       height.range,
                                       height.title,
                                       bar.max.height,
                                       alpha,
                                       color.by,
                                       color.range = NULL,
                                       color.title = NULL,
                                       bar.color = "steelblue4",
                                       value.colors = c("grey85", "steelblue4"),
                                       sign.colors = c("firebrick3", "grey90", "steelblue4"),
                                       cex.text = 0.85,
                                       cex.title = 0.9) {
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 0.72), ylim = c(0, 1),
                        xaxs = "i", yaxs = "i")
  has.color <- color.by %in% c("value", "sign") &&
    length(color.range) == 2L && all(is.finite(color.range))
  has.height.title <- .rhf_has_matrix_legend_title(height.title)
  has.separate.color.title <- has.color &&
    .rhf_has_matrix_legend_title(color.title) &&
    !identical(color.title, height.title)
  height.breaks <- as.numeric(height.breaks)
  height.breaks <- sort(unique(height.breaks[is.finite(height.breaks)]),
                        decreasing = TRUE)
  height.breaks <- .rhf_thin_breaks(height.breaks, max.breaks = 4L)
  x.title <- 0.06
  x.bar <- 0.22
  x.height.lab <- 0.40
  if (length(height.breaks)) {
    height.labels <- .rhf_format_legend_values(height.breaks)
    label.height <- suppressWarnings(max(
      graphics::strheight(height.labels,
                          units = "user",
                          cex = cex.text),
      na.rm = TRUE
    ))
    if (!is.finite(label.height)) {
      label.height <- 0
    }
    ## Pack the reference bars into a compact block. The spacing is based on
    ## the larger of the text height and a small fixed cell size, while the
    ## maximum bar remains smaller than that spacing. This preserves a visible
    ## gap between bars without spreading a short legend over the full panel.
    if (has.color) {
      item.spacing <- max(0.078, 1.35 * label.height)
      available <- 0.27
      if (length(height.breaks) > 1L) {
        item.spacing <- min(item.spacing,
                            available / (length(height.breaks) - 1L))
      }
      block.center <- 0.755
      legend.bar.max <- min(0.055, 0.65 * item.spacing)
    }
    else {
      item.spacing <- max(0.115, 1.35 * label.height)
      available <- 0.50
      if (length(height.breaks) > 1L) {
        item.spacing <- min(item.spacing,
                            available / (length(height.breaks) - 1L))
      }
      block.center <- 0.50
      legend.bar.max <- min(0.10, 0.72 * item.spacing)
    }
    center.y <- block.center +
      ((length(height.breaks) + 1) / 2 - seq_along(height.breaks)) *
      item.spacing
    baseline.y <- center.y - legend.bar.max / 2
    if (has.height.title) {
      title.y <- min(0.97,
                     max(center.y) + legend.bar.max / 2 + 0.055)
      graphics::text(x.title,
                     title.y,
                     labels = height.title,
                     adj = c(0, 0.5),
                     font = 2,
                     cex = cex.title)
    }
    height.max <- max(height.range, na.rm = TRUE)
    scale.range <- if (is.finite(height.max) && height.max > 0) {
      c(0, height.max)
    }
    else {
      c(0, 1)
    }
    h.val <- .rhf_rescale_from_range(height.breaks,
                                     from = scale.range,
                                     to = c(0, legend.bar.max))
    graphics::segments(x.bar - 0.065,
                       baseline.y,
                       x.bar + 0.065,
                       baseline.y,
                       col = "grey60")
    graphics::rect(x.bar - 0.040,
                   baseline.y,
                   x.bar + 0.040,
                   baseline.y + h.val,
                   col = grDevices::adjustcolor(bar.color, alpha.f = alpha),
                   border = NA)
    graphics::text(rep(x.height.lab, length(height.breaks)),
                   center.y,
                   labels = height.labels,
                   adj = c(0, 0.5),
                   cex = cex.text)
  }
  else {
    if (has.height.title) {
      graphics::text(x.title,
                     0.80,
                     labels = height.title,
                     adj = c(0, 0.5),
                     font = 2,
                     cex = cex.title)
    }
    graphics::text(x.title,
                   if (has.height.title) 0.70 else 0.78,
                   labels = "No positive values",
                   adj = c(0, 0.5),
                   cex = cex.text)
  }
  if (has.color) {
    ## When both encodings describe the same quantity, no second title is
    ## needed, so the color key can move upward and use the otherwise empty
    ## space between the two legend sections.
    color.y.top <- if (has.separate.color.title) 0.43 else 0.52
    color.y.bottom <- 0.10
    n.grad <- 80L
    yy <- seq(color.y.bottom, color.y.top, length.out = n.grad + 1L)
    vals <- seq(color.range[1L], color.range[2L], length.out = n.grad)
    cols <- if (color.by == "sign") {
      .rhf_map_palette(vals, sign.colors, symmetric = TRUE)
    }
    else {
      .rhf_map_palette(vals, value.colors, symmetric = FALSE)
    }
    cols <- grDevices::adjustcolor(cols, alpha.f = alpha)
    if (has.separate.color.title) {
      graphics::text(x.title,
                     color.y.top + 0.08,
                     labels = color.title,
                     adj = c(0, 0.5),
                     font = 2,
                     cex = cex.title)
    }
    graphics::rect(rep(x.title, n.grad),
                   yy[-length(yy)],
                   rep(x.title + 0.10, n.grad),
                   yy[-1L],
                   col = cols,
                   border = cols)
    br <- .rhf_pretty_breaks(color.range,
                             n = 5L,
                             positive.only = FALSE,
                             symmetric = color.by == "sign")
    br <- br[br >= color.range[1L] & br <= color.range[2L]]
    br <- unique(br[is.finite(br)])
    if (length(br)) {
      by <- .rhf_rescale_from_range(br,
                                    from = color.range,
                                    to = c(color.y.bottom, color.y.top))
      graphics::segments(x.title + 0.10,
                         by,
                         x.title + 0.13,
                         by,
                         col = "grey45")
      graphics::text(rep(x.title + 0.16, length(br)),
                     by,
                     labels = .rhf_format_legend_values(br),
                     adj = c(0, 0.5),
                     cex = cex.text)
    }
  }
  invisible(TRUE)
}
.rhf_map_palette <- function(x, colors, symmetric = FALSE) {
  x <- as.numeric(x)
  colors <- as.character(colors)
  if (length(colors) < 1L || anyNA(colors) || any(!nzchar(colors))) {
    stop("A color palette must contain at least one non-missing color.")
  }
  ## Handle a one-color palette explicitly. This avoids relying on palette
  ## interpolation for a constant scale and guarantees that value.colors =
  ## "steelblue4" (and the analogous sign.colors case) is valid.
  pal <- if (length(colors) == 1L) {
    rep(colors, 64L)
  }
  else {
    grDevices::colorRampPalette(colors)(64L)
  }
  idx <- rep(1L, length(x))
  ok <- is.finite(x)
  if (!any(ok)) {
    return(pal[idx])
  }
  if (symmetric) {
    lim <- max(abs(x[ok]), na.rm = TRUE)
    if (!is.finite(lim) || lim <= 0) {
      idx[ok] <- ceiling(length(pal) / 2)
    }
    else {
      idx[ok] <- 1L + floor((x[ok] + lim) / (2 * lim) *
                              (length(pal) - 1L))
    }
  }
  else {
    rng <- range(x[ok], na.rm = TRUE)
    if (!is.finite(rng[1L]) || !is.finite(rng[2L]) ||
        rng[1L] == rng[2L]) {
      idx[ok] <- length(pal)
    }
    else {
      idx[ok] <- 1L + floor((x[ok] - rng[1L]) /
                              (rng[2L] - rng[1L]) *
                              (length(pal) - 1L))
    }
  }
  idx <- pmax(1L, pmin(length(pal), idx))
  pal[idx]
}
.rhf_open_plot_device <- function(out.file, width, height) {
  ext <- tolower(sub("^.*\\.", "", out.file))
  if (!nzchar(ext) || identical(ext, out.file) || ext == "pdf") {
    grDevices::pdf(file = out.file, width = width, height = height)
  }
  else if (ext == "png") {
    grDevices::png(filename = out.file, width = width, height = height,
                   units = "in", res = 300)
  }
  else if (ext %in% c("jpg", "jpeg")) {
    grDevices::jpeg(filename = out.file, width = width, height = height,
                    units = "in", res = 300, quality = 100)
  }
  else if (ext %in% c("tif", "tiff")) {
    grDevices::tiff(filename = out.file, width = width, height = height,
                    units = "in", res = 300, compression = "lzw")
  }
  else {
    stop("Unsupported plot file extension in 'out.file': ", out.file)
  }
  invisible(TRUE)
}
########################################################################
## label helpers for plotting
########################################################################
.rhf_unique_in_order <- function(x) {
  x <- as.character(x)
  x[!duplicated(x)]
}
.rhf_clean_dummy_suffix <- function(s) {
  s <- as.character(s)
  if (!nzchar(s)) {
    return(s)
  }
  s <- gsub("\\.+", " ", s)
  s <- gsub("_+", " ", s)
  s <- trimws(gsub("\\s+", " ", s))
  if (nzchar(s) && identical(s, toupper(s)) && nchar(s) >= 4) {
    s <- tools::toTitleCase(tolower(s))
  }
  s <- sub(" ([A-Z]{2,6})$", " (\\1)", s)
  s
}
.rhf_infer_prefix_label <- function(code, map) {
  code <- as.character(code)
  if (is.null(map) || is.null(names(map))) {
    return(NA_character_)
  }
  keys <- names(map)
  if (!length(keys)) {
    return(NA_character_)
  }
  hit <- keys[startsWith(code, keys)]
  if (!length(hit)) {
    return(NA_character_)
  }
  hit <- hit[order(nchar(hit), decreasing = TRUE)]
  for (k in hit) {
    suf <- substr(code, nchar(k) + 1L, nchar(code))
    if (!nzchar(suf)) {
      next
    }
    first.chr <- substr(suf, 1L, 1L)
    if (first.chr %in% c("_")) {
      next
    }
    if (!grepl("^[A-Za-z0-9]", suf)) {
      next
    }
    base.lab <- as.character(map[[k]])
    if (!nzchar(base.lab) || is.na(base.lab)) {
      next
    }
    suf.clean <- .rhf_clean_dummy_suffix(suf)
    if (!nzchar(suf.clean)) {
      return(base.lab)
    }
    return(paste0(base.lab, ": ", suf.clean))
  }
  NA_character_
}
.rhf_label_lookup <- function(x, map, infer_prefix = TRUE) {
  x <- as.character(x)
  if (is.null(map)) {
    return(x)
  }
  if (is.data.frame(map)) {
    if (ncol(map) < 2L) {
      stop("label map data.frame must have at least 2 columns")
    }
    nms <- names(map)
    if (all(c("variable", "label") %in% nms)) {
      map <- stats::setNames(as.character(map$label),
                             as.character(map$variable))
    }
    else if (all(c("outcome", "label") %in% nms)) {
      map <- stats::setNames(as.character(map$label),
                             as.character(map$outcome))
    }
    else {
      map <- stats::setNames(as.character(map[[2L]]),
                             as.character(map[[1L]]))
    }
  }
  if (is.null(names(map))) {
    return(x)
  }
  if (anyDuplicated(names(map))) {
    map <- map[!duplicated(names(map), fromLast = TRUE)]
  }
  idx <- match(x, names(map))
  out <- as.character(map[idx])
  miss <- is.na(out) | out == ""
  if (any(miss) && isTRUE(infer_prefix)) {
    out2 <- vapply(x[miss], .rhf_infer_prefix_label,
                   character(1), map = map)
    fill.ok <- !is.na(out2) & nzchar(out2)
    out[which(miss)[fill.ok]] <- out2[fill.ok]
    miss <- is.na(out) | out == ""
  }
  out[miss] <- x[miss]
  out
}
.rhf_make_unique_labels <- function(labels, codes) {
  dup <- duplicated(labels) | duplicated(labels, fromLast = TRUE)
  labels[dup] <- paste0(labels[dup], " [", codes[dup], "]")
  labels
}
