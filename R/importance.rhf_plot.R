dotmatrix.importance.rhf <- function(x,
       vars = NULL,
       top.n.union = 15L,
       variable.labels = NULL,
       time.labels = NULL,
       sort.by = c("q90", "sum", "max", "mean", "median", "alphabetical", "cluster", "none"),
       sort.abs = TRUE,
       transform = c("none", "log10"),
       color.by = c("value", "sign", "single", "none"),
       point.color = "steelblue4",
       value.colors = c("grey85", "steelblue4"),
       sign.colors = c("firebrick3", "grey90", "steelblue4"),
       pch = 16,
       cex.range = c(0.6, 3.2),
       size.cap = 0.99,
       color.cap = 0.99,
       alpha = 0.9,
       show.grid = FALSE,
       grid.col = "grey92",
       legend = TRUE,
       legend.args = list(),
       display.note = FALSE,
       xlab = "",
       ylab = "",
       main = "RHF time-localized VarPro importance",
       axis.cex = 0.7,
       var.cex = 0.7,
       time.label.srt = 45,
       save.plot = FALSE,
       out.file = "rhf_time_varpro_dotmatrix.pdf",
       width = 11,
       height = NULL,
       mar = NULL,
       legend.width = 0.7,
       point.args = list(),
       ...) {
  dots <- list(...)
  sort.by <- match.arg(sort.by)
  transform <- match.arg(transform)
  color.by <- match.arg(color.by)
  cex.range <- as.numeric(cex.range)
  if (length(cex.range) != 2L || any(!is.finite(cex.range)) ||
      any(cex.range < 0)) {
    stop("'cex.range' must be a length-2 nonnegative numeric vector.")
  }
  alpha <- as.numeric(alpha)[1L]
  if (!is.finite(alpha) || alpha < 0 || alpha > 1) {
    stop("'alpha' must be a numeric value in [0, 1].")
  }
  legend.width <- as.numeric(legend.width)[1L]
  if (!is.finite(legend.width) || legend.width <= 0) {
    stop("'legend.width' must be a positive numeric value.")
  }
  .rhf_validate_named_list(point.args, "point.args")
  plot.data <- .rhf_importance_plot_data(x)
  mat <- plot.data$mat
  mat <- .rhf_select_dotmatrix_variables(mat = mat,
                                         vars = vars,
                                         top.n.union = top.n.union,
                                         sort.abs = sort.abs)
  var.order <- .rhf_order_dotmatrix_variables(mat = mat,
                                              variable.labels = variable.labels,
                                              sort.by = sort.by,
                                              sort.abs = sort.abs)
  var.order <- .rhf_unique_in_order(var.order)
  mat <- mat[var.order, , drop = FALSE]
  var.codes <- rownames(mat)
  time.codes <- colnames(mat)
  time.values <- plot.data$time.values
  var.labels <- .rhf_label_lookup(var.codes,
                                  variable.labels,
                                  infer_prefix = TRUE)
  var.labels <- .rhf_make_unique_labels(var.labels, var.codes)
  x.labels <- .rhf_resolve_time_labels(time.codes = time.codes,
                                       time.values = time.values,
                                       time.labels = time.labels)
  has.negative <- any(mat[is.finite(mat)] < 0)
  if (has.negative && color.by != "sign") {
    warning("Negative importance values are omitted unless 'color.by = \"sign\"'.",
            call. = FALSE)
  }
  if (color.by == "sign") {
    size.metric <- abs(mat)
    color.metric <- mat
    size.title <- if (transform == "log10") {
      "log10(|Score| + 1)"
    }
    else {
      "|Score|"
    }
    color.title <- "Score"
  }
  else {
    size.metric <- pmax(mat, 0)
    color.metric <- if (color.by == "value") size.metric else NULL
    size.title <- if (transform == "log10") {
      "log10(Score + 1)"
    }
    else {
      "Score"
    }
    color.title <- size.title
  }
  if (transform == "log10") {
    size.metric <- log10(size.metric + 1)
    if (color.by == "value") {
      color.metric <- size.metric
    }
  }
  legend.options <- .rhf_resolve_matrix_legend_args(
    legend.args = legend.args,
    title = size.title,
    color.title = color.title
  )
  size.cap.info <- .rhf_cap_values(size.metric,
                                   cap = size.cap,
                                   symmetric = FALSE,
                                   positive.only = TRUE,
                                   arg = "size.cap")
  size.metric.display <- matrix(size.cap.info$values,
                                nrow = nrow(mat),
                                ncol = ncol(mat),
                                dimnames = dimnames(mat))
  if (color.by == "value") {
    color.cap.info <- .rhf_cap_values(color.metric,
                                      cap = color.cap,
                                      symmetric = FALSE,
                                      positive.only = FALSE,
                                      arg = "color.cap")
    color.metric.display <- matrix(color.cap.info$values,
                                   nrow = nrow(mat),
                                   ncol = ncol(mat),
                                   dimnames = dimnames(mat))
  }
  else if (color.by == "sign") {
    color.cap.info <- .rhf_cap_values(color.metric,
                                      cap = color.cap,
                                      symmetric = TRUE,
                                      positive.only = FALSE,
                                      arg = "color.cap")
    color.metric.display <- matrix(color.cap.info$values,
                                   nrow = nrow(mat),
                                   ncol = ncol(mat),
                                   dimnames = dimnames(mat))
  }
  else {
    color.cap.info <- list(applied = FALSE,
                           label = "none",
                           cap = NA_real_,
                           range = c(NA_real_, NA_real_))
    color.metric.display <- color.metric
  }
  draw <- is.finite(size.metric.display) & (size.metric.display > 0)
  cex.mat <- matrix(0, nrow = nrow(mat), ncol = ncol(mat))
  size.range <- if (any(draw)) {
    range(size.metric.display[draw], na.rm = TRUE)
  }
  else {
    c(0, 1)
  }
  if (any(draw)) {
    cex.mat[draw] <- .rhf_rescale_from_range(size.metric.display[draw],
                                             from = size.range,
                                             to = cex.range)
  }
  if (color.by == "none") {
    col.mat <- matrix("black", nrow = nrow(mat), ncol = ncol(mat))
  }
  else if (color.by == "single") {
    col.mat <- matrix(point.color, nrow = nrow(mat), ncol = ncol(mat))
  }
  else if (color.by == "value") {
    col.mat <- matrix(.rhf_map_palette(color.metric.display,
                                       value.colors,
                                       symmetric = FALSE),
                      nrow = nrow(mat), ncol = ncol(mat))
  }
  else {
    col.mat <- matrix(.rhf_map_palette(color.metric.display,
                                       sign.colors,
                                       symmetric = TRUE),
                      nrow = nrow(mat), ncol = ncol(mat))
  }
  if (any(draw)) {
    col.mat[draw] <- grDevices::adjustcolor(col.mat[draw], alpha.f = alpha)
  }
  display.note.text <- NULL
  if (isTRUE(display.note)) {
    if (isTRUE(size.cap.info$applied) &&
        isTRUE(color.cap.info$applied) &&
        identical(size.cap.info$label, color.cap.info$label)) {
      display.note.text <- paste0("plot size/color capped at ",
                                  size.cap.info$label)
    }
    else {
      note.parts <- character(0)
      if (isTRUE(size.cap.info$applied)) {
        note.parts <- c(note.parts,
                        paste0("size capped at ", size.cap.info$label))
      }
      if (isTRUE(color.cap.info$applied)) {
        note.parts <- c(note.parts,
                        paste0("color capped at ", color.cap.info$label))
      }
      if (length(note.parts)) {
        display.note.text <- paste0("plot ",
                                    paste(note.parts, collapse = "; "))
      }
    }
  }
  if (is.null(height)) {
    height <- max(5.5, 0.22 * nrow(mat) + 1.8)
  }
  width <- as.numeric(width)[1L]
  height <- as.numeric(height)[1L]
  if (!is.finite(width) || width <= 0 ||
      !is.finite(height) || height <= 0) {
    stop("'width' and 'height' must be positive numeric values.")
  }
  if (isTRUE(save.plot)) {
    .rhf_open_plot_device(out.file = out.file,
                          width = width,
                          height = height)
    on.exit(grDevices::dev.off(), add = TRUE)
  }
  old.par <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(old.par), add = TRUE)
  if (is.null(mar)) {
    mar <- .rhf_dotmatrix_default_mar(var.labels = var.labels,
                                      x.labels = x.labels,
                                      var.cex = var.cex,
                                      axis.cex = axis.cex,
                                      time.label.srt = time.label.srt,
                                      legend = legend)
  }
  mar <- as.numeric(mar)
  if (length(mar) != 4L || any(!is.finite(mar)) || any(mar < 0)) {
    stop("'mar' must be a length-4 nonnegative numeric vector.")
  }
  if (isTRUE(legend)) {
    graphics::layout(matrix(c(1, 2), nrow = 1L),
                     widths = c(5.6, legend.width))
    on.exit(graphics::layout(1), add = TRUE)
  }
  graphics::par(mar = mar, mgp = c(0.9, 0.12, 0), xpd = NA)
  x.pos <- seq_len(ncol(mat))
  y.pos <- rev(seq_len(nrow(mat)))
  matrix.xlim <- c(0.5, ncol(mat) + 0.5)
  matrix.ylim <- c(0.5, nrow(mat) + 0.5)
  frame.args <- list(
    x = NA_real_,
    xlim = matrix.xlim,
    ylim = matrix.ylim,
    xlab = xlab,
    ylab = ylab,
    xaxt = "n",
    yaxt = "n",
    bty = "n",
    xaxs = "i",
    yaxs = "i",
    main = main
  )
  .rhf_graphics_call(graphics::plot,
                     fixed = frame.args,
                     extra = dots,
                     protected = names(frame.args),
                     arg = "...")
  if (isTRUE(show.grid)) {
    .rhf_draw_matrix_guides(x.at = x.pos,
                            y.at = y.pos,
                            xlim = matrix.xlim,
                            ylim = matrix.ylim,
                            col = grid.col,
                            lty = 3)
  }
  if (!is.null(display.note.text) && nzchar(display.note.text)) {
    graphics::mtext(display.note.text,
                    side = 3,
                    line = 0.30,
                    adj = 1,
                    cex = 0.75)
  }
  xx <- rep(x.pos, each = nrow(mat))
  yy <- rep(y.pos, times = ncol(mat))
  keep <- as.vector(draw)
  if (any(keep)) {
    point.fixed <- list(
      x = xx[keep],
      y = yy[keep],
      pch = pch,
      cex = as.vector(cex.mat)[keep],
      col = as.vector(col.mat)[keep]
    )
    .rhf_graphics_call(graphics::points,
                       fixed = point.fixed,
                       extra = point.args,
                       protected = names(point.fixed),
                       arg = "point.args")
  }
  graphics::axis(2,
                 at = y.pos,
                 labels = var.labels,
                 las = 1,
                 tick = FALSE,
                 cex.axis = var.cex)
  .rhf_draw_dotmatrix_xlabels(at = x.pos,
                              labels = x.labels,
                              cex = axis.cex,
                              gap.lines = 0.10,
                              srt = time.label.srt)
  graphics::box()
  if (isTRUE(legend)) {
    graphics::par(mar = c(mar[1L], 0.10, mar[3L], 0.10), xpd = NA)
    size.breaks <- if (any(draw)) {
      .rhf_pretty_breaks(size.metric.display[draw],
                         n = 4L,
                         positive.only = TRUE,
                         symmetric = FALSE)
    }
    else {
      numeric(0)
    }
    color.range <- NULL
    if (color.by == "value" && any(draw)) {
      color.range <- range(color.metric.display[draw], na.rm = TRUE)
    }
    if (color.by == "sign") {
      finite.color <- color.metric.display[is.finite(color.metric.display)]
      if (length(finite.color)) {
        lim <- max(abs(finite.color), na.rm = TRUE)
        if (is.finite(lim) && lim > 0) {
          color.range <- c(-lim, lim)
        }
      }
    }
    legend.point.color <- if (color.by == "none") "black" else point.color
    .rhf_draw_dotmatrix_legend(size.breaks = size.breaks,
                               size.range = size.range,
                               size.title = legend.options$title,
                               cex.range = cex.range,
                               alpha = alpha,
                               color.by = color.by,
                               color.range = color.range,
                               color.title = legend.options$color.title,
                               point.color = legend.point.color,
                               value.colors = value.colors,
                               sign.colors = sign.colors,
                               cex.text = legend.options$cex,
                               cex.title = legend.options$title.cex)
  }
  invisible(list(matrix = mat,
                 variables = var.codes,
                 labels = var.labels,
                 times = time.values,
                 time.labels = x.labels,
                 size.metric = size.metric,
                 size.metric.display = size.metric.display,
                 color.metric = color.metric,
                 color.metric.display = color.metric.display,
                 point.cex = cex.mat,
                 size.cap = size.cap.info,
                 color.cap = color.cap.info,
                 legend.args = legend.options,
                 display.note = display.note.text,
                 mar = mar))
}
dotmatrix.importance <- dotmatrix.importance.rhf
barplot.importance.rhf <- function(x,
       vars = NULL,
       top.n.union = 15L,
       variable.labels = NULL,
       time.labels = NULL,
       sort.by = c("q90", "sum", "max", "mean", "median", "alphabetical", "cluster", "none"),
       sort.abs = TRUE,
       transform = c("none", "log10"),
       color.by = c("value", "sign", "single", "none"),
       bar.color = "steelblue4",
       value.colors = c("grey85", "steelblue4"),
       sign.colors = c("firebrick3", "grey90", "steelblue4"),
       bar.width = 0.65,
       bar.max.height = NULL,
       size.cap = 0.99,
       color.cap = 0.99,
       alpha = 0.9,
       show.grid = FALSE,
       grid.col = "grey92",
       zero.line = TRUE,
       zero.col = "grey65",
       legend = TRUE,
       legend.args = list(),
       display.note = FALSE,
       xlab = "",
       ylab = "",
       main = "RHF time-localized VarPro importance",
       axis.cex = 0.7,
       var.cex = 0.7,
       time.label.srt = 45,
       save.plot = FALSE,
       out.file = "rhf_time_varpro_barplot.pdf",
       width = 11,
       height = NULL,
       mar = NULL,
       legend.width = 0.7,
       border = NA,
       bar.args = list(),
       ...) {
  dots <- list(...)
  sort.by <- match.arg(sort.by)
  transform <- match.arg(transform)
  color.by <- match.arg(color.by)
  bar.width <- as.numeric(bar.width)[1L]
  if (!is.finite(bar.width) || bar.width <= 0 || bar.width > 1) {
    stop("'bar.width' must be a numeric value in (0, 1].")
  }
  if (is.null(bar.max.height)) {
    bar.max.height <- if (color.by == "sign") 0.42 else 0.85
  }
  bar.max.height <- as.numeric(bar.max.height)[1L]
  if (!is.finite(bar.max.height) || bar.max.height <= 0) {
    stop("'bar.max.height' must be a positive numeric value.")
  }
  if (color.by == "sign" && bar.max.height >= 0.5) {
    stop("'bar.max.height' must be less than 0.5 when 'color.by = \"sign\"'.")
  }
  if (color.by != "sign" && bar.max.height >= 1) {
    stop("'bar.max.height' must be less than 1 when 'color.by' is not 'sign'.")
  }
  alpha <- as.numeric(alpha)[1L]
  if (!is.finite(alpha) || alpha < 0 || alpha > 1) {
    stop("'alpha' must be a numeric value in [0, 1].")
  }
  legend.width <- as.numeric(legend.width)[1L]
  if (!is.finite(legend.width) || legend.width <= 0) {
    stop("'legend.width' must be a positive numeric value.")
  }
  .rhf_validate_named_list(bar.args, "bar.args")
  plot.data <- .rhf_importance_plot_data(x)
  mat <- plot.data$mat
  mat <- .rhf_select_dotmatrix_variables(mat = mat,
                                         vars = vars,
                                         top.n.union = top.n.union,
                                         sort.abs = sort.abs)
  var.order <- .rhf_order_dotmatrix_variables(mat = mat,
                                              variable.labels = variable.labels,
                                              sort.by = sort.by,
                                              sort.abs = sort.abs)
  var.order <- .rhf_unique_in_order(var.order)
  mat <- mat[var.order, , drop = FALSE]
  var.codes <- rownames(mat)
  time.codes <- colnames(mat)
  time.values <- plot.data$time.values
  var.labels <- .rhf_label_lookup(var.codes,
                                  variable.labels,
                                  infer_prefix = TRUE)
  var.labels <- .rhf_make_unique_labels(var.labels, var.codes)
  x.labels <- .rhf_resolve_time_labels(time.codes = time.codes,
                                       time.values = time.values,
                                       time.labels = time.labels)
  has.negative <- any(mat[is.finite(mat)] < 0)
  if (has.negative && color.by != "sign") {
    warning("Negative importance values are omitted unless 'color.by = \"sign\"'.",
            call. = FALSE)
  }
  if (color.by == "sign") {
    height.metric <- abs(mat)
    color.metric <- mat
    height.title <- if (transform == "log10") {
      "log10(|Score| + 1)"
    }
    else {
      "|Score|"
    }
    color.title <- "Score"
  }
  else {
    height.metric <- pmax(mat, 0)
    color.metric <- if (color.by == "value") height.metric else NULL
    height.title <- if (transform == "log10") {
      "log10(Score + 1)"
    }
    else {
      "Score"
    }
    color.title <- height.title
  }
  if (transform == "log10") {
    height.metric <- log10(height.metric + 1)
    if (color.by == "value") {
      color.metric <- height.metric
    }
  }
  legend.options <- .rhf_resolve_matrix_legend_args(
    legend.args = legend.args,
    title = height.title,
    color.title = color.title
  )
  height.cap.info <- .rhf_cap_values(height.metric,
                                     cap = size.cap,
                                     symmetric = FALSE,
                                     positive.only = TRUE,
                                     arg = "size.cap")
  height.metric.display <- matrix(height.cap.info$values,
                                  nrow = nrow(mat),
                                  ncol = ncol(mat),
                                  dimnames = dimnames(mat))
  if (color.by == "value") {
    color.cap.info <- .rhf_cap_values(color.metric,
                                      cap = color.cap,
                                      symmetric = FALSE,
                                      positive.only = FALSE,
                                      arg = "color.cap")
    color.metric.display <- matrix(color.cap.info$values,
                                   nrow = nrow(mat),
                                   ncol = ncol(mat),
                                   dimnames = dimnames(mat))
  }
  else if (color.by == "sign") {
    color.cap.info <- .rhf_cap_values(color.metric,
                                      cap = color.cap,
                                      symmetric = TRUE,
                                      positive.only = FALSE,
                                      arg = "color.cap")
    color.metric.display <- matrix(color.cap.info$values,
                                   nrow = nrow(mat),
                                   ncol = ncol(mat),
                                   dimnames = dimnames(mat))
  }
  else {
    color.cap.info <- list(applied = FALSE,
                           label = "none",
                           cap = NA_real_,
                           range = c(NA_real_, NA_real_))
    color.metric.display <- color.metric
  }
  draw <- is.finite(height.metric.display) & (height.metric.display > 0)
  bar.height.mat <- matrix(0, nrow = nrow(mat), ncol = ncol(mat))
  height.range <- if (any(draw)) {
    c(0, max(height.metric.display[draw], na.rm = TRUE))
  }
  else {
    c(0, 1)
  }
  if (any(draw)) {
    bar.height.mat[draw] <- .rhf_rescale_from_range(
      height.metric.display[draw],
      from = height.range,
      to = c(0, bar.max.height)
    )
  }
  if (color.by == "none") {
    col.mat <- matrix("black", nrow = nrow(mat), ncol = ncol(mat))
  }
  else if (color.by == "single") {
    col.mat <- matrix(bar.color, nrow = nrow(mat), ncol = ncol(mat))
  }
  else if (color.by == "value") {
    col.mat <- matrix(.rhf_map_palette(color.metric.display,
                                       value.colors,
                                       symmetric = FALSE),
                      nrow = nrow(mat), ncol = ncol(mat))
  }
  else {
    col.mat <- matrix(.rhf_map_palette(color.metric.display,
                                       sign.colors,
                                       symmetric = TRUE),
                      nrow = nrow(mat), ncol = ncol(mat))
  }
  if (any(draw)) {
    col.mat[draw] <- grDevices::adjustcolor(col.mat[draw], alpha.f = alpha)
  }
  display.note.text <- NULL
  if (isTRUE(display.note)) {
    if (isTRUE(height.cap.info$applied) &&
        isTRUE(color.cap.info$applied) &&
        identical(height.cap.info$label, color.cap.info$label)) {
      display.note.text <- paste0("plot height/color capped at ",
                                  height.cap.info$label)
    }
    else {
      note.parts <- character(0)
      if (isTRUE(height.cap.info$applied)) {
        note.parts <- c(note.parts,
                        paste0("bar height capped at ",
                               height.cap.info$label))
      }
      if (isTRUE(color.cap.info$applied)) {
        note.parts <- c(note.parts,
                        paste0("color capped at ", color.cap.info$label))
      }
      if (length(note.parts)) {
        display.note.text <- paste0("plot ",
                                    paste(note.parts, collapse = "; "))
      }
    }
  }
  if (is.null(height)) {
    height <- max(5.5, 0.22 * nrow(mat) + 1.8)
  }
  width <- as.numeric(width)[1L]
  height <- as.numeric(height)[1L]
  if (!is.finite(width) || width <= 0 ||
      !is.finite(height) || height <= 0) {
    stop("'width' and 'height' must be positive numeric values.")
  }
  if (isTRUE(save.plot)) {
    .rhf_open_plot_device(out.file = out.file,
                          width = width,
                          height = height)
    on.exit(grDevices::dev.off(), add = TRUE)
  }
  old.par <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(old.par), add = TRUE)
  if (is.null(mar)) {
    mar <- .rhf_dotmatrix_default_mar(var.labels = var.labels,
                                      x.labels = x.labels,
                                      var.cex = var.cex,
                                      axis.cex = axis.cex,
                                      time.label.srt = time.label.srt,
                                      legend = legend)
  }
  mar <- as.numeric(mar)
  if (length(mar) != 4L || any(!is.finite(mar)) || any(mar < 0)) {
    stop("'mar' must be a length-4 nonnegative numeric vector.")
  }
  if (isTRUE(legend)) {
    graphics::layout(matrix(c(1, 2), nrow = 1L),
                     widths = c(5.6, legend.width))
    on.exit(graphics::layout(1), add = TRUE)
  }
  graphics::par(mar = mar, mgp = c(0.9, 0.12, 0), xpd = NA)
  x.pos <- seq_len(ncol(mat))
  y.pos <- rev(seq_len(nrow(mat)))
  matrix.xlim <- c(0.5, ncol(mat) + 0.5)
  matrix.ylim <- c(0.5, nrow(mat) + 0.5)
  frame.args <- list(
    x = NA_real_,
    xlim = matrix.xlim,
    ylim = matrix.ylim,
    xlab = xlab,
    ylab = ylab,
    xaxt = "n",
    yaxt = "n",
    bty = "n",
    xaxs = "i",
    yaxs = "i",
    main = main
  )
  .rhf_graphics_call(graphics::plot,
                     fixed = frame.args,
                     extra = dots,
                     protected = names(frame.args),
                     arg = "...")
  if (isTRUE(show.grid)) {
    .rhf_draw_matrix_guides(x.at = x.pos,
                            y.at = y.pos,
                            xlim = matrix.xlim,
                            ylim = matrix.ylim,
                            col = grid.col,
                            lty = 3)
  }
  ## In a signed bar matrix, each horizontal row guide is also the zero
  ## reference for that variable. Do not cover a requested dashed grid with
  ## a second solid line; use the explicit zero-line style only when the grid
  ## itself is not being drawn.
  if (color.by == "sign" && isTRUE(zero.line) && !isTRUE(show.grid)) {
    .rhf_draw_matrix_guides(y.at = y.pos,
                            xlim = matrix.xlim,
                            ylim = matrix.ylim,
                            col = zero.col,
                            lty = 1)
  }
  if (!is.null(display.note.text) && nzchar(display.note.text)) {
    graphics::mtext(display.note.text,
                    side = 3,
                    line = 0.30,
                    adj = 1,
                    cex = 0.75)
  }
  xx <- rep(x.pos, each = nrow(mat))
  yy <- rep(y.pos, times = ncol(mat))
  hh <- as.vector(bar.height.mat)
  keep <- as.vector(draw)
  xleft <- xx - bar.width / 2
  xright <- xx + bar.width / 2
  if (color.by == "sign") {
    dir <- sign(as.vector(color.metric.display))
    dir[!is.finite(dir)] <- 1
    ybottom <- ifelse(dir >= 0, yy, yy - hh)
    ytop <- ifelse(dir >= 0, yy + hh, yy)
  }
  else {
    ybottom <- yy - bar.max.height / 2
    ytop <- ybottom + hh
  }
  if (any(keep)) {
    bar.fixed <- list(
      xleft = xleft[keep],
      ybottom = ybottom[keep],
      xright = xright[keep],
      ytop = ytop[keep],
      col = as.vector(col.mat)[keep],
      border = border
    )
    .rhf_graphics_call(graphics::rect,
                       fixed = bar.fixed,
                       extra = bar.args,
                       protected = names(bar.fixed),
                       arg = "bar.args")
  }
  graphics::axis(2,
                 at = y.pos,
                 labels = var.labels,
                 las = 1,
                 tick = FALSE,
                 cex.axis = var.cex)
  .rhf_draw_dotmatrix_xlabels(at = x.pos,
                              labels = x.labels,
                              cex = axis.cex,
                              gap.lines = 0.10,
                              srt = time.label.srt)
  graphics::box()
  if (isTRUE(legend)) {
    graphics::par(mar = c(mar[1L], 0.10, mar[3L], 0.10), xpd = NA)
    height.breaks <- if (any(draw)) {
      .rhf_pretty_breaks(height.metric.display[draw],
                         n = 4L,
                         positive.only = TRUE,
                         symmetric = FALSE)
    }
    else {
      numeric(0)
    }
    color.range <- NULL
    if (color.by == "value" && any(draw)) {
      color.range <- range(color.metric.display[draw], na.rm = TRUE)
    }
    if (color.by == "sign") {
      finite.color <- color.metric.display[is.finite(color.metric.display)]
      if (length(finite.color)) {
        lim <- max(abs(finite.color), na.rm = TRUE)
        if (is.finite(lim) && lim > 0) {
          color.range <- c(-lim, lim)
        }
      }
    }
    legend.bar.color <- if (color.by == "none") "black" else bar.color
    .rhf_draw_barmatrix_legend(height.breaks = height.breaks,
                               height.range = height.range,
                               height.title = legend.options$title,
                               bar.max.height = bar.max.height,
                               alpha = alpha,
                               color.by = color.by,
                               color.range = color.range,
                               color.title = legend.options$color.title,
                               bar.color = legend.bar.color,
                               value.colors = value.colors,
                               sign.colors = sign.colors,
                               cex.text = legend.options$cex,
                               cex.title = legend.options$title.cex)
  }
  invisible(list(matrix = mat,
                 variables = var.codes,
                 labels = var.labels,
                 times = time.values,
                 time.labels = x.labels,
                 height.metric = height.metric,
                 height.metric.display = height.metric.display,
                 size.metric = height.metric,
                 size.metric.display = height.metric.display,
                 color.metric = color.metric,
                 color.metric.display = color.metric.display,
                 bar.height = bar.height.mat,
                 height.cap = height.cap.info,
                 size.cap = height.cap.info,
                 color.cap = color.cap.info,
                 legend.args = legend.options,
                 display.note = display.note.text,
                 mar = mar))
}
barplot.importance <- barplot.importance.rhf
########################################################################
## plotting method
########################################################################
plot.importance.rhf <- function(x,
                 type = c("barplot", "dotmatrix", "lines"),
                 vars = NULL,
                 variable.labels = NULL,
                 top = 10L,
                 rank.by = c("q90", "median", "mean", "max"),
                 curve = c("step", "line", "lowess"),
                 smooth.f = 2/3,
                 display.cap = 0.99,
                 display.note = FALSE,
                 xlab = NULL,
                 ylab = NULL,
                 lty = 1,
                 lwd = 2.0,
                 line.colors = NULL,
                 line.args = list(),
                 legend = TRUE,
                 legend.args = list(),
                 ...) {
  dots <- list(...)
  type <- match.arg(type)
  .rhf_validate_named_list(legend.args, "legend.args")
  if (type == "dotmatrix") {
    if (is.null(xlab)) {
      xlab <- ""
    }
    if (is.null(ylab)) {
      ylab <- ""
    }
    args <- c(list(x = x,
                   vars = vars,
                   variable.labels = variable.labels,
                   legend = legend,
                   legend.args = legend.args,
                   display.note = display.note,
                   xlab = xlab,
                   ylab = ylab),
              dots)
    return(do.call(dotmatrix.importance.rhf, args))
  }
  if (type == "barplot") {
    if (is.null(xlab)) {
      xlab <- ""
    }
    if (is.null(ylab)) {
      ylab <- ""
    }
    args <- c(list(x = x,
                   vars = vars,
                   variable.labels = variable.labels,
                   legend = legend,
                   legend.args = legend.args,
                   display.note = display.note,
                   xlab = xlab,
                   ylab = ylab),
              dots)
    return(do.call(barplot.importance.rhf, args))
  }
  rank.by <- match.arg(rank.by)
  curve <- match.arg(curve)
  top <- as.integer(top)[1L]
  if (!is.finite(top) || top < 1L) {
    stop("'top' must be a positive integer.")
  }
  smooth.f <- as.numeric(smooth.f)[1L]
  if (!is.finite(smooth.f) || smooth.f <= 0) {
    stop("'smooth.f' must be a positive numeric value.")
  }
  .rhf_validate_named_list(line.args, "line.args")
  .rhf_validate_named_list(legend.args, "legend.args")
  plot.data <- .rhf_importance_plot_data(x)
  mat <- plot.data$mat
  if (is.null(vars)) {
    score <- .rhf_row_summary(mat, rank.by = rank.by)
    ord <- order(score, decreasing = TRUE, na.last = TRUE)
    vars <- rownames(mat)[head(ord, top)]
  }
  vars <- intersect(as.character(vars), rownames(mat))
  if (!length(vars)) {
    stop("No requested variables found in the importance object.")
  }
  zz.raw <- mat[vars, , drop = FALSE]
  xx <- plot.data$time.values
  if (is.null(xlab)) {
    xlab <- "Time"
  }
  if (is.null(ylab)) {
    ylab <- "Localized Score"
  }
  cap.info <- .rhf_cap_values(
    zz.raw,
    cap = display.cap,
    symmetric = any(zz.raw[is.finite(zz.raw)] < 0),
    positive.only = FALSE,
    arg = "display.cap"
  )
  zz <- matrix(cap.info$values,
               nrow = nrow(zz.raw),
               ncol = ncol(zz.raw),
               dimnames = dimnames(zz.raw))
  finite.zz <- zz[is.finite(zz)]
  if (!length(finite.zz)) {
    ylim <- c(0, 1)
  }
  else if (min(finite.zz) >= 0 &&
           diff(range(finite.zz)) == 0) {
    upper <- max(1, finite.zz[1L] * 1.05)
    ylim <- c(0, upper)
  }
  else {
    ylim <- .rhf_expand_plot_range(finite.zz)
  }
  finite.xx <- xx[is.finite(xx)]
  if (!length(finite.xx)) {
    stop("No finite time values are available for the line plot.")
  }
  xlim <- .rhf_expand_plot_range(finite.xx,
                                 fallback = c(0, 1),
                                 relative.pad = 0.02,
                                 absolute.pad = 0.5)
  if (is.null(line.colors)) {
    cols <- seq_len(nrow(zz))
  }
  else {
    if (!length(line.colors) || anyNA(line.colors)) {
      stop("'line.colors' must contain at least one non-missing color.")
    }
    cols <- rep_len(line.colors, nrow(zz))
  }
  lty <- rep_len(lty, nrow(zz))
  lwd <- rep_len(lwd, nrow(zz))
  frame.args <- list(
    x = NA_real_,
    xlim = xlim,
    ylim = ylim,
    xlab = xlab,
    ylab = ylab,
    type = "n"
  )
  .rhf_graphics_call(graphics::plot,
                     fixed = frame.args,
                     extra = dots,
                     protected = c("x", "xlab", "ylab", "type"),
                     arg = "...")
  for (i in seq_len(nrow(zz))) {
    ok <- is.finite(xx) & is.finite(zz[i, ])
    if (sum(ok) < 2L) {
      next
    }
    if (curve == "lowess") {
      sm <- stats::lowess(xx[ok], zz[i, ok], f = smooth.f, iter = 0)
      line.x <- sm$x
      line.y <- sm$y
      line.type <- "l"
    }
    else {
      line.x <- xx[ok]
      line.y <- zz[i, ok]
      line.type <- if (curve == "step") "s" else "l"
    }
    line.fixed <- list(
      x = line.x,
      y = line.y,
      type = line.type,
      col = cols[i],
      lty = lty[i],
      lwd = lwd[i]
    )
    .rhf_graphics_call(graphics::lines,
                       fixed = line.fixed,
                       extra = line.args,
                       protected = names(line.fixed),
                       arg = "line.args")
  }
  if (isTRUE(display.note) && isTRUE(cap.info$applied)) {
    graphics::mtext(paste0("plot capped at ", cap.info$label),
                    side = 3,
                    line = 0.30,
                    adj = 1,
                    cex = 0.75)
  }
  var.labels <- .rhf_label_lookup(vars,
                                  variable.labels,
                                  infer_prefix = TRUE)
  var.labels <- .rhf_make_unique_labels(var.labels, vars)
  if (isTRUE(legend)) {
    legend.fixed <- list(
      x = "topright",
      legend = var.labels,
      col = cols,
      lty = lty,
      lwd = lwd,
      bty = "n"
    )
    .rhf_graphics_call(graphics::legend,
                       fixed = legend.fixed,
                       extra = legend.args,
                       protected = c("legend", "col", "lty", "lwd"),
                       arg = "legend.args")
  }
  attr(zz, "variables") <- vars
  attr(zz, "labels") <- var.labels
  attr(zz, "times") <- xx
  attr(zz, "display.cap") <- cap.info
  attr(zz, "legend.args") <- legend.args
  invisible(zz)
}
