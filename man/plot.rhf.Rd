\name{plot.rhf}
\alias{plot.rhf}
\title{Plot case-specific event probability, cumulative hazard, survival
  and hazard curves from an RHF analysis}

\description{
  Case-specific displays from a fitted random hazard forest (RHF)
  object: the probability of an event in each interval of the time grid
  (the default), the cumulative hazard (CHF), the survival probability,
  or the smoothed hazard.  Curves are drawn over each case's observed
  follow-up.  For simulated data the true curves can be overlaid.
}

\usage{\method{plot}{rhf}(x, idx = NULL, type = c("prob", "chf", "surv", "hazard"),
         window = NULL, curve = c("step", "line", "lowess"), f = 2/3,
         curve.lwd = 2, truth = NULL,
         scale.hazard = FALSE, ngrid = 30, bass = 0, q = 0.99, grid = FALSE,
         col = NULL, lty = NULL, legend.loc = "topright",
         jitter.factor = 1, lwd = 4,
         hazard.only = TRUE, legend.show = TRUE, ...)
}

\arguments{

  \item{x}{An object of class \code{rhf}: a forest grown by
  \code{\link{rhf}}, a prediction from \code{\link{predict.rhf}} on test
  data with outcomes, or a smoothed hazard from
  \code{\link{smoothed.hazard.rhf}}.}

  \item{idx}{Identifiers of the cases to plot: values of
  \code{x$ensemble.id} (the subject identifiers of \code{x$id}).  By
  default the first case.  Names, if present, are used as the legend
  labels.}

  \item{type}{What is drawn for each case on the time grid
  \code{x$time.interest}.  \code{"prob"} (the default): the probability
  of an event in each grid interval given the case is at risk at its
  start, \code{1 - exp(-(H(t[k]) - H(t[k-1])))} from the case's
  cumulative hazard \code{H}.  \code{"chf"}: the cumulative hazard
  \code{H(t)}.  \code{"surv"}: the survival probability
  \code{exp(-H(t))}.  \code{"hazard"}: the smoothed hazard display
  described below.  For a \code{smoothed.hazard.rhf} object the default
  is \code{"hazard"}.}

  \item{window}{For \code{type = "prob"}: \code{NULL} for the intervals
  of the time grid, or a positive width in the time units of the data,
  giving the probability of an event within \code{window} time units for
  a case at risk, \code{1 - exp(-h[k] * window)}, with \code{h[k]} the
  hazard over the grid interval (its CHF increment divided by its
  width).  This takes the uneven widths of the adaptive time grid out of
  the curves.}

  \item{curve}{How the values on the grid are drawn, for \code{type}
  other than \code{"hazard"}: \code{"step"}, constant over each grid
  interval; \code{"line"}, joined at the grid points; or
  \code{"lowess"}, a lowess smooth of the points shown.}

  \item{f}{The lowess span for \code{curve = "lowess"}; see
  \code{\link[stats]{lowess}}.}

  \item{curve.lwd}{Line width of the curves, and of the legend lines.}

  \item{truth}{For simulated data: the list returned by
  \code{\link{hazard.simulation}}.  Its \code{haz} closure (and
  \code{chf} closure, when the simulation has one) gives each case's
  true curve, which is drawn on the chosen display in the case's color
  with one dash pattern per case, faint beyond the case's observed
  follow-up.  Requires an object that carries the records of the cases
  (\code{x$id} and \code{x$xvar}), that is a grow or predict object.}

  \item{scale.hazard}{For \code{type = "hazard"}: logical or numeric.
  If \code{TRUE}, hazards are multiplied by the local time step (the
  width of the grid interval) so they approximate CHF increments.  If
  numeric, hazards are multiplied by the given constant.  The true
  hazard, when shown, is scaled the same way.}

  \item{ngrid}{Number of equally spaced points used when \code{grid = TRUE}.}

  \item{bass}{Smoothing parameter passed to \code{\link[stats]{supsmu}}.}

  \item{q}{Quantile used to trim extreme hazard values before smoothing.}

  \item{grid}{For \code{type = "hazard"}: if \code{TRUE}, overlays the
  hazard smoothed on an equally spaced grid of \code{ngrid} points
  (dashed) and, with \code{hazard.only = FALSE}, the smoothed CHF and its
  derivative.}

  \item{col}{Colors for the selected cases.  Recycled as needed.}

  \item{lty}{Line types for the estimated curves.  Recycled as needed.
  The true curves use their own dash patterns.}

  \item{legend.loc}{Legend location, passed to
  \code{\link[graphics]{legend}}.  For \code{type = "surv"} the default
  becomes \code{"bottomleft"}.}

  \item{jitter.factor}{Amount of horizontal jitter applied to the hazard
  spikes (\code{type = "hazard"}).}

  \item{lwd}{Line width of the unsmoothed hazard spikes
  (\code{type = "hazard"}); \code{0} hides them.}

  \item{hazard.only}{For \code{type = "hazard"}: if \code{TRUE}, only
  the hazard is drawn; otherwise the CHF is drawn as well.}

  \item{legend.show}{If \code{TRUE}, show a legend when plotting
  multiple cases.}

  \item{...}{Additional graphics parameters passed to
  \code{\link[graphics]{plot}}, including \code{xlim}, \code{ylim},
  \code{xlab}, \code{ylab} and \code{main}.}

}

\details{

  The curves are computed from the out-of-bag estimates of a grow object
  (\code{chf.oob}, \code{hazard.oob}) or the test-set estimates of a
  predict object (\code{chf.test}, \code{hazard.test}) on the time grid
  \code{x$time.interest}, and are drawn over each case's observed
  follow-up only: for counting-process data the estimates are \code{NA}
  after the case's last stop time and nothing is drawn there.  (Earlier
  versions drew these missing values as zero.)  For right-censored data
  the estimates cover the whole time horizon.

  The event probability is the recommended display.  The hazard is a
  volatile target that is hard to estimate for an individual case,
  whereas the probability of an event in an interval, the cumulative
  hazard and the survival probability are stable targets that the forest
  estimates well.  With \code{window = NULL} the probability refers to
  the intervals of the adaptive time grid, which need not have equal
  widths; a fixed \code{window} compares cases over equal lengths of
  time.

  The automatic time range runs from zero to a little beyond the
  selected cases' follow-up (the longest, when several cases are drawn;
  the curves of the others end earlier).  The room beyond the follow-up
  does not extend into a run of very wide intervals at the end of the
  grid (wider than ten times the median width, as the adaptive grid can
  end in a few long intervals holding few events), but the follow-up
  itself is always shown.  For right-censored data, whose estimates cover
  the whole grid, the follow-up is taken as the cases' observed times;
  \code{xlim} shows more.  A rug marks the observed event times.

  The hazard display (\code{type = "hazard"}) shows the unsmoothed
  hazard estimates on the grid as jittered spikes (\code{lwd}) and their
  \code{\link[stats]{supsmu}} smooth after trimming values above the
  \code{q} quantile (\code{bass}).  \code{scale.hazard} puts them on the
  scale of the CHF increments, \code{grid} overlays a smooth on an
  equally spaced grid, and \code{hazard.only = FALSE} adds the CHF.  This
  is the display of earlier versions and remains the default for
  \code{smoothed.hazard.rhf} objects.

  For data from \code{\link{hazard.simulation}}, \code{truth} gives each
  case's true curve on the chosen display, computed from the true hazard
  (and the true cumulative hazard when the simulation provides one;
  otherwise the hazard is integrated numerically over each grid interval)
  with the case's own x-variables as stored in \code{x}, including its
  latent time-varying covariate path for simulations 2 and 3.  The true
  curves are dashed or dotted, one pattern per case, in full color over
  the case's follow-up and faint beyond it, where the estimates are not
  defined.

  Plots are drawn to the current device; no model re-estimation is
  performed.

}

\value{
  Invisibly, a list with components \code{type}; \code{time}, the time
  grid; \code{value}, a matrix of the drawn values, cases by grid points,
  \code{NA} outside a case's follow-up (for the hazard display, the
  hazard estimates after scaling, before smoothing); \code{truth}, the
  matrix of true values, or \code{NULL} when none were drawn (for the
  hazard display, a list with the fine time grid and the true hazards);
  and \code{idx}, the identifiers of the cases drawn.
}

\author{
  Hemant Ishwaran and Udaya B. Kogalur
}

\references{

  Ishwaran H. and Kogalur U.B. (2007).
  Random survival forests for R.
  \emph{R News}, 7(2): 25--31.

  Ishwaran H., Kogalur U.B., Blackstone E.H. and Lauer M.S. (2008).
  Random survival forests.
  \emph{Annals of Applied Statistics}, 2: 841--860.

  Lee D.K., Chen N., and Ishwaran H. (2021).
  Boosted nonparametric hazards with time dependent covariates.
  \emph{Annals of Statistics}, 49: 2101--2128.

  Ishwaran H., Lee D.K. and Hsich E.M. (2025).
  Random hazard forests.
}

\seealso{
  \code{\link{hazard.simulation}},
  \code{\link{predict.rhf}},
  \code{\link{rhf}},
  \code{\link{smoothed.hazard.rhf}}
}

\examples{
\donttest{

## ------------------------------------------------------------
##  time static peakVO2
## ------------------------------------------------------------
data(peakVO2, package = "randomForestSRC")
d <- convert.counting(Surv(ttodead, died)~., peakVO2)
f <- "Surv(id, start, stop, event) ~ ."

set.seed(1)
o <- rhf(f, d)
ids <- o$ensemble.id[1:3]

## probability of an event in each grid interval (the default), as steps
plot(o, idx = ids)

## probability of an event within one time unit, as lines
plot(o, idx = ids, window = 1, curve = "line")

## cumulative hazard and survival probability
plot(o, idx = ids, type = "chf")
plot(o, idx = ids, type = "surv")

## the smoothed hazard display
plot(o, idx = ids, type = "hazard")

## custom axis label
plot(o, idx = ids, type = "hazard", ylab = "my hazard")

## scaled hazard with CHF
plot(o, idx = ids, type = "hazard", scale.hazard = TRUE, hazard.only = FALSE)

## auxiliary grid with smoother control
plot(o, idx = ids, type = "hazard", grid = TRUE, ngrid = 60, bass = 2,
     hazard.only = FALSE)

## many cases, no spikes, no legend
plot(o, idx = o$ensemble.id[1:10], type = "hazard", lwd = 0, legend.show = FALSE)

## lowess median smoothed hazard: a smoothed hazard object shows the
## hazard by default
s <- smoothed.hazard(o)  ## default method="median.loess"
plot(s, idx = o$ensemble.id[1:10])
plot(s, idx = o$ensemble.id[1:10], lwd = 0)

## ------------------------------------------------------------
##  complex simulated time dependent covariate hazards, with the
##  true curves of the simulation
## ------------------------------------------------------------
f <- "Surv(id, start, stop, event) ~ ."
sim2 <- hazard.simulation(2)
o2 <- rhf(f, sim2$dta)

## event probability, estimated and true (dashed)
plot(o2, idx = 1:3, truth = sim2)

## lowess smoothed curves; the survival probability
plot(o2, idx = 1:3, truth = sim2, curve = "lowess")
plot(o2, idx = 1:3, type = "surv", truth = sim2)

## the hazard display with the true hazard
plot(o2, idx = 1, type = "hazard", truth = sim2)

## ------------------------------------------------------------
##  same simulation, but using smoothed hazard
## ------------------------------------------------------------
s2.loess <- smoothed.hazard(o2, method="loess")
s2.med.loess <- smoothed.hazard(o2, method="median.loess")

plot(o2, 1, type = "hazard")
plot(s2.loess, 1)
plot(s2.med.loess, 1)
plot(s2.med.loess, 1:10, lwd = 0)

}

}

\keyword{plot}
\keyword{rhf}
