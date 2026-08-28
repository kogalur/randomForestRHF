get.lot <- function(hcut = 1,
                    tune = TRUE,
                    lag = NULL,
                    strikeout = NULL,
                    max.two   = NULL,
                    max.three = NULL,
                    max.four  = NULL) {
  ## legacy: plays no role here
  if (is.null(lag)) {
    lag <- 50
  }
  if (tune == FALSE) {
    lag <- 0
  }
  if (is.null(strikeout)) {
    strikeout <- 7
  }
  if (is.null(max.two)) {
    max.two <- 200
  }
  if (is.null(max.three)) {
    max.three <- 60
  }
  if (is.null(max.four)) {
    max.four <- 30
  }
  ## return the object: key is treesize
  list(hcut = as.integer(hcut),  
       lag = as.integer(lag),
       strikeout = as.integer(strikeout),
       max.two = as.integer(max.two),
       max.three = as.integer(max.three),
       max.four = as.integer(max.four)
       )
}
get.splitinfo <- function(formula.detail, splitrule, nsplit) {
  ## CAUTION: HARD CODED ON NATIVE SIDE
  splitrule.names <- c("sg.regr",             ##  1
                       "sg.class",            ##  2
                       "cart.regr",           ##  3
                       "cart.class",          ##  4
                       "cart.random",         ##  5
                       "hazard.loglik",          ##  6
                       "hazard.nelson.aalen")    ##  7  
  ## set the split rule
  ## Note no error checking for now. TBD
  if (is.null(splitrule)) {
      splitrule <- "hazard.loglik"
  }
  splitrule.idx <- which(splitrule.names == splitrule)
  if (length(splitrule.idx) == 0) {
    stop("invalid split rule:  ", splitrule)
  }
  ## set nsplit
  if(!is.null(nsplit)) {
    nsplit <- round(nsplit)    
    if (nsplit < 0) {
      stop("invalid nsplit value: set nsplit >= 0")
    }
  }
  else {
    nsplit <- 10
  }
  list(splitrule = splitrule, index = splitrule.idx, nsplit = nsplit)
}
