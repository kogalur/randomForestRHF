\name{auct.rhf}
\alias{auct.rhf}
\alias{auct}
\alias{plot.auct.rhf}
\alias{print.auct.rhf}
\title{Time-varying AUC(t) and iAUC for Random Hazard Forests (TDC)}

\description{
Compute the time-varying AUC(t) and its time-aggregated
summaries for Random Hazard Forests (RHF) with time-dependent covariates
(TDC).
}

\usage{
auct.rhf(
  object,
  marker = c("cumhaz", "hazard", "chf", "haz"),
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
  verbose = TRUE
)

\method{print}{auct.rhf}(x, digits = 4, max.rows = 8, \dots)
\method{plot}{auct.rhf}(x, bass = 10, xlab = "Time", ylab = NULL,
         main = NULL, ylim = NULL, pch = 16, alpha = .05, \dots)
}

\arguments{

  \item{object}{An RHF object. For grow/restore objects (class includes \code{"rhf"} and \code{"grow"}),
  OOB prediction matrices are used. For predict objects (class includes \code{"rhf"} and \code{"predict"}),
  test data is used (supply \code{ydata=} if the object does not include \code{id}/\code{yvar}).}

  \item{marker}{Which time-varying score to evaluate: \code{"cumhaz"} (alias \code{"chf"})
    or \code{"hazard"} (alias \code{"haz"}).}

  \item{method}{Target estimand. \code{"incident"} (incident/dynamic) uses cases who fail at time \eqn{t}
  and controls who are at risk at \eqn{t}; this targets instantaneous hazard discrimination.
  \code{"cumulative"} (cumulative/dynamic) uses cases who have failed by \eqn{t} and controls who are event-free at \eqn{t};
  this matches the more commonly used time-dependent AUC (Heagerty and Zheng, 2005).}

  \item{tau}{Optional time horizon. Evaluation is restricted to times \code{t <= tau}.}

  \item{riskset}{Risk-set definition for \code{method = "incident"}:
    \code{"subject"} treats a subject as at risk when \code{entry < t <= stop};
    \code{"record"} uses counting-process rows. Ignored when \code{method = "cumulative"}.}

  \item{min.controls}{Minimum number of controls required at each evaluated time.}

  \item{nfrac.controls}{Minimum fraction of the total sample to be available as controls at each evaluated time.}

  \item{min.cases}{Minimum number of cases required at each evaluated time.}

  \item{g.floor}{Lower bound used to stabilize inverse-probability-of-censoring weights \code{G(t)} (global KM).}

  \item{g.floor.q}{Optional quantile-based floor (computed over the evaluation grid) to further protect tails.}

  \item{power}{Exponent in the Uno-style time weight, effectively using weights proportional to \code{1 / G(t)^{power}}.
  The classical choice is \code{power = 2}.}

  \item{ydata}{Counting-process data frame \code{(id, start, stop, event, ...)}.
  Required when \code{object} is a predict object that does not carry \code{id}/\code{yvar}.}

  \item{winsor.q}{Optional winsorization quantile (e.g., \code{0.99})
    applied to the time weights to minimize extreme influence.}

  \item{eps}{Small positive constant for numerical stability in weight
    calculations.}

  \item{bootstrap.rep}{Number of bootstrap replicates for standard errors. Default is \code{0} (no bootstrap).}

  \item{bootstrap.refit}{Logical. If \code{FALSE} (default), uses a subject-level pairs bootstrap with the
  fitted marker held fixed ("plug-in"). If \code{TRUE}, performs a \emph{full refit} at each replicate.
  Complete counting-process histories are resampled by subject with multiplicity, and each sampled copy
  receives a new bootstrap ID. Refit models use the original RHF tuning parameters and inherit the saved
  hazard/CHF settings from \code{object$forest$parms$hazard.config}.}

  \item{bootstrap.conf}{Confidence level for pointwise normal bands on AUC(t) when \code{bootstrap.rep > 0}
    (e.g., \code{0.95}). Set to \code{NA} to suppress bands.}

  \item{verbose}{Logical; if \code{TRUE}, enable bootstrap progress messages.
  Messages can be silenced with \code{suppressMessages()}.}

  \item{bootstrap.seed}{Optional integer seed used before bootstrap resampling for reproducibility.}
  
  \item{x, digits, max.rows, bass, xlab, ylab, main, ylim, pch, alpha, \dots}{
    Standard arguments for the \code{print} and \code{plot} methods.}
}

\details{
\strong{What is estimated.}
At each evaluation time \eqn{t}, the function computes an AUC for the chosen marker
(either cumulative hazard or hazard), using the specified case/control definition:
\itemize{
  \item \emph{Incident/dynamic} (\code{method = "incident"}): cases fail at \eqn{t}; controls are at risk at \eqn{t}.
  \item \emph{Cumulative/dynamic} (\code{method = "cumulative"}): cases have failed by \eqn{t}; controls are event-free at \eqn{t}.
}

The per-time AUC(t) values are combined in two ways:
\itemize{
  \item \code{iAUC.uno}: an inverse-probability-of-censoring weighted (IPCW) average of AUC(t) over time,
        using a global KM estimate \code{G(t)} and a weight proportional to \code{1 / G(t)^{power}}
        (Uno-style time weighting). Stabilization parameters include \code{g.floor}, \code{g.floor.q}, and \code{winsor.q}.
  \item \code{iAUC.std}: a simple time-standardized mean of AUC(t) over the evaluation grid (trapezoidal rule divided by span).
        This quantity is sensitive to the time window and the shape of AUC(t) across time.
}

\strong{Markers.}
For \code{method = "cumulative"}, using \code{marker = "cumhaz"} matches standard
time-dependent AUCs. Using \code{marker = "hazard"} with \code{"cumulative"}
often yields smaller AUC(t), as it targets instantaneous risk rather than cumulative risk.

\strong{Risk-set choice.}
When \code{method = "incident"} there are two ways to define controls at time \code{t}:
\itemize{

  \item \code{riskset = "subject"}: at risk when \code{entry < t <= Tstop} (one interval per subject).
    Fast and appropriate when subject rows tile continuous follow-up (no gaps).
  \item \code{riskset = "record"}: at risk when a counting-process row satisfies \code{start < t <= stop}.
        Exact under gaps but may yield fewer controls at sparse times.

}
If rows tile the entire follow-up, the two definitions coincide (up to ties). With gaps,
\code{"subject"} can over-include controls (lower variance but a conceptual mismatch),
while \code{"record"} is exact but can be sparser. For \code{method = "cumulative"} the risk-set choice is ignored.

\strong{Bootstrap.}
When \code{bootstrap.rep > 0}, two modes are available:
\itemize{
  \item \emph{Plug-in} (\code{bootstrap.refit = FALSE}): subject-level pairs bootstrap holding the fitted marker matrix fixed.
        Weights the within-time AUC(t) using resampled multiplicities and recomputes Uno's time weights via a weighted KM.
  \item \emph{Refit} (\code{bootstrap.refit = TRUE}): for each replicate, resample complete subject histories with replacement,
        retaining repeated draws as separate bootstrap subjects, \emph{refit} the RHF using the original tuning parameters and
        saved hazard/CHF configuration, and re-evaluate AUC(t). The returned per-time SEs are matched to the original
        evaluation grid. For predict objects, the refit is performed using the data carried in the object; predictions are then
        recomputed for those data. This is computationally heavier but captures variability from model fitting. If every refit
        fails, the function reports the first captured failure rather than silently returning an all-\code{NA} bootstrap result.
}
The \code{plot} method draws a base-R shaded band for AUC(t) when bootstrap SEs are present.
}

\value{
An object of class \code{"auct.rhf"} with elements:
\itemize{
  \item \code{AUC.by.time}: data frame with columns \code{time}, \code{AUC}, \code{n.cases}, \code{n.ctrl}, \code{G}, \code{W}.
  \item \code{iAUC.uno}: IPCW (Uno-style) time-averaged AUC.
  \item \code{iAUC.std}: time-standardized mean of AUC(t).
  \item \code{marker}, \code{method}, \code{riskset}, \code{power}, \code{g.floor}, \code{g.floor.q}, \code{winsor.q}, \code{times}: metadata.
  \item \code{diag.riskset}: Quick diagnostic comparing control counts under
        \code{riskset = "subject"} vs \code{"record"} on a small subset of times (list with
        \code{times}, \code{n.ctrl.subject}, \code{n.ctrl.record}, \code{n.diff}, \code{prop.times.different}).
  \item \code{boot}: present when \code{bootstrap.rep > 0} with
        \code{AUC.se} (per-time SE matched to the reporting grid), \code{iAUC.uno.se}, \code{iAUC.std.se},
        \code{conf.level}, \code{AUC.lower}, \code{AUC.upper}, \code{rep}, and \code{mode} (\code{"plug-in"} or \code{"refit"}).
}
Generic methods \code{print} and \code{plot} are provided for compact summaries and visualization.
}

\references{
Heagerty, P. J., Lumley, T., and Pepe, M. S. (2000).
Time-dependent ROC curves for censored survival data and a diagnostic marker.
\emph{Biometrics}, 56(2), 337--344.

Heagerty, P. J., and Zheng, Y. (2005).
Survival model predictive accuracy and ROC curves.
\emph{Biometrics}, 61(1), 92--105.

Uno, H., Tian, L., Cai, T., Kohane, I. S., Wei, L.-J. (2013).
A unified inference procedure for a class of measures to assess improvement in risk prediction systems with survival data.
\emph{Statistics in Medicine}, 32(14), 2430--2442.
}

\seealso{
  \code{\link{rhf}},
  \code{\link{predict.rhf}}
}

\author{
Hemant Ishwaran and Udaya B. Kogalur
}

\examples{
\donttest{

## ------------------------------------------------------------
## Peak VO2 example
## ------------------------------------------------------------

data(peakVO2, package = "randomForestSRC")
d <- convert.counting(Surv(ttodead, died) ~ ., peakVO2)
f <- "Surv(id, start, stop, event) ~ ."

o <- rhf(f, d, ntree = 25, nodesize = 5)

## AUC(t) with cumulative/dynamic definition and cumhaz marker
a.chf <- auct.rhf(o, marker = "cumhaz", method = "cumulative")

## AUC(t) with incident/dynamic definition and hazard marker
a.haz <- auct.rhf(o, marker = "hazard", method = "incident")

print(a.chf)
print(a.haz)

oldpar <- par(mfrow = c(1, 2))
plot(a.chf, main = "AUC(t): cumulative + cumhaz")
plot(a.haz, main = "AUC(t): incident + hazard")
par(oldpar)

## ------------------------------------------------------------
##  TDC illustration with training/testing
## ------------------------------------------------------------

trn <- hazard.simulation(1)$dta
tst <- hazard.simulation(1)$dta
f <- "Surv(id, start, stop, event) ~ ."
o <- rhf(f, trn, ntree = 25)
p <- predict(o, tst)
a.trn <- auct.rhf(o)
a.tst <- auct.rhf(p)

oldpar <- par(mfrow = c(1, 2))
plot(a.trn, main = "AUC(t): chf marker, train", ylim = c(0.5,1))
plot(a.tst, main = "AUC(t): chf marker, test",  ylim = c(0.5,1))
par(oldpar)

## ------------------------------------------------------------
## Bootstrap SEs and shaded band
## ------------------------------------------------------------
d <- hazard.simulation(1)$dta
f <- "Surv(id, start, stop, event) ~ ."
o <- rhf(f, d)


oldpar <- par(mfrow = c(1, 2))


## plug-in bootstrap
a.bs1 <- auct.rhf(o, marker = "cumhaz", method = "cumulative",
                  bootstrap.rep = 20, bootstrap.seed = 123)
plot(a.bs1, main = "AUC(t) with bootstrap band (plug-in)")

## refit bootstrap (can be slow)
a.bs2 <- auct.rhf(o, marker = "cumhaz", method = "cumulative",
                  bootstrap.rep = 10, bootstrap.refit = TRUE, bootstrap.seed = 7)
plot(a.bs2, main = "AUC(t) with bootstrap band (refit)")


par(oldpar)
}
}

\keyword{survival}
\keyword{ROC}
\keyword{AUC}
