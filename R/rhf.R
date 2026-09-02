rhf <- function(formula,
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
                ...
                )
{
  user.call <- match.call()
  user.call$formula <- formula
  bootstrap <- match.arg(bootstrap, c("by.root", "none", "by.user"))
  samptype <- match.arg(samptype, c("swor", "swr"))
  adaptive <- get.adaptive(adaptive)
  dots <- list(...)
  hazard.options <- get.hazard.options(dots, adaptive = adaptive)
  dots[names(hazard.options)] <- hazard.options
  ## Normalize the public formula/data interface before entering the canonical
  ## counting-process workhorse.  Ordinary Surv(time, event) input is converted
  ## to one interval per subject; existing Surv(id, start, stop, event) input is
  ## returned unchanged.
  input <- .rhf.prepare.input(formula, data)
  declared.event.process <- dots$event.process
  if (is.null(declared.event.process)) {
    declared.event.process <- attr(input$data, "event.process", exact = TRUE)
  }
  declared.event.process <- .rhf.match.event.process(declared.event.process)
  if (identical(input$info$format, "right-censored") &&
      identical(declared.event.process, "recurrent")) {
    stop(
      "Surv(time, event) is a terminal right-censored response and cannot be ",
      "used with event.process = 'recurrent'.",
      call. = FALSE
    )
  }
  right.censored <- identical(input$info$format, "right-censored")    
  dots$right.censored <- right.censored
  fit <- do.call("rhf.workhorse", c(list(
                             formula = input$formula,
                             data = input$data,
                             ntree = ntree,
                             nsplit = nsplit,
                             treesize = treesize,
                             nodesize = nodesize,
                             block.size = block.size,
                             bootstrap = bootstrap,
                             samptype = samptype,
                             samp = samp,
                             case.wt = case.wt,
                             membership = membership,
                             sampsize = sampsize,
                             xvar.wt = xvar.wt,
                             ntime = ntime,
                             min.events.per.gap = min.events.per.gap,
                             adaptive = adaptive,
                             seed = seed,
                             do.trace = do.trace),
                             dots))
  ## Retain the user-facing input contract for prediction and printing.  The
  ## forest copy allows this metadata to survive reduced or reconstructed RHF
  ## objects that retain the fitted forest but not every top-level component.
  fit$input.info <- input$info
  fit$forest$input.info <- input$info
  fit$forest$parms$input.info <- input$info
  fit$call <- user.call
  fit
}
