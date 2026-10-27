\name{rhf}
\alias{rhf}
\alias{xvar.wt.rhf}
\title{Random Hazard Forests}
\description{

  Random Hazard Forest (RHF) is a tree-ensemble survival method that
  estimates case-specific hazards and cumulative hazard functions on a
  working time grid. It accepts ordinary right-censored data through
  \code{Surv(time, event)} and time-dependent covariates through
  counting-process \code{Surv(id, start, stop, event)} input.  The
  helper \code{xvar.wt.rhf()} computes sparse split weights for guided
  feature selection in high dimensions.

}

\usage{
rhf(formula,
      data,
      ntree = 500,
      nsplit = 10,
      treesize = NULL,
      nodesize = NULL,
      block.size = 10,
      bootstrap = c("by.root", "none", "by.user"),
      samptype = c("swor", "swr"),
      samp = NULL,
      case.wt = NULL,
      membership = TRUE,
      sampsize = if (samptype == "swor") function(x){x * .632} else function(x){x},
      xvar.wt = NULL,
      ntime = 50,
      min.events.per.gap = 10,
      adaptive = TRUE,
      seed = NULL,
      do.trace = FALSE,
      ...)

xvar.wt.rhf(f,
      d,
      method = c("lasso", "tree"),
      nvar = 30L,
      sparse = TRUE,
      guided.args = list())
}

\arguments{

  \item{formula}{Model formula specifying the response and predictors.
  The response may be ordinary right-censored survival data,
  \code{Surv(time, event)}, or RHF counting-process data,
  \code{Surv(id, start, stop, event)}.}

  \item{data}{Data frame containing the variables referenced in
  \code{formula}. Ordinary right-censored input has one row per subject;
  counting-process input may have multiple rows per subject.}

  \item{ntree}{Number of trees to grow in the ensemble.}

  \item{nsplit}{Non-negative integer specifying the number of random
  split points to consider for each variable. When set to 0, all
  possible split points are evaluated (deterministic splitting), which
  may be slower. The default is 10.}

  \item{treesize}{Specifies the desired tree size, defined as the number
  of terminal nodes.  If unspecified, an internal default is used.}

  \item{nodesize}{Minimum number of cases required in a terminal
    node. If not specified, an internal default is used.}

  \item{block.size}{Controls the granularity of cumulative error rate
  reporting. Setting this to an integer between 1 and \code{ntree}
  yields the cumulative error every \code{block.size} trees.  Currently
  ignored.}

  \item{bootstrap}{Bootstrap strategy for generating inbag samples. The
  default is \code{"by.root"}, which bootstraps by sampling with or
  without replacement (default is without; see \code{samptype}). If set
  to \code{"none"}, no bootstrapping is performed (OOB predictions and
  errors are then unavailable). The option \code{"by.user"} uses a
  user-defined bootstrap specified by \code{samp}.}

  \item{samptype}{Sampling type used when \code{bootstrap =
  "by.root"}. Options are \code{"swor"} (sampling without replacement,
  default) and \code{"swr"} (sampling with replacement).}

  \item{samp}{User-specified bootstrap when \code{bootstrap =
  "by.user"}. Should be an \code{n} by \code{ntree} array, where each
  entry gives the number of times a case appears in the inbag sample for
  a given tree.}

  \item{case.wt}{Non-negative vector of case weights (not required to
  sum to 1). Higher weights increase the probability of an observation
  being selected during bootstrapping or subsampling. Using real-valued
  weights is preferred over integer weights.}

  \item{membership}{Logical flag indicating whether to return terminal
    node membership and inbag information.}

  \item{sampsize}{Specifies the size of the bootstrap sample when
  \code{bootstrap = "by.root"}. For sampling without replacement, it
  represents the requested subsample size (default is 0.632 times the
  sample size). For sampling with replacement, it equals the sample
  size. Can be supplied as a numeric value or a function.}

  \item{xvar.wt}{Non-negative vector of variable selection probabilities
  for splitting. Values do not need to sum to 1. Defaults to uniform
  selection probability. A variable with weight zero is never selected.
  \code{xvar.wt.rhf()} computes sparse weights for guided feature
  selection; see Details.}


  \item{ntime}{Controls the working time grid used for all
   ensemble calculations. Can be:
   \describe{

     \item{\code{ntime >= 1} (integer):}{Request approximately \code{ntime} grid
        points chosen from the observed event times. When used with
       \code{min.events.per.gap}, grid points are selected adaptively so that each
       interval contains at least \code{min.events.per.gap} events (when possible);
       therefore the resulting grid may contain fewer than \code{ntime} points when
       events are sparse (especially in the tail).}

     \item{numeric vector:}{A user-supplied set of time points. Each value is
       aligned (snapped) to the nearest observed event time and duplicates are
       removed.}

     \item{\code{0} or \code{NULL}:}{Use all observed (unique) event times.}

 }}

 \item{min.events.per.gap}{Minimum number of observed events required in
   each time interval when \code{ntime} is specified as an integer.
   Together with ntime, this provides an automatic event-balanced grid
   that allocates more resolution where events are dense and avoids
   sparse tail intervals.}

  \item{adaptive}{Logical value controlling the default trimmed-mean
  aggregation protocol. When \code{TRUE}, the default, RHF evaluates a
  candidate vector of trimming fractions and retains the value selected
  by the OOB-risk criterion. When \code{FALSE}, the default candidate
  vector is replaced by the single value \code{coe.trim = 0.05}.  This can be
  useful when tuning other parameters, such as \code{treesize}, without
  simultaneously optimizing the trimming fraction, otherwise leave at
  the default.}

  \item{seed}{Negative integer setting the random seed for reproducibility.}

  \item{do.trace}{Time in seconds between progress updates printed to the console.}

  \item{...}{Additional expert-level controls passed to internal RHF methods.}

  \item{f, d}{Formula and data frame for \code{xvar.wt.rhf()}, in the
  same forms accepted by \code{rhf()}.}

  \item{method}{Screening components used by \code{xvar.wt.rhf()}.
  One or more of \code{"lasso"} (penalized hazard regression on the
  counting process records with subject level cross-validation folds),
  \code{"tree"}
  (split frequency from a shallow RHF grown with \code{mtry} equal to
  the number of variables), and \code{"pilot"} (time-localized
  importance from a pilot RHF, summarized over time). The default
  combines the lasso and tree screens. The lasso screen is linear in
  the variables and on its own misses nonlinear effects; the tree
  screen is the remedy.}

  \item{nvar}{Number of variables retained by \code{xvar.wt.rhf()}.
  All other variables receive weight zero.}

  \item{sparse}{Logical. If \code{TRUE}, each screening component is
  raised to a power that increases with the size of its support, which
  concentrates the weights on the top ranked variables. If
  \code{FALSE}, the scaled components are used as they are.}

  \item{guided.args}{Named list of further options for the split weight
  calculation. The entries are \code{ntree.reduce} (trees in the shallow
  RHF, default 100), \code{treesize.reduce} (terminal nodes in the
  shallow RHF, default 4 when there are at most 200 subjects and 8
  otherwise), \code{nsplit.reduce} (default 10), \code{mtry.reduce}
  (default equal to the number of variables), \code{ntree.pilot}
  (default 50), \code{rank.by} (over-time summary for the pilot screen,
  default \code{"q90"}), \code{lasso.family} (\code{"poisson"}, the
  default, or \code{"cox"}), \code{lasso.ncut} (baseline pieces for the
  poisson screen, default 10), \code{lasso.s} (penalty selected by
  cross-validation, \code{"lambda.min"}, the default, or
  \code{"lambda.1se"}), \code{nfolds} (default 10), \code{maxit}
  (default 7500, passed to \code{glmnet}), \code{max.subjects}
  (optional subject subsample size for the lasso screen),
  \code{tolerance} (default \code{1e-50}), \code{seed}, and
  \code{mtry.guided} (number of candidate variables per split in the
  guided rule forest grown by \code{importance.rhf()}, default one third
  of the retained variables).}

}

\details{

\strong{Overview}

\code{rhf()} is the main fitting function for Random Hazard Forests
(RHF). Ordinary right-censored data can be supplied directly as
\code{Surv(time, event)} with one row per subject. RHF converts this
internally to a one-interval predictable process with \code{start = 0},
\code{stop = time}, and time-static predictors. Time-dependent data are
supplied explicitly in counting-process form as
\code{Surv(id, start, stop, event)}. Multiple rows for the same
\code{id} then describe an evolving covariate path. Predictors may
include time-static variables, repeated across rows, and time-dependent
covariates that change from row to row.

RHF estimates hazards pathwise on the time grid
\code{time.interest}. For a supplied predictable covariate path, each
tree routes the current covariate state through its partition over time
and returns the corresponding terminal-node hazard. Averaging across
trees yields a case-specific hazard trajectory. A fitted RHF object
stores in-sample ensemble estimates of the hazard and cumulative hazard
on \code{time.interest}. Predictions for new data, or from restored
fitted objects, are obtained with \code{predict.rhf()}.

The default hazard aggregation uses an adaptive trimming protocol: RHF
evaluates a grid of candidate trimming fractions and retains the
candidate selected by OOB risk. Setting \code{adaptive = FALSE} uses the
fixed trimming fraction \code{coe.trim = 0.05} instead. This can be useful when
another tuning procedure should hold the hazard aggregation protocol
fixed; however the value 0.05 is arbitrary and is not guaranteed to give
good peformance in all settings.


\strong{Predictable covariate paths}

For counting-process input, the start--stop rows must represent a
predictable covariate process. That is, the covariate values used to
evaluate the hazard at a given time must be determined by information
available before that time. Measurements or treatments recorded later
must not be used to construct covariates for an earlier prediction
time. \code{rhf()} assumes that this no-lookahead convention has already
been encoded in the input data. For ordinary \code{Surv(time, event)}
input, each subject's supplied predictors are treated as time-static
over the interval from zero to the observed time.


\strong{Supported response formats}

RHF accepts either of the following response forms.

\describe{

  \item{\code{Surv(time, event)}}{
  Ordinary terminal right-censored data with one row per subject. The
  \code{time} and \code{event} arguments must each be column names in
  \code{data}. Times must be non-negative, and \code{event} must be
  coded \code{0} for censoring and \code{1} for an event. RHF creates
  a private subject identifier and internally represents each row as
  one counting-process interval \code{(0, time]}.
  }

  \item{\code{Surv(id, start, stop, event)}}{
  Counting-process data for time-dependent covariates. The subject
  identifier \code{id} is repeated across all rows for that subject.
  Each row must satisfy \code{stop > start}. Intervals may be
  contiguous or separated by gaps, but they may not overlap within a
  subject. The row-level \code{event} increment must be coded
  \code{0/1}; terminal-event data may contain at most one event per
  subject, on that subject's final row.
  }

}

Times are supplied in their original non-negative units. RHF maps them
to its internal working scale during data processing and returns
\code{time.interest} and time-based predictions in the original units.


\strong{Tree construction}

Each tree is grown by a best-first search guided by reduction in
empirical hazard risk. Candidate splits are evaluated using a
nonparametric hazard likelihood for predictable covariate processes.
For computational efficiency, tree induction uses a working model that
assigns a time-constant hazard to each current node. Under this
restriction, candidate splits can be scored using node-level at-risk
exposure and event totals.

The node-constant model is used only to choose the partition. Once the
partition is fixed, RHF removes this restriction and estimates a
time-varying step-function hazard in each terminal node on
\code{time.interest}. Both static and time-dependent covariates are
eligible for splitting. The option \code{xvar.wt} controls how often
individual variables are considered, and can be used, for example, to
give additional weight to time-dependent covariates.


\strong{Guided feature selection}

In the presence of a large number of variables, a tree split can easily
end up splitting on noise when \code{mtry} candidate split variables are
selected randomly.  A guided forest helps mitigate this problem and
replaces uniform selection with selection probabilities proportional to
\code{xvar.wt}, so that candidate variables at each split are drawn
toward the top ranked variables.  \code{xvar.wt.rhf()} computes these
weights by the split weight regularization of VarPro (Lu and Ishwaran,
2024).  Two screens are applied to the counting process records to
obtain these weights.

A lasso for the hazard defines the first screen.  The default likelihood
is the piecewise exponential model, the Poisson approximation to the Cox
model.  Records are split at \code{lasso.ncut} baseline cut points
placed at quantiles of the event times, each piece contributes its event
count with log exposure as offset, and the baseline pieces enter as
unpenalized indicators.  The Cox partial likelihood on \code{Surv(start,
stop, event)} is available through \code{lasso.family = "cox"};
\code{glmnet} fits start-stop data through an R level iteration that
runs an order of magnitude slower.  Subject level cross-validation folds
select the penalty at \code{lambda.min}.  The one standard error rule
used by VarPro is available through \code{lasso.s = "lambda.1se"}; for a
screen it discards weak signals that the cap on \code{nvar} would
otherwise retain.  The absolute standardized coefficients are the
weights, and variables outside the lasso support receive zero.  The
second screen uses a RHF of shallow trees; weights are set to the
observed forest averaged splitting frquency of a variable.  Each
screen's weights are scaled to a maximum of one and raised to a power
that increases with the size of its support (2, 5, 10, or 20 for
supports below 20, below 50, below 100, and at least 100).  These are
summed, the top \code{nvar} variables are retained, and all other
variables receive weight zero.  When no screen retains a variable,
\code{xvar.wt.rhf()} issues a warning and returns uniform weights. Its
attribute \code{status} is set to \code{"failed"} to indicate an
unguided forest.

Use \code{xvar.wt.rhf()} to obtain a guided forest from these weights,
as in \code{rhf(f, d, xvar.wt = xvar.wt.rhf(f, d))}.  The
function \code{\link{importance.rhf}} performs the same screening
internally when called with \code{guided = TRUE}, and uses the rules of
a guided forest directly when the supplied forest was grown with
nonuniform \code{xvar.wt}.


\strong{In-sample fitted trajectories}

For the training data, RHF assembles case-specific fitted curves on
\code{time.interest} using an active-record rule. Each start--stop row
supplies the routing covariate state for the portion of the grid on
which that row is active. Rows belonging to the same individual are
then stitched together to form the fitted pathwise hazard trajectory.
At a grid point \eqn{t}, the returned case-specific hazard is defined
only when \eqn{t} lies in at least one of the individual's supplied
\eqn{(\mathit{start},\mathit{stop}]} intervals. It is returned as
\code{NA} in gaps and after the final supplied stop time; covariate
values are not carried forward outside the observed path.

The corresponding cumulative hazard is calculated using the exact
overlap between the working time-grid intervals and the supplied
start--stop path. It therefore remains flat through gaps and after
follow-up. An observed portion of a final grid interval still
contributes to cumulative hazard even when the pointwise hazard at that
grid interval's right endpoint lies outside the supplied path. These
output conventions do not alter the likelihood contribution of the
training data.


\strong{Data conversion}

Manual conversion is not required for ordinary right-censored data:
\code{rhf(Surv(time, event) ~ ., data)} performs the one-interval
conversion internally. The helper \code{convert.counting()} remains
available when an explicit counting-process data frame is desired.

}


\value{

  \code{rhf()} returns an object of class \code{"rhf"} containing the
  fitted forest and related results. Components include (among others)
  the working time grid \code{time.interest} and case-specific ensemble
  estimates of the hazard and cumulative hazard. When bootstrapping is
  used, these are typically returned as \code{hazard.oob}/\code{chf.oob}
  (out-of-bag) and \code{hazard.inbag}/\code{chf.inbag} (in-bag). The
  component \code{input.info} records whether the forest was grown from
  ordinary right-censored or counting-process input and retains the
  response names needed for prediction. Use \code{\link{predict.rhf}}
  to obtain estimates for new data.

  \code{xvar.wt.rhf()} returns a named numeric vector of split weights
  with one entry per predictor, in the order used by \code{rhf()}, for
  the \code{xvar.wt} argument of \code{rhf()}. Variables outside the
  retained set have weight zero. The attributes \code{selected} and
  \code{raw} record the retained variables and the raw screening
  components.

}

\author{

  Hemant Ishwaran and Udaya B. Kogalur

}

\references{

  Ishwaran H. and Kogalur U.B. (2007).  Random survival forests for R,
  \emph{Rnews}, 7(2):25-31.

  Ishwaran H., Kogalur U.B., Blackstone E.H. and Lauer M.S.
  (2008).  Random survival forests, \emph{Ann. App.
    Statist.}, 2:841-860.

  Lee, D.K. and Chen N. and Ishwaran H (2021). Boosted nonparametric
  hazards with time-dependent covariates. \emph{Annals of Statistics},
  49: 2101-2128.

  Ishwaran H. (2025). Multivariate Statistics: Classical Foundations and
  Modern Machine Learning.  Chapman and Hall.

  Ishwaran H., Kogalur U.B., Hsich E.M. and Lee D.K. (2026).  Random
  hazard forests.

  Lu, M. and Ishwaran, H. (2024). Model-independent variable selection
  via the rule-based variable priority. arXiv e-prints, pp.arXiv-2409.

}

\seealso{
  \code{\link{auct.rhf}},
  \code{\link{importance.rhf}},
  \code{\link{plot.rhf}},
  \code{\link{predict.rhf}},
  \code{\link{smoothed.hazard.rhf}},
  \code{\link{tune.treesize.rhf}}
}


\examples{


## ------------------------------------------------------------
##  time-static pbc: parameters set for fast CRAN run
## ------------------------------------------------------------

## load the data
data(pbc, package = "randomForestSRC")
pbc.raw <- na.omit(pbc)

## ordinary right-censored data can be supplied directly
f <- Surv(days, status) ~ .
print((o <- rhf(f, pbc.raw, ntree = 3)))

## case-specific curves: the probability of an event in each grid
## interval (the default), the cumulative hazard, the survival probability
plot(o, idx=c(1,5,10))
plot(o, idx=c(1,5,10), type="chf")
plot(o, idx=c(1,5,10), type="surv")

## the smoothed hazard display
plot(o, idx=c(1,5,10), type="hazard")
plot(o, idx=c(1,5,10), type="hazard", lwd=0)
plot(o, idx=1:10, type="hazard", lwd=0, legend.show=FALSE)

\donttest{

## ------------------------------------------------------------
##  time-static pbc: compare RHF to RSF
## ------------------------------------------------------------

data(pbc, package = "randomForestSRC")
pbc.raw <- na.omit(pbc)

## first we run rhf directly on the ordinary survival data
o.rhf <- rhf(Surv(days, status) ~ ., pbc.raw)
h.rhf <- o.rhf$hazard.oob
time <- o.rhf$time.interest
H.rhf <- o.rhf$chf.oob
S.rhf <- exp(-H.rhf)

## next we run rsf, using the same cases and time.interest grid
o.rsf <- randomForestSRC::rfsrc(
  Surv(days, status) ~ ., pbc.raw, ntime = time, use.uno = FALSE
)
H.rsf <- o.rsf$chf.oob
S.rsf <- o.rsf$survival.oob

## compare C-stat of RHF to RSF
cat("RHF C-index:",
  randomForestSRC::get.cindex(o.rhf$yvar[,2],o.rhf$yvar[,3],rowSums(H.rhf, na.rm = TRUE)),"\n")
cat("RSF C-index:",
  randomForestSRC::get.cindex(o.rsf$yvar[,1],o.rsf$yvar[,2],rowSums(H.rsf, na.rm = TRUE)),"\n")
cat("RSF C-index (from rsf object):",tail(o.rsf$err.rate, 1),"\n")


## graphical parameters
oldpar <- par(mfrow=c(2,2))

## plot survival results
matplot(time,t(S.rhf),type="l",col=gray(.6),ylab="RHF survival")
matplot(time,t(S.rsf),type="l",col=gray(.6),ylab="RSF survival")
boxplot(t(S.rhf-S.rsf),ylab="survival diff.",xlab="cases",xaxt="n",outline=FALSE,range=1e-10)
abline(h=0,lwd=3,col=2)

## plot hazard direct approach - see plot.rhf() for user friendly function
finite <- is.finite(h.rhf)
matplot(time,t(h.rhf),ylab="RHF hazard",
        pch=16,type="n",
        ylim=c(0,quantile(h.rhf[finite],.99)))
nO <- lapply(which(rowSums(finite) >= 2L), function(i) {
  lines(supsmu(time[finite[i,]],h.rhf[i,finite[i,]],bass=1),
        type="b",pch=16,col=gray(.6),cex=.5)
})



par(oldpar)


## ------------------------------------------------------------
##  TDC illustration (using built in hazard simulation function)
## ------------------------------------------------------------

sim1 <- hazard.simulation(1); d1 <- sim1$dta
sim2 <- hazard.simulation(2); d2 <- sim2$dta
sim3 <- hazard.simulation(3); d3 <- sim3$dta
f <- "Surv(id, start, stop, event) ~ ."

o1 <- rhf(f, d1)
o2 <- rhf(f, d2)
o3 <- rhf(f, d3)

## event probability per grid interval, with the true curves of the
## simulation (dashed; faint beyond the case's follow-up)
plot(o1, idx=4, truth=sim1)
plot(o2, idx=1:3, truth=sim2)
plot(o3, idx=2, truth=sim3)

## the smoothed hazard display, with the true hazard
plot(o2, idx=1:3, type="hazard", truth=sim2)


## ------------------------------------------------------------
##  peakVO2: demonstrates time-varying auc
## ------------------------------------------------------------

data(peakVO2, package = "randomForestSRC")
f <- Surv(ttodead, died) ~ .

## build the forest directly from ordinary right-censored data
o1 <- rhf(f, peakVO2, treesize=10)
o2 <- rhf(f, peakVO2, treesize=30)

## old-school C-stat
cstat.f <- function(o) {randomForestSRC::get.cindex(o$yvar[, 2],
  o$yvar[, 3],rowSums(o$chf.oob, na.rm =TRUE))}
cat("C-stat treesize 10:", cstat.f(o1), "\n")
cat("C-stat treesize 30:", cstat.f(o2), "\n")

## acquire auc-t
a1.chf <- auct.rhf(o1) ## same as auct.rhf(o1, marker = "chf")
a1.haz <- auct.rhf(o1, marker = "haz")
a2.chf <- auct.rhf(o2) ## same as auct.rhf(o2, marker = "chf")
a2.haz <- auct.rhf(o2, marker = "haz")

## print auc-t
print(a1.chf)
print(a2.chf)
print(a1.haz)
print(a2.haz)

## plot auc-t
oldpar <- par(mfrow=c(2,2))
plot(a1.chf, main="treesize 1")
plot(a1.haz, main="treesize 1")
plot(a2.chf, main="treesize 15")
plot(a2.haz, main="treesize 15")
par(oldpar)

## ------------------------------------------------------------
##  more detailed example of time-varying performance
## ------------------------------------------------------------

d <- hazard.simulation(1)$dta
f <- "Surv(id, start, stop, event) ~ ."
treesize <- c(10, 30, 100)

oldpar <- par(mfrow=c(3,2))
perf <- lapply(treesize, function(tz) {
  o <- rhf(f, d, treesize=tz)
  print(o)
  rO <- list(chf = auct.rhf(o, marker="chf"),
             haz = auct.rhf(o, marker="haz"))
  plot(rO$chf, main=paste("chf marker, treesize=", tz))
  plot(rO$haz, main=paste("hazard marker, treesize=", tz))
  rO
})
par(oldpar)

## ------------------------------------------------------------
##  example illustrating tuning the tree size
##  using function 'rhf.tune.treesize'
## ------------------------------------------------------------

d <- hazard.simulation(1)$dta
f <- "Surv(id, start, stop, event) ~ ."

tune <- tune.rhf(f, d)  ## same as rhf.tune.treesize(f,d)
oldpar <- par(mfrow=c(1,1))
plot(tune)
par(oldpar)

## ------------------------------------------------------------
##  example illustrating guided feature selection
##  using built in 'xvar.wt.rhf' helper
## ------------------------------------------------------------

d <- hazard.simulation(1)$dta
f <- "Surv(id, start, stop, event) ~ ."

o <- rhf(f,d)
o.gfs <- rhf(f,d, xvar.wt = xvar.wt.rhf(f, d))

print(o)
print(o.gfs)

## high dimension: add noise variables to the simulation
d.noise <- data.frame(d, matrix(rnorm(nrow(d) * 200), nrow(d),
                                dimnames = list(NULL, paste0("noise", 1:200))))

## split weights: retained variables have positive weight
w <- xvar.wt.rhf(f, d.noise)
print(w[w > 0])
print(attr(w, "selected"))

## guided forest on the high-dimensional data
o.hd <- rhf(f, d.noise)
o.hd.gfs <- rhf(f, d.noise, xvar.wt = w)

print(o.hd)
print(o.hd.gfs)

}
}


\keyword{rhf}
