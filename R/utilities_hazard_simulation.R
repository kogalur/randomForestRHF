###################################################################
### Hazard simulation machinery 
###################################################################
RHF_SIMULATION_UTILITY_VERSION <- "2026-07-04-sim2b-sim3wide"
####################################################################
## basic theory
## given for t, but applies for x-variables by conditioning on x
##
## relationship between F and CHF
## F(t) = 1 - exp(-H(t))
##
## probability integral transform
## Y           ~  F
## F(Y)        ~  U[0,1]
## 1 - F(Y)    ~  U[0,1]
## exp(-H(T))  ~  U[0,1]
## H(T)        ~  -log(U[0,1])
## T           ~  H^{-1}(-log{U[0,1]})
##
## illustration for Cox PH model
## h(t|x) = h_0(t) exp(b x)
## H(t|x) = H_0(t) exp(b x)
## T|x ~ H_0^{-1}(-log{U[0,1]} * exp(-b x))
##
## time scaling convention (used below)
## Let t* = s * t be scaled time with scale factor s.
## Then h*(t*) = h(t* / s) / s and H*(t*) = H(t* / s).
## Our code applies this consistently when scale != 1.
####################################################################
hazard.simulation <- function(type = 1,
                              n = 500, p = 10, nrecords = 7,
                              scale = FALSE, ngrid = 1e5, ...) {
  ## Allow numeric or character type specification
  hazard.types <- c("hazard.1", "hazard.2", "hazard.3")
  if (is.numeric(type)) {
    if (type < 1 || type > length(hazard.types)) {
      stop("Invalid numeric type. Must be 1, 2, or 3.")
    }
    type <- hazard.types[type]
  } else {
    type <- match.arg(type, choices = hazard.types)
  }
  ## Dispatch to selected hazard function
  sim_data <- switch(type,
    hazard.1 = hazard.1(n = n, p = p, nrecords = nrecords, scale = scale, ngrid = ngrid, ...),
    hazard.2 = hazard.2b(n = n, p = p, nrecords = nrecords, scale = scale, ...),
    hazard.3 = hazard.3b(n = n, p = p, nrecords = nrecords, scale = scale, region.preset = "wide", ...)
  )
  sim_data
}
####################################################################
## SIMULATION 1
##
## h(t|x) = (1 + z_2 * t) * exp(z_1 + z_2 * t)
## where z_1 = 1.5 * x_1,  z_2 = 1.5 * (x_4 + x_5)
##
## integration by parts gives
## H(t|x) = t * exp(z_1 + z_2 * t)
##
## write z2(t) = z_2 * t = 1.5 * x_4(t) + 1.5 * x_5(t)
## where x_4(t) = x_4 * t, x_5(t) = x_5 * t
##
## p = dimension
## nrecords = number of records (nr) per case: 1 + Bin(nr - 1, 0.7)
## scale:
##   FALSE -> no scaling
##   TRUE  -> scale times to [0,1] by dividing by max(stop)
##   numeric s -> multiply times by s (e.g., s=365 to map to days)
## ngrid kept for backward compatibility (not used by new inversion)
####################################################################
hazard.1 <- function(n = 500, p = 10, nrecords = 7, scale = FALSE, ngrid = 1e5) {
  ## static covariates
  p <- max(5, p)
  x <- matrix(runif(n * p), n)
  ## numerical inversion for CHF using uniroot with automatic bracketing
  ## Solve t * exp(Z1 + Z2 * t) = -log(U)
  invert.H <- function(Z1, Z2, U, upper = 100) {
    rhs <- -log(U)
    if (Z2 == 0) return(rhs * exp(-Z1))          # closed form when Z2=0
    f   <- function(t) t * exp(Z1 + Z2 * t) - rhs
    ub  <- upper
    ## expand upper bound until f(ub) >= 0 (monotone increasing)
    while (f(ub) < 0) ub <- ub * 2
    stats::uniroot(f, c(0, ub), tol = 1e-10)$root
  }
  ## simulate number of records per case
  if (nrecords > 1) {
    id.nrecords <- 1 + rbinom(n, size = (nrecords - 1), prob = .7)
  } else {
    id.nrecords <- rep(1, n)
  }
  ## build up the data, one case at a time
  dta <- do.call(rbind, lapply(seq_len(n), function(i) {
    ## simulate the event and censoring time 
    x4 <- x[i, 4]
    x5 <- x[i, 5]
    z1 <- 1.5 * x[i, 1]
    z2 <- 1.5 * (x4 + x5)
    Tm <- invert.H(z1, z2, runif(1))
    Ce <- -1.5 * log(runif(1))
    ## observed time 
    observed.time <- pmin(Tm, Ce)
    ## time dependent covariates
    ## sample random points between 0 and the observed time
    tseq <- c(sort(runif(id.nrecords[i] - 1, 0, observed.time)), observed.time)
    xtd  <- (x4 + x5) * tseq
    ## start and stop times
    start <- c(0, head(tseq, -1))
    stop  <- tseq
    ## event occurrence flags per interval
    event <- 1L * ((Tm <= Ce) & Tm <= stop)
    ## assemble the data for the case
    dta.i <- data.frame(id = i,
                        start = start,
                        stop  = stop,
                        event = event,
                        xtd   = xtd)
    data.frame(dta.i, x = do.call(cbind, lapply(x[i, ], function(xx) rep(xx, id.nrecords[i]))))
  }))
  ## compute scale factor s:
  ## FALSE -> 1, TRUE -> 1 / max(stop), numeric -> that numeric
  s <- if (isTRUE(scale)) {
    1 / max(dta$stop)
  } else if (isFALSE(scale)) {
    1
  } else if (is.numeric(scale) && length(scale) == 1L) {
    as.numeric(scale)
  } else {
    1
  }
  dta$start <- s * dta$start
  dta$stop  <- s * dta$stop
  ## true hazard for data (ID-aligned; accounts for time scaling)
  haz <- function(time, x) {
    ids  <- x[, "id"]
    ## original-time evaluation point for theory-based hazard
    time <- sort(time)
    t0   <- time / s                         # map scaled time back to original
    X    <- x[match(unique(ids), ids), grepl("^x\\.", names(x)), drop = FALSE]
    out  <- do.call(rbind, lapply(seq_len(nrow(X)), function(i) {
      x4 <- X[i, 4]; x5 <- X[i, 5]
      z1 <- 1.5 * X[i, 1]
      z2 <- 1.5 * (x4 + x5)
      h0 <- (1 + z2 * t0) * exp(z1 + z2 * t0)  # hazard in original time
      h0 / s                                   # transform to scaled-time hazard
    }))
    rownames(out) <- as.character(unique(ids))
    out
  }
  list(dta = dta, haz = haz, scale = s)
}
####################################################################
## SIMULATION 2 
##
## if x_1 <= .5 & x_2<=.5:
## h(t|x) = 0 if 0.5 <= t <= 2.5 else h(t|x) = exp(.2 * x_2)
## i.e. H(t|x)= H_0(t) * g1(x), where g_1(x) = exp(.2 * x_2)
##
## H_0(t) = t                      for 0<t<0.5
## H_0(t) = .5                     for 0.5<=t<=2.5
## H_0(t) = t - 2                  for 2.5<t
##
## otherwise if x_1 and x_2 are not as above: 
## h(t|x) = 0 if 2.5 <= t <= 4.5 else h(t|x) = exp(.2 * x_3 + x_4(t))
## where x_4(t) is the time dependent covariate
##
## x_4(t) = x_4 * log(t), x_4 is a 0/1 binary variable
##
## i.e. if  t < 2.5 or  t > 4.5
## h(t|x) = t ^ (x_4) * exp(.2 * x_3)
##
## So H(t|x) = H_0(t) * g2(x), g2(x) = exp(.2 * x_3)
##
## thus if x_4 = 0:
## H_0(t) = t                      for 0<t<2.5
## H_0(t) = 2.5                    for 2.5<=t<=4.5
## H_0(t) = t - 2                  for 4.5<t
## 
## thus if x_4 = 1:
## H_0(t) = 0.5 * t^2                                for 0<t<2.5
## H_0(t) = 3.125                                    for 2.5<=t<=4.5
## H_0(t) = 0.5 t^2 - 7                               for 4.5<t
####################################################################
##################################################################
## 
## modified simulation 2b
## made more challenging by hidden longitudinal signal
## simulation 2 now deprecated
## 
###################################################################
hazard.2b <- function(n = 500, p = 10, nrecords = 7, scale = FALSE,
                      gamma = 1.1, threshold = 0,
                      a.sd = 0.8, b.sd = 0.45) {
  p <- max(4, p)
  x <- matrix(runif(n * p), n)
  a <- rnorm(n, 0, a.sd)
  b <- rnorm(n, 0, b.sd)
  a <- pmax(pmin(a, 4 * a.sd), -4 * a.sd)
  b <- pmax(pmin(b, 4 * b.sd), -4 * b.sd)
  names(a) <- names(b) <- as.character(seq_len(n))
  if (nrecords > 1) {
    id.nrecords <- 1 + rbinom(n, size = nrecords - 1, prob = 0.7)
  } else {
    id.nrecords <- rep(1, n)
  }
  len.pos <- function(lo, hi, ai, bi) {
    if (!is.finite(lo) || !is.finite(hi) || hi <= lo) return(0)
    if (abs(bi) < 1e-12) return(if (ai > threshold) hi - lo else 0)
    cross <- (threshold - ai) / bi
    if (bi > 0) max(0, hi - max(lo, cross)) else max(0, min(hi, cross) - lo)
  }
  active.len <- function(t, z0, z1) {
    if (t <= 0) return(0)
    max(0, min(t, z0)) + max(0, t - z1)
  }
  active.pos.len <- function(t, ai, bi, z0, z1) {
    if (t <= 0) return(0)
    len.pos(0, min(t, z0), ai, bi) + if (t > z1) len.pos(z1, t, ai, bi) else 0
  }
  H_i <- function(t, xi, ai, bi) {
    if (t <= 0) return(0)
    x.pt <- xi[1] <= 0.5 && xi[2] <= 0.5
    if (x.pt) {
      H0 <- if (t < 0.5) t else if (t <= 2.5) 0.5 else t - 2.0
      return(H0 * exp(0.2 * xi[2]))
    }
    active <- active.len(t, 2.5, 4.5)
    high <- active.pos.len(t, ai, bi, 2.5, 4.5)
    low <- active - high
    exp(0.2 * xi[3]) * (low + exp(gamma) * high)
  }
  h_i <- function(t, xi, ai, bi) {
    x.pt <- xi[1] <= 0.5 && xi[2] <= 0.5
    if (x.pt) {
      if (0.5 <= t && t <= 2.5) 0 else exp(0.2 * xi[2])
    } else {
      if (2.5 <= t && t <= 4.5) 0 else exp(0.2 * xi[3] + gamma * ((ai + bi * t) > threshold))
    }
  }
  dta <- do.call(rbind, lapply(seq_len(n), function(i) {
    xi <- x[i, ]
    target <- -log(runif(1))
    ub <- 8
    while (H_i(ub, xi, a[i], b[i]) < target) ub <- 2 * ub
    Tm <- uniroot(function(t) H_i(t, xi, a[i], b[i]) - target,
                  interval = c(0, ub), tol = 1e-9)$root
    Ce <- -5.5 * log(runif(1))
    observed.time <- pmin(Tm, Ce)
    nrec <- id.nrecords[i]
    if (nrec > 1) {
      tseq <- c(sort(runif(nrec - 1, 0, observed.time)), observed.time)
    } else {
      tseq <- observed.time
    }
    start <- c(0, head(tseq, -1))
    stop <- tseq
    event <- as.integer((Tm <= Ce) & Tm <= stop)
    xtd <- a[i] + b[i] * stop
    dta.i <- data.frame(id = i, start = start, stop = stop,
                        event = event, xtd = xtd)
    data.frame(dta.i, x = do.call(cbind, lapply(x[i, ], function(xx) rep(xx, nrec))))
  }))
  s <- if (isTRUE(scale)) {
    1 / max(dta$stop)
  } else if (isFALSE(scale)) {
    1
  } else if (is.numeric(scale) && length(scale) == 1L) {
    as.numeric(scale)
  } else {
    1
  }
  dta$start <- s * dta$start
  dta$stop <- s * dta$stop
  truth <- data.frame(id = seq_len(n), a = as.numeric(a), b = as.numeric(b))
  haz <- function(time, x) {
    ids <- as.character(x[, "id"])
    id.unq <- unique(ids)
    X <- as.matrix(x[match(id.unq, ids), grepl("^x\\.", names(x)), drop = FALSE])
    t0 <- as.numeric(time) / s
    out <- matrix(NA_real_, nrow = length(id.unq), ncol = length(t0),
                  dimnames = list(id.unq, NULL))
    for (ii in seq_along(id.unq)) {
      ai <- a[id.unq[ii]]
      bi <- b[id.unq[ii]]
      out[ii, ] <- vapply(t0, h_i, numeric(1), xi = X[ii, ], ai = ai, bi = bi) / s
    }
    out
  }
  chf <- function(time, x) {
    ids <- as.character(x[, "id"])
    id.unq <- unique(ids)
    X <- as.matrix(x[match(id.unq, ids), grepl("^x\\.", names(x)), drop = FALSE])
    t0 <- as.numeric(time) / s
    out <- matrix(NA_real_, nrow = length(id.unq), ncol = length(t0),
                  dimnames = list(id.unq, NULL))
    for (ii in seq_along(id.unq)) {
      ai <- a[id.unq[ii]]
      bi <- b[id.unq[ii]]
      out[ii, ] <- vapply(t0, H_i, numeric(1), xi = X[ii, ], ai = ai, bi = bi)
    }
    out
  }
  hazchf <- function(id, times) {
    dd <- dta[as.character(dta$id) == as.character(id), , drop = FALSE]
    cbind(time = as.numeric(times),
          true_hazard = as.numeric(haz(times, dd)[1, ]),
          true_chf = as.numeric(chf(times, dd)[1, ]))
  }
  list(dta = dta, haz = haz, chf = chf, hazchf = hazchf,
       scale = s, truth = truth, type = "hazard.2b")
}
######################################################################
## Simulation 3b: local longitudinal risk region with tunable rectangle
## modified from original simulation 3 (no depracated)
## 
##
## The two time-dependent trajectories are latent intercept/slope
## processes that are not baseline covariates:
##
##   W4_i(t) = A4_i + B4_i t,
##   W5_i(t) = A5_i + B5_i t,
##
## with A4_i, A5_i iid U(0,1).  The row-level learner-facing covariates
## are evaluated at the stop time:
##
##   xtd1 = W4_i(stop),   xtd2 = W5_i(stop).
##
## The hazard is elevated when the current longitudinal state lies inside
## a local rectangular region:
##
##   lambda_i(t) = (1 + t) exp{ beta1*x1 + beta2*x2
##                              + gamma * 1(region_i(t)) }.
##
## Region experimentation examples:
##
##   hazard.simulation(type = 3, region.preset = "wide")
##   hazard.simulation(type = 3,
##     region = c(w4.lower = 0.25, w4.upper = 0.85,
##                w5.lower = 0.20, w5.upper = 0.80),
##     gamma = 1.5)
##   hazard.simulation(type = 3,
##     w4.region = c(0.20, 0.90), w5.region = c(0.15, 0.85),
##     gamma = 1.75)
######################################################################
hazard.3b.region.presets <- function() {
  list(
    current = list(
      region = c(w4.lower = 0.35, w4.upper = 0.75,
                 w5.lower = 0.25, w5.upper = 0.65),
      gamma = 1.25
    ),
    wide = list(
      region = c(w4.lower = 0.25, w4.upper = 0.85,
                 w5.lower = 0.20, w5.upper = 0.80),
      gamma = 1.50
    ),
    wide.strong = list(
      region = c(w4.lower = 0.25, w4.upper = 0.85,
                 w5.lower = 0.20, w5.upper = 0.80),
      gamma = 1.75
    ),
    very.wide = list(
      region = c(w4.lower = 0.20, w4.upper = 0.90,
                 w5.lower = 0.15, w5.upper = 0.85),
      gamma = 1.50
    )
  )
}
.hazard3b_parse_region <- function(region = NULL,
                                    w4.region = NULL,
                                    w5.region = NULL,
                                    w4.lower = NULL,
                                    w4.upper = NULL,
                                    w5.lower = NULL,
                                    w5.upper = NULL) {
  if (is.null(region)) {
    region <- hazard.3b.region.presets()$current$region
  }
  if (is.list(region) && !is.data.frame(region)) {
    if (!is.null(region$w4)) {
      w4.region <- region$w4
    }
    if (!is.null(region$w5)) {
      w5.region <- region$w5
    }
    if (!is.null(region$gamma)) {
      ## Parsed by hazard.3b(), not here.
    }
    if (!is.null(w4.region) && !is.null(w5.region)) {
      region <- c(w4.region, w5.region)
    } else if (all(c("w4.lower", "w4.upper", "w5.lower", "w5.upper") %in% names(region))) {
      region <- unlist(region[c("w4.lower", "w4.upper", "w5.lower", "w5.upper")])
    } else {
      stop("hazard.3b: list 'region' must contain w4/w5 vectors or named bounds.")
    }
  }
  if (!is.null(w4.region)) {
    if (length(w4.region) != 2L) stop("hazard.3b: 'w4.region' must have length 2.")
    region[1:2] <- as.numeric(w4.region)
  }
  if (!is.null(w5.region)) {
    if (length(w5.region) != 2L) stop("hazard.3b: 'w5.region' must have length 2.")
    region[3:4] <- as.numeric(w5.region)
  }
  region <- as.numeric(region)
  if (length(region) != 4L || any(!is.finite(region))) {
    stop("hazard.3b: 'region' must be a finite numeric vector of length 4.")
  }
  names(region) <- c("w4.lower", "w4.upper", "w5.lower", "w5.upper")
  if (!is.null(w4.lower)) region["w4.lower"] <- as.numeric(w4.lower)
  if (!is.null(w4.upper)) region["w4.upper"] <- as.numeric(w4.upper)
  if (!is.null(w5.lower)) region["w5.lower"] <- as.numeric(w5.lower)
  if (!is.null(w5.upper)) region["w5.upper"] <- as.numeric(w5.upper)
  if (!(region["w4.lower"] < region["w4.upper"]) ||
      !(region["w5.lower"] < region["w5.upper"])) {
    stop("hazard.3b: region lower bounds must be smaller than upper bounds.")
  }
  region
}
hazard.3b <- function(n = 500, p = 10, nrecords = 7, scale = FALSE,
                      b4 = 0, b5 = 0,
                      b4_sd = 0.5, b5_sd = 0.5,
                      slope.clip = 4,
                      gamma = NULL,
                      region = NULL,
                      region.preset = NULL,
                      w4.region = NULL, w5.region = NULL,
                      w4.lower = NULL, w4.upper = NULL,
                      w5.lower = NULL, w5.upper = NULL,
                      beta1 = 0.3, beta2 = -0.3,
                      ## Compatibility with older tuning names.
                      a4 = NULL, a5 = NULL,
                      a4_sd = NULL, a5_sd = NULL) {
  if (!is.null(a4)) b4 <- a4
  if (!is.null(a5)) b5 <- a5
  if (!is.null(a4_sd)) b4_sd <- a4_sd
  if (!is.null(a5_sd)) b5_sd <- a5_sd
  presets <- hazard.3b.region.presets()
  region.label <- "custom"
  if (!is.null(region.preset)) {
    region.preset <- as.character(region.preset)[1L]
    if (!region.preset %in% names(presets)) {
      stop("hazard.3b: unknown region.preset. Available presets are: ",
           paste(names(presets), collapse = ", "))
    }
    region <- presets[[region.preset]]$region
    if (is.null(gamma)) gamma <- presets[[region.preset]]$gamma
    region.label <- region.preset
  }
  if (is.null(gamma) && is.list(region) && !is.null(region$gamma)) {
    gamma <- as.numeric(region$gamma)
  }
  if (is.null(gamma)) gamma <- presets$current$gamma
  gamma <- as.numeric(gamma)
  region <- .hazard3b_parse_region(region = region,
                                    w4.region = w4.region,
                                    w5.region = w5.region,
                                    w4.lower = w4.lower,
                                    w4.upper = w4.upper,
                                    w5.lower = w5.lower,
                                    w5.upper = w5.upper)
  w4.lower <- unname(region["w4.lower"])
  w4.upper <- unname(region["w4.upper"])
  w5.lower <- unname(region["w5.lower"])
  w5.upper <- unname(region["w5.upper"])
  if (!is.finite(gamma)) {
    stop("hazard.3b: 'gamma' must be finite.")
  }
  if (b4_sd < 0 || b5_sd < 0) {
    stop("hazard.3b: slope standard deviations must be nonnegative.")
  }
  if (!is.finite(slope.clip) || slope.clip < 0) {
    stop("hazard.3b: 'slope.clip' must be a finite nonnegative value.")
  }
  p <- max(5, p)
  x <- matrix(runif(n * p), n)
  if (nrecords > 1) {
    id.nrecords <- 1 + rbinom(n, size = nrecords - 1, prob = 0.7)
  } else {
    id.nrecords <- rep(1, n)
  }
  A4_i <- runif(n)
  A5_i <- runif(n)
  B4_i <- rnorm(n, mean = b4, sd = b4_sd)
  B5_i <- rnorm(n, mean = b5, sd = b5_sd)
  if (b4_sd > 0 && slope.clip > 0) {
    B4_i <- pmin(pmax(B4_i, b4 - slope.clip * b4_sd), b4 + slope.clip * b4_sd)
  }
  if (b5_sd > 0 && slope.clip > 0) {
    B5_i <- pmin(pmax(B5_i, b5 - slope.clip * b5_sd), b5 + slope.clip * b5_sd)
  }
  names(A4_i) <- names(A5_i) <- names(B4_i) <- names(B5_i) <- as.character(seq_len(n))
  base_fun <- function(xi) {
    x1 <- unname(as.numeric(xi[1L]))
    x2 <- unname(as.numeric(xi[2L]))
    unname(beta1 * x1 + beta2 * x2)
  }
  between_interval <- function(A, B, lower, upper) {
    A <- unname(as.numeric(A)); B <- unname(as.numeric(B))
    lower <- unname(as.numeric(lower)); upper <- unname(as.numeric(upper))
    if (abs(B) < 1e-12) {
      if (A > lower && A < upper) c(-Inf, Inf) else c(Inf, -Inf)
    } else {
      sort(c((lower - A) / B, (upper - A) / B))
    }
  }
  intersect_interval <- function(a, b) {
    lo <- max(a[1L], b[1L], 0)
    hi <- min(a[2L], b[2L])
    if (!is.finite(lo) && lo < 0) lo <- 0
    if (hi <= lo) c(Inf, -Inf) else c(lo, hi)
  }
  region_interval <- function(A4, A5, B4, B5) {
    i4 <- between_interval(A4, B4, w4.lower, w4.upper)
    i5 <- between_interval(A5, B5, w5.lower, w5.upper)
    intersect_interval(i4, i5)
  }
  J0 <- function(t) {
    t <- pmax(as.numeric(t), 0)
    t + 0.5 * t^2
  }
  J_interval <- function(lo, hi) {
    if (!is.finite(lo) || !is.finite(hi) || hi <= lo) return(0)
    (hi - lo) + 0.5 * (hi^2 - lo^2)
  }
  active_J <- function(t, A4, A5, B4, B5) {
    t <- as.numeric(t)
    if (t <= 0) return(0)
    ri <- region_interval(A4, A5, B4, B5)
    lo <- max(0, ri[1L])
    hi <- min(t, ri[2L])
    J_interval(lo, hi)
  }
  active_indicator <- function(t, A4, A5, B4, B5) {
    if (t < 0) return(FALSE)
    w4 <- A4 + B4 * t
    w5 <- A5 + B5 * t
    isTRUE(w4 > w4.lower && w4 < w4.upper && w5 > w5.lower && w5 < w5.upper)
  }
  H_fun_i <- function(t, xi, A4, A5, B4, B5) {
    t <- as.numeric(t)
    if (t <= 0) return(0)
    base <- base_fun(xi)
    exp(base) * (J0(t) + (exp(gamma) - 1) * active_J(t, A4, A5, B4, B5))
  }
  h_fun_i <- function(t, xi, A4, A5, B4, B5) {
    t <- as.numeric(t)
    if (t < 0) return(NA_real_)
    base <- base_fun(xi)
    ind <- active_indicator(t, A4, A5, B4, B5)
    (1 + t) * exp(base + gamma * as.numeric(ind))
  }
  dta <- do.call(rbind, lapply(seq_len(n), function(i) {
    xi <- x[i, ]
    A4 <- A4_i[i]; A5 <- A5_i[i]
    B4 <- B4_i[i]; B5 <- B5_i[i]
    target <- -log(runif(1))
    upper <- 1
    H.upper <- H_fun_i(upper, xi, A4, A5, B4, B5)
    while (H.upper < target && upper < 1e3) {
      upper <- 2 * upper
      H.upper <- H_fun_i(upper, xi, A4, A5, B4, B5)
    }
    if (H.upper < target) {
      Tm <- Inf
    } else {
      Tm <- uniroot(function(t) H_fun_i(t, xi, A4, A5, B4, B5) - target,
                    interval = c(0, upper), tol = 1e-8)$root
    }
    Ce <- -4 * log(runif(1))
    observed.time <- min(Tm, Ce)
    nrec <- id.nrecords[i]
    if (nrec > 1) {
      tseq <- c(sort(runif(nrec - 1, 0, observed.time)), observed.time)
    } else {
      tseq <- observed.time
    }
    start <- c(0, head(tseq, -1))
    stop <- tseq
    event <- as.integer((Tm <= Ce) & (Tm <= stop))
    xtd1 <- A4 + B4 * stop
    xtd2 <- A5 + B5 * stop
    dta.i <- data.frame(id = i,
                        start = start,
                        stop = stop,
                        event = event,
                        xtd1 = xtd1,
                        xtd2 = xtd2)
    data.frame(dta.i,
               x = do.call(cbind, lapply(x[i, ], function(xx) rep(xx, nrec))))
  }))
  s <- if (isTRUE(scale)) {
    1 / max(dta$stop)
  } else if (isFALSE(scale)) {
    1
  } else if (is.numeric(scale) && length(scale) == 1L) {
    as.numeric(scale)
  } else {
    1
  }
  dta$start <- s * dta$start
  dta$stop <- s * dta$stop
  haz <- function(time, x) {
    time <- as.numeric(time)
    ids <- as.character(x[, "id"])
    id.unq <- unique(ids)
    X <- as.matrix(x[match(id.unq, ids), grepl("^x\\.", names(x)), drop = FALSE])
    t0 <- time / s
    out <- matrix(NA_real_, nrow = length(id.unq), ncol = length(t0),
                  dimnames = list(id.unq, NULL))
    for (ii in seq_along(id.unq)) {
      id <- id.unq[ii]
      out[ii, ] <- vapply(t0, h_fun_i, numeric(1L),
                          xi = X[ii, ],
                          A4 = A4_i[id], A5 = A5_i[id],
                          B4 = B4_i[id], B5 = B5_i[id]) / s
    }
    out
  }
  chf <- function(time, x) {
    time <- as.numeric(time)
    ids <- as.character(x[, "id"])
    id.unq <- unique(ids)
    X <- as.matrix(x[match(id.unq, ids), grepl("^x\\.", names(x)), drop = FALSE])
    t0 <- time / s
    out <- matrix(NA_real_, nrow = length(id.unq), ncol = length(t0),
                  dimnames = list(id.unq, NULL))
    for (ii in seq_along(id.unq)) {
      id <- id.unq[ii]
      out[ii, ] <- vapply(t0, H_fun_i, numeric(1L),
                          xi = X[ii, ],
                          A4 = A4_i[id], A5 = A5_i[id],
                          B4 = B4_i[id], B5 = B5_i[id])
    }
    out
  }
  hazchf <- function(id, times) {
    dd <- dta[as.character(dta$id) == as.character(id), , drop = FALSE]
    cbind(time = as.numeric(times),
          true_hazard = as.numeric(haz(times, dd)[1L, ]),
          true_chf = as.numeric(chf(times, dd)[1L, ]))
  }
  truth <- data.frame(
    id = seq_len(n),
    A4 = as.numeric(A4_i),
    A5 = as.numeric(A5_i),
    B4 = as.numeric(B4_i),
    B5 = as.numeric(B5_i),
    A4_intercept = as.numeric(A4_i),
    A5_intercept = as.numeric(A5_i),
    B4_slope = as.numeric(B4_i),
    B5_slope = as.numeric(B5_i)
  )
  list(dta = dta,
       haz = haz,
       chf = chf,
       hazchf = hazchf,
       scale = s,
       truth = truth,
       type = "hazard.3b",
       parameters = list(
         mechanism = "local_longitudinal_risk_region",
         region.label = region.label,
         region = region,
         b4 = b4, b5 = b5,
         b4_sd = b4_sd, b5_sd = b5_sd,
         slope.clip = slope.clip,
         gamma = gamma,
         w4.lower = w4.lower, w4.upper = w4.upper,
         w5.lower = w5.lower, w5.upper = w5.upper,
         beta = c(beta1 = beta1, beta2 = beta2)
       ))
}
