predict.rhf.workhorse <-  function(object,
                                   newdata,
                                   get.tree = NULL,
                                   block.size = NULL,
                                   seed = NULL,
                                   membership = FALSE,
                                   do.trace = FALSE,
                                   adaptive = TRUE,
                                   ...)
{
  ## confirm this is a rhf object
  if (!inherits(object, "rhf")) {
    stop("this function only works for objects of class 'rhf'")
  }
  ## Retain the public input contract and trained event-process mode before the
  ## main object is replaced below by its forest component.
  input.info <- object$input.info
  if (is.null(input.info) && !is.null(object$forest)) {
    input.info <- object$forest$input.info
  }
  if (is.null(input.info) &&
      !is.null(object$forest) &&
      !is.null(object$forest$parms)) {
    input.info <- object$forest$parms$input.info
  }
  ## Inherit the public time-domain contract from the fitted object; do not
  ## re-infer it from newdata.
  right.censored <- identical(input.info$format, "right-censored")
  right.censored.bits <- get.rc.bits(right.censored)
  event.process <- object$event.process
  if (is.null(event.process) && !is.null(object$forest)) {
    event.process <- object$forest$event.process
  }
  if (is.null(event.process)) {
    event.process <- "auto"
  }
  event.process <- .rhf.match.event.process(event.process)
  ## hidden options (used later)
  dots <- list(...)
  adaptive <- get.adaptive(adaptive)
  ## Inherit the fitted forest's hazard configuration, then apply and validate
  ## any prediction-specific overrides supplied through `...`.  Setting
  ## adaptive = FALSE replaces the inherited/default trim grid with the
  ## historical fixed value 0.05 unless coe.trim is supplied explicitly.
  hazard.config <- get.hazard.options(
    dots,
    object$forest$parms$hazard.config,
    adaptive = adaptive
  )
  ## Remove hazard options from the general-purpose dots list.
  ## This prevents accidental forwarding or duplicate storage later.
  for (option.name in names(hazard.config)) {
    dots[[option.name]] <- NULL
  }
  ## initialize the seed
  seed <- get.seed(seed)
  ## Uniform versus endpoint estimation hazard. The effective prediction
  ## configuration controls option bits 4--6, as in grow mode.
  experimental.bits <- get.experimental.bits(
    dots$experimental.bits,
    FALSE,
    hazard.estimator = hazard.config$hazard.estimator,
    coe.aggregate = hazard.config$coe.aggregate
  )
  ## hard coded options (some are legacy)
  perf.type <- NULL
  ## set restore.mode and the ensemble option
  if (missing(newdata)) {##restore: no data
    restore.mode <- TRUE
    ensemble <- "all"
  }
  else {##not restore: test data present
    restore.mode <- FALSE
    ensemble <- "inbag"
  }
  ## check if this is an anonymous object and process accordingly
  if (inherits(object, "anonymous")) {
    anonymize.bits <- 2^26
    if (restore.mode) {
      stop("in order to predict with anonymous forests please provide a test data set")
    }
  }
  else {
    anonymize.bits <- 0
  }
  ## set the family
  family <- object$family
  subj  <- object$id
  subj.unique.count <- length(unique(subj))
  case.wt  <- get.weight(NULL, subj.unique.count)
  event.info <- object$event.info
  if (identical(event.process, "auto") &&
      !is.null(event.info$event.process)) {
    event.process <- .rhf.match.event.process(event.info$event.process)
  }
  ## get time-map information
  max.time <- object$max.time 
  time.map <- object$time.map
  if (is.null(time.map)) {
    time.map <- list(method = "legacy",
                     max.time = as.double(max.time),
                     tau = as.double(max.time))
  }
  ## Obtain y-outcome information using the exact internal-scale
  ## start/stop values supplied during forest growth.
  yvar.names <- object$yvar.names
  yvar.types <- object$yvar.types
  start.name <- yvar.names[yvar.types == "t"]
  stop.name <- yvar.names[yvar.types == "T"]
  if (length(start.name) != 1L || length(stop.name) != 1L) {
    stop(
      "The fitted forest does not contain coherent start/stop response metadata.",
      call. = FALSE
    )
  }
  yvar <- as.matrix(object$yvar)
  yvar[, start.name] <- event.info$start.time
  yvar[, stop.name] <- event.info$time
  yvar.nlevels  <- object$yvar.factor$nlevels
  yvar.nlevels  <- NULL
  ## obtain x information from the grow object 
  xvar <- object$xvar
  xvar.names <- object$xvar.names
  xvar.types <- object$xvar.types
  xvar.nlevels  <- rep(0, length(xvar.types))
  xvar.nlevels  <- NULL
  ## get the subject name
  subj.names  <- object$subj.names  
  ## hard coded options
  xvar.augment.newdata <- augmentXlist <- hcutCnt <- NULL
  hcut  <- 1
  ## recover the split information
  splitinfo <- object$splitinfo
  splitrule <- object$splitinfo$splitrule
  ## get the subjects -- this might be the test subjects eventually TBD
  id = object$id  
  ## initialize the seed
  seed <- get.seed(seed)
  ## REASSIGN OBJECT: hereafter we only need the forest 
  object <- object$forest
  ## confirm version coherence
  if (is.null(object$version)) {
      stop(
          paste(
              "This function only works with objects created with the following minimum version of the package:",
                     "  Minimum version:  0.0.0.0",
              paste0("  Your version:     unknown"),
              sep = "\n"
          ),
          call. = FALSE
      )
  }
  else {
    object.version <- as.integer(unlist(strsplit(object$version, "[.]")))
    installed.version <- as.integer(unlist(strsplit("2.0.3", "[.]")))
    minimum.version <- as.integer(unlist(strsplit("0.0.0.0", "[.]")))
    object.version.adj <- object.version[1] + (object.version[2]/10) + (object.version[3]/100)
    installed.version.adj <- installed.version[1] + (installed.version[2]/10) + (installed.version[3]/100)
    minimum.version.adj <- minimum.version[1] + (minimum.version[2]/10) + (minimum.version[3]/100)
    ## Minimum object version must be satisfied for us to proceed.  This is the only way
    ## terminal node restoration is guaranteed, due to RNG coherency.
    if (object.version.adj >= minimum.version.adj) {
      ## We are okay
    }
    else {
      stop(
          paste(
              "This function only works with objects created with the following minimum version of the package:",
              "  Minimum version:  0.0.0.0",
              paste0("  Your version:     ", object$version),
              sep = "\n"
          ),
          call. = FALSE
      )
    }
  }
  ##--------------------------------------------------------
  ##
  ## process x and y: test data is present
  ##
  ##--------------------------------------------------------
  if (!restore.mode) {
    ## clean up test data (handle missingness, scale time, scale y)
    nd <- cleanup.counting.newdata(newdata    = newdata,
                                   xvar.names = xvar.names,
                                   yvar.names = yvar.names,
                                   subj.names = subj.names,
                                   time.map   = time.map,
                                   max.time   = max.time,
                                   event.process = event.process)
    if (!is.null(nd$event.process)) {
      event.process <- nd$event.process
    }
    ## overwrite with cleaned version
    newdata   <- nd$newdata
    n.newdata <- nrow(newdata)
    ## get the test subjects
    subj.newdata  <- nd$subj
    subj.newdata.output <- subj.newdata
    subj.newdata.unique.count <- length(unique(subj.newdata))
    ## restrict xvar to the training xvar.names
    xvar.newdata <- nd$xvar
    ## hard coded 
    xvar.augment.newdata <- NULL
    ## extract test yvar (if present); already scaled to [0,1]
    yvar.newdata <- nd$yvar
    yvar.present <- nd$yvar.present
    if (yvar.present) {
      perf.type <- get.perf(perf.type, family)
    } else {
      ## Without start/stop/event, case-specific test ensembles cannot be
      ## stitched across the working time grid.  Turn those outputs off, but
      ## continue prediction so terminal membership and the training-derived
      ## node.U/node.V tables remain available.
      subj.newdata <- yvar.newdata <- NULL
      ensemble <- "none"
      perf.type <- "none"
    }
  }
  ##--------------------------------------------------------
  ##
  ##  process x and y: no test data is present
  ##
  ##--------------------------------------------------------
  else {
    ## There cannot be test data in restore mode
    ## The native code switches based on n.newdata being zero (0).  Be careful.
    n.newdata <- 0
    xvar.newdata <- yvar.newdata <-  subj.newdata  <- NULL
    subj.newdata.output <- NULL
    ## perf type
    perf.type <- get.perf(perf.type, family)
  }
  ## ------------------------------------------------------------
  ##
  ## restore/non-restore x/y processing completed
  ## finalize and make C call
  ##
  ## ------------------------------------------------------------
  ## set the performance bits
  perf.bits <-  get.perf.bits(perf.type)
  ## initialize the number of trees in the forest
  ntree <- object$ntree
  ## process the get.tree vector that specifies which trees we want
  ## to extract from the forest.  This is only relevant to restore mode.
  ## The parameter is ignored in predict mode.
  get.tree <- get.tree.index(get.tree, ntree)
  bootstrap.bits <- get.bootstrap.bits(object$parms$bootstrap)
  ## initialize the low bits
  ensemble.bits <- get.ensemble.bits(ensemble)
  ## sample related
  samptype <- object$parms$samptype
  sampsize <- object$parms$sampsize
  samp <- object$parms$samp
  ## Initalize the high bits
  samptype.bits <- get.samptype.bits(samptype)
  membership.bits <-  get.membership.bits(membership)
  ##  jitt.bits <- get.jitt.bits(jitt)
  ## We over-ride block-size in the case that get.tree is user specified
  block.size <- min(get.block.size.bits(block.size, ntree), sum(get.tree))
  ## Default target. We don't support more than one, and this is a bit of a legacy issue.
  m.target.idx <- 1
  ## do.trace
  do.trace <- get.trace(do.trace)
  ## WARNING: Note that the maximum number of slots in the following
  ## foreign function call is 64.  Ensure that this limit is not
  ## exceeded.  Otherwise, the program will error on the call.
  ## Real time prediction option:
  real.time  <- is.hidden.rt(dots)    
  real.time.bits  <- get.rt.bits(real.time)
  if (real.time) {
    real.time.options  <- is.hidden.rt.opt(dots)
  }
  else {
    real.time.options  <- NULL
  }
  ## Start the C external timer.
  ctime.external.start  <- proc.time()
  nativeOutput <- tryCatch({.Call("entryPred",
                                  as.integer(do.trace),
                                  as.integer(seed),
                                  as.integer(bootstrap.bits +   
                                             perf.bits +
                                             ensemble.bits +
                                             anonymize.bits),   ## low option word
                                  as.integer(membership.bits +  ## high option word
                                             2^19 + 2^18 +      ## TERM_INCG and TERM_OUTG
                                             samptype.bits),
                                  as.integer(experimental.bits +
                                             right.censored.bits),  ## rhf (local and experimental) option word
                                  as.integer(ntree),
                                  as.integer(object$n),
                                  list(as.integer(subj.unique.count),
                                       if (is.null(case.wt)) NULL else as.double(case.wt),
                                       as.integer(sampsize),
                                       if (is.null(samp)) NULL else as.integer(samp)),
                                  as.integer(hcut),
                                  as.integer(splitinfo$index),
                                  list(if (is.null(m.target.idx)) as.integer(0) else as.integer(length(m.target.idx)),
                                       if (is.null(m.target.idx)) NULL else as.integer(m.target.idx)),
                                  list(as.integer(length(yvar.types)),
                                       if (is.null(yvar.types)) NULL else as.character(yvar.types),
                                       if (is.null(yvar.nlevels)) NULL else as.integer(yvar.nlevels),
                                       if (is.null(yvar.nlevels)) NULL else sapply(1:length(yvar.nlevels), function(nn) {as.integer(length(yvar.nlevels[[nn]]))}),
                                       if (is.null(subj)) NULL else as.integer(subj),
                                       if (is.null(event.info)) as.integer(0) else as.integer(length(event.info$event.type)),
                                       if (is.null(event.info)) NULL else as.integer(event.info$event.type)),
                                  if (is.null(yvar.nlevels)) {
                                    NULL
                                  }
                                  else {
                                    lapply(1:length(yvar.nlevels),
                                           function(nn) {as.integer(yvar.nlevels[[nn]])})
                                  },
                                  if (is.null(yvar.types)) NULL else as.double(as.vector(data.matrix(yvar))),
                                  list(if(is.null(event.info$time.interest)) as.integer(0) else as.integer(length(event.info$time.interest)),
                                       if(is.null(event.info$time.interest)) NULL else as.double(event.info$time.interest)),
                                  list(as.integer(ncol(xvar)),
                                       if (is.null(xvar.types)) NULL else as.character(xvar.types),
                                       if (is.null(xvar.nlevels)) NULL else as.integer(xvar.nlevels),
                                       if (is.null(xvar.nlevels)) NULL else sapply(1:length(xvar.nlevels), function(nn) {as.integer(length(xvar.nlevels[[nn]]))}),
                                       NULL,
                                       NULL),
                                  if (is.null(xvar.nlevels)) {
                                    NULL
                                  }
                                  else {
                                    lapply(1:length(xvar.nlevels),
                                           function(nn) {as.integer(xvar.nlevels[[nn]])})
                                  },
                                  as.double(as.vector(data.matrix(xvar))),
                                  ## assignment of augmented variables (list of two values: dimension, data)
                                  augmentXlist,
                                  as.integer(n.newdata),
                                  if (is.null(subj.newdata)) NULL else as.integer(subj.newdata),
                                  if (is.null(yvar.newdata)) NULL else as.double(as.vector(data.matrix(yvar.newdata))),
                                  if (is.null(xvar.newdata)) NULL else as.double(as.vector(data.matrix(xvar.newdata))),
                                  as.integer(object$totalNodeCount),
                                  as.integer(object$leafCount),
                                  as.integer(object$seed),
                                  as.integer((object$nativeArray)$treeID),
                                  as.integer((object$nativeArray)$nodeID),
                                  as.integer((object$nativeArray)$nodeSZ),
                                  as.integer((object$nativeArray)$brnodeID),
                                  ## This is hc_zero.  It is never NULL.
                                  list(as.integer((object$nativeArray)$parmID),
                                  as.double((object$nativeArray)$contPT),
                                  as.integer((object$nativeArray)$mwcpSZ),
                                  as.integer((object$nativeArray)$fsrecID),
                                  if (is.null((object$nativeFactorArray)$mwcpPT)) NULL else as.integer((object$nativeFactorArray)$mwcpPT)),
                                  as.integer(object$trmbrCaseCt),
                                  as.integer(object$timbrCaseCt),
                                  as.integer(object$tombrCaseCt),
                                  as.integer(object$trmbrCaseId),
                                  as.integer(object$timbrCaseId),
                                  as.integer(object$tombrCaseId),
                                  as.integer(get.tree),
                                  as.integer(block.size),
                                  ## Pass the complete trim vector.  
                                  as.double(hazard.config$coe.trim),
                                  ## True prediction reuses the selected
                                  ## grow-time candidate.  Restore mode may
                                  ## replace this index after its OOB search.
                                  as.integer(hazard.config$coe.trim.index),
                                  if (real.time) list(as.integer(real.time.options$port), as.integer(real.time.options$time.out)) else NULL,
                                  as.integer(get.rf.cores()))}, error = function(e){NULL})
  ## Stop the C external timer.
  ctime.external.stop <- proc.time()
  ## check for error return condition in the native code
  if (is.null(nativeOutput)) {
    if (real.time == TRUE) {
      ## This is acceptable, for now.  Real time mode returns null,
      ## but we can revist this as the code evolves.
      return (NULL)  
    }
    else {
      stop("An error has occurred in prediction.  Please turn trace on for further analysis.")
    }
  }
  ## Restore mode can reselect coe.trim from the restored OOB risks.  True
  ## prediction has no OOB objective and returns the grow-time selected index
  ## supplied above.  Retain the effective protocol in the R-side object.
  hazard.config <- .update.coe.trim.selection(hazard.config, nativeOutput)
  nativeOutput$coeTrimIndex <- NULL
  nativeOutput$coeTrimRiskOOB <- NULL
  ## sample size used for the return predict object
  n.observed = ifelse(restore.mode, nrow(xvar), n.newdata)
  ## Membership targets the training observations in restore mode and
  ## the test observations in predict mode.
  pseudo.membership <- NULL
  inbag.out <- NULL
  if (membership) {
    expected.membership.length <- n.observed * ntree
    if (is.null(nativeOutput$nodeMembership) ||
        length(nativeOutput$nodeMembership) != expected.membership.length) {
      stop(paste0("Invalid native nodeMembership output: expected ",
                  expected.membership.length, " values, received ",
                  length(nativeOutput$nodeMembership), "."))
    }
    pseudo.membership <- matrix(nativeOutput$nodeMembership,
                                nrow = n.observed,
                                ncol = ntree)
    nativeOutput$nodeMembership <- NULL
    ## Bootstrap counts describe the training subjects and are meaningful
    ## on the returned object only when restoring the training forest.
    if (restore.mode) {
      expected.inbag.length <- subj.unique.count * ntree
      if (is.null(nativeOutput$bootstrapCount) ||
          length(nativeOutput$bootstrapCount) != expected.inbag.length) {
        stop(paste0("Invalid native bootstrapCount output: expected ",
                    expected.inbag.length, " values, received ",
                    length(nativeOutput$bootstrapCount), "."))
      }
      inbag.out <- matrix(nativeOutput$bootstrapCount,
                          nrow = subj.unique.count,
                          ncol = ntree)
    }
    nativeOutput$bootstrapCount <- NULL
  }
  unpack.coe.tree <- function(x, subj.count) {
    if (!is.null(x)) {
      array(x, c(subj.count, length(event.info$time.interest), ntree))
    }
    else {
      NULL
    }
  }
  if (!restore.mode) {
      hazard.ibg <- NULL
      hazard.oob <- NULL
      chf.ibg <- NULL
      chf.oob <- NULL
      coe.hazard.tree.ibg <- NULL
      coe.hazard.tree.oob <- NULL
      coe.chf.tree.ibg <- NULL
      coe.chf.tree.oob <- NULL
      risk.ibg     <- NULL
      risk.oob     <- NULL
      int.haz.ibg <- NULL
      int.haz.oob <- NULL
  } 
  if (restore.mode) {
    if (!is.null(nativeOutput$ensembleID)) {
      ensemble.id <- nativeOutput$ensembleID
    }
    else {
      ensemble.id <- NULL
    }
    if (!is.null(nativeOutput$ibgEnsbHazard)) {
      hazard.ibg  <- array(nativeOutput$ibgEnsbHazard, c(subj.unique.count, length(event.info$time.interest)))
    } else {
      hazard.ibg <- NULL
    }
    if (!is.null(nativeOutput$oobEnsbHazard)) {
      hazard.oob  <- array(nativeOutput$oobEnsbHazard, c(subj.unique.count, length(event.info$time.interest)))
    } else {
      hazard.oob <- NULL
    }
    if (!is.null(nativeOutput$ibgEnsbNlsnAaln)) {
      chf.ibg  <- array(nativeOutput$ibgEnsbNlsnAaln, c(subj.unique.count, length(event.info$time.interest)))
    } else {
      chf.ibg <- NULL
    }
    if (!is.null(nativeOutput$oobEnsbNlsnAaln)) {
      chf.oob  <- array(nativeOutput$oobEnsbNlsnAaln, c(subj.unique.count, length(event.info$time.interest)))
    } else {
      chf.oob <- NULL
    }
    if (!is.null(nativeOutput$coeHazardTreeIBG)) {      
      coe.hazard.tree.ibg <- unpack.coe.tree(nativeOutput$coeHazardTreeIBG, subj.unique.count)
    }
    else {
        coe.hazard.tree.ibg <- NULL
    }
    if (!is.null(nativeOutput$coeHazardTreeOOB)) {            
      coe.hazard.tree.oob <- unpack.coe.tree(nativeOutput$coeHazardTreeOOB, subj.unique.count)
    }
    else {
      coe.hazard.tree.oob <- NULL
    }
    if (!is.null(nativeOutput$coeCHFTreeIBG)) {
      coe.chf.tree.ibg <- unpack.coe.tree(nativeOutput$coeCHFTreeIBG, subj.unique.count)
    }
    else {
      coe.chf.tree.ibg <- NULL
    }
    if (!is.null(nativeOutput$coeCHFTreeOOB)) {
      coe.chf.tree.oob <- unpack.coe.tree(nativeOutput$coeCHFTreeOOB, subj.unique.count)
    }
    else {
      coe.chf.tree.oob <- NULL
    }
    nativeOutput$coeHazardTreeIBG <- NULL
    nativeOutput$coeHazardTreeOOB <- NULL
    nativeOutput$coeCHFTreeIBG    <- NULL
    nativeOutput$coeCHFTreeOOB    <- NULL
    if (!is.null(nativeOutput$ibgRisk)) {
      risk.ibg <- nativeOutput$ibgRisk
    } else {
      risk.ibg <- NULL
    }
    if (!is.null(nativeOutput$oobRisk)) {
      risk.oob <- nativeOutput$oobRisk
    } else {
      risk.oob <- NULL
    }
    if (!is.null(nativeOutput$ibgWCase)) {
        int.haz.ibg <- nativeOutput$ibgWCase
    } else {
        int.haz.ibg <- NULL
    }
    if (!is.null(nativeOutput$oobWCase)) {
        int.haz.oob <- nativeOutput$oobWCase
    } else {
        int.haz.oob <- NULL
    }
    if (!is.null(nativeOutput$absWCaseTimeLeft)) {
        int.haz.left <- .inverse.time(nativeOutput$absWCaseTimeLeft, time.map)
    } else {
        int.haz.left <- NULL
    }
    if (!is.null(nativeOutput$absWCaseTimeRight)) {
        int.haz.right <- .inverse.time(nativeOutput$absWCaseTimeRight, time.map)
    } else {
        int.haz.right <- NULL
    }
    hazard.tst  <- NULL
    chf.tst  <- NULL
    unscaled.risk.tst  <- NULL
    risk.tst     <- NULL
    int.haz.tst <- NULL
    coe.hazard.tree.tst <- NULL
    coe.chf.tree.tst <- NULL
    ttmbrCaseCt <- NULL
    ttmbrCaseId <- NULL
  } else {
    if (!is.null(nativeOutput$ensembleID)) {
      ensemble.id <- nativeOutput$ensembleID
    }
    else {
      ensemble.id <- NULL
    }
    if (!is.null(nativeOutput$ibgEnsbHazard)) {
      hazard.tst  <- array(nativeOutput$ibgEnsbHazard, c(subj.newdata.unique.count, length(event.info$time.interest)))
    } else {
      hazard.tst <- NULL
    }
    if (!is.null(nativeOutput$ibgEnsbNlsnAaln)) {
      chf.tst  <- array(nativeOutput$ibgEnsbNlsnAaln, c(subj.newdata.unique.count, length(event.info$time.interest)))
    } else {
      chf.tst <- NULL
    }
    if (!is.null(nativeOutput$ibgRisk)) {
      risk.tst <- nativeOutput$ibgRisk
    } else {
      risk.tst <- NULL
    }
    ## In prediction mode, the native layer currently overloads the IBG
    ## COE tree slots for test-data stitching.  There are no distinct
    ## coeHazardTreeTST / coeCHFTreeTST outgoing SEXPs.
    if (!is.null(nativeOutput$coeHazardTreeIBG)) {
      coe.hazard.tree.tst <- unpack.coe.tree(nativeOutput$coeHazardTreeIBG, subj.newdata.unique.count)
    }
    else {
      coe.hazard.tree.tst <- NULL
    }
    if (!is.null(nativeOutput$coeCHFTreeIBG)) {
      coe.chf.tree.tst <- unpack.coe.tree(nativeOutput$coeCHFTreeIBG, subj.newdata.unique.count)
    }
    else {
        coe.chf.tree.tst <- NULL
    }
    nativeOutput$coeHazardTreeIBG <- NULL
    nativeOutput$coeCHFTreeIBG <- NULL
    if (!is.null(nativeOutput$ibgWCase)) {
        int.haz.tst <- nativeOutput$ibgWCase
    } else {
        int.haz.tst <- NULL
    }
    if (!is.null(nativeOutput$absWCaseTimeLeft)) {
      int.haz.left <- .inverse.time(nativeOutput$absWCaseTimeLeft, time.map)
    } else {
      int.haz.left <- NULL
    }
    if (!is.null(nativeOutput$absWCaseTimeRight)) {
      int.haz.right <- .inverse.time(nativeOutput$absWCaseTimeRight, time.map)
    } else {
      int.haz.right <- NULL
    }
    ## We use the existing oob data structure to output the test case counts and ids.
    ttmbrCaseCt = nativeOutput$tombrCaseCt
    ttmbrCaseId = nativeOutput$tombrCaseId
  }
  if (!is.null(nativeOutput$tNelsonAalen)) {
      t.chf <- vector("list", ntree)
      offset = 0
      for (i in 1:ntree) {
        t.chf[[i]] <- matrix(nativeOutput$tNelsonAalen[(offset+1):(offset + (nativeOutput$leafCount[i] * length(event.info$time.interest)))],
                                    c(nativeOutput$leafCount[i], length(event.info$time.interest)), byrow=TRUE)
          offset = offset + (nativeOutput$leafCount[i] * length(event.info$time.interest))
      }
  } else {
      t.chf <- NULL
  }
  if (!is.null(nativeOutput$tHazard)) {
      t.hazard <- vector("list", ntree)
      offset = 0
      for (i in 1:ntree) {
        t.hazard[[i]] <- matrix(nativeOutput$tHazard[(offset+1):(offset + (nativeOutput$leafCount[i] * length(event.info$time.interest)))],
                                    c(nativeOutput$leafCount[i], length(event.info$time.interest)), byrow=TRUE)
          offset = offset + (nativeOutput$leafCount[i] * length(event.info$time.interest))
      }
  } else {
      t.hazard <- NULL
  }
  ## Terminal-node exposure, event counts, COE interval hazard, and COE
  ## cumulative hazard are always reconstructed from the training outcomes and
  ## replicated training membership restored with the forest.  Consequently,
  ## these matrices are identical in restore and new-data prediction and do not
  ## depend on test outcomes.  node.COE is rescaled below to the original hazard
  ## scale.  node.cumulative.COE is a cumulative hazard and is not rescaled.
  unpack.node.time <- function(x, native.name) {
    if (is.null(x)) {
      return(NULL)
    }
    q <- length(event.info$time.interest)
    leaf.count <- as.integer(nativeOutput$leafCount)
    if (length(leaf.count) != ntree || anyNA(leaf.count) || any(leaf.count < 0L)) {
      stop(paste0("Invalid native leafCount output while unpacking ",
                  native.name, "."))
    }
    expected.length <- sum(leaf.count) * q
    if (length(x) != expected.length) {
      stop(paste0("Invalid native ", native.name, " output: expected ",
                  expected.length, " values, received ", length(x), "."))
    }
    out <- vector("list", ntree)
    offset <- 0L
    for (i in seq_len(ntree)) {
      tree.length <- leaf.count[i] * q
      if (tree.length > 0L) {
        tree.index <- seq.int(offset + 1L, offset + tree.length)
        out[[i]] <- matrix(x[tree.index],
                           nrow=leaf.count[i],
                           ncol=q,
                           byrow=TRUE)
      }
      else {
        out[[i]] <- matrix(numeric(0L), nrow=0L, ncol=q)
      }
      offset <- offset + tree.length
    }
    out
  }
  node.U <- unpack.node.time(nativeOutput$nodeU, "nodeU")
  node.V <- unpack.node.time(nativeOutput$nodeV, "nodeV")
  node.COE <- unpack.node.time(nativeOutput$nodeCOE, "nodeCOE")
  node.cumulative.COE <- unpack.node.time(nativeOutput$nodeCumulativeCOE,
                                        "nodeCumulativeCOE")
  nativeOutput$nodeU <- NULL
  nativeOutput$nodeV <- NULL
  nativeOutput$nodeCOE <- NULL
  nativeOutput$nodeCumulativeCOE <- NULL
  if (!is.null(nativeOutput$tHazardTimeCnt)) {
      t.haz.time.cnt  <- nativeOutput$tHazardTimeCnt
  }
  else {
      t.haz.time.cnt  <- NULL
  }
  if (!is.null(nativeOutput$tHazardTimeIdx)) {
      t.haz.time.idx <- vector("list", n.observed)
      offset = 0
      for (i in 1:n.observed) {
          if (t.haz.time.cnt[i] != 0) {
              t.haz.time.idx[[i]]  <- nativeOutput$tHazardTimeIdx[(offset+1):(offset + t.haz.time.cnt[i])]
              offset = offset + t.haz.time.cnt[i]
          }
          else {
              t.haz.time.idx[[i]] <- NA_integer_
          }
      }
  }
  else {
      t.haz.time.idx  <- NULL
  }
  ## set this to NULL 
  err.rate <- NULL
  ## scale values back to original time scale
  hz.scale <- .hazard.scale(event.info$time.interest, time.map)
  if (!is.null(hazard.ibg)) hazard.ibg <- sweep(hazard.ibg, 2L, hz.scale, "*")
  if (!is.null(hazard.oob)) hazard.oob <- sweep(hazard.oob, 2L, hz.scale, "*")
  if (!is.null(hazard.tst)) hazard.tst <- sweep(hazard.tst, 2L, hz.scale, "*")
  if (!is.null(coe.hazard.tree.ibg)) coe.hazard.tree.ibg <- sweep(coe.hazard.tree.ibg, 2L, hz.scale, "*")
  if (!is.null(coe.hazard.tree.oob)) coe.hazard.tree.oob <- sweep(coe.hazard.tree.oob, 2L, hz.scale, "*")
  if (!is.null(coe.hazard.tree.tst)) coe.hazard.tree.tst <- sweep(coe.hazard.tree.tst, 2L, hz.scale, "*")
  if (!is.null(node.COE)) node.COE <- lapply(node.COE, function(h) sweep(h, 2L, hz.scale, "*"))
  if (!is.null(t.hazard)) {
    t.hazard <- lapply(t.hazard, function(h) sweep(h, 2L, hz.scale, "*"))
  }
  ## DO NOT rescale chf or t.chf
  ## make the output object
  rhfOutput <- list(
    forest = object,
    family = family,
    event.process = event.process,
    input.info = input.info,
    n = n.observed,
    ntree = ntree,
    yvar = if (restore.mode) {
      as.data.frame(.scale.yvar(yvar, time.map))
    }
    else if (is.null(yvar.newdata)) {
      NULL
    }
    else {
      as.data.frame(.scale.yvar(yvar.newdata, time.map))
    },
    xvar = if (restore.mode) xvar else xvar.newdata,
    xvar.time = object$xvar.time, 
    hcut = hcut,
    max.time = max.time,
    time.map = time.map,
    time.interest = .inverse.time(event.info$time.interest, time.map),
    event.info = event.info,
    ensemble.id = ensemble.id,
    hazard.inbag = hazard.ibg,
    hazard.oob = hazard.oob,
    hazard.test = hazard.tst,
    chf.inbag = chf.ibg,
    chf.oob   = chf.oob,
    chf.test = chf.tst,
    hazard.config = hazard.config,
    hazard.tree.inbag = coe.hazard.tree.ibg,
    hazard.tree.oob = coe.hazard.tree.oob,
    hazard.tree.test = coe.hazard.tree.tst,
    chf.tree.inbag = coe.chf.tree.ibg,
    chf.tree.oob = coe.chf.tree.oob,
    chf.tree.test = coe.chf.tree.tst,
    risk.inbag = risk.ibg,
    risk.oob   = risk.oob,
    risk.test  = risk.tst,
    int.haz.inbag = int.haz.ibg,
    int.haz.oob   = int.haz.oob,
    int.haz.test  = int.haz.tst,
    int.haz.left = int.haz.left,
    int.haz.right = int.haz.right,
    t.chf = t.chf,
    t.hazard = t.hazard,
    node.U = node.U,
    node.V = node.V,
    node.COE = node.COE,
    node.cumulative.COE = node.cumulative.COE,
    t.haz.time.cnt = t.haz.time.cnt,
    t.haz.time.idx = t.haz.time.idx,
    ttmbrCaseCt = ttmbrCaseCt,
    ttmbrCaseId = ttmbrCaseId,
    id = if (restore.mode) id else subj.newdata.output,
    pseudo.membership = pseudo.membership,
    inbag = inbag.out,
    err.rate = err.rate,
    ctime.internal = nativeOutput$cTimeInternal,
    ctime.external = ctime.external.stop - ctime.external.start
  )
  ## memory management
  nativeOutput$leafCount <- NULL
  remove(object)
  class(rhfOutput) <- c("rhf", "predict",   family)
  return(rhfOutput)
}
