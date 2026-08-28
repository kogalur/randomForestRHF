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
  args <- c(list(object = object),
            if (!missing(newdata)) list(newdata = newdata),
            list(get.tree = get.tree,
                 block.size = block.size,
                 membership = membership,
                 adaptive = adaptive,
                 seed = seed,
                 do.trace = do.trace),
            dots)
  do.call("predict.rhf.workhorse", args)
}
