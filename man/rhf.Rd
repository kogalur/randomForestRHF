\name{rhf}
\alias{rhf}
\title{Random Hazard Forests}
\description{

  Random Hazard Forest (RHF) is a tree-ensemble survival method that
  estimates case-specific hazards and cumulative hazard functions on a
  working time grid and supports time-dependent covariates using
  counting-process (start/stop) format.

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
}

\arguments{

  \item{formula}{Model formula specifying the response and predictors.}

  \item{data}{Data frame containing the variables referenced in \code{formula}.}

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
  selection probability.}


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

  \item{...}{Additional arguments (currently unused).}

}

\details{

\strong{Overview}

\code{rhf()} is the main fitting function for Random Hazard Forests
(RHF). It grows an ensemble of hazard trees from survival data
represented in counting-process, start--stop form,
\code{Surv(id, start, stop, event)}. Multiple rows for the same
\code{id} describe an evolving covariate path. Predictors may include
time-static variables, repeated across rows, and time-dependent
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

The start--stop rows must represent a predictable covariate process.
That is, the covariate values used to evaluate the hazard at a given
time must be determined by information available before that time.
Measurements or treatments recorded later must not be used to
construct covariates for an earlier prediction time. \code{rhf()}
assumes that this no-lookahead convention has already been encoded in
the input data.


\strong{Required data format}

The input data must contain the following four columns. Column names
must agree with those specified in the formula; see the examples.

\describe{

  \item{\code{id}}{
  A unique integer identifier for each individual. The identifier is
  repeated across all rows belonging to that individual.
  }

  \item{\code{start}}{
  The start time of the row. All times must be scaled to
  \code{[0, 1]} and must use the same scale as
  \code{time.interest}.
  }

  \item{\code{stop}}{
  The stop time of the row. Each row must satisfy
  \code{stop > start}.
  }

  \item{\code{event}}{
  A binary event indicator for the row
  (\code{0} = no event, \code{1} = event). The current implementation
  supports single-event survival data, so at most one event may be
  recorded for each individual.
  }

}


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

The helper function \code{convert.counting()} converts conventional
survival data to counting-process form. See the examples for additional
guidance on data preparation.

}


\value{

  An object of class \code{"rhf"} containing the fitted forest and related
  results. Components include (among others) the working time grid
  \code{time.interest} and case-specific ensemble estimates of the hazard
  and cumulative hazard. When bootstrapping is used, these are typically
  returned as \code{hazard.oob}/\code{chf.oob} (out-of-bag) and
  \code{hazard.inbag}/\code{chf.inbag} (in-bag). Use \code{\link{predict.rhf}}
  to obtain estimates for new data.

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
## convert the data to counting process
d <- convert.counting(Surv(days, status) ~ ., na.omit(pbc))
## set the formula
f <- "Surv(id, start, stop, event) ~ ."

## rhf call
print((o <- rhf(f, d, ntree = 3)))

## smooth hazard estimator for specific cases
plot(o, idx=c(1,5,10))
plot(o, idx=c(1,5,10), hazard.only=TRUE)
plot(o, idx=c(1,5,10), hazard.only=TRUE, lwd=0)
plot(o, idx=1:10, lwd=0, hazard.only=TRUE, legend.show=FALSE)

\donttest{

## ------------------------------------------------------------
##  time-static pbc: compare RHF to RSF
## ------------------------------------------------------------

data(pbc, package = "randomForestSRC")
d <- convert.counting(Surv(days, status) ~ ., na.omit(pbc))

## first we run rhf
o.rhf <- rhf("Surv(id, start, stop, event) ~ .", d)
h <- o.rhf$hazard.oob
time <- o.rhf$time.interest
H <- t(o.rhf$chf.oob)
S.rhf <- exp(-H)

## next we run rsf, using the same time.interest grid
o.rsf <- randomForestSRC::rfsrc(Surv(days, status) ~ ., pbc, ntime = time)
S.rsf <- t(o.rsf$survival.oob)

## graphical parameters
bass <- 1
oldpar <- par(mfrow=c(2,2))

## plot survival results 
matplot(time,S.rhf,type="l",col=gray(.6))
matplot(time,S.rsf,type="l",col=gray(.6))
boxplot(S.rhf-S.rsf,ylab="S.rhf-S.rsf",xaxt="n",outline=FALSE,range=1e-10)
abline(h=0,lwd=3,col=2)

## plot chf and hazard results
finite <- is.finite(h)
matplot(time,t(h),ylab="hazard",pch=16,type="n",
        ylim=c(0,quantile(h[finite],.99)))
nO <- lapply(which(rowSums(finite) >= 2L), function(i) {
  lines(supsmu(time[finite[i,]],h[i,finite[i,]],bass=bass),
        type="b",pch=16,col=gray(.6),cex=.5)
})

par(oldpar)

## ------------------------------------------------------------
##  TDC illustration (using built in hazard simulation function)
## ------------------------------------------------------------

d1 <- hazard.simulation(1)$dta
d2 <- hazard.simulation(2)$dta
d3 <- hazard.simulation(3)$dta
f <- "Surv(id, start, stop, event) ~ ."

o1 <- rhf(f, d1)
o2 <- rhf(f, d2)
o3 <- rhf(f, d3)

plot(o1,idx=4)
plot(o2,idx=1:3)
plot(o3,idx=2)


## ------------------------------------------------------------
##  peakVO2: demonstrates time-varying auc
## ------------------------------------------------------------

data(peakVO2, package = "randomForestSRC")
d <- convert.counting(Surv(ttodead, died)~., peakVO2)
f <- "Surv(id, start, stop, event) ~ ."

## build the forest
o1 <- rhf(f, d, treesize=10)
o2 <- rhf(f, d, treesize=30)

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

}
}


\keyword{rhf}
