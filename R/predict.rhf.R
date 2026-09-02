predict.rhf <- function(object,
                        newdata,
                        get.tree = NULL,
                        block.size = 10,
                        membership = TRUE,
                        adaptive = TRUE,
                        seed = NULL,
                        do.trace = FALSE,
                        ...)
{
  has.newdata <- !missing(newdata)
  adaptive <- get.adaptive(adaptive)
  dots <- list(...)
  ## Prefer the forest-level training configuration.  The main object-level
  ## configuration is retained as a fallback for older or nonstandard objects.
  hazard.config <- object$forest$parms$hazard.config
  if (is.null(hazard.config)) {
    hazard.config <- object$hazard.config
  }
  hazard.options <- get.hazard.options(
    dots,
    hazard.config,
    adaptive = adaptive
  )
  dots[names(hazard.options)] <- hazard.options
  ## A forest grown from ordinary Surv(time, event) data retains the original
  ## response names.  Convert raw test data to the same private one-interval
  ## counting-process representation used during growth.  Counting-process
  ## forests and older objects retain the historical newdata contract.
  if (has.newdata) {
    newdata <- .rhf.prepare.newdata(object, newdata)
  }
  args <- c(list(object = object),
            if (has.newdata) list(newdata = newdata),
            list(get.tree = get.tree,
                 block.size = block.size,
                 membership = membership,
                 adaptive = adaptive,
                 seed = seed,
                 do.trace = do.trace),
            dots)
  do.call("predict.rhf.workhorse", args)
}
