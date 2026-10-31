\name{pbcseq}
\alias{pbcseq}
\docType{data}
\title{Mayo Clinic PBC Data with Time-Dependent Covariates}
\description{
Repeated clinical and laboratory measurements from the 312 randomized
participants in the Mayo Clinic primary biliary cirrhosis (PBC) study.
The data are derived from \code{survival::pbcseq} and arranged in
counting-process format for \code{\link{rhf}}. Death is the event of interest;
liver transplantation is treated as censoring.
}
\usage{
data(pbcseq, package = "randomForestRHF")
}
\format{
A data frame with 1945 rows and 19 columns, ordered by patient and interval
start time. Each row represents one interval \code{(start, stop]}.
The data contain 312 patients and 140 deaths.
\describe{
  \item{\code{id}}{Integer patient identifier.}
  \item{\code{start}}{Interval start, in days since registration. This is
    the visit day at which the row's covariates were recorded.}
  \item{\code{stop}}{Interval end, in days since registration. This is
    the next visit day, or the end of follow-up for the final interval.}
  \item{\code{event}}{Integer indicator of death at \code{stop}:
    1 for death and 0 otherwise. Only a patient's final interval can have
    \code{event = 1}. Transplantation and other censoring have
    \code{event = 0}.}
  \item{\code{trt}}{Randomized treatment: 1 for D-penicillamine and
    2 for placebo. Constant within patient.}
  \item{\code{age}}{Age at registration, in years. Constant within patient.}
  \item{\code{sex}}{Factor with levels \code{"m"} (male) and
    \code{"f"} (female). Constant within patient.}
  \item{\code{ascites}}{Ascites: 0 absent, 1 present.}
  \item{\code{hepato}}{Hepatomegaly (enlarged liver): 0 absent, 1 present.}
  \item{\code{spiders}}{Spider angiomas: 0 absent, 1 present.}
  \item{\code{edema}}{Edema score: 0 for no edema and no diuretic treatment;
    0.5 for edema without diuretics or edema resolved by diuretics;
    1 for edema persisting despite diuretics.}
  \item{\code{bili}}{Serum bilirubin, in mg/dl.}
  \item{\code{chol}}{Serum cholesterol, in mg/dl.}
  \item{\code{albumin}}{Serum albumin, in g/dl.}
  \item{\code{alk.phos}}{Alkaline phosphatase, in U/liter.}
  \item{\code{ast}}{Aspartate aminotransferase (formerly SGOT), in U/ml
    as reported in the source data.}
  \item{\code{platelet}}{Platelet count.}
  \item{\code{protime}}{Prothrombin time, in seconds.}
  \item{\code{stage}}{Histologic disease stage, coded 1 through 4.}
}
The clinical and laboratory variables from \code{ascites} through
\code{stage} are recorded at each visit and may change over follow-up.
}
\details{
Each patient's first interval starts at day zero. Subsequent intervals
start on the recorded visit days. The final interval ends at the original
\code{futime}, the time to death, transplantation, or censoring.
The 29 transplant recipients contribute follow-up until transplantation
and are censored at that time; 143 other patients are censored without a
recorded death or transplant.

Measurements recorded at \code{start} apply throughout
\code{(start, stop]}. A measurement recorded at an
interval's right endpoint therefore takes effect in the next interval.
The final recorded covariate values apply until follow-up ends.
No future measurements are used to construct earlier intervals.

All visits are retained. Predictor values, classes, and missing values
are unchanged. Missing values at a visit are not replaced by values
from earlier or later visits. The original \code{day}, \code{futime}, and
\code{status} columns are replaced by \code{start}, \code{stop}, and
\code{event}; final follow-up time and outcome status are therefore not
available as predictors.

The sequential data include follow-up and baseline corrections not present
in the original baseline-only PBC data. They should not be reconstructed
by joining visit records to \code{survival::pbc}.
}
\note{
Missing measurements can be informative: unscheduled visits near death or
transplantation often have less complete laboratory testing. The example
uses predictors with no missing values in this data set, so it retains all
patients and intervals. Analyses using additional predictors require an
explicit approach to missing values; removing incomplete interval rows
can remove follow-up time and events.
}
\source{
Converted from \code{pbcseq} in the \pkg{survival} package:
\url{https://CRAN.R-project.org/package=survival}.
See \code{\link[survival]{pbcseq}} for the original visit-level data.

The original sequential data and variable definitions are available from
StatLib: \url{https://lib.stat.cmu.edu/datasets/pbcseq}.
The albumin unit, g/dl, follows that original data description.
}
\references{
Fleming, T. R. and Harrington, D. P. (1991).
\emph{Counting Processes and Survival Analysis}. Wiley, New York.

Murtaugh, P. A., Dickson, E. R., Van Dam, G. M., Malinchoc, M.,
Grambsch, P. M., Langworthy, A. L. and Gips, C. H. (1994).
Primary biliary cirrhosis: prediction of short-term survival based on
repeated patient visits. \emph{Hepatology}, \bold{20}, 126--134.
\doi{10.1002/hep.1840200120}.

Therneau, T. M. and Grambsch, P. M. (2000).
\emph{Modeling Survival Data: Extending the Cox Model}.
Springer, New York.
}
\seealso{
\code{\link{rhf}}, \code{\link{plot.rhf}},
\code{\link[survival]{pbcseq}}
}
\examples{
data(pbcseq, package = "randomForestRHF")

## Patient 1: two intervals, with death at the end of the second.
pbcseq[pbcseq$id == 1, c("id", "start", "stop", "event", "bili")]

## Remove cholesterol before removing missing values
d <- pbcseq
d$chol <- NULL
d <- na.omit(d)

## Reduce min events per gap to create a rich time grid
o <- rhf(Surv(id, start, stop, event) ~ ., data = d, min.events.per.gap = 1)
print(o)

## Survival probabilities for all patients
plot(o, idx = o$ensemble.id, type = "surv",
     legend.show = FALSE,
     xlab = "Days since registration",
     ylab = "Survival Probability")

## Time-varying importance
imp <- importance.rhf(o)
print(imp)
plot(imp)


}
\keyword{datasets}
