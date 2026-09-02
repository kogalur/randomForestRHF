\name{tune.treesize.rhf}
\alias{tune.treesize.rhf}
\alias{tune.rhf}
\alias{tune.iAUC.rhf}
\alias{tune.iAUC}
\alias{plot.tune.treesize.rhf}
\title{Tune tree size for Random Hazard Forests}

\description{

  Tune the \code{treesize} for a Random Hazard Forest using either
  out-of-bag (OOB) empirical risk or an OOB integrated AUC computed by
  \code{\link{auct.rhf}}.

}

\usage{
tune.treesize.rhf(
  formula,
  data,
  ntree = 500,
  nsplit = 10,
  nodesize = NULL,
  ntime = 50,
  min.events.per.gap = 10,
  adaptive = TRUE,
  perf = c("risk", "iAUC"),
  auct.args = NULL,
  lower = 5L,
  upper = NULL,
  C = 3,
  method = c("golden", "bisect"),
  max.evals = 20L,
  bracket.tol = 2L,
  seed = NULL,
  verbose = TRUE,
  forest = TRUE,
  ...
)


tune.iAUC.rhf(
  formula,
  data,
  auct.args = NULL,
  adaptive = TRUE,
  ...
)

\method{plot}{tune.treesize.rhf}(x, ylab = NULL, main = NULL,
    se.band = TRUE, se.mult = 1, ylim = NULL, \dots)
}


\arguments{
  
  \item{formula}{Survival formula for \code{\link{rhf}}. The
    response may be ordinary right-censored data,
    \code{Surv(time, event)}, or counting-process data,
    \code{Surv(id, start, stop, event)}.}

  \item{data}{Data frame containing the variables in \code{formula}.
    Ordinary right-censored input has one row per subject;
    counting-process input may have multiple rows per subject.}

  \item{ntree}{Number of trees grown at each candidate \code{treesize}.}

  \item{nsplit}{Number of random split points tried per variable.}

  \item{nodesize}{Minimum number of events in a terminal node; passed to
    \code{\link{rhf}}.}

  \item{ntime}{Controls the working time grid used by every candidate
    \code{\link{rhf}} fit and by the final refit. It has the same meaning
    and default as in \code{\link{rhf}}. When \code{upper = NULL}, it is
    also used when processing the event information for the automatic tuning
    range.}

  \item{min.events.per.gap}{Minimum number of observed events required in
    each working-time interval when \code{ntime} is specified as an integer.
    The value is passed to every candidate \code{\link{rhf}} fit and to the
    final refit. When \code{upper = NULL}, it also determines the
    package-default tree size and event-support limit used to construct the
    automatic upper bound.}

  \item{adaptive}{Logical flag passed to \code{\link{rhf}}. When
    \code{TRUE}, each candidate forest uses the default adaptive
    trimming protocol. When \code{FALSE}, each candidate forest uses the
    fixed trimming fraction \code{0.05}, so the tuning criterion varies
    with \code{treesize} while holding this hazard aggregation setting
    fixed.}

  \item{perf}{Tuning criterion. \code{"risk"} minimizes mean OOB risk;
    \code{"iAUC"} maximizes integrated AUC obtained using
    \code{\link{auct.rhf}}.}

  \item{auct.args}{Optional list of arguments passed to
    \code{\link{auct.rhf}} when \code{perf = "iAUC"}. }

  \item{lower}{Smallest \code{treesize} considered.}

  \item{upper}{Largest \code{treesize} considered. If \code{NULL},
    the upper bound is computed from the event information used by
    \code{\link{rhf}}. Specifically, it is the smaller of \code{C}
    times the package-default tree size and the event-supported limit
    \code{floor(ndead / min.events.per.gap)}, where \code{ndead} is
    the number of events remaining after RHF data processing.}

  \item{C}{Multiplier applied to the package-default tree size when
    computing the automatic upper bound. The resulting value is capped
    by the event-supported limit.}

  \item{method}{Discrete search strategy: \code{"golden"} (golden-section
    search) or \code{"bisect"} (bisection-style search).}

  \item{max.evals}{Maximum number of distinct \code{treesize} values
    evaluated by the search.}

  \item{bracket.tol}{Tolerance for the bracketing interval width used by
    the search algorithms.}

  \item{seed}{Optional random seed for reproducible comparisons across
    tree sizes.}

  \item{verbose}{Logical; if \code{TRUE}, print progress messages when
    evaluating new \code{treesize} values.}

  \item{forest}{Logical; if \code{TRUE}, return the RHF object at the
    best \code{treesize}.}

  \item{\dots}{Additional arguments passed to \code{\link{rhf}}.}

  \item{x, ylab, main, se.band, se.mult, ylim}{Arguments to
     customize \code{plot}.}
   
}

\details{

The alias \code{tune.rhf} is provided for convenience.

  
Repeatedly fits a hazard forest with different values of \code{treesize}
and selects the value that optimizes the chosen criterion
\code{perf}. Ordinary \code{Surv(time, event)} input is converted
internally to the same one-interval counting-process representation used
by \code{\link{rhf}}. The tuning preflight, automatic upper bound, all
candidate forests, and the final refit therefore use the same effective
subjects and event information. The returned forest retains the original
right-censored response names and can be used directly with ordinary
survival test data through \code{predict.rhf()}.

When \code{perf = "risk"}, the criterion is the mean OOB risk. When
\code{perf = "iAUC"}, \code{\link{auct.rhf}} is applied to each fit and
the criterion is \code{1 - iAUC.uno}.  \code{tune.iAUC} is a wrapper
around \code{tune.rhf} with \code{perf = "iAUC"}, using default
\code{auct.rhf} settings when \code{auct.args = NULL}.

Because the default RHF fit adaptively selects the trimming fraction by
OOB risk, tuning by OOB risk can otherwise combine the choice of
\code{treesize} with adaptive trimming. Use \code{adaptive = FALSE} for
a controlled tree-size search that fixes the trimming fraction at
\code{coe.trim = 0.05}.

}

\value{
An object of class \code{"tune.treesize.rhf"} with components
\itemize{
  \item \code{best.size}: optimal \code{treesize};
  \item \code{best.err}: minimal criterion value (mean OOB risk if
    \code{perf = "risk"}, or \code{1 - iAUC.uno} if \code{perf = "iAUC"});
  \item \code{path}: data frame with evaluated \code{treesize} values and
    corresponding criterion values (and an \code{iAUC} column when
    \code{perf = "iAUC"});
  \item \code{n.subjects}: number of subjects remaining after RHF input
    processing;
  \item \code{adaptive}: logical value indicating whether adaptive
    trimming was used during tuning;
  \item \code{forest}: RHF fit at \code{best.size} when
    \code{forest = TRUE}.}
}

\seealso{
\code{\link{rhf}}, \code{\link{auct.rhf}}
}

\examples{
\donttest{
## ------------------------------------------------------------
## Example: tuning treesize by OOB empirical risk
## ------------------------------------------------------------

data(pbc, package = "randomForestSRC")
pbc.raw <- na.omit(pbc)
set.seed(7)
trn <- sample(
  seq_len(nrow(pbc.raw)),
  size = floor(0.75 * nrow(pbc.raw)),
  replace = FALSE
)

d <- pbc.raw[trn, , drop = FALSE]
tst <- pbc.raw[-trn, , drop = FALSE]
f <- Surv(days, status) ~ .

## tune.rhf is an alias for tune.treesize.rhf; no manual conversion is needed
tuneRisk <- tune.rhf(f, d)  ## same as tune.treesize.rhf(f, d)

## For a controlled tree-size search, keep the trimming fraction fixed.
tuneRisk.fixed <- tune.rhf(f, d, adaptive = FALSE)

oldpar <- par(mfrow = c(1, 1))
plot(tuneRisk)
par(oldpar)

tuneRisk$best.size    # treesize minimizing mean OOB risk
tuneRisk$best.err

## Access the tuned forest and refit AUC diagnostics if desired
best.forest <- tuneRisk$forest
a.risk <- auct.rhf(best.forest)
print(a.risk$iAUC.uno)

## the tuned forest accepts the ordinary PBC test data directly
print(predict(best.forest, tst))


## ------------------------------------------------------------
## Example: tuning treesize by iAUC
## ------------------------------------------------------------

set.seed(7)
f <- "Surv(id, start, stop, event) ~ ."
d <- hazard.simulation(1, n=100)$dta
tuneiAUC <- tune.iAUC(f, d)

oldpar <- par(mfrow = c(1, 1))
plot(tuneiAUC)
par(oldpar)

print(tuneiAUC$best.size)
print(1 - tuneiAUC$best.err)

best.forest.iauc <- tuneiAUC$forest
a.iauc <- auct.rhf(best.forest.iauc)
print(1 - a.iauc$iAUC.uno)


## ------------------------------------------------------------
## Example: tuning treesize by iAUC with bootstrap s.e.
## ------------------------------------------------------------

set.seed(7)
f <- "Surv(id, start, stop, event) ~ ."
d <- hazard.simulation(1, n=100)$dta
tuneiAUC.boot <- tune.iAUC(f, d, auct.args=list(bootstrap.rep=25))
oldpar <- par(mfrow = c(1, 1))
plot(tuneiAUC.boot)        
par(oldpar)

## ------------------------------------------------------------
## Example: tuning by hazard-based incident AUC
## increase min.cases for stability
## ------------------------------------------------------------

set.seed(7)
f <- "Surv(id, start, stop, event) ~ ."
d <- hazard.simulation(1, n=100)$dta
tuneHazInc <- tune.iAUC(
  f, d,
  auct.args = list(
    min.cases    = 5,
    marker       = "hazard",
    method       = "incident"
  )
)

oldpar <- par(mfrow = c(1, 1))
plot(tuneHazInc)
par(oldpar)

print(tuneHazInc$best.size)
print(tuneHazInc$best.err)

## Confirm the tuned incident AUC on the selected forest
best.forest.haz <- tuneHazInc$forest
aHazInc <- auct.rhf(
  best.forest.haz,
  min.cases = 5,
  marker  = "hazard",
  method  = "incident"
)
print(aHazInc)
print(1 - aHazInc$iAUC.uno)

}}

\keyword{survival}
\keyword{tuning}
