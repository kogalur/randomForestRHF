\name{predict.rhf}
\alias{predict.rhf}
\title{Prediction on Test Data for Random Hazard Forests}

\description{
  Obtain predicted values on test data using a trained random hazard
  forests.
}

\usage{\method{predict}{rhf}(object, newdata,  get.tree = NULL,
     block.size = 10, membership = TRUE, adaptive = TRUE,
     seed = NULL, do.trace = FALSE,...)}

\arguments{

  \item{object}{An \code{rhf} object returned from a previous training
    call to \code{rhf}.}
  

  \item{newdata}{Test data frame. If omitted, the original training data
    is used and the full training forest is restored.}
  

  \item{get.tree}{Optional vector of integer indices specifying which
  trees to use for ensemble predictions. Defaults to using all trees in
  the forest. Currently ignored, future functionality.}


  \item{block.size}{Controls how cumulative error rate is reported. To
  obtain cumulative error every \code{n} trees, set this to an integer
  between 1 and \code{ntree}.  Currently ignored.}


  \item{membership}{Logical flag indicating whether terminal node
    membership and inbag information should be returned.}
  

  \item{adaptive}{Logical flag controlling the default trimmed-mean
    protocol used by prediction and restore mode. The default
    \code{TRUE} inherits the adaptive trim configuration saved with the
    trained forest. Setting \code{adaptive = FALSE} replaces the default
    or inherited trim grid by the fixed value \code{0.05}, unless an
    expert-level \code{coe.trim} value is supplied through \code{...}.}
  

  \item{seed}{Negative integer specifying the random seed for
    reproducibility.}
  

  \item{do.trace}{Number of seconds between progress updates printed to
    the console.}
  

  \item{...}{Additional optional arguments passed to internal methods.}
  

}

\details{

  Returns the predicted values for a random hazard forests.

  Prediction inherits the hazard calculation configuration saved with
  the trained forest. In ordinary test-data prediction there is no OOB
  objective for reselecting the trim value, so the grow-time
  selected index is used. In restore mode, the stored forest can
  reconstruct OOB quantities and may reselect the trim value over the
  active candidate grid. Setting \code{adaptive = FALSE} changes that
  grid to the single value \code{0.05}, unless \code{coe.trim} is
  supplied through \code{...}.
  
}

\value{
An object of class \code{c("rhf", "predict", family)}. The returned list
contains the fitted forest together with prediction summaries on the
evaluation grid \code{time.interest}. Important components include:

\itemize{
  \item \code{hazard.test}, \code{chf.test}, \code{risk.test}, and
    \code{int.haz.test}: test-set hazard, cumulative hazard, risk, and
    integrated-hazard summaries when \code{newdata} is supplied.
  \item \code{hazard.oob}, \code{chf.oob}, \code{risk.oob}, and
    \code{int.haz.oob}: out-of-bag summaries for the training data.
  \item \code{hazard.inbag}, \code{chf.inbag}, \code{risk.inbag}, and
    \code{int.haz.inbag}: in-bag summaries when available.
  \item \code{id}, \code{yvar}, and \code{xvar}: identifiers and processed
    outcome/predictor data used by the returned prediction object.
  \item \code{pseudo.membership} and \code{inbag}: terminal-node membership
    and inbag information when \code{membership = TRUE}.
  \item \code{forest}: the fitted forest object used to generate the
    predictions.
}

If \code{newdata} is omitted, the function restores predictions for the
original training data using the stored forest and returns the same class of
object.
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
  \command{\link{rhf}}
}

\examples{

## ------------------------------------------------------------
## canonical train/test example (synthetic data)
## ------------------------------------------------------------

simID <- 1
trn <- hazard.simulation(simID)$dta
tst <- hazard.simulation(simID)$dta
f <- "Surv(id, start, stop, event) ~ ."

## training
o <- rhf(f, trn, ntree = 3)
print(o)

## testing
p <- predict(o, tst)
print(p)

## fixed trim protocol
p.fixed <- predict(o, tst, adaptive = FALSE)

\donttest{

## ------------------------------------------------------------
##  pbc: train/test example
## ------------------------------------------------------------

library("randomForestSRC")
data(pbc, package = "randomForestSRC")
pbc.raw <- na.omit(pbc)
trn <- sample(1:nrow(pbc.raw), size=nrow(pbc.raw) * .75, replace = FALSE)

d.trn <- convert.counting(Surv(days, status) ~ ., pbc.raw[trn,])
d.tst <- convert.counting(Surv(days, status) ~ ., pbc.raw[-trn,])
f <- "Surv(id, start, stop, event) ~ ."

## train/predict
o <- rhf(f, d.trn)
print(predict(o, d.tst))

## restore the forest
print(predict(o))

}
}

\keyword{predict rhf}
