####################################################################
##
## default tree size
##
####################################################################
default.treesize <- function(ndead,
                             min.events.per.leaf = 10L,
                             target.events.per.leaf = 50L,
                             min.treesize = 15L) {
  target <- max(min.treesize,
                ndead / target.events.per.leaf)
  support.limit <- ndead / min.events.per.leaf
  max(1L, as.integer(floor(min(target, support.limit))))
}
####################################################################
##
## Event-process validation helpers
##
####################################################################
.rhf.match.event.process <- function(event.process = c("auto", "terminal", "recurrent")) {
  if (is.null(event.process)) {
    event.process <- "auto"
  }
  match.arg(event.process, c("auto", "terminal", "recurrent"))
}
.rhf.coerce.event.code <- function(event,
                                   binary = TRUE,
                                   what = "event") {
  event.na <- is.na(event)
  if (is.factor(event)) {
    event <- as.character(event)
  }
  if (is.logical(event)) {
    event <- as.integer(event)
  }
  event.num <- suppressWarnings(as.numeric(event))
  bad.coercion <- is.na(event.num) & !event.na
  if (any(bad.coercion)) {
    stop("The ", what, " variable could not be converted to numeric values.",
         call. = FALSE)
  }
  if (any(is.na(event.num))) {
    stop("The ", what, " variable cannot contain missing values.",
         call. = FALSE)
  }
  if (any(!is.finite(event.num))) {
    stop("The ", what, " variable must contain finite values.",
         call. = FALSE)
  }
  if (isTRUE(binary)) {
    if (any(!(event.num %in% c(0, 1)))) {
      stop("The ", what,
           " variable must be coded 0/1 for terminal or recurrent RHF data.",
           call. = FALSE)
    }
  } else {
    if (any(event.num < 0 | event.num != floor(event.num))) {
      stop("The ", what,
           " variable must be coded as a non-negative integer.",
           call. = FALSE)
    }
  }
  as.integer(event.num)
}
.rhf.validate.counting.intervals <- function(id,
                                             start,
                                             stop,
                                             eps = 1e-8,
                                             data.name = "data") {
  if (!(length(id) == length(start) && length(start) == length(stop))) {
    stop("Subject, start, and stop vectors have incompatible lengths in ",
         data.name, ".", call. = FALSE)
  }
  if (!length(id)) {
    stop("No counting-process rows remain in ", data.name, ".",
         call. = FALSE)
  }
  if (anyNA(id)) {
    stop("Subject identifiers cannot be missing in ", data.name, ".",
         call. = FALSE)
  }
  if (any(!is.finite(start) | !is.finite(stop))) {
    stop("Start and stop times must be finite in ", data.name, ".",
         call. = FALSE)
  }
  if (any(stop <= start)) {
    stop("Every counting-process row must satisfy start < stop in ",
         data.name, ".", call. = FALSE)
  }
  id.key <- if (is.factor(id)) as.integer(id) else id
  subject.blocks <- rle(id.key)$values
  if (anyDuplicated(subject.blocks)) {
    stop("Rows for each subject must form one contiguous block in ",
         data.name, ".", call. = FALSE)
  }
  n <- length(id.key)
  if (n > 1L) {
    same.subject <- id.key[-1L] == id.key[-n]
    out.of.order <- same.subject &
      (start[-1L] < start[-n] - eps)
    if (any(out.of.order)) {
      stop("Within each subject, counting-process rows must be ordered by start time in ",
           data.name, ".", call. = FALSE)
    }
    overlap <- same.subject &
      (start[-1L] < stop[-n] - eps)
    if (any(overlap)) {
      stop("Overlapping counting-process intervals were found within a subject in ",
           data.name, ". Intervals may be contiguous or separated by gaps, but they may not overlap.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}
.rhf.event.process.info <- function(id,
                                    event,
                                    start = NULL,
                                    stop = NULL,
                                    event.process = c("auto", "terminal", "recurrent"),
                                    binary = TRUE,
                                    what = "event",
                                    presorted = FALSE) {
  requested <- .rhf.match.event.process(event.process)
  event <- .rhf.coerce.event.code(event, binary = binary, what = what)
  if (length(id) != length(event)) {
    stop("Subject and event vectors have incompatible lengths.",
         call. = FALSE)
  }
  if (!length(id)) {
    stop("No subjects are available for event-process validation.",
         call. = FALSE)
  }
  if (anyNA(id)) {
    stop("Subject identifiers cannot be missing when validating the event process.",
         call. = FALSE)
  }
  if (!is.null(start) || !is.null(stop)) {
    if (is.null(start) || is.null(stop) ||
        length(start) != length(event) || length(stop) != length(event)) {
      stop("Start and stop vectors must both be supplied and have one value per event row.",
           call. = FALSE)
    }
    if (any(!is.finite(start) | !is.finite(stop))) {
      stop("Start and stop times must be finite when validating the event process.",
           call. = FALSE)
    }
  }
  id.key <- if (is.factor(id)) as.integer(id) else id
  if (isTRUE(presorted)) {
    id.ord <- id.key
    subject.id.ord <- id
    event.ord <- event
  } else {
    group <- match(id.key, id.key)
    if (!is.null(start)) {
      ord <- order(group, start, stop, seq_along(event), method = "radix")
    } else {
      ord <- order(group, seq_along(event), method = "radix")
    }
    id.ord <- id.key[ord]
    subject.id.ord <- id[ord]
    event.ord <- event[ord]
  }
  rr <- rle(id.ord)
  ends <- cumsum(rr$lengths)
  starts <- ends - rr$lengths + 1L
  subject.order <- subject.id.ord[starts]
  event.count <- integer(length(rr$lengths))
  premature.event <- logical(length(rr$lengths))
  event.position <- which(event.ord != 0L)
  if (length(event.position)) {
    event.group <- findInterval(event.position - 1L, ends) + 1L
    event.count <- tabulate(event.group, nbins = length(rr$lengths))
    premature.group <- unique(event.group[event.position < ends[event.group]])
    if (length(premature.group)) {
      premature.event[premature.group] <- TRUE
    }
  }
  names(event.count) <- as.character(subject.order)
  recurrent.pattern <- any(event.count > 1L) || any(premature.event)
  inferred <- if (recurrent.pattern) "recurrent" else "terminal"
  resolved <- if (requested == "auto") inferred else requested
  q <- stats::quantile(event.count,
                       probs = c(0, 0.25, 0.50, 0.75, 1),
                       names = FALSE,
                       type = 1)
  list(
    event = event,
    requested = requested,
    inferred = inferred,
    event.process = resolved,
    terminal.valid = !recurrent.pattern,
    n.subject = length(event.count),
    n.event = sum(event.count),
    n.event.subject = sum(event.count > 0L),
    mean.events.per.subject = mean(event.count),
    max.events.per.subject = max(event.count),
    events.per.subject.summary = c(
      min = q[1L],
      q1 = q[2L],
      median = q[3L],
      mean = mean(event.count),
      q3 = q[4L],
      max = q[5L]
    ),
    event.count.by.subject = event.count,
    subject.order = subject.order,
    premature.event.subject = subject.order[premature.event]
  )
}
####################################################################
##
## TDC Helper Functions
##
####################################################################
## Internal formula/data normalization for the public RHF interfaces.
## The workhorses continue to receive only the canonical four-argument
## counting-process response Surv(id, start, stop, event).
.rhf.deparse1 <- function(x) {
  paste(deparse(x, width.cutoff = 500L), collapse = "")
}
.rhf.make.internal.names <- function(existing,
                                     roots = c(".rhf.id",
                                               ".rhf.start",
                                               ".rhf.stop",
                                               ".rhf.event")) {
  existing <- as.character(existing)
  out <- character(length(roots))
  used <- existing
  for (j in seq_along(roots)) {
    candidate <- roots[j]
    suffix <- 0L
    while (candidate %in% used) {
      suffix <- suffix + 1L
      candidate <- paste0(roots[j], ".", suffix)
    }
    out[j] <- candidate
    used <- c(used, candidate)
  }
  names(out) <- c("id", "start", "stop", "event")
  out
}
.rhf.coerce.right.time <- function(x, what = "time") {
  x.na <- is.na(x)
  if (is.factor(x)) {
    out <- suppressWarnings(as.numeric(as.character(x)))
  }
  else {
    out <- suppressWarnings(as.numeric(x))
  }
  bad.coercion <- is.na(out) & !x.na
  if (any(bad.coercion)) {
    stop("The ", what, " variable could not be converted to numeric values.",
         call. = FALSE)
  }
  if (any(!is.finite(out) & !is.na(out))) {
    stop("The ", what, " variable must contain finite values or NA.",
         call. = FALSE)
  }
  if (any(out < 0, na.rm = TRUE)) {
    stop("The ", what, " variable cannot contain negative values.",
         call. = FALSE)
  }
  out
}
.rhf.prepare.input <- function(formula, data) {
  if (missing(formula) || is.null(formula)) {
    stop("Argument 'formula' must be supplied.", call. = FALSE)
  }
  if (missing(data) || is.null(data)) {
    stop("Argument 'data' must be supplied.", call. = FALSE)
  }
  if (!is.data.frame(data)) {
    data <- as.data.frame(data)
  }
  f <- as.formula(formula)
  if (length(f) != 3L) {
    stop("RHF requires a two-sided model formula.", call. = FALSE)
  }
  lhs <- f[[2L]]
  if (!is.call(lhs) || !identical(as.character(lhs[[1L]]), "Surv")) {
    stop("The left-hand side of 'formula' must be a Surv(...) call.",
         call. = FALSE)
  }
  response.args <- as.list(lhs)[-1L]
  ## Existing RHF counting-process interface.  Return it unchanged so the
  ## current workhorse remains the sole implementation for model fitting.
  if (length(response.args) == 4L) {
    response.names <- vapply(
      response.args,
      function(z) if (is.symbol(z)) as.character(z) else .rhf.deparse1(z),
      character(1L)
    )
    names(response.names) <- c("id", "start", "stop", "event")
    missing.response <- setdiff(unname(response.names), names(data))
    if (length(missing.response)) {
      stop("The following response variable(s) are missing from 'data': ",
           paste(missing.response, collapse = ", "),
           call. = FALSE)
    }
    return(list(
      formula = f,
      data = data,
      info = list(
        version = 1L,
        format = "counting",
        response.names = response.names,
        internal.names = response.names,
        n.original = nrow(data)
      )
    ))
  }
  if (length(response.args) == 3L) {
    stop(
      "RHF counting-process input requires an explicit subject identifier: ",
      "use Surv(id, start, stop, event), not Surv(start, stop, event).",
      call. = FALSE
    )
  }
  if (length(response.args) != 2L) {
    stop(
      "RHF accepts either Surv(time, event) for ordinary right-censored data ",
      "or Surv(id, start, stop, event) for counting-process data.",
      call. = FALSE
    )
  }
  ## For ordinary survival input, require direct column references.  This
  ## keeps the stored response map compact and allows raw test data to be
  ## converted later using the same original column names.
  simple.response <- vapply(response.args, is.symbol, logical(1L))
  if (!all(simple.response)) {
    stop(
      "The time and event arguments in Surv(time, event) must each be a ",
      "column name in 'data'.",
      call. = FALSE
    )
  }
  response.names <- vapply(response.args, as.character, character(1L))
  names(response.names) <- c("time", "event")
  missing.response <- setdiff(unname(response.names), names(data))
  if (length(missing.response)) {
    stop("The following response variable(s) are missing from 'data': ",
         paste(missing.response, collapse = ", "),
         call. = FALSE)
  }
  if (identical(response.names[["time"]], response.names[["event"]])) {
    stop("The time and event variables in Surv(time, event) must be distinct.",
         call. = FALSE)
  }
  time <- .rhf.coerce.right.time(
    data[[response.names[["time"]]]],
    what = response.names[["time"]]
  )
  internal.names <- .rhf.make.internal.names(
    c(names(data), all.vars(f[[3L]]))
  )
  internal.data <- data
  internal.data[[internal.names[["id"]]]] <- seq_len(nrow(internal.data))
  internal.data[[internal.names[["start"]]]] <- rep(0, nrow(internal.data))
  internal.data[[internal.names[["stop"]]]] <- time
  internal.data[[internal.names[["event"]]]] <-
    internal.data[[response.names[["event"]]]]
  ## A two-column right-censored response is necessarily a terminal-event
  ## representation.  cleanup.counting() will still perform the full binary
  ## event and interval validation used by the canonical RHF path.
  attr(internal.data, "event.process") <- "terminal"
  ## Resolve '.' against the original formula and data before replacing the
  ## response.  This prevents the original time and event columns from entering
  ## the predictor set merely because the internal response uses new names.
  formula.terms <- tryCatch(
    stats::terms(f, data = data),
    error = function(e) {
      stop("Unable to process 'formula': ", conditionMessage(e),
           call. = FALSE)
    }
  )
  term.labels <- attr(formula.terms, "term.labels")
  intercept <- attr(formula.terms, "intercept")
  internal.response <- paste0(
    "Surv(",
    paste(unname(internal.names), collapse = ", "),
    ")"
  )
  internal.formula <- stats::reformulate(
    termlabels = term.labels,
    response = internal.response,
    intercept = intercept,
    env = environment(f)
  )
  list(
    formula = internal.formula,
    data = internal.data,
    info = list(
      version = 1L,
      format = "right-censored",
      response.names = response.names,
      internal.names = internal.names,
      n.original = nrow(data)
    )
  )
}
.rhf.prepare.newdata <- function(object, newdata) {
  if (missing(newdata) || is.null(newdata)) {
    stop("Argument 'newdata' must be a non-null data.frame.", call. = FALSE)
  }
  if (!is.data.frame(newdata)) {
    newdata <- as.data.frame(newdata)
  }
  input.info <- object$input.info
  if (is.null(input.info) && !is.null(object$forest)) {
    input.info <- object$forest$input.info
  }
  if (is.null(input.info) &&
      !is.null(object$forest) &&
      !is.null(object$forest$parms)) {
    input.info <- object$forest$parms$input.info
  }
  ## Older RHF objects and forests grown directly from counting-process data
  ## retain the historical newdata contract.
  if (is.null(input.info) ||
      is.null(input.info$format) ||
      identical(input.info$format, "counting")) {
    return(newdata)
  }
  if (!identical(input.info$format, "right-censored")) {
    stop("The fitted RHF object contains an unrecognized input format.",
         call. = FALSE)
  }
  response.names <- input.info$response.names
  internal.names <- input.info$internal.names
  required.response <- c("time", "event")
  required.internal <- c("id", "start", "stop", "event")
  if (!all(required.response %in% names(response.names)) ||
      !all(required.internal %in% names(internal.names))) {
    stop("The fitted RHF object contains incomplete survival-input metadata.",
         call. = FALSE)
  }
  time.name <- unname(response.names[["time"]])
  event.name <- unname(response.names[["event"]])
  has.time <- time.name %in% names(newdata)
  has.event <- event.name %in% names(newdata)
  if (xor(has.time, has.event)) {
    stop(
      "For a forest grown from Surv(time, event), 'newdata' must contain ",
      "both original response variables ('", time.name, "' and '",
      event.name, "') or neither.",
      call. = FALSE
    )
  }
  internal.data <- newdata
  internal.data[[internal.names[["id"]]]] <- seq_len(nrow(internal.data))
  if (has.time && has.event) {
    time <- .rhf.coerce.right.time(
      internal.data[[time.name]],
      what = time.name
    )
    internal.data[[internal.names[["start"]]]] <- rep(0, nrow(internal.data))
    internal.data[[internal.names[["stop"]]]] <- time
    internal.data[[internal.names[["event"]]]] <- internal.data[[event.name]]
    attr(internal.data, "event.process") <- "terminal"
  }
  internal.data
}
## converts a standard survival data set to counting process format
## scale is ignored but kept in place for legacy
convert.counting <- function(f, dta, scale = FALSE) {
  ## coerce formula
  f <- as.formula(f)
  ## extract names
  time.nm  <- all.vars(f)[1]
  event.nm <- all.vars(f)[2]
  ## remove missing values
  dta <- na.omit(dta)
  ## raw time
  time <- as.numeric(dta[[time.nm]])
  if (any(!is.finite(time))) {
    stop("Non-finite time values found.")
  }
  if (any(time < 0, na.rm = TRUE)) {
    stop("time values cannot be negative")
  }
  if (isTRUE(scale)) {
    warning("'scale=TRUE' is deprecated for RHF workflows: rhf() now maps time internally. Returning raw times.")
  }
  data.frame(id = seq_len(nrow(dta)),
             start = 0,
             stop = time,
             event = dta[[event.nm]],
             dta[, !(colnames(dta) %in% all.vars(f)[1:2]), drop = FALSE])
}
## clean up counting process data
cleanup.counting <- function(dta,
                             xvar.names = NULL,
                             yvar.names,
                             subj.names,
                             sorted = FALSE,
                             eps = 1e-6,
                             event.process = c("auto", "terminal", "recurrent")) {
  event.process <- .rhf.match.event.process(event.process)
  stored.event.process <- attr(dta, "event.process", exact = TRUE)
  if (event.process == "auto" && !is.null(stored.event.process)) {
    event.process <- .rhf.match.event.process(stored.event.process)
  }
  if (length(yvar.names) < 3L) {
    stop("Counting-process RHF data must include start, stop, and event variables.",
         call. = FALSE)
  }
  if (length(subj.names) != 1L) {
    stop("Counting-process RHF data must contain exactly one subject identifier.",
         call. = FALSE)
  }
  ## work out candidate x variables
  if (is.null(xvar.names)) {
    xvar.candidate <- setdiff(colnames(dta), c(subj.names, yvar.names))
  } else {
    missing.x <- setdiff(xvar.names, colnames(dta))
    if (length(missing.x) > 0L) {
      stop("The following xvar.names are not columns of 'dta': ",
           paste(missing.x, collapse = ", "))
    }
    xvar.candidate <- setdiff(unique(xvar.names), c(subj.names, yvar.names))
  }
  xvar.all   <- xvar.candidate
  xvar.names <- xvar.candidate
  ## coerce start/stop once, early
  start.nm <- yvar.names[1L]
  stop.nm  <- yvar.names[2L]
  event.nm <- yvar.names[3L]
  for (nm in c(start.nm, stop.nm)) {
    v <- dta[[nm]]
    if (is.factor(v)) {
      v <- as.numeric(as.character(v))
    } else {
      v <- as.numeric(v)
    }
    dta[[nm]] <- v
  }
  startv <- dta[[start.nm]]
  stopv  <- dta[[stop.nm]]
  ## check if time is non-negative (ignoring NAs)
  if (any(startv < 0 | stopv < 0, na.rm = TRUE)) {
    stop("time values cannot be negative")
  }
  ## drop x variables with all missing values
  if (length(xvar.names) > 0L) {
    all.na <- vapply(
      xvar.names,
      function(z) all(is.na(dta[[z]])),
      logical(1L)
    )
    if (any(all.na)) {
      drop.x     <- xvar.names[all.na]
      dta        <- dta[, !(colnames(dta) %in% drop.x), drop = FALSE]
      xvar.names <- xvar.names[!all.na]
      warning("Dropping x variable(s) with all missing values: ",
              paste(drop.x, collapse = ", "))
    }
  }
  ## case-wise deletion of remaining missing data
  cols.to.check <- intersect(c(subj.names, yvar.names, xvar.names),
                             colnames(dta))
  if (length(cols.to.check) == 0L) {
    stop("No variables remain in data after removing predictors with all missing values.")
  }
  cc <- complete.cases(dta[, cols.to.check, drop = FALSE])
  if (!all(cc)) {
    n.rem <- sum(!cc)
    dta   <- dta[cc, , drop = FALSE]
    warning(sprintf("Removing %d row(s) with missing values.", n.rem))
  }
  ## checks after NA cleaning
  if (nrow(dta) == 0L) {
    stop("After processing (including removing missing values) there are no observations left (NULL data set).")
  }
  if (length(xvar.names) == 0L) {
    if (length(xvar.all) == 0L) {
      stop("No x variables were supplied (xvar.names is empty and no extra variables were found).")
    } else {
      stop("After removing missing values there are no x variables left.")
    }
  }
  ## RHF terminal and recurrent event processes both use a binary row increment.
  dta[[event.nm]] <- .rhf.coerce.event.code(
    dta[[event.nm]],
    binary = TRUE,
    what = event.nm
  )
  ## one-pass stable sort by subject encounter-order, then start time.
  ## This preserves the original grouping semantics without the O(n * n_subjects)
  ## cost of lapply(unique(id), which(id == i), ...).
  if (isFALSE(sorted)) {
    id  <- dta[[subj.names]]
    ord <- order(match(id, id), dta[[start.nm]], method = "radix")
    if (!identical(ord, seq_len(nrow(dta)))) {
      dta <- dta[ord, , drop = FALSE]
    }
  }
  ## Remove rows with invalid start--stop intervals before time
  ## transformation.  RHF permits gaps in a subject's supplied path, so an
  ## isolated invalid interval can be removed.  If the row carries an event,
  ## the warning explicitly records that the event is also removed.
  startv <- dta[[start.nm]]
  stopv  <- dta[[stop.nm]]
  eventv <- dta[[event.nm]]
  bad.raw <- !is.finite(startv) | !is.finite(stopv) | (stopv <= startv)
  bad.raw[is.na(bad.raw)] <- TRUE
  if (any(bad.raw)) {
    n.bad <- sum(bad.raw)
    n.bad.event <- sum(eventv[bad.raw] == 1L)
    n.bad.nonevent <- n.bad - n.bad.event
    warning(sprintf(
      paste0(
        "Removing %d row(s) with non-finite or non-positive start--stop length ",
        "(%d event row(s), %d non-event row(s)).%s"
      ),
      n.bad,
      n.bad.event,
      n.bad.nonevent,
      if (n.bad.event > 0L) {
        " Removed event rows will not contribute to the event process."
      } else {
        ""
      }
    ), call. = FALSE)
    dta <- dta[!bad.raw, , drop = FALSE]
  }
  if (nrow(dta) == 0L) {
    stop("After processing there are no valid counting-process intervals left.")
  }
  .rhf.validate.counting.intervals(
    id = dta[[subj.names]],
    start = dta[[start.nm]],
    stop = dta[[stop.nm]],
    eps = eps,
    data.name = "training data"
  )
  ## transform time to [0,1] using modified logit with tau = training max.time
  max.time <- max(dta[[stop.nm]], na.rm = TRUE)
  if (!is.finite(max.time) || max.time <= 0) {
    stop("Invalid max time in training data: max(stop) must be positive and finite.")
  }
  time.map <- list(method   = "mlogit",
                   tau      = as.double(max.time),
                   max.time = as.double(max.time))
  startv <- .forward.time(dta[[start.nm]], time.map)
  stopv  <- .forward.time(dta[[stop.nm]],  time.map)
  eventv <- dta[[event.nm]]
  ## A strictly increasing transformation should preserve start < stop.
  ## Do not impose an epsilon-based minimum interval width on the transformed
  ## scale: every finite interval with stop > start remains valid.
  bad.map <- !is.finite(startv) | !is.finite(stopv) | (stopv <= startv)
  bad.map[is.na(bad.map)] <- TRUE
  if (any(bad.map)) {
    n.bad <- sum(bad.map)
    n.bad.event <- sum(eventv[bad.map] == 1L)
    n.bad.nonevent <- n.bad - n.bad.event
    warning(sprintf(
      paste0(
        "Removing %d row(s) with non-finite or non-positive length after ",
        "time transformation (%d event row(s), %d non-event row(s)).%s"
      ),
      n.bad,
      n.bad.event,
      n.bad.nonevent,
      if (n.bad.event > 0L) {
        " Removed event rows will not contribute to the event process."
      } else {
        ""
      }
    ), call. = FALSE)
    keep <- !bad.map
    dta   <- dta[keep, , drop = FALSE]
    startv <- startv[keep]
    stopv  <- stopv[keep]
  }
  if (nrow(dta) == 0L) {
    stop("After processing there are no valid counting-process intervals left.")
  }
  dta[[start.nm]] <- startv
  dta[[stop.nm]]  <- stopv
  event.info <- .rhf.event.process.info(
    id = dta[[subj.names]],
    event = dta[[event.nm]],
    start = dta[[start.nm]],
    stop = dta[[stop.nm]],
    event.process = event.process,
    binary = TRUE,
    what = event.nm,
    presorted = TRUE
  )
  if (event.info$requested == "terminal" && !event.info$terminal.valid) {
    stop("Terminal-event RHF data may contain at most one event per subject, ",
         "and an event row must be the final row for that subject. ",
         "Use event.process = 'recurrent' for recurrent-event data.",
         call. = FALSE)
  }
  ## store helpful attributes
  attr(dta, "max.time")              <- max.time
  attr(dta, "time.map")              <- time.map
  attr(dta, "xvar.names")            <- xvar.names
  attr(dta, "sorted.by.subj.start")  <- TRUE
  attr(dta, "event.process")         <- event.info$event.process
  attr(dta, "event.process.info")    <- event.info[c(
    "requested", "inferred", "event.process", "terminal.valid",
    "n.subject", "n.event", "n.event.subject",
    "mean.events.per.subject", "max.events.per.subject",
    "events.per.subject.summary"
  )]
  dta
}
## helper to clean and scale new (test) counting-process data for predict.rhf
cleanup.counting.newdata <- function(newdata,
                                     xvar.names,
                                     yvar.names,
                                     subj.names,
                                     time.map,
                                     max.time,
                                     sorted = FALSE,
                                     eps = 1e-6,
                                     nonfinite.action = c("stop", "drop"),
                                     event.process = c("auto", "terminal", "recurrent")) {
  nonfinite.action <- match.arg(nonfinite.action)
  event.process <- .rhf.match.event.process(event.process)
  if (missing(newdata) || is.null(newdata)) {
    stop("Argument 'newdata' must be a non-null data.frame.")
  }
  stored.event.process <- attr(newdata, "event.process", exact = TRUE)
  if (event.process == "auto" && !is.null(stored.event.process)) {
    event.process <- .rhf.match.event.process(stored.event.process)
  }
  cn <- colnames(newdata)
  ## check subject variable present
  missing.subj <- setdiff(subj.names, cn)
  if (length(missing.subj) > 0L) {
    stop("Subject variable(s) not found in 'newdata': ",
         paste(missing.subj, collapse = ", "))
  }
  ## check predictor variables present (must match training forest)
  missing.x <- setdiff(xvar.names, cn)
  if (length(missing.x) > 0L) {
    stop("The following predictor variable(s) used to fit the forest are missing in 'newdata': ",
         paste(missing.x, collapse = ", "))
  }
  ## determine whether y is present in newdata
  y.in <- yvar.names %in% cn
  if (any(y.in) && !all(y.in)) {
    stop("Argument 'yvar.names' must refer to variables that are either all present in 'newdata' or all absent.")
  }
  yvar.present <- all(y.in)
  start.nm <- stop.nm <- event.nm <- NULL
  ## coerce start/stop once, early (if y present)
  if (yvar.present) {
    if (length(yvar.names) < 3L) {
      stop("Counting-process outcomes in 'newdata' must include start, stop, and event variables.",
           call. = FALSE)
    }
    start.nm <- yvar.names[1L]
    stop.nm  <- yvar.names[2L]
    event.nm <- yvar.names[3L]
    for (nm in c(start.nm, stop.nm)) {
      v <- newdata[[nm]]
      if (is.factor(v)) {
        v <- as.numeric(as.character(v))
      } else {
        v <- as.numeric(v)
      }
      newdata[[nm]] <- v
    }
    if (any(newdata[[start.nm]] < 0 | newdata[[stop.nm]] < 0, na.rm = TRUE)) {
      stop("time values in 'newdata' cannot be negative")
    }
    ## retained for legacy/interface sanity checks
    if (length(max.time) != 1L || !is.finite(max.time) || max.time <= 0) {
      stop("Invalid 'max.time' from training data: must be a positive finite scalar.")
    }
  }
  ## case-wise deletion of missing values in id, x, and (if present) y
  cols.to.check <- c(subj.names, xvar.names)
  if (yvar.present) {
    cols.to.check <- c(cols.to.check, yvar.names)
  }
  cols.to.check <- intersect(cols.to.check, cn)
  cc <- complete.cases(newdata[, cols.to.check, drop = FALSE])
  if (!all(cc)) {
    n.drop <- sum(!cc)
    warning(sprintf(
      "Removing %d row(s) from 'newdata' due to missing values in subject, y, or x.",
      n.drop
    ))
  }
  if (!any(cc)) {
    stop("After removing missing values from 'newdata' there are no observations left.")
  }
  dta <- newdata[cc, , drop = FALSE]
  if (yvar.present) {
    dta[[event.nm]] <- .rhf.coerce.event.code(
      dta[[event.nm]],
      binary = TRUE,
      what = event.nm
    )
  }
  ## one-pass stable sort by subject encounter-order, then start time.
  ## If y is absent, group by subject while preserving within-subject order.
  if (isFALSE(sorted)) {
    id <- dta[[subj.names]]
    if (yvar.present) {
      ord <- order(match(id, id), dta[[start.nm]], method = "radix")
    } else {
      ord <- order(match(id, id), seq_len(nrow(dta)), method = "radix")
    }
    if (!identical(ord, seq_len(nrow(dta)))) {
      dta <- dta[ord, , drop = FALSE]
    }
  }
  start.scaled <- stop.scaled <- NULL
  event.process.out <- if (event.process == "auto") NULL else event.process
  if (yvar.present) {
    ## Remove invalid start--stop rows before time transformation.  Finite
    ## non-positive intervals are removed regardless of event status.  The
    ## existing nonfinite.action setting continues to govern non-finite times.
    start.raw <- dta[[start.nm]]
    stop.raw  <- dta[[stop.nm]]
    event.raw <- dta[[event.nm]]
    raw.nonfinite <- !is.finite(start.raw) | !is.finite(stop.raw)
    raw.bad <- raw.nonfinite | (stop.raw <= start.raw)
    raw.nonfinite[is.na(raw.nonfinite)] <- TRUE
    raw.bad[is.na(raw.bad)] <- TRUE
    if (any(raw.nonfinite) && nonfinite.action == "stop") {
      stop(sprintf(
        "Found %d row(s) in 'newdata' with non-finite start/stop values.",
        sum(raw.nonfinite)
      ), call. = FALSE)
    }
    if (any(raw.bad)) {
      n.bad <- sum(raw.bad)
      n.bad.event <- sum(event.raw[raw.bad] == 1L)
      n.bad.nonevent <- n.bad - n.bad.event
      warning(sprintf(
        paste0(
          "Removing %d row(s) from 'newdata' with non-finite or non-positive ",
          "start--stop length (%d event row(s), %d non-event row(s)).%s"
        ),
        n.bad,
        n.bad.event,
        n.bad.nonevent,
        if (n.bad.event > 0L) {
          " Removed event rows will not contribute to the event process."
        } else {
          ""
        }
      ), call. = FALSE)
      dta <- dta[!raw.bad, , drop = FALSE]
    }
    if (nrow(dta) == 0L) {
      stop("After removing invalid/non-positive length intervals from 'newdata' there are no observations left.")
    }
    .rhf.validate.counting.intervals(
      id = dta[[subj.names]],
      start = dta[[start.nm]],
      stop = dta[[stop.nm]],
      eps = eps,
      data.name = "newdata"
    )
    ## transform start/stop outcomes to the internal time scale
    start.scaled <- .forward.time(dta[[start.nm]], time.map)
    stop.scaled  <- .forward.time(dta[[stop.nm]],  time.map)
    event.raw <- dta[[event.nm]]
    ## Coherence check.  Do not use eps as a minimum interval width after
    ## transformation; strict start < stop is the only length requirement.
    nonfinite <- !is.finite(start.scaled) | !is.finite(stop.scaled)
    bad.map <- !is.finite(start.scaled) |
      !is.finite(stop.scaled) |
      (stop.scaled <= start.scaled)
    nonfinite[is.na(nonfinite)] <- TRUE
    bad.map[is.na(bad.map)] <- TRUE
    if (any(nonfinite) && nonfinite.action == "stop") {
      stop(sprintf(
        "Found %d row(s) in 'newdata' with non-finite start/stop after scaling.",
        sum(nonfinite)
      ), call. = FALSE)
    }
    if (any(bad.map)) {
      n.bad <- sum(bad.map)
      n.bad.event <- sum(event.raw[bad.map] == 1L)
      n.bad.nonevent <- n.bad - n.bad.event
      warning(sprintf(
        paste0(
          "Removing %d row(s) from 'newdata' with non-finite or non-positive ",
          "length after time transformation (%d event row(s), %d non-event row(s)).%s"
        ),
        n.bad,
        n.bad.event,
        n.bad.nonevent,
        if (n.bad.event > 0L) {
          " Removed event rows will not contribute to the event process."
        } else {
          ""
        }
      ), call. = FALSE)
      dta <- dta[!bad.map, , drop = FALSE]
      start.scaled <- start.scaled[!bad.map]
      stop.scaled  <- stop.scaled[!bad.map]
    }
    if (nrow(dta) == 0L) {
      stop("After removing invalid/non-positive length intervals from 'newdata' there are no observations left.")
    }
    event.info <- .rhf.event.process.info(
      id = dta[[subj.names]],
      event = dta[[event.nm]],
      start = start.scaled,
      stop = stop.scaled,
      event.process = event.process,
      binary = TRUE,
      what = event.nm,
      presorted = TRUE
    )
    if (event.info$requested == "terminal" && !event.info$terminal.valid) {
      stop("Terminal-event RHF data in 'newdata' may contain at most one event per subject, ",
           "and an event row must be the final row for that subject. ",
           "Use event.process = 'recurrent' for recurrent-event data.",
           call. = FALSE)
    }
    event.process.out <- event.info$event.process
    attr(dta, "event.process") <- event.process.out
  }
  attr(dta, "sorted.by.subj.start") <- isTRUE(yvar.present)
  ## initialise outputs only after final filtering to avoid extra copies
  subj.newdata <- dta[, subj.names]
  xvar.newdata <- dta[, xvar.names, drop = FALSE]
  yvar.newdata <- NULL
  if (yvar.present) {
    ## preserve original coercion behavior for non-time y columns
    yraw <- dta[, yvar.names, drop = FALSE]
    for (nm in yvar.names[1:2]) {
      v <- yraw[[nm]]
      if (is.factor(v)) v <- as.numeric(as.character(v))
      yraw[[nm]] <- as.numeric(v)
    }
    yvar.newdata <- as.matrix(yraw)
    storage.mode(yvar.newdata) <- "double"
    yvar.newdata[, 1L] <- start.scaled
    yvar.newdata[, 2L] <- stop.scaled
  }
  list(
    newdata      = dta,
    subj         = subj.newdata,
    xvar         = xvar.newdata,
    yvar         = yvar.newdata,
    yvar.present = yvar.present,
    event.process = event.process.out
  )
}
get.duplicated <- function(x) {
  c(apply(x, 2, function(xx) {
    1 * !all(xx == xx[1])
  }))
}
get.tdc.cov <- function(dta, subj.names, yvar.names,
                        presorted = isTRUE(attr(dta, "sorted.by.subj.start"))) {
  ## extract covariates
  x <- dta[, !(colnames(dta) %in% c(subj.names, yvar.names)), drop = FALSE]
  p <- ncol(x)
  if (p == 0L) {
    return(numeric(0L))
  }
  id <- dta[, subj.names]
  n  <- length(id)
  if (n <= 1L) {
    out <- rep(0L, p)
    names(out) <- colnames(x)
    return(out)
  }
  if (presorted) {
    ord <- seq_len(n)
    id.ord <- id
  } else {
    ord <- order(id, method = "radix")
    id.ord <- id[ord]
  }
  same <- id.ord[-1L] == id.ord[-n]
  if (!any(same, na.rm = TRUE)) {
    out <- rep(0L, p)
    names(out) <- colnames(x)
    return(out)
  }
  out <- vapply(
    x,
    function(v) {
      v <- v[ord]
      chg <- (v[-1L] != v[-n]) & same
      as.integer(any(chg, na.rm = TRUE))
    },
    integer(1L)
  )
  out
}
get.tdc.subj.time <- function(dta, subj.names, yvar.names,
                              presorted = isTRUE(attr(dta, "sorted.by.subj.start"))) {
  ## extract covariates
  x <- dta[, !(colnames(dta) %in% c(subj.names, yvar.names)), drop = FALSE]
  p <- ncol(x)
  ## preserve original behavior in trivial cases
  if (p == 0L) {
    return(rep(0L, nrow(dta)))
  }
  id <- dta[, subj.names]
  n  <- length(id)
  if (n <= 1L) {
    return(rep(0L, nrow(dta)))
  }
  if (presorted) {
    ord <- seq_len(n)
    id.ord <- id
  } else {
    ord <- order(id, method = "radix")
    id.ord <- id[ord]
  }
  same <- id.ord[-1L] == id.ord[-n]
  if (!any(same, na.rm = TRUE)) {
    return(rep(0L, nrow(dta)))
  }
  cov.tdc <- integer(p)
  names(cov.tdc) <- colnames(x)
  pair.chg <- logical(n - 1L)
  for (j in seq_len(p)) {
    v <- x[[j]][ord]
    chg <- (v[-1L] != v[-n]) & same
    cov.tdc[j] <- as.integer(any(chg, na.rm = TRUE))
    pair.chg <- pair.chg | (!is.na(chg) & chg)
  }
  if (sum(cov.tdc) == 0) {
    return(rep(0L, nrow(dta)))
  }
  pc <- as.integer(pair.chg)
  cs <- c(0L, cumsum(pc))
  rr <- rle(id.ord)
  ends <- cumsum(rr$lengths)
  starts <- ends - rr$lengths + 1L
  subj.has.chg <- (cs[ends] - cs[starts]) > 0L
  if (presorted) {
    out <- as.integer(subj.has.chg)
  } else {
    id.unq <- unique(id)
    by_id <- setNames(as.integer(subj.has.chg), as.character(rr$values))
    out <- unname(by_id[as.character(id.unq)])
  }
  out
}
#########################################################################################
##
## process survival information, set time.interest
##
#########################################################################################
timegrid.min.events <- function(data,
                                stop.col = "stop",
                                event.col = "event",
                                ntime = 50L,
                                min.events.per.gap = 10L,
                                include.first.event = FALSE,
                                merge.tail = TRUE) {
  if (!stop.col %in% names(data))  stop("stop.col not found in data")
  if (!event.col %in% names(data)) stop("event.col not found in data")
  ntime <- as.integer(ntime)
  if (is.na(ntime) || ntime < 0L) stop("ntime must be >= 0")
  min.events.per.gap <- as.integer(min.events.per.gap)
  if (is.na(min.events.per.gap) || min.events.per.gap < 1L) {
    stop("min.events.per.gap must be >= 1")
  }
  # Robust conversion for stop
  stopv <- data[[stop.col]]
  if (is.factor(stopv)) stopv <- as.numeric(as.character(stopv))
  stopv <- as.numeric(stopv)
  evv <- data[[event.col]]
  evv <- as.integer(!is.na(evv) & evv != 0L)
  ev_time <- stopv[evv == 1L]
  ev_time <- ev_time[is.finite(ev_time) & ev_time > 0]
  if (!length(ev_time)) stop("No positive event times found.")
  # Unique event times + event counts at each time
  ut <- sort(unique(ev_time))
  counts <- tabulate(match(ev_time, ut), nbins = length(ut))
  n_events <- sum(counts)
  # If ntime is 0: all unique event times
  if (is.null(ntime) || ntime == 0L) {
    grid <- ut
    attr(grid, "n_events") <- n_events
    attr(grid, "n_unique_event_times") <- length(ut)
    attr(grid, "min.events.per.gap_eff") <- NA_integer_
    return(grid)
  }
  # Effective events per gap combines both controls:
  # - never < min.events.per.gap
  # - tends to produce ~ntime grid points when possible
  m_eff <- max(min.events.per.gap, as.integer(ceiling(n_events / ntime)))
  m_eff <- max(1L, min(m_eff, n_events))
  grid_idx <- integer(0)
  acc <- 0L
  for (k in seq_along(ut)) {
    acc <- acc + counts[k]
    if (acc >= m_eff) {
      grid_idx <- c(grid_idx, k)
      acc <- 0L
    }
  }
  tmax <- ut[length(ut)]
  if (!length(grid_idx)) {
    grid <- tmax
  } else {
    grid <- ut[grid_idx]
    if (tail(grid, 1) < tmax) {
      if (merge.tail && acc > 0L && acc < m_eff) {
        grid[length(grid)] <- tmax
      } else {
        grid <- c(grid, tmax)
      }
    }
  }
  if (include.first.event) grid <- c(ut[1L], grid)
  grid <- sort(unique(grid))
  ## do not attach attributes, native code does not like that 
  #attr(grid, "n_events") <- n_events
  #attr(grid, "n_unique_event_times") <- length(ut)
  #attr(grid, "min.events.per.gap_eff") <- m_eff
  grid
}
get.grow.event.info <- function(yvar,
                                fmly,
                                need.deaths = TRUE,
                                ntime,
                                min.events.per.gap,
                                subj = NULL,
                                event.process = c("auto", "terminal", "recurrent"),
                                process.info = NULL) {
  event.process <- .rhf.match.event.process(event.process)
  event <- event.type <- cens <- time.interest <- time <- start.time <- NULL
  r.dim <- NULL
  event.process.out <- NULL
  n.event <- n.event.subject <- n.subject <- n.unique.event.time <- NULL
  mean.events.per.subject <- max.events.per.subject <- NULL
  events.per.subject.summary <- NULL
  if (grepl("surv", fmly)) {
    if (dim(yvar)[2] == 2) {
      ##---------------------------------
      ## survival or competing risks:
      ##---------------------------------
      r.dim <- 2
      time <- yvar[, 1]
      cens <- yvar[, 2]
      start.time <- NULL
      ## censoring must be coded coherently
      if (!all(floor(cens) == abs(cens), na.rm = TRUE)) {
        stop("for survival families censoring variable must be coded as a non-negative integer (perhaps the formula is set incorrectly?)")
      }
      ## check if events are available (if user specified)
      if (need.deaths && (all(na.omit(cens) == 0))) {
        stop("no events in data!")
      }
      ## Extract the unique event types.
      event.type <- unique(na.omit(cens))
      if (sum(event.type >= 0) != length(event.type)) {
        stop("censoring variable must be coded as NA, 0, or greater than 0.")
      }
      ## Discard the censored state, if it exists.
      event <- na.omit(cens)[na.omit(cens) > 0]
      event.type <- unique(event)
      ## Set grid of time points.
      nonMissingOutcome <- which(!is.na(cens) & !is.na(time))
      nonMissingDeathFlag <- (cens[nonMissingOutcome] != 0)
      time.interest <- sort(unique(time[nonMissingOutcome[nonMissingDeathFlag]]))
      ## trim the time points if the user has requested it
      ## we also allow the user to pass requested time points
      if (!is.null(ntime) && length(ntime) == 1 && ntime < 0) {
        ntime <- 0
      }
      if (!is.null(ntime) && !((length(ntime) == 1) && ntime == 0)) {
        if (length(ntime) == 1 && length(time.interest) > ntime) {
          time.interest <- time.interest[
            seq(1, length(time.interest), length = ntime)]
        }
        if (length(ntime) > 1) {
          time.interest <- unique(sapply(ntime, function(tt) {
            time.interest[max(1, sum(tt >= time.interest, na.rm = TRUE))]
          }))
        }
      }
      ## A two-column response is a terminal-event representation.
      event.process.out <- "terminal"
      event.indicator <- as.integer(!is.na(cens) & cens != 0)
      n.event <- sum(event.indicator)
      n.event.subject <- n.event
      n.subject <- length(cens)
      n.unique.event.time <- length(unique(time[!is.na(time) & event.indicator == 1L]))
      mean.events.per.subject <- if (n.subject > 0L) n.event / n.subject else NA_real_
      max.events.per.subject <- if (n.subject > 0L) max(event.indicator) else NA_integer_
      if (n.subject > 0L) {
        q <- stats::quantile(event.indicator,
                             probs = c(0, 0.25, 0.50, 0.75, 1),
                             names = FALSE,
                             type = 1)
        events.per.subject.summary <- c(
          min = q[1L], q1 = q[2L], median = q[3L],
          mean = mean(event.indicator), q3 = q[4L], max = q[5L]
        )
      }
    } else {
      ##-------------------------------
      ## time dependent covariates:
      ##-------------------------------
      r.dim <- 3
      start.time <- yvar[, 1]
      time <- yvar[, 2]
      cens <- .rhf.coerce.event.code(
        yvar[, 3],
        binary = TRUE,
        what = "event"
      )
      ## check if events are available (if user specified)
      if (need.deaths && all(cens == 0L)) {
        stop("no events in data!")
      }
      ## Check for event time consistency.
      if (!all(na.omit(time) >= 0)) {
        stop("time must be positive")
      }
      ## The recurrent extension has one nonzero event type, coded 1.
      event <- cens[cens > 0L]
      event.type <- unique(event)
      if (!is.null(process.info)) {
        required.process.fields <- c(
          "event.process", "n.event", "n.event.subject", "n.subject",
          "mean.events.per.subject", "max.events.per.subject",
          "events.per.subject.summary"
        )
        missing.process.fields <- setdiff(required.process.fields, names(process.info))
        if (length(missing.process.fields)) {
          stop("The supplied event-process summary is incomplete: ",
               paste(missing.process.fields, collapse = ", "),
               call. = FALSE)
        }
      } else if (!is.null(subj)) {
        if (length(subj) != length(cens)) {
          stop("The subject vector and counting-process response have incompatible lengths.",
               call. = FALSE)
        }
        process.info <- .rhf.event.process.info(
          id = subj,
          event = cens,
          start = start.time,
          stop = time,
          event.process = event.process,
          binary = TRUE,
          what = "event"
        )
        if (process.info$requested == "terminal" && !process.info$terminal.valid) {
          stop("Terminal-event RHF data may contain at most one event per subject, ",
               "and an event row must be the final row for that subject. ",
               "Use event.process = 'recurrent' for recurrent-event data.",
               call. = FALSE)
        }
      }
      if (!is.null(process.info)) {
        event.process.out <- process.info$event.process
        n.event <- process.info$n.event
        n.event.subject <- process.info$n.event.subject
        n.subject <- process.info$n.subject
        mean.events.per.subject <- process.info$mean.events.per.subject
        max.events.per.subject <- process.info$max.events.per.subject
        events.per.subject.summary <- process.info$events.per.subject.summary
      } else {
        ## Subject-level summaries require the row-to-subject map.  Existing
        ## callers without this map retain terminal behavior unless recurrent
        ## mode was explicitly requested.
        event.process.out <- if (event.process == "recurrent") "recurrent" else "terminal"
        n.event <- sum(cens != 0L)
        n.event.subject <- NA_integer_
        n.subject <- NA_integer_
        mean.events.per.subject <- NA_real_
        max.events.per.subject <- NA_integer_
        events.per.subject.summary <- NULL
      }
      n.unique.event.time <- length(unique(time[cens != 0L]))
      ## Set grid of time points.
      nonMissingOutcome <- which(!is.na(cens) & !is.na(time))
      nonMissingDeathFlag <- (cens[nonMissingOutcome] != 0)
      time.interest <- sort(unique(time[nonMissingOutcome[nonMissingDeathFlag]]))
      ## trim the time points if the user has requested it
      ## we also allow the user to pass requested time points
      if (!is.null(ntime) && length(ntime) == 1 && ntime < 0) {
        ntime <- 0
      }
      if (!is.null(ntime) && !((length(ntime) == 1) && ntime == 0)) {
        if (length(ntime) == 1) {
          time.interest <- timegrid.min.events(
            data.frame(stop = time, event = cens),
            ntime = ntime,
            min.events.per.gap = min.events.per.gap
          )
        } else {
          time.interest <- unique(sapply(ntime, function(tt) {
            time.interest[max(1, sum(tt >= time.interest, na.rm = TRUE))]
          }))
        }
      }
    }
  } else {
    ##---------------------
    ## other families
    ##---------------------
    if ((fmly == "regr+") | (fmly == "class+") | (fmly == "mix+")) {
      r.dim <- dim(yvar)[2]
    } else {
      if (fmly == "unsupv") {
        r.dim <- 0
      } else {
        r.dim <- 1
      }
    }
  }
  return(list(
    event = event,
    event.type = event.type,
    cens = cens,
    time.interest = time.interest,
    time = time,
    start.time = start.time,
    r.dim = r.dim,
    event.process = event.process.out,
    n.event = n.event,
    n.event.subject = n.event.subject,
    n.subject = n.subject,
    n.unique.event.time = n.unique.event.time,
    mean.events.per.subject = mean.events.per.subject,
    max.events.per.subject = max.events.per.subject,
    events.per.subject.summary = events.per.subject.summary
  ))
}
####################################################################
##
## TDC Helper Functions for hazards
## - only coherent for single or time static trees
##
####################################################################
hazard.to.chf <- function(o, max.time = 1) {
  tme.delta <- diff(c(0, o$time.interest))
  hz <- if (!is.null(o$hazard.oob)) o$hazard.oob else o$hazard
  t(apply(hz, 1, function(h) cumsum(h * tme.delta)))
}
#########################################################################################
##
## convert.standard.counting()
##
## Collapse counting-process (start/stop) data to a single-row-per-ID dataset.
##
## Original purpose:
##   - Quickly convert counting-process survival data to a standard survival
##     data set using a baseline snapshot of covariates.
##
## Extension (landmarking):
##   - Provide a landmark snapshot at a user-specified time (landmark.time)
##     using the covariate row whose [start, stop) interval contains t0^-.
##   - Optionally return the row index used for the snapshot (row_index)
##     which is useful for extracting record-level predictions (e.g., CHF)
##     from survival forests fit on the long (record-level) data.
##
## Notes:
##   - The function supports a "pseudo" Surv() with an ID argument:
##       Surv(id, start, stop, event)
##     as well as the standard counting-process Surv():
##       Surv(start, stop, event)
##     In the latter case, id.default is used.
##   - landmark.time is assumed to be on the *same scale* as the start/stop
##     columns in `data`.
##
#########################################################################################
convert.standard.counting <- function(formula, data,
                                      scale             = FALSE,
                                      rescale.from.attr = FALSE,
                                      keep.id           = FALSE,
                                      keep.row_index    = FALSE,
                                      sorted            = FALSE,
                                      id.default        = "id",
                                      eps               = 1e-8,
                                      landmark.time     = NULL,
                                      landmark.use.tminus = TRUE,
                                      return.type       = c("survival", "x"),
                                      keep.landmark.cols = FALSE) {
  return.type <- match.arg(return.type)
  ## ---- parse Surv(...) on LHS ----
  f   <- as.formula(formula)
  lhs <- f[[2]]
  if (!is.call(lhs) || !identical(as.character(lhs[[1]]), "Surv")) {
    stop("Left-hand side of formula must be a Surv(...) call.")
  }
  getnm <- function(z) paste(deparse(z), collapse = "")
  L <- as.list(lhs)[-1]  # drop 'Surv'
  if (length(L) == 4L) {
    ## Surv(id, start, stop, event)
    subj.nm  <- getnm(L[[1]])
    start.nm <- getnm(L[[2]])
    stop.nm  <- getnm(L[[3]])
    event.nm <- getnm(L[[4]])
  } else if (length(L) == 3L) {
    ## Surv(start, stop, event) -> use default id column
    subj.nm  <- id.default
    start.nm <- getnm(L[[1]])
    stop.nm  <- getnm(L[[2]])
    event.nm <- getnm(L[[3]])
  } else {
    stop("Expecting Surv(id, start, stop, event) or Surv(start, stop, event).")
  }
  ## required columns
  req  <- c(subj.nm, start.nm, stop.nm, event.nm)
  miss <- setdiff(req, names(data))
  if (length(miss)) {
    stop("Missing required columns in data: ", paste(miss, collapse = ", "))
  }
  id         <- data[[subj.nm]]
  start.time <- data[[start.nm]]
  stop.time  <- data[[stop.nm]]
  event.val  <- data[[event.nm]]
  if (any(!is.finite(start.time) | !is.finite(stop.time))) {
    stop("Non-finite start/stop values found.")
  }
  if (any(stop.time < start.time - eps, na.rm = TRUE)) {
    stop("Found rows with stop < start beyond tolerance.")
  }
  ## Optional: rescale start/stop times (and landmark.time) using attr(data, 'max.time')
  ## This is mainly useful if start/stop were stored on [0,1] and you want
  ## to work in original units.
  if (isTRUE(rescale.from.attr)) {
    tm <- attr(data, "time.map")
    if (!is.null(tm)) {
      start.time <- .inverse.time(start.time, tm)
      stop.time  <- .inverse.time(stop.time,  tm)
      if (!is.null(landmark.time)) {
        landmark.time <- .inverse.time(landmark.time, tm)
      }
    } else {
      mt <- attr(data, "max.time")
      if (!is.null(mt) && is.finite(mt) && mt > 0) {
        start.time <- start.time * mt
        stop.time  <- stop.time  * mt
        if (!is.null(landmark.time)) {
          landmark.time <- landmark.time * mt
        }
      }
    }
  }
  ## Original code silently drops NA ids because which(id == NA) returns integer(0).
  ## Preserve that behavior, but do it up front to avoid carrying empty groups around.
  valid.id <- !is.na(id)
  if (!any(valid.id)) {
    return(data.frame())
  }
  if (!all(valid.id)) {
    row.map    <- which(valid.id)
    id         <- id[valid.id]
    start.time <- start.time[valid.id]
    stop.time  <- stop.time[valid.id]
    event.val  <- event.val[valid.id]
  } else {
    row.map <- seq_along(id)
  }
  ## Collapsing to a one-row survival outcome is not defined for a recurrent
  ## event process.  Covariate-only snapshots remain available through
  ## return.type = "x".
  declared.event.process <- attr(data, "event.process", exact = TRUE)
  if (is.null(declared.event.process)) {
    declared.event.process <- "auto"
  }
  declared.event.process <- .rhf.match.event.process(declared.event.process)
  process.info <- .rhf.event.process.info(
    id = id,
    event = as.integer(!is.na(event.val) & event.val != 0),
    start = start.time,
    stop = stop.time,
    event.process = declared.event.process,
    binary = TRUE,
    what = event.nm
  )
  recurrent.data <- identical(process.info$event.process, "recurrent") ||
                    !isTRUE(process.info$terminal.valid)
  if (return.type == "survival" && recurrent.data) {
    stop("convert.standard.counting(..., return.type = 'survival') is not defined ",
         "for recurrent-event data because collapsing to one row per subject ",
         "would discard recurrent event times. Use return.type = 'x' for a ",
         "covariate snapshot, or define an explicit single-event target before conversion.",
         call. = FALSE)
  }
  n <- length(id)
  x.cols <- setdiff(names(data), req)
  ## One-pass grouping strategy:
  ## - preserve subject encounter order via match(id, id)
  ## - if sorted=FALSE, sort within subject by (start, stop)
  ## - if sorted=TRUE, preserve original within-subject row order
  presorted <- isTRUE(attr(data, "sorted.by.subj.start"))
  grp <- match(id, id)
  if (sorted && presorted) {
    ord <- seq_len(n)
  } else if (sorted) {
    ord <- order(grp, seq_len(n), method = "radix")
  } else {
    ord <- order(grp, start.time, stop.time, method = "radix")
  }
  id.ord    <- id[ord]
  start.ord <- start.time[ord]
  stop.ord  <- stop.time[ord]
  event.ord <- event.val[ord]
  row.ord   <- row.map[ord]
  rr <- rle(id.ord)
  uid.ord <- rr$values
  ends   <- cumsum(rr$lengths)
  starts <- ends - rr$lengths + 1L
  n.id   <- length(uid.ord)
  keep.vec <- rep(TRUE, n.id)
  time.vec <- numeric(n.id)
  event.vec <- integer(n.id)
  base.row <- integer(n.id)
  if (!is.null(landmark.time)) {
    t0 <- as.numeric(landmark.time)
    if (!is.finite(t0)) {
      stop("landmark.time must be finite.")
    }
    t.eff <- if (isTRUE(landmark.use.tminus)) (t0 - eps) else t0
    if (isTRUE(keep.landmark.cols)) {
      landmark.time.vec <- rep(NA_real_, n.id)
      t.end.vec         <- rep(NA_real_, n.id)
      t.end.event.vec   <- rep(NA_real_, n.id)
    }
  } else {
    t0 <- NULL
  }
  ## Scan each subject exactly once using group boundaries.
  for (ii in seq_len(n.id)) {
    s <- starts[ii]
    e <- ends[ii]
    start.slice <- start.ord[s:e]
    stop.slice  <- stop.ord[s:e]
    ## end of follow-up for this id
    t.end <- max(stop.slice, na.rm = TRUE)
    ## last row at end time (used for event indicator)
    last.local <- tail(which(stop.slice >= t.end - eps), 1L)
    last.idx   <- s + last.local - 1L
    event.end  <- as.integer(event.ord[last.idx] > 0)
    ## default: baseline snapshot row
    base.local <- 1L
    time.i     <- t.end
    event.i    <- event.end
    if (!is.null(t0)) {
      ## exclude those not at risk at landmark
      if (t.end <= t0 + eps) {
        keep.vec[ii] <- FALSE
        next
      }
      ## find interval containing t_eff: start <= t_eff < stop
      cand <- which(start.slice <= t.eff & stop.slice > t.eff)
      if (length(cand)) {
        ## if multiple, take the one with largest start
        base.local <- cand[which.max(start.slice[cand])]
      } else {
        ## fallback: last row with stop <= t0 (if exists), else first row
        cand2 <- which(stop.slice <= t0 + eps)
        if (length(cand2)) {
          base.local <- cand2[which.max(stop.slice[cand2])]
        } else {
          base.local <- 1L
        }
      }
      ## define outcome relative to landmark (standard landmarking)
      time.i  <- t.end - t0
      event.i <- as.integer(event.end == 1L && t.end > t0 + eps)
      if (isTRUE(keep.landmark.cols)) {
        landmark.time.vec[ii] <- t0
        t.end.vec[ii]         <- t.end
        t.end.event.vec[ii]   <- if (isTRUE(event.end == 1L)) t.end else NA_real_
      }
    }
    base.row[ii]  <- row.ord[s + base.local - 1L]
    time.vec[ii]  <- time.i
    event.vec[ii] <- event.i
  }
  uid.keep   <- uid.ord[keep.vec]
  base.row   <- base.row[keep.vec]
  time.vec   <- time.vec[keep.vec]
  event.vec  <- event.vec[keep.vec]
  if (!length(time.vec)) {
    return(data.frame())
  }
  if (!is.null(t0) && isTRUE(keep.landmark.cols)) {
    landmark.time.vec <- landmark.time.vec[keep.vec]
    t.end.vec         <- t.end.vec[keep.vec]
    t.end.event.vec   <- t.end.event.vec[keep.vec]
  }
  if (isTRUE(scale)) {
    mx <- max(time.vec, na.rm = TRUE)
    if (is.finite(mx) && mx > 0) {
      time.vec <- time.vec / mx
    }
  }
  out <- NULL
  if (return.type == "survival") {
    out <- data.frame(time = time.vec, event = event.vec, check.names = FALSE)
  }
  ## bind covariates with one direct subset instead of per-id pieces + rbind
  if (length(x.cols)) {
    cov.rows <- data[base.row, x.cols, drop = FALSE]
    rownames(cov.rows) <- NULL
    if (is.null(out)) {
      out <- data.frame(cov.rows, check.names = FALSE)
    } else {
      out <- data.frame(out, cov.rows, check.names = FALSE)
    }
  } else {
    if (is.null(out)) {
      out <- data.frame(check.names = FALSE)
    }
  }
  ## optional helper columns
  if (isTRUE(keep.row_index)) {
    out <- data.frame(row_index = base.row, out, check.names = FALSE)
  }
  if (!is.null(t0) && isTRUE(keep.landmark.cols)) {
    out <- data.frame(landmark_time = landmark.time.vec,
                      t_end = t.end.vec,
                      t_end_event = t.end.event.vec,
                      out,
                      check.names = FALSE)
  }
  if (isTRUE(keep.id)) {
    id.df <- setNames(data.frame(uid.keep, check.names = FALSE), subj.nm)
    out   <- data.frame(id.df, out, check.names = FALSE)
  }
  out
}
