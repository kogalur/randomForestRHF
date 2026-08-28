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
  bootstrap <- match.arg(bootstrap, c("by.root", "none", "by.user"))
  samptype <- match.arg(samptype, c("swor", "swr"))
  adaptive <- get.adaptive(adaptive)
  dots <- list(...)
  hazard.options <- get.hazard.options(dots, adaptive = adaptive)
  dots[names(hazard.options)] <- hazard.options
  do.call("rhf.workhorse", c(list(
                             formula = formula,
                             data = data,
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
}
