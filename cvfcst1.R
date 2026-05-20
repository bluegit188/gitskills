cvfcst1 <- function(form, data, byvarname, func, fold)
# return y, yhat(cvfcst), ymean_cv
# usage: cvFcst=cvfcst1( ooF1D ~ SP.CC.1 + SP.CC.2 + VX.CC.1 + JY.CC.1 , regdata, "DATE", lm, 10)
{
  uniquevar <- unique(data[[byvarname]])
  #uniquevar <- unique(data$DATE)
   N <- length(uniquevar)
  if(missing(fold)){
    # USE  loo_cvfcst
    fold <- N
    varspliter <- c(1:N, N)
  } else {
    varstep <- ceiling(N/fold)
    varspliter <- c(varstep*(0:(fold-1))+1, N)
  }
  
  yname <- all.vars(form)[1]
  xnames <- all.vars(form)[-1]
  nx <- length(xnames)
  cvys <- data.frame(y=data[[yname]], yhat=rep(0, nrow(data)), cv_ymean=rep(0, nrow(data)))

  for (i in 1:fold){
    modeldata <- data[!(data[[byvarname]] %in% uniquevar[varspliter[i]:(varspliter[i+1]-1)]),]
    newdata <- data[data[[byvarname]] %in% uniquevar[varspliter[i]:(varspliter[i+1]-1)],]
    # assign value to yhat
    cvys[data[[byvarname]] %in% uniquevar[varspliter[i]:(varspliter[i+1]-1)], 2] <- 
      predict(func(form, modeldata),newdata)
    # assign value to cv_ymean
    cvys[data[[byvarname]] %in% uniquevar[varspliter[i]:(varspliter[i+1]-1)], 3] <-
      mean(modeldata[[yname]])
  }
  # plot(cvys$yhat, cvys$y) #[wz] this line is for testing purpose
  R2 <- c(0,0)
  names(R2) <- c("cv","y~x")
  ### mis-specified R2, simple R2 w/o intercept
  ###R2[1] <- summary(lm(y~yhat-1, cvys))$r.squared
  # R2 where ymean is from corresponding in-sample CV folds
  R2[1] <- 1-sum((cvys[,1]-cvys[,2])^2)/sum((cvys[,1]-cvys[,3])^2)
  R2[2] <- summary(lm(form, data))$r.squared
  #return(R2)
  return(cvys)
}
