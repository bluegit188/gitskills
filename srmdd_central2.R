# '@param posType - 0: optXT 1: optZ 2:optZA 
SrMdd2 <- function(model, dataTable, tcost=0.0, sizeX=0.0, posType=c(0,1,2), methodStr="Nelder-Mead",lambda=1, verbose=FALSE) {
  #  method = c("Nelder-Mead", "BFGS", "CG", "L-BFGS-B", "SANN", "Brent"),
  #0=optXT  1=optZ 2=optZA
  # Check inputs
  if (missing(dataTable))
    stop("Need to specify the data table.")
  if (!any("DATE" == colnames(dataTable)))
    stop("dataTable need DATE column!!")
  
  mf <- model.frame(formula=model, data=dataTable)
  y <- model.response(mf)
  x <- model.matrix(attr(mf, "terms"), data=mf)
  
  qtrLen <- dim(x)[2]
  dataTable$tcost <- tcost
  dataTable$y <- y
  ret = list()
  
  # centralize predictor
  x_mean = colMeans(x)
  for (i in c(2:qtrLen)) {
    x[,i] <- x[,i] - x_mean[i]
  }

  nwgts <- function(wgts) {
    wgts = c(0, wgts)
    yhat <- x %*% wgts
    tempLM <- lm(y~yhat)
    coeff <- tempLM$coefficients['yhat']* wgts
    coeff[1] <- tempLM$coefficients['(Intercept)']
    return (coeff)
  }
  
  optZA <- function(fcst, SYM, adj) {
    len <- length(fcst)
    pos <- numeric(len)
    pos[1] <- (abs(fcst[1]) - sizeX) * sign(fcst[1])* (abs(fcst[1])-sizeX > 0)
    for (i in c(2:len)) {
      if (SYM[i-1] != SYM[i]) {
        pos[i] <- (abs(fcst[i]) - sizeX) * sign(fcst[i])*(abs(fcst[i])-sizeX > 0)
      } else {
        if (pos[i-1] > fcst[i]) {
          pos[i] <- min(fcst[i] + sizeX, pos[i-1])
        } else {
          pos[i] <- max(fcst[i] - sizeX, pos[i-1])
        }
        if (adj) {
          pos[i] <- pos[i] * (pos[i]*fcst[i] > 0)
        }
      }
    }
    
    return(pos)
  }
  
  calc <- function(wgts)
  {
    ret$lmCoefs <- nwgts(wgts)
    dataTable$x <- x %*% ret$lmCoefs
    if (sum(y*dataTable$x) < 0) {
      dataTable$x <- -dataTable$x
    }
    
    if (posType == 0)
    {
      dataTable <- dataTable %>%
        dplyr::group_by(SYM) %>%
        dplyr::mutate( pos = sign(x) * (abs(x) - sizeX) * (abs(x) >= sizeX) ) %>%
        dplyr::mutate( pnl = y*pos - tcost * abs(pos - dplyr::lag(pos, default = 0, order_by = DATE)) )
    }
    else {
      dataTable$pos = optZA(dataTable$x, dataTable$SYM, posType == 2)
      dataTable <- dataTable %>%
        dplyr::group_by(SYM) %>%
        dplyr::mutate( pnl = y*pos - tcost * abs(pos - dplyr::lag(pos, default = 0, order_by = DATE)) )
    }
    
    groupData <- dataTable %>% dplyr::group_by(DATE) %>% dplyr::summarise(pnl = sum(pnl))
    ppnlStd <- sd(groupData$pnl)
    ret$portfolioSharpeRatio <- mean(groupData$pnl) / ppnlStd * sqrt(252)
    ret$MDD <- tseries::maxdrawdown(cumsum(groupData$pnl))$maxdrawdown / ppnlStd / sqrt(252)
    return(ret)
  }
  
  objFunc <- function(wgts) 
  {
    ret = calc(wgts)
    eval = ret$portfolioSharpeRatio - lambda * ret$MDD
    if (verbose) 
      print (cat("wgts=", ret$lmCoefs, "shp=", ret$portfolioSharpeRatio,"MDD=", ret$MDD, "objFunc=", eval))
    return (-eval)
  }
  
  #junf: use OLS coef as init guess
  lmfit=lm(model, dataTable);
  lmCoefs=summary(lmfit)$coefficients[2:qtrLen]; # ignore intercept

  #lmCoefs <- rep(1, qtrLen - 1)
  #lmCoefs=c(0.05,-0.15,0.05)
  #ret <- nlminb(lmCoefs, objFunc)
  #ret <- optimx(lmCoefs, objFunc,  method = "BFGS",control = list(maxit = 5000))
  ret <- optim(lmCoefs, objFunc, method = methodStr,control = list(maxit = 5000))
  #ret <- solnp(lmCoefs, objFunc)


  stcalc <- calc(ret$par)
  ret$portfolioSharpeRatio <- stcalc$portfolioSharpeRatio
  ret$MDD <- stcalc$MDD
  
  for (i in c(2:qtrLen)) {
    x[,i] <- x[,i] + x_mean[i]
  }
  ret$npar <- nwgts(ret$par)
  
  # print coefs in vertical format
  #SMCoefs=data.table(cbind(dimnames(summary(lmfit)$coefficients)[[1]],round(summary(lmfit)$coefficients[1:qtrLen],digits=7)))
  SMCoefs=data.table(cbind(dimnames(summary(lmfit)$coefficients)[[1]],round(ret$npar,digits=7)))
  names(SMCoefs)=c("indicator", "coef")
  ret$SMCoefs=SMCoefs


  return (ret)
}
