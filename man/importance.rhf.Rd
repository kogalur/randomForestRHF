\name{importance.rhf}
\alias{importance.rhf}
\alias{varpro.cache.rhf}
\alias{varpro.cache}
\alias{print.importance.rhf}
\alias{as.data.frame.importance.rhf}
\alias{plot.importance.rhf}
\alias{dotmatrix.importance.rhf}
\alias{dotmatrix.importance}
\alias{barplot.importance.rhf}
\alias{barplot.importance}
\title{Time-localized VarPro importance for random hazard forests}

\description{
Computes time-localized variable importance for a random hazard forest
(RHF) by using VarPro (variable priority) importance and restricting
rule and near-miss memberships to pseudo-individuals whose start-stop
intervals overlap selected windows from the master time grid
\code{time.interest}. The working response used for VarPro importance is
now taken directly from the RHF object as the logarithm of the upstream
integrated hazard exposure, giving a fast localized view of how variable
importance evolves over time.
}

\usage{
importance.rhf(o,
 cache = NULL,
 time.index = NULL,
 trim = 0.1,
 sort = TRUE,
 max.rules.tree,
 max.tree,
 eps = 1e-6,
 y.external = NULL,
 verbose = FALSE,
 ...)

varpro.cache.rhf(o,
 max.rules.tree = 150L,
 max.tree = 150L,
 y.external = NULL,
 eps = 1e-6,
 verbose = FALSE)

\method{print}{importance.rhf}(x,
 top = 10L,
 rank.by = c("q90", "median", "mean", "max"),
 digits = 4L,
 scientific.threshold = 1e4,
 ...)

\method{as.data.frame}{importance.rhf}(x,
  row.names = NULL,
  optional = FALSE,
  format = c("long", "variable_by_time", "time_by_variable"),
  ...)

dotmatrix.importance.rhf(x,
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
 ...)

barplot.importance.rhf(x,
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
 ...)

\method{plot}{importance.rhf}(x,
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
 lwd = 2,
 line.colors = NULL,
 line.args = list(),
 legend = TRUE,
 legend.args = list(),
 ...)
}

\arguments{

  \item{o}{A RHF object with class \code{"rhf"}.}

  \item{cache}{Optional cache object returned by \code{varpro.cache()}.
  If \code{NULL}, the cache is built internally. Supplying a cache is
  useful when repeated calls are made.}

  \item{time.index}{Optional vector identifying which windows of the time
  grid \code{o$time.interest} are to be analyzed. This may be an integer index
  vector or a logical vector of length \code{length(o$time.interest)}. If
  omitted, all windows are used.}

  \item{trim}{Tuning parameter passed to the underlying VarPro
  importance workhorse. \code{trim} controls winsorized aggregation
  across trees.}

  \item{sort}{Logical. If \code{TRUE}, variables are ordered within each
  window in decreasing importance before the long-format output is assembled.}

  \item{max.rules.tree, max.tree}{Arguments controlling rule extraction when
  the cache is built.}

  \item{y.external}{Optional externally supplied working response. When
  \code{NULL}, the working response is built internally from the RHF object's
  integrated hazard exposure values.}

  \item{eps}{Nonnegative value added before taking the logarithm of the
  integrated hazard exposure when \code{y.external} is not supplied.}

  \item{verbose}{Logical. If \code{TRUE}, reports cache construction and
  per-window progress.}

  \item{x}{An object of class \code{"importance.rhf"}.}

  \item{top, rank.by}{Arguments used by \code{print()} and by
  \code{plot(type = "lines")}. Printing now ranks variables robustly over
  time by default using \code{rank.by = "q90"}. The line plot also uses
  \code{rank.by} when \code{vars} is omitted.}

  \item{digits, scientific.threshold}{Formatting controls for
  \code{print()}, used to keep very large importance values readable.}

  \item{row.names, optional}{Included for compatibility with
  \code{as.data.frame()}.}

  \item{format}{Output format for \code{as.data.frame()}. \code{"long"}
  returns the long-format table, \code{"variable_by_time"} returns a data
  frame whose rows are variables and columns are times, and
  \code{"time_by_variable"} returns the transpose with window metadata.}

  \item{type, vars, top.n.union}{Arguments controlling which
  variables are displayed and which plot is produced. \code{type = "barplot"}
  (the default) gives the time-by-variable bar-matrix display,
  \code{type = "dotmatrix"} gives the companion dot-matrix display, and
  \code{type = "lines"}
  gives a line, step, or smoothed view for selected variables. When \code{vars}
  is omitted, the line plot chooses \code{top} variables using \code{rank.by},
  while the dot-matrix and bar-matrix plots use the union of the top
  \code{top.n.union} variables across time.}

  \item{curve, smooth.f, lty, lwd, line.colors, line.args, display.cap,
  display.note}{Arguments for \code{type = "lines"}. \code{curve} chooses
  between step, ordinary line, and lowess-smoothed displays;
  \code{smooth.f} is passed to \code{stats::lowess()} when needed;
  \code{lty}, \code{lwd}, and \code{line.colors} control line appearance;
  and \code{line.args} is a named list of additional arguments for the
  \code{graphics::lines()} layer. \code{display.cap} applies display-only
  quantile capping to stabilize the vertical scale in the presence of extreme
  spikes. \code{display.note} toggles the on-plot capping note for every plot
  type.}

  \item{variable.labels, time.labels, sort.by, sort.abs}{Arguments controlling
  labels and ordering. \code{variable.labels} is used by all plot types and may
  be a named vector or a two-column data frame. \code{time.labels},
  \code{sort.by}, and \code{sort.abs} apply to the dot-matrix and bar-matrix
  displays. An unnamed \code{time.labels} vector must have one label per time
  window. Variables may be ordered by robust aggregate importance,
  alphabetically, hierarchical clustering, or left in their existing order.}

  \item{transform, color.by, point.color, bar.color, value.colors,
  sign.colors, pch, cex.range, bar.width, bar.max.height, size.cap, color.cap,
  alpha}{Arguments controlling dot size or bar height, color encoding,
  display-only quantile capping, and transparency. For the bar-matrix plot,
  \code{bar.width} controls the width of each bar within a time cell and
  \code{bar.max.height} controls the largest bar height within a variable row.
  When \code{color.by = "sign"}, magnitude controls size or height and signed
  importance controls color; signed bars extend upward or downward from the
  row center. Negative values are omitted, with a warning, for the other color
  modes. A one-color \code{value.colors} or \code{sign.colors} vector is
  allowed and produces constant coloring. To omit the continuous color-scale
  legend as well, use \code{color.by = "single"} together with
  \code{point.color} for a dot matrix or \code{bar.color} for a bar matrix.}

  \item{legend}{Logical. If \code{TRUE}, draw the applicable matrix or
  line-plot legend.}

  \item{legend.args}{Named list controlling the legend for every plot type.
  For \code{type = "dotmatrix"} and \code{type = "barplot"}, supported entries
  are \code{title}, \code{color.title}, \code{cex}, and \code{title.cex}.
  Omitting \code{title}, or setting it to \code{TRUE}, retains the automatic
  magnitude title. Setting \code{title = FALSE}, \code{NULL}, or \code{""}
  suppresses both matrix-legend headings; a character string supplies a custom
  magnitude title. \code{color.title} can independently retain, suppress, or
  replace the color-scale title. \code{cex} controls numeric legend labels and
  defaults to 0.85; \code{title.cex} controls legend headings and defaults to
  0.9. A specifically supplied \code{color.title} takes precedence over the
  general title suppression. Increase \code{legend.width} when using a long
  custom title or unusually large legend text. For \code{type = "lines"}, the
  list is passed to \code{graphics::legend()}, allowing options such as
  \code{x}, \code{cex}, \code{bty}, \code{ncol}, and \code{title}.}

  \item{point.args, bar.args}{Named lists passed to the dot
  \code{graphics::points()} layer and bar \code{graphics::rect()} layer,
  respectively. Data-driven coordinates, sizes, heights, and colors are
  protected and cannot be replaced through these lists.}

  \item{xlab, ylab, main, axis.cex, var.cex, time.label.srt, show.grid,
  grid.col, zero.line, zero.col, border, mar, legend.width, width, height,
  save.plot, out.file}{Display, layout, and export options for the plotting
  helpers. The matrix plots use blank axis labels and do not draw guide lines
  by default. When \code{mar = NULL}, the left margin is computed from the
  physical width of the resolved variable labels, retaining space for long
  informatics names without imposing a large fixed margin for short names.
  The bar-matrix magnitude key uses compact, non-overlapping reference-bar
  spacing; when the magnitude and color titles are identical, the color key
  moves upward to avoid unused space between the legend sections. Files can
  be written with \code{save.plot = TRUE}. \code{zero.line} and
  \code{zero.col} control row-center reference lines for signed bar plots;
  \code{border} controls rectangle borders.}

  \item{...}{Additional named arguments for the initial
  \code{graphics::plot()} frame. Point, bar, and line layers use
  \code{point.args}, \code{bar.args}, and \code{line.args}, respectively.
  Legend formatting uses \code{legend.args} for both matrix and line plots.
  Structural matrix geometry such as \code{xlim} and
  \code{ylim} is controlled by the matrix helpers and cannot be replaced
  through \code{...}; line plots accept user-supplied \code{xlim} and
  \code{ylim} through \code{...}.}

}

\details{


Implements time-localized RHF variable priority.  The time grid is given
by \code{time.interest}.  For each selected time window, the method uses
the counting process start--stop records whose intervals overlap that
window.  The forest rules and near-miss sets are taken from the fitted
RHF object and are reused across time windows.

For RHF objects, variable priority (VarPro) is applied in a
regression-style form.  The working response is the logarithm of the
integrated hazard exposure assigned by RHF over the relevant
interval-window overlap.  Local priority for a variable is computed by
comparing this working response among records satisfying a forest rule
with the corresponding response among records in the rule's near-miss
set, obtained by releasing that variable from the rule.  Temporal
localization comes from restricting the calculation to records active in
each time window, rather than rebuilding the rules or refitting the
forest at each time point.

The helper \code{varpro.cache()} stores the minimum information needed
for repeated localized importance calculations: a regression-style rule
template, window metadata, the working response source, and precomputed
window-local rule statistics. During cache construction, raw OOB and
complementary memberships are converted into compact per-window rule
summaries, so the later window sweep does not need to rescan membership
vectors.

The returned importance matrix has variables in rows and selected time
windows in columns. Column names correspond to the right endpoints of
the selected windows. The long-format table contains the same values
together with window metadata such as start, stop, midpoint, number at
risk, and number of active rules.

Printing and plotting share a robust strategy.  Summaries default to a
robust over-time ranking based on the 90th percentile, and the plotting
helpers apply optional quantile capping for display only. This prevents
rare extreme spikes from flattening curves while preserving the original
importance matrix for downstream analyses.

For consistent base-graphics behavior, \code{...} customizes the initial
plot frame for every plot type. Layer-specific options belong in
\code{point.args}, \code{bar.args}, or \code{line.args}. The single
\code{legend.args} list controls the custom matrix legend or is passed to
\code{graphics::legend()} for a line plot. Data-driven coordinates, sizes,
heights, and colors remain under control of the plotting helper. Line-plot
limits may still be supplied as \code{xlim} or \code{ylim} through \code{...}.

}

\value{

\code{varpro.cache()} returns an object containing cached rule
memberships, the working response used for importance, start-stop
information for pseudo-individuals, time-window metadata, and the rule
extraction settings.

\code{importance.rhf()} returns a list including:

\itemize{
  \item \code{importance.matrix}: matrix of localized importance values with
  variables in rows and selected time windows in columns.
  \item \code{importance.long}: long-format data frame containing variable,
  time, window metadata, and localized importance.
  \item \code{window.info}: data frame describing the analyzed windows,
  including start, stop, midpoint, \code{n.risk}, and \code{n.rules}.
  \item \code{y.source}: source of the working response. This is
  \code{"int.haz.oob"}, \code{"int.haz.test"}, or \code{"y.external"}.
  \item \code{trim}: tuning value used in importance aggregation.
}

\code{print()} returns its input invisibly after displaying a short summary
that includes robust over-time summaries for the leading variables.

\code{as.data.frame()} returns one of the supported data-frame views.

\code{dotmatrix.importance.rhf()} produces a base-R dot-matrix plot and
returns plotting metadata invisibly, including the resolved
\code{legend.args} settings.

\code{barplot.importance.rhf()} produces a base-R bar-matrix plot and returns
plotting metadata invisibly, including the resolved \code{legend.args}
settings.

\code{plot()} returns invisibly the result of the underlying plotting helper.
For \code{type = "lines"}, the returned display-capped matrix has attributes
containing the selected variable codes, resolved labels and time values.
}

\references{
  
  Ishwaran H. (2025). Multivariate Statistics: Classical Foundations and
  Modern Machine Learning.  Chapman and Hall.

  Ishwaran H., Kogalur U.B., Hsich E.M. and Lee D.K. (2026).  Random
  hazard forests.
  
  Lu, M. and Ishwaran, H. (2024). Model-independent variable selection
  via the rule-based variable priority. arXiv e-prints, pp.arXiv-2409.

  Lu, M. and Ishwaran, H. (2025). Individual variable priority: a
  model-independent local gradient method for variable importance.
  \emph{Artificial Intelligence Review}, 58:407.
  
  Zhou L., Lu M. and Ishwaran H. (2026).  Variable priority for
  unsupervised variable selection.  \emph{Pattern Recognition},
  172:112727.

}



\seealso{
  \code{\link{rhf}}
}

\examples{
\donttest{
################################################################
##
## simulation model
##
################################################################

## draw simulation (can be modified)
n <- 400
p <- 10
simid <- 2
d <- hazard.simulation(type = simid, n = n, p = p, nrecords = 4)$dta

## fit a RHF model with weighted mtry (use for high-dimension)
f <- "Surv(id, start, stop, event) ~ ."
o <- rhf(f, d, ntree = 50, nsplit = 5, xvar.wt = xvar.wt.rhf(f, d))
print(o)

## time-localized RHF importance across the full time grid
imp.t <- importance.rhf(o)
print(imp.t)

## extract the variable-by-time matrix
print(head(imp.t$importance.matrix))

oldpar <- par(mfrow=c(1,1))

## bar-matrix importance plot (default)
plot(imp.t)

## companion dot-matrix importance plot
plot(imp.t, type = "dotmatrix")

## suppress matrix-legend titles and enlarge its numeric labels
plot(imp.t, legend.args = list(title = FALSE, cex = 1.15))

## retain titles but control their size separately
plot(imp.t, legend.args = list(cex = 1.05, title.cex = 0.9))

## step-style importance line plot for the top variables
## (ranked by the 90th percentile over time and display-capped at q99)
plot(imp.t, type = "lines", top = 10)

## smoothed importance plot for all variables with display capping
plot(imp.t, type = "lines", curve = "lowess", smooth.f = 0.5, display.cap = 0.95)

## robust ordering and display capping
plot(imp.t, sort.by = "q90", size.cap = 0.99, color.cap = 0.99)

## bar-matrix plot using signed colors, if signed importance values are present
plot(imp.t, color.by = "sign")

par(oldpar)


## reuse a cache for repeated calls on subsets of the time grid
cache <- varpro.cache(o)
imp.t.sub <- importance.rhf(
  o,
  cache = cache,
  time.index = seq(1, length(o$time.interest), by = 5),
  verbose = TRUE
)

## long-format export
print(head(as.data.frame(imp.t.sub)))
}
}

\keyword{rhf importance}
