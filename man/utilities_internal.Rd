\name{internal.utils}
\alias{convert.counting}
\alias{convert.standard.counting}
\alias{hazard.simulation}
\alias{xvar.wt.rhf}

\title{Advanced Utility Functions for RHF Workflows}

\description{
These helper functions support advanced random-hazard-forest workflows,
including data conversion, simulation, and predictor weighting.
}

\usage{
convert.counting(f, dta, scale = FALSE)

convert.standard.counting(formula, data,
  scale = FALSE,
  rescale.from.attr = FALSE,
  keep.id = FALSE,
  keep.row_index = FALSE,
  sorted = FALSE,
  id.default = "id",
  eps = 1e-8,
  landmark.time = NULL,
  landmark.use.tminus = TRUE,
  return.type = c("survival", "x"),
  keep.landmark.cols = FALSE)

hazard.simulation(type = 1,
  n = 500, p = 10, nrecords = 7,
  scale = FALSE, ngrid = 1e5, ...)

xvar.wt.rhf(f, 
    d,
    scale = 4,
    rank.by = c("q90", "median", "mean", "max", "sum"),
    rhf.args = list(),
    cache.args = list())

}

\arguments{
  \item{f, formula}{A survival formula. \code{convert.counting()} expects a
  standard survival formula such as \code{Surv(time, event) ~ .}. 
  \code{convert.standard.counting()} expects counting-process style input such
  as \code{Surv(id, start, stop, event) ~ .} or
  \code{Surv(start, stop, event) ~ .}.}

  \item{dta, data, d}{Input data frame.}

  \item{scale}{Logical or numeric time-scaling control, depending on the
  helper being used.}

  \item{rescale.from.attr}{Logical; if \code{TRUE},
  \code{convert.standard.counting()} rescales times using attributes stored on
  the counting-process data.}

  \item{keep.id}{Logical; if \code{TRUE}, retain the subject identifier in the
  returned data frame from \code{convert.standard.counting()}.}

  \item{keep.row_index}{Logical; if \code{TRUE}, include the source row index
  in the output of \code{convert.standard.counting()}.}

  \item{sorted}{Logical; indicates whether the counting-process input is
  already sorted by subject and time.}

  \item{id.default}{Default subject identifier column name used when
  \code{formula} omits an explicit \code{id} term.}

  \item{eps}{Small positive tolerance used in internal time comparisons.}

  \item{landmark.time}{Optional landmark time passed to
  \code{convert.standard.counting()}.}

  \item{landmark.use.tminus}{Logical; controls how landmark covariates are
  selected when \code{landmark.time} is supplied.}

  \item{return.type}{Character string specifying whether
  \code{convert.standard.counting()} returns a standard survival outcome plus
  covariates (\code{"survival"}) or only the covariate frame (\code{"x"}).}

  \item{keep.landmark.cols}{Logical; if \code{TRUE}, keep auxiliary landmark
  columns in the output of \code{convert.standard.counting()}.}

  \item{type}{Simulation scenario. May be given numerically
  (\code{1}, \code{2}, \code{3}) or by name.}

  \item{n, p, nrecords, ngrid}{Simulation controls used by
  \code{hazard.simulation()}.}

  \item{...}{Additional arguments passed to the selected simulation engine.}

}

\details{
\code{convert.counting()} converts standard right-censored survival data to the
counting-process representation expected by \code{rhf()}.

\code{convert.standard.counting()} converts counting-process style RHF data to
a conventional survival-analysis data frame or to a predictor-only frame.

\code{hazard.simulation()} generates synthetic counting-process data together
with the corresponding theoretical hazard function.

\code{xvar.wt.rhf()} computes variable weights that can be supplied to
\code{rhf(..., xvar.wt = ...)}.
}

\value{
The returned value depends on the helper:

\itemize{
  \item \code{convert.counting()}: a data frame with columns
  \code{id}, \code{start}, \code{stop}, \code{event}, followed by the predictor
  columns from the input data.
  \item \code{convert.standard.counting()}: a data frame in the format requested
  by \code{return.type}. With \code{return.type = "survival"}, the leading
  columns are \code{time} and \code{event}; additional covariate and optional
  helper columns may also be present. The function may return an empty data
  frame when no valid rows remain after filtering.
  \item \code{hazard.simulation()}: a list with components \code{dta}
  (simulated counting-process data frame), \code{haz}
  (a function that evaluates the true hazard on a supplied time grid), and
  \code{scale} (the time-scaling factor used in the simulation).
  \item \code{xvar.wt.rhf()}: a named numeric vector of predictor weights for
  the \code{xvar.wt} argument of \code{rhf()}.
}
}

\seealso{
  \code{\link{rhf}},
  \code{\link{predict.rhf}}
}

\keyword{internal}
