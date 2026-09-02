rhf.workhorse <- function(formula,
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
                          membership = FALSE,
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
  ## hidden options (used later)
  dots <- list(...)
  ## Event-process mode is currently supplied through `...` so the public
  ## interface remains unchanged while recurrent-event support is developed.
  event.process.requested <- .rhf.match.event.process(dots$event.process)
  dots$event.process <- NULL
  adaptive <- get.adaptive(adaptive)
  ## Extract, default, and validate the hidden hazard options.
  hazard.config <- get.hazard.options(dots, adaptive = adaptive)
  ## Remove hazard options from the general-purpose dots list.
  ## This prevents accidental forwarding or duplicate storage later.
  for (option.name in names(hazard.config)) {
    dots[[option.name]] <- NULL
  }
  ## initialize the seed
  seed <- get.seed(seed)
  ## formula, family, xvar.names, yvar.names
  formula.prelim <- parse.formula(as.formula(formula), data, NULL)
  formula.detail <- finalize.formula(formula.prelim, data)
  family <- formula.detail$family
  xvar.names <- formula.detail$xvar.names
  yvar.names <- formula.detail$yvar.names
  subj.names <- formula.detail$subj.names
  ## coherence check
  if (family != "surv-tdc") {
    stop("this function (currently) only works for TDC survival")
  }
  if (length(xvar.names) == 0) {
    stop("something seems wrong: your formula did not define any x-variables")
  }
  if (length(yvar.names) == 0) {
    stop("something seems wrong: your formula did not define any y-variables")
  }
  if (length(subj.names) == 0) {
    stop("something seems wrong: your formula did not identify an id variable")
  }
  ## process y, scale time to [0,1]
  data <- cleanup.counting(
    data,
    xvar.names,
    yvar.names,
    subj.names,
    event.process = event.process.requested
  )
  max.time <- attr(data, "max.time")
  time.map <- attr(data, "time.map")
  event.process <- attr(data, "event.process")
  event.process.info <- attr(data, "event.process.info")
  subj <- data[, subj.names]
  subj.unique.count <- length(unique(subj))
  yvar <- data[, yvar.names]
  yfactor <- extract.factor(data, yvar.names)
  yfactor$types <- yvar.types <- get.yvar.type(family, yfactor$generic.types, yvar.names)
  yfactor$nlevels <- yvar.nlevels <- get.yvar.nlevels(family, yfactor$nlevels, yvar.names, yvar)
  yfactor$numeric.levels <- yvar.numeric.levels <- get.numeric.levels(family, yfactor$nlevels, yvar)
  ## process x
  xvar <- data[, xvar.names, drop = FALSE]
  n.xvar <- length(xvar.names)
  n <- nrow(xvar)
  ## We manually patch in the factor object.
  xfactor <- list(factor = character(0),
                  order = character(0),
                  levels = NULL,
                  order.levels = NULL,
                  nlevels = rep(0, n.xvar),
                  types = rep("R", n.xvar))
  xvar.types <- xfactor$types
  xvar.nlevels <- xfactor$nlevels
  xfactor$numeric.levels <- xvar.numeric.levels <- get.numeric.levels(family, xfactor$nlevels, xvar)
  xvar.wt  <- get.weight(xvar.wt, n.xvar)
  ## determine which x-variables are time-dependent
  ## determine which individuals have any time-varying information
  xvar.time <- get.tdc.cov(data, subj.names, yvar.names)
  subj.time <- get.tdc.subj.time(data, subj.names, yvar.names)
  ## don't need the data anymore
  remove(data)
  ## tree grow options
  mtry <- get.mtry(family, n.xvar, dots$mtry)
  nodesize <- get.nodesize(nodesize, any(xvar.time > 0))
  splitinfo <- get.splitinfo(formula.detail, dots$splitrule, nsplit)
  ## hard coded options 
  hcut <- 1
  tune <- FALSE
  augmentX <- augmentXlist <- NULL
  ## experimental options
  experimental.bits <- get.experimental.bits(
    dots$experimental.bits,
    FALSE,
    hazard.estimator = hazard.config$hazard.estimator,
    coe.aggregate = hazard.config$coe.aggregate
  )
  ## missingness not allowed in rhf
  data.pass <- TRUE
  data.pass.bits <- get.data.pass.bits(data.pass)
  ## hard coded options (some are legacy)
  perf.type <- NULL
  ensemble <- NULL
  empirical.risk <- TRUE
  forest <- TRUE
  m.target.idx <- 1
  ## Get event information and dimensioning for families
  if (length(ntime) > 1) {
    ## user specified time points have to be mapped to [0,1]
    ntime <- .forward.time(ntime, time.map)
  }
  event.info <- get.grow.event.info(
    yvar,
    family,
    ntime = ntime,
    min.events.per.gap = min.events.per.gap,
    subj = subj,
    event.process = event.process,
    process.info = event.process.info
  )
  event.process <- event.info$event.process
  ## legacy lot
  lot <- get.lot(hcut,
                 tune=tune,
                 lag=dots$lag,
                 strikeout=dots$strikeout,
                 max.two=dots$max.two,
                 max.three=dots$max.three,
                 max.four=dots$max.four)
  ## set tree size.  event.info$n.event is the total number of row-level
  ## event increments, equivalently the number of subjects multiplied by the
  ## average number of events per subject.
  if (is.null(treesize) || !is.numeric(treesize)) {
    treesize <- default.treesize(
      ndead = event.info$n.event,
      min.events.per.leaf = min.events.per.gap
    )
  }
  treesize <- max(1L, as.integer(treesize))
  ## add this to lot, must be in slot #2
  lot <- c(
    lot[1],
    list(treesize = treesize),
    lot[-1]
  )
  ## Temporary capability gate.  The R layer now validates and classifies
  ## recurrent input, but the current CRAN native implementation still assumes
  ## a terminal event.  Remove this gate when the recurrent native mode and its
  ## explicit interface flag are available.
  if (identical(event.process, "recurrent")) {
    stop(
      "Recurrent-event input was detected and validated, but recurrent-event ",
      "fitting is not enabled in this build of randomForestRHF because the ",
      "required native implementation is still under development.",
      call. = FALSE
    )
  }
  ## initialize samptype
  samptype <- match.arg(samptype, c("swor", "swr"))
  ## bootstrap specifics
  bootstrap <- match.arg(bootstrap, c("by.root", "none", "by.user"))
  if (bootstrap == "by.root") {
    ## Nominal bootstrap at the root node.
    if (!is.function(sampsize) && !is.numeric(sampsize)) {
      stop("sampsize must be a function or number specifying size of subsampled data")
    }
    if (is.function(sampsize)) {
      sampsize.function <- sampsize
    }
    else {
      ## convert user passed sample size to a function
      sampsize.function <- make.samplesize.function(sampsize / subj.unique.count)
    }
    sampsize <- round(sampsize.function(subj.unique.count))
    if (sampsize < 1) {
      stop("sampsize must be greater than zero")
    }
    ## for swor size is limited by the number of cases
    if (samptype == "swor" && (sampsize > subj.unique.count)) {
      sampsize <- subj.unique.count
      sampsize.function <- function(x){x}
    }
    samp <- NULL
    case.wt  <- get.weight(case.wt, subj.unique.count)
  }
  else if (bootstrap == "by.user") {    
    ## check for coherent sample: it will of be dim [.] x [ntree]
    ## where [.] is the number of rows in the data set or unique subjects in
    ## the case of time dependent covariates.
    if (is.null(samp)) {
      stop("samp must not be NULL when bootstrapping by user")
    }
    ## ntree should be coherent with the sample provided
    ntree <- ncol(samp)
    sampsize <- colSums(samp)
    if (sum(sampsize == sampsize[1]) != ntree) {
      stop("sampsize must be identical for each tree")
    }
    ## set the sample size and function
    sampsize <- sampsize[1]
    sampsize.function <- make.samplesize.function(sampsize[1] / subj.unique.count)
    case.wt  <- get.weight(NULL, subj.unique.count)
  }
  ## This is "none".
  else {
    sampsize <- subj.unique.count
    sampsize.function <- function(x){x}
    case.wt  <- get.weight(case.wt, sampsize)
  }
  ## Turn performance output off unless bootstrapping by root or user.
  if ((bootstrap != "by.root") && (bootstrap != "by.user")) {
    perf.type <- "none"
  }
  ## Set the ensemble option.
  if (!is.null(ensemble)) {
    ## leave the ensemble as is for testing purposes.
  }
  else {
    ensemble <- "all"
    if (bootstrap == "none") {
      ensemble <- "inbag"
    }
  }
  ## perf type
  perf.type <- get.perf(perf.type, family)
  ## Assign low bits for the native code
  bootstrap.bits <- get.bootstrap.bits(bootstrap)
  empirical.risk.bits <- get.empirical.risk.bits(empirical.risk)
  perf.bits <-  get.perf.bits(perf.type)
  ensemble.bits <- get.ensemble.bits(ensemble)
  forest.bits <- get.forest.bits(forest)
  ## Assign high bits for the native code
  membership.bits <-  get.membership.bits(membership)
  samptype.bits <- get.samptype.bits(samptype)
  ## block size
  block.size <- get.block.size.bits(block.size, ntree)
  ## integrated hazard calculation
  wmode <- is.hidden.wmode(dots)    
  ## values of wmode in [1, 2, 3] are converted to local bits.
  wmode.bits <- get.wmode.bits(wmode)
  ## right censored flag will typically always exist and be true or
  ## false, not hidden, but we allow some flexibility
  right.censored <- is.hidden.rc(dots)
  right.censored.bits <- get.rc.bits(right.censored)
  ## Set the user defined trace.
  do.trace <- get.trace(do.trace)
  ## Start the C external timer.
  ctime.external.start  <- proc.time()
################################################ ##
  nativeOutput <- tryCatch({.Call("entryGrow",
                                  as.integer(do.trace),
                                  as.integer(seed),
                                  as.integer(bootstrap.bits +     ## low option word
                                             empirical.risk.bits +
                                             perf.bits +
                                             ensemble.bits +
                                             forest.bits),  
                                  as.integer(membership.bits +    ## high option word
                                             2^16 + 2^18 +        ## MEMB_OUTG and TERM_OUTG
                                             samptype.bits),
                                  as.integer(experimental.bits +
                                             wmode.bits +
                                             right.censored.bits),  ## rhf (local experimental) option word
                                  as.integer(ntree),
                                  as.integer(n),
                                  list(as.integer(subj.unique.count),
                                       if (is.null(case.wt)) NULL else as.double(case.wt),
                                       as.integer(sampsize),
                                       if (is.null(samp)) NULL else as.integer(samp)),
                                  as.integer(splitinfo$index),
                                  as.integer(splitinfo$nsplit),
                                  as.integer(mtry),
                                  as.integer(nodesize),
                                  lot,
                                  list(if (is.null(m.target.idx)) as.integer(0) else as.integer(length(m.target.idx)),
                                       if (is.null(m.target.idx)) NULL else as.integer(m.target.idx)),
                                  list(as.integer(length(yvar.types)),
                                       if (is.null(yvar.types)) NULL else as.character(yvar.types),
                                       ## No factors, so we massage pass zeros.
                                       if (is.null(yvar.types)) NULL else as.integer(yvar.nlevels),
                                       if (is.null(yvar.numeric.levels)) NULL else sapply(1:length(yvar.numeric.levels), function(nn) {as.integer(length(yvar.numeric.levels[[nn]]))}),
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
                                  list(as.integer(n.xvar),
                                       as.character(xvar.types),
                                       if (is.null(xvar.types)) NULL else as.integer(xvar.nlevels),
                                       if (is.null(xvar.nlevels)) NULL else sapply(1:length(xvar.nlevels), function(nn) {as.integer(length(xvar.nlevels[[nn]]))}),
                                       if (is.null(xvar.time)) NULL else as.integer(xvar.time),
                                       if (is.null(subj.time)) NULL else as.integer(subj.time)),
                                  if (is.null(xvar.nlevels)) {
                                    NULL
                                  }
                                  else {
                                    lapply(1:length(xvar.nlevels),
                                           function(nn) {as.integer(xvar.nlevels[[nn]])})
                                  },
                                  as.double(as.vector(data.matrix(xvar))),
                                  as.double(xvar.wt),
                                  ## Here is the hack for the augmented x-vars.  The C-side needs to know how many there are,
                                  ## so we have two elements, the first is the dimension, the second is the array. You should
                                  ## replace these with the actual values.
                                  augmentXlist,
                                  as.integer(block.size),
                                  ## Pass the complete trim vector.  
                                  as.double(hazard.config$coe.trim),
                                  as.integer(get.rf.cores()))},
                           ## error = function(e) {NULL}
                           error = function(e) { print(e); NULL }
                           )
  ## Stop the C external timer.
  ctime.external.stop <- proc.time()
  ## check for error return condition in the native code
  if (is.null(nativeOutput)) {
    stop("An error has occurred on the C-side.  Please turn trace on for further analysis.")
  }
  ## In winsorized-mean COE mode, native grow selects the candidate trim
  ## fraction that minimizes the aggregate OOB risk.  Retain both the winning
  ## index/value and the complete candidate-risk curve in hazard.config.  The
  ## native-only SEXP objects are then removed from the general output list.
  hazard.config <- .update.coe.trim.selection(hazard.config, nativeOutput)
  nativeOutput$coeTrimIndex <- NULL
  nativeOutput$coeTrimRiskOOB <- NULL
  nativeArraySize  <- 0
  mwcpCountSummary <- 0  
  nullO <- lapply(1:ntree, function(b) {
    if (nativeOutput$leafCount[b] > 0) {
      ## The tree was not rejected.  Count the number of internal
      ## and external (terminal) nodes in the forest.
      nativeArraySize <<- nativeArraySize + (2 * nativeOutput$leafCount[b]) - 1
      mwcpCountSummary <<- mwcpCountSummary + nativeOutput$mwcpCT[b]
    }
    else {
      ## The tree was rejected.  However, it acts as a
      ## placeholder, being a stump topologically and thus
      ## adds to the total node count.
      nativeArraySize <<- nativeArraySize + 1
    }
    NULL
  })
  rm(nullO)  ##memory saver
  ## save the native array
  nativeArray <- as.data.frame(cbind(nativeOutput$treeID[1:nativeArraySize],
                                     nativeOutput$nodeID[1:nativeArraySize],
                                     nativeOutput$nodeSZ[1:nativeArraySize],
                                     nativeOutput$brnodeID[1:nativeArraySize],
                                     nativeOutput$prnodeID[1:nativeArraySize],
                                     nativeOutput$parmID[1:nativeArraySize],
                                     nativeOutput$contPT[1:nativeArraySize],
                                     nativeOutput$mwcpSZ[1:nativeArraySize],
                                     nativeOutput$fsrecID[1:nativeArraySize]
                                     ))
  colnames(nativeArray) <- c("treeID", "nodeID", "nodeSZ", "brnodeID", "prnodeID", "parmID", "contPT", "mwcpSZ", "fsrecID")
  ## save the native factor array
  if (mwcpCountSummary > 0) {
    ## This can be NULL if there are no factor splits along this dimension.
    nativeFactorArray <- as.data.frame(cbind(nativeOutput$mwcpPT[1:mwcpCountSummary]))
    colnames(nativeFactorArray)  <- c("mwcpPT")
  }
  else {
    nativeFactorArray  <- NULL
  }
  ## save the forest
  lot <- c(lot, tune=tune)
  forest.out  <- list(forest = TRUE,
                      ntree = ntree,
                      n = n,
                      subj.names = subj.names,
                      id = subj,
                      yvar = .scale.yvar(yvar, time.map),
                      yvar.names = yvar.names,
                      yvar.factor = yfactor,
                      event.info = event.info,
                      xvar = xvar,
                      xvar.names = xvar.names,
                      xvar.factor = xfactor,
                      xvar.time = xvar.time,
                      seed = nativeOutput$seed,
                      nativeArray = nativeArray,
                      nativeFactorArray = nativeFactorArray,
                      leafCount = nativeOutput$leafCount,
                      totalNodeCount = dim(nativeArray)[1],
                      nodesize = nodesize,
                      perf.type = perf.type,
                      lot = lot,
                      family = family,
                      event.process = event.process,
                      ##                        bootstrap = bootstrap,
                      ##                        samptype = samptype,
                      experimental.bits = experimental.bits,
                      data.pass = data.pass,
                      parms = list(splitrule = splitinfo$splitrule,
                                   ntree = ntree,
                                   mtry = mtry,
                                   nodesize = nodesize,
                                   ntime = if (length(ntime) > 1) .inverse.time(ntime, time.map) else ntime,
                                   nsplit = splitinfo$nsplit,
                                   adaptive = adaptive,
                                   event.process = event.process,
                                   experimental.bits = experimental.bits,
                                   bootstrap = bootstrap,
                                   case.wt = case.wt,
                                   sampsize = sampsize,             
                                   samp = samp, 
                                   samptype = samptype,
                                   xvar.wt = xvar.wt),
                      trmbrCaseCt = nativeOutput$trmbrCaseCt,
                      timbrCaseCt = nativeOutput$timbrCaseCt,
                      tombrCaseCt = nativeOutput$tombrCaseCt,
                      trmbrCaseId = nativeOutput$trmbrCaseId,
                      timbrCaseId = nativeOutput$timbrCaseId,
                      tombrCaseId = nativeOutput$tombrCaseId,
                      ibgSizeCase = nativeOutput$ibgSizeCase,
                      oobSizeCase = nativeOutput$oobSizeCase,
                      terminal.qualts = TRUE,
                      terminal.quants = TRUE,
                      ## add x,y values here as needed
                      xvar.time = xvar.time,
                      version = "2.0.3")
  empr.risk <- NULL
  oob.empr.risk <- NULL
  nodeStat <- NULL
  if (!is.null(nativeOutput$bsfOrder)) {
    bsf.order <- nativeOutput$bsfOrder
    nativeOutput$bsfOrder <- NULL
  }
  if (membership) {
    pseudo.membership <- matrix(nativeOutput$nodeMembership, c(n, ntree))
    inbag.out <- matrix(nativeOutput$bootstrapCount, c(subj.unique.count, ntree))
    nativeOutput$nodeMembership <- NULL
    nativeOutput$bootstrapCount <- NULL
  }
  else {
    pseudo.membership <- NULL
    inbag.out  <- NULL
  }
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
  unpack.coe.tree <- function(x) {
    if (!is.null(x)) {
      array(x, c(subj.unique.count, length(event.info$time.interest), ntree))
    }
    else {
      NULL
    }
  }
  coe.hazard.tree.ibg <- unpack.coe.tree(nativeOutput$coeHazardTreeIBG)
  coe.hazard.tree.oob <- unpack.coe.tree(nativeOutput$coeHazardTreeOOB)
  coe.chf.tree.ibg <- unpack.coe.tree(nativeOutput$coeCHFTreeIBG)
  coe.chf.tree.oob <- unpack.coe.tree(nativeOutput$coeCHFTreeOOB)
  nativeOutput$coeHazardTreeIBG <- NULL
  nativeOutput$coeHazardTreeOOB <- NULL
  nativeOutput$coeCHFTreeIBG <- NULL
  nativeOutput$coeCHFTreeOOB <- NULL
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
  ## New left and right hand time points over which the case hazard was integrated.
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
  if (empirical.risk) {
    if (!is.null(nativeOutput$nodeRisk)) {
      node.risk <- array(nativeOutput$nodeRisk, c(nativeArraySize, 1))
      nativeOutput$nodeRisk <- NULL
    }
    if (!is.null(nativeOutput$ibgTreeRisk)) {
      tree.risk.ibg <- array(nativeOutput$ibgTreeRisk, c(lot$treesize, ntree))
      nativeOutput$ibgTreeRisk <- NULL
    }
    if (!is.null(nativeOutput$oobTreeRisk)) {
      tree.risk.oob <- array(nativeOutput$oobTreeRisk, c(lot$treesize, ntree))
      nativeOutput$oobTreeRisk <- NULL
    }
    ## Not populated for now.
    if (!is.null(nativeOutput$nodeStat)) {
      nodeStat <- array(nativeOutput$nodeStat[1:nativeArraySize])
      nativeOutput$nodeStat <- NULL
    }
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
  if (!is.null(nativeOutput$tHazardTimeCnt)) {
    t.haz.time.cnt  <- nativeOutput$tHazardTimeCnt
  }
  else {
    t.haz.time.cnt  <- NULL
  }
  if (!is.null(nativeOutput$tHazardTimeIdx)) {
    t.haz.time.idx <- vector("list", n)
    offset = 0
    for (i in 1:n) {
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
  ## Add the terminal quantitative information to the forest object for now.
  hz.scale <- .hazard.scale(event.info$time.interest, time.map)
  if (!is.null(hazard.ibg)) {
    hazard.ibg <- sweep(hazard.ibg, 2L, hz.scale, "*")
  }
  if (!is.null(hazard.oob)) {
    hazard.oob <- sweep(hazard.oob, 2L, hz.scale, "*")
  }
  if (!is.null(t.hazard)) {
    t.hazard <- lapply(t.hazard, function(h) sweep(h, 2L, hz.scale, "*"))
  }
  ## Terminal-node exposure, event counts, COE interval hazard, and COE
  ## cumulative hazard.  Each tree element has one row per terminal node and
  ## one column per time-interest interval.  node.U is on the internal time
  ## scale used by transformation; node.V is a count; node.COE is V/U, returned below
  ## on the original hazard scale.  node.cumulatve.COE is the terminal-node COE
  ## cumulative hazard on the internal time scale and is not hazard-rescaled.
  if (!is.null(nativeOutput$nodeU)) {
    node.U <- vector("list", ntree)
    offset = 0
    for (i in 1:ntree) {
      node.U[[i]] <- matrix(nativeOutput$nodeU[(offset+1):(offset + (nativeOutput$leafCount[i] * length(event.info$time.interest)))],
                            c(nativeOutput$leafCount[i], length(event.info$time.interest)), byrow=TRUE)
      offset = offset + (nativeOutput$leafCount[i] * length(event.info$time.interest))
    }
    nativeOutput$nodeU <- NULL
  } else {
    node.U <- NULL
  }
  if (!is.null(nativeOutput$nodeV)) {
    node.V <- vector("list", ntree)
    offset = 0
    for (i in 1:ntree) {
      node.V[[i]] <- matrix(nativeOutput$nodeV[(offset+1):(offset + (nativeOutput$leafCount[i] * length(event.info$time.interest)))],
                            c(nativeOutput$leafCount[i], length(event.info$time.interest)), byrow=TRUE)
      offset = offset + (nativeOutput$leafCount[i] * length(event.info$time.interest))
    }
    nativeOutput$nodeV <- NULL
  } else {
    node.V <- NULL
  }
  if (!is.null(nativeOutput$nodeCOE)) {
    node.COE <- vector("list", ntree)
    offset = 0
    for (i in 1:ntree) {
      node.COE[[i]] <- matrix(nativeOutput$nodeCOE[(offset+1):(offset + (nativeOutput$leafCount[i] * length(event.info$time.interest)))],
                              c(nativeOutput$leafCount[i], length(event.info$time.interest)), byrow=TRUE)
      offset = offset + (nativeOutput$leafCount[i] * length(event.info$time.interest))
    }
    node.COE <- lapply(node.COE, function(h) sweep(h, 2L, hz.scale, "*"))
    nativeOutput$nodeCOE <- NULL
  } else {
    node.COE <- NULL
  }
  if (!is.null(nativeOutput$nodeCumulativeCOE)) {
    node.cumulative.COE <- vector("list", ntree)
    offset = 0
    for (i in 1:ntree) {
      node.cumulative.COE[[i]] <- matrix(nativeOutput$nodeCumulativeCOE[(offset+1):(offset + (nativeOutput$leafCount[i] * length(event.info$time.interest)))],
                                       c(nativeOutput$leafCount[i], length(event.info$time.interest)), byrow=TRUE)
      offset = offset + (nativeOutput$leafCount[i] * length(event.info$time.interest))
    }
    nativeOutput$nodeCumulativeCOE <- NULL
  } else {
    node.cumulative.COE <- NULL
  }
  if (!is.null(coe.hazard.tree.ibg)) {
    coe.hazard.tree.ibg <- sweep(coe.hazard.tree.ibg, 2L, hz.scale, "*")
  }
  if (!is.null(coe.hazard.tree.oob)) {
    coe.hazard.tree.oob <- sweep(coe.hazard.tree.oob, 2L, hz.scale, "*")
  }
  ## assemble the forest object
  forest.out  <- append(forest.out,
                        list(time.map = time.map,
                             t.chf = t.chf,
                             t.hazard = t.hazard,
                             t.haz.time.cnt = t.haz.time.cnt,
                             t.haz.time.idx = t.haz.time.idx))
  ## Save the validated hazard configuration with the forest.
  forest.out$parms$hazard.config <- hazard.config
  ## Initialize the default class of the forest.
  class(forest.out) <- c("rhf", "forest", family)
  ## set this to NULL 
  err.rate <- NULL
  ## make the output object    
  rhfOutput  <- list(
    family = family,
    event.process = event.process,
    n = n,
    ntree = ntree,
    hcut = hcut,
    max.time = max.time,
    time.map = time.map,
    time.interest = .inverse.time(event.info$time.interest, time.map),
    hazard.inbag = hazard.ibg,
    hazard.oob = hazard.oob,
    chf.inbag = chf.ibg,
    chf.oob   = chf.oob,
    adaptive = adaptive,
    hazard.config = hazard.config,
    hazard.tree.inbag = coe.hazard.tree.ibg,
    hazard.tree.oob = coe.hazard.tree.oob,
    chf.tree.inbag = coe.chf.tree.ibg,
    chf.tree.oob = coe.chf.tree.oob,
    risk.inbag = risk.ibg,
    risk.oob   = risk.oob,
    int.haz.inbag = int.haz.ibg,
    int.haz.oob = int.haz.oob,
    int.haz.left = int.haz.left,
    int.haz.right = int.haz.right,
    event.info = event.info,
    ensemble.id = ensemble.id,
    splitrule = splitinfo$splitrule,
    splitinfo = splitinfo,
    subj.names = subj.names,
    id = subj,
    yvar = as.data.frame(.scale.yvar(yvar, time.map)),
    yvar.names = yvar.names,
    yvar.factor = yfactor,
    yvar.types = yvar.types,
    xvar = xvar,
    xvar.names = xvar.names,
    xvar.types = xvar.types,
    xvar.time = xvar.time,
    forest = forest.out,
    node.risk = node.risk,
    node.U = node.U,
    node.V = node.V,
    node.COE = node.COE,
    node.cumulative.COE = node.cumulative.COE,
    tree.risk.inbag = tree.risk.ibg,
    tree.risk.oob   = tree.risk.oob,
    nodeStat = nodeStat,
    bsf.order = bsf.order,
    pseudo.membership = pseudo.membership,
    inbag = inbag.out,
    err.rate = err.rate,
    ctime.internal = nativeOutput$cTimeInternal,
    ctime.external = ctime.external.stop - ctime.external.start
  )
  ## save the call/formula for the return object
  my.call <- match.call()
  my.call$formula <- eval(formula)
  rhfOutput$call <- my.call
  ## return the object
  class(rhfOutput) <- c("rhf", "grow", family)
  return(rhfOutput)
}
